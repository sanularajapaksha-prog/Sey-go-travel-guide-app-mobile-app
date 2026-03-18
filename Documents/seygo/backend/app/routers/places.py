import os
import json
import re

from fastapi import APIRouter, Depends, HTTPException, Query, status
import httpx

from ..dependencies import get_current_user, get_supabase_client
from ..schemas.google_places import GooglePlacesSearchRequest
from ..schemas.place import PlaceCreate
from ..schemas.recommendation import MLRecommendationRequest, PlaceRecommendationRequest
from ..services.google_photo_resolver import (
    GOOGLE_IMAGE_HEADERS,
    append_maxwidth,
    is_direct_image_url,
    is_missing_column_error,
    is_valid_http_url,
    resolve_photo_url_from_google_url,
    update_place_photo_cache,
)
from ..services.google_places import GooglePlacesService
from ..services.place_taxonomy import PLACE_TAXONOMY, infer_taxonomy
from ..services.ml_recommender import MLRecommender
from ..services.recommender import PlaceFeature, PlaceRecommender, _haversine_km

router = APIRouter(prefix='/places', tags=['places'])
recommender = PlaceRecommender()
ml_recommender = MLRecommender()
google_places_service = GooglePlacesService()
# Default table name corrected to the expected `places`.
PLACES_TABLE = os.getenv('SUPABASE_PLACES_TABLE', 'placses')
PHOTOS_BUCKET = os.getenv('SUPABASE_PLACE_PHOTOS_BUCKET', 'place-photos')
SUPABASE_URL = os.getenv('SUPABASE_URL', '').rstrip('/')
PHOTOS_PRIVATE = os.getenv('SUPABASE_PLACE_PHOTOS_PRIVATE', 'false').lower() == 'true'


def _parse_tags(value) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        if not value.strip():
            return []
        return [part.strip() for part in value.split(',') if part.strip()]
    return []


def _parse_categories(value) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        text = value.strip()
        if not text:
            return []
        try:
            decoded = json.loads(text)
            if isinstance(decoded, list):
                return [str(item).strip() for item in decoded if str(item).strip()]
        except Exception:
            pass
        return [part.strip() for part in text.split(',') if part.strip()]
    return []


def _resolve_primary_category(row: dict) -> str:
    category = _first_non_empty(row, ['primary_category', 'category', 'type', 'primary_type'])
    if category is not None and str(category).strip():
        text = str(category).strip()
        if text.lower() != 'unknown':
            return text

    categories = _parse_categories(_first_non_empty(row, ['categories', 'category_list']))
    if categories:
        return categories[0]
    return 'unknown'


def _first_non_empty(row: dict, keys: list[str]):
    lowered_map = {str(k).lower(): k for k in row.keys()}
    for key in keys:
        value = row.get(key)
        if value is None:
            real_key = lowered_map.get(key.lower())
            if real_key is not None:
                value = row.get(real_key)
        if value is None:
            continue
        if isinstance(value, str) and not value.strip():
            continue
        return value
    return None


def _coerce_float(value, default: float | None = None) -> float | None:
    if value is None:
        return default
    try:
        return float(value)
    except Exception:
        return default


def _coerce_list(value) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        text = value.strip()
        if not text:
            return []
        try:
            decoded = json.loads(text)
            if isinstance(decoded, list):
                return [str(item).strip() for item in decoded if str(item).strip()]
        except Exception:
            pass
        return [item.strip() for item in text.split(',') if item.strip()]
    return []


def _extract_photo_path(row: dict) -> str | None:
    for key in ['photo_url', 'image_url', 'place_url', 'photo_path', 'image_path', 'photo', 'image', 'photo_key', 'image_key']:
        value = _first_non_empty(row, [key])
        if isinstance(value, str) and value.strip():
            raw = value.strip()
            if raw.startswith('http://') or raw.startswith('https://'):
                return raw
            return raw.lstrip('/')
    storage_paths = _first_non_empty(row, ['photo_storage_paths', 'image_storage_paths'])
    if isinstance(storage_paths, list):
        for item in storage_paths:
            if isinstance(item, str) and item.strip():
                return item.strip().lstrip('/')
    if isinstance(storage_paths, str) and storage_paths.strip():
        return storage_paths.strip().lstrip('/')
    return None


def _guess_photo_path_from_row(row: dict) -> str | None:
    # Disabled expensive bucket scanning to keep /places fast.
    return None


def _storage_public_url(supabase, path: str) -> str | None:
    try:
        if path.startswith('http://') or path.startswith('https://'):
            return path

        # Fast deterministic public URL for public buckets.
        if SUPABASE_URL:
            public_url = f'{SUPABASE_URL}/storage/v1/object/public/{PHOTOS_BUCKET}/{path.lstrip("/")}'
            if not PHOTOS_PRIVATE:
                return public_url

        # For private buckets only, generate signed URL.
        if PHOTOS_PRIVATE:
            signed = supabase.storage.from_(PHOTOS_BUCKET).create_signed_url(path, 60 * 60 * 24)
            if isinstance(signed, dict):
                signed_url = signed.get('signedURL') or signed.get('signedUrl')
                if isinstance(signed_url, str) and signed_url.startswith('http'):
                    return signed_url
                data = signed.get('data')
                if isinstance(data, dict):
                    signed_url = data.get('signedURL') or data.get('signedUrl')
                    if isinstance(signed_url, str) and signed_url.startswith('http'):
                        return signed_url
        return None
    except Exception:
        return None


_GMAPS_COORD_RE = re.compile(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)')


def _coords_from_google_url(url: str | None) -> tuple[float | None, float | None]:
    """Extract lat/lng from a Google Maps URL like .../place/Name/@7.2906,80.6337,17z/..."""
    if not url:
        return (None, None)
    m = _GMAPS_COORD_RE.search(url)
    if m:
        try:
            return (float(m.group(1)), float(m.group(2)))
        except Exception:
            pass
    return (None, None)


def _normalize_place_row(supabase, row: dict) -> dict:
    normalized = dict(row)
    # Storage bucket was deleted — skip all storage-based photo resolution.
    # Photos are resolved client-side via google_url using the Places API.
    photo_public_urls: list[str] = []

    normalized['photo_public_urls'] = photo_public_urls
    normalized['image_url'] = None
    normalized['image_source'] = _first_non_empty(row, ['image_source'])
    normalized['photo_last_checked'] = _first_non_empty(row, ['photo_last_checked'])
    normalized['photo_url'] = None
    normalized['name'] = str(_first_non_empty(row, ['name', 'place_name', 'title']) or '')
    normalized['primary_category'] = _resolve_primary_category(row)
    normalized['category'] = normalized['primary_category']
    normalized['categories'] = _parse_categories(_first_non_empty(row, ['categories', 'category_list']))
    normalized['description'] = _first_non_empty(row, ['description', 'details', 'summary']) or ''
    normalized['location'] = _first_non_empty(row, ['location', 'formatted_address', 'address']) or ''
    google_url = _first_non_empty(row, ['google_url'])
    normalized['google_url'] = google_url
    normalized['tags'] = _parse_tags(_first_non_empty(row, ['tags', 'keywords', 'labels']))

    lat = _coerce_float(_first_non_empty(row, ['latitude', 'lat']))
    lng = _coerce_float(_first_non_empty(row, ['longitude', 'lng', 'lon']))

    # If coordinates missing from DB columns, try extracting from google_url
    if lat is None or lng is None:
        url_lat, url_lng = _coords_from_google_url(google_url)
        if lat is None:
            lat = url_lat
        if lng is None:
            lng = url_lng

    normalized['latitude'] = lat
    normalized['longitude'] = lng
    normalized['avg_rating'] = _coerce_float(_first_non_empty(row, ['avg_rating', 'rating']), 0.0) or 0.0
    normalized['review_count'] = int(_first_non_empty(row, ['review_count', 'reviews', 'user_rating_count']) or 0)
    return normalized


def _legacy_place_photo_url(client: httpx.Client, place_id: str, api_key: str) -> str | None:
    details_response = client.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        params={
            'place_id': place_id,
            'fields': 'photo',
            'key': api_key,
        },
        headers=GOOGLE_IMAGE_HEADERS,
    )
    details_response.raise_for_status()
    payload = details_response.json()

    result = payload.get('result') or {}
    photos = result.get('photos') or []
    if not photos:
        return None

    photo_reference = photos[0].get('photo_reference')
    if not isinstance(photo_reference, str) or not photo_reference.strip():
        return None

    return (
        'https://maps.googleapis.com/maps/api/place/photo'
        f'?maxheight=600&maxwidth=900&photo_reference={photo_reference}&key={api_key}'
    )


def _to_place_feature(row: dict) -> PlaceFeature:
    tags = _parse_tags(_first_non_empty(row, ['tags', 'keywords', 'labels']))
    latitude = _coerce_float(_first_non_empty(row, ['latitude', 'lat']), 0.0) or 0.0
    longitude = _coerce_float(_first_non_empty(row, ['longitude', 'lng', 'lon']), 0.0) or 0.0
    name = str(_first_non_empty(row, ['name', 'place_name', 'title']) or '')
    category = _resolve_primary_category(row)
    description = _first_non_empty(row, ['description', 'details', 'summary'])
    taxonomy_category, taxonomy_group = infer_taxonomy(
        name,
        category,
        tags,
        description,
    )
    return PlaceFeature(
        place_id=str(row.get('id', '')),
        name=name,
        category=category,
        tags=tags,
        latitude=latitude,
        longitude=longitude,
        avg_rating=float(_first_non_empty(row, ['avg_rating', 'rating']) or 0.0),
        review_count=int(_first_non_empty(row, ['review_count', 'reviews', 'user_rating_count']) or 0),
        description=description,
        taxonomy_category=taxonomy_category,
        taxonomy_group=taxonomy_group,
    )


def _fetch_all_places_rows(supabase) -> list[dict]:
    rows: list[dict] = []
    start = 0
    step = 1000
    while True:
        response = supabase.table(PLACES_TABLE).select('*').range(start, start + step - 1).execute()
        batch = response.data or []
        rows.extend(batch)
        if len(batch) < step:
            break
        start += step
    return rows


@router.get('/')
def get_places(limit: int = 500, offset: int = 0):
    supabase = get_supabase_client()
    try:
        sb = _create_client(os.environ['SUPABASE_URL'], os.environ['SUPABASE_SERVICE_ROLE_KEY'])
        response = sb.table(PLACES_TABLE).select('*').range(offset, offset + limit - 1).execute()
        rows = response.data or []
        return [_normalize_place_row(sb, row) for row in rows]
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f'Failed to fetch places: {exc}',
        ) from exc


@router.post('/')
async def create_place(
    place: PlaceCreate,
    user=Depends(get_current_user),
):
    try:
        supabase = get_supabase_client()
        payload = place.model_dump()
        payload['created_by'] = str(user.id)

        response = supabase.table(PLACES_TABLE).insert(payload).execute()
        created_rows = response.data or []
        if not created_rows:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail='Insert succeeded but returned no rows.',
            )
        return created_rows[0]
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f'Failed to create place: {exc}',
        ) from exc


@router.post('/recommend')
async def recommend_places(
    request: PlaceRecommendationRequest,
    user=Depends(get_current_user),
):
    try:
        supabase = get_supabase_client()
        place_rows = _fetch_all_places_rows(supabase)

        places = [
            _to_place_feature(row)
            for row in place_rows
            if row.get('latitude') is not None and row.get('longitude') is not None
        ]

        results = recommender.recommend(
            places=places,
            preference_tags=request.preference_tags,
            selected_categories=request.selected_categories,
            selected_group=request.selected_group,
            latitude=request.latitude,
            longitude=request.longitude,
            search_keyword=request.search_keyword,
            radius_km=request.radius_km,
            top_n=request.top_n,
        )
        return {
            'user_id': str(user.id),
            'count': len(results),
            'selected_categories': request.selected_categories,
            'selected_group': request.selected_group,
            'recommendations': [item.model_dump() for item in results],
        }
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f'Failed to generate recommendations: {exc}',
        ) from exc


@router.post('/recommend-ml')
async def recommend_places_ml(
    request: MLRecommendationRequest,
    user=Depends(get_current_user),
):
    """Hybrid ML recommendation endpoint.

    Combines TF-IDF content-based similarity with collaborative filtering
    (SVD on saved_destinations) plus popularity and distance signals.
    Auto-trains the model on first call if no cached model exists.
    """
    try:
        supabase = get_supabase_client()
        result = ml_recommender.recommend(
            supabase,
            user_id=str(user.id),
            query=request.query,
            latitude=request.latitude,
            longitude=request.longitude,
            radius_km=request.radius_km,
            preferred_categories=request.preferred_categories or [],
            top_n=request.top_n,
        )
        return result
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f'ML recommendation failed: {exc}',
        ) from exc


@router.post('/recommend-ml/retrain')
async def retrain_ml_model(user=Depends(get_current_user)):
    """Force a synchronous retrain of the ML model.

    This re-fetches all places and saved_destinations from Supabase and
    rebuilds both the content-based and collaborative filtering models.
    May take several seconds on large datasets.
    """
    try:
        supabase = get_supabase_client()
        ml_recommender.retrain(supabase)
        return ml_recommender.model_info()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f'Retraining failed: {exc}',
        ) from exc


@router.get('/recommend-ml/info')
async def ml_model_info():
    """Return metadata about the currently loaded ML model (no auth required)."""
    return ml_recommender.model_info()


@router.get('/search')
async def search_places(
    q: str = Query(..., min_length=1),
    latitude: float | None = None,
    longitude: float | None = None,
    radius_km: float = 60.0,
    limit: int = 30,
):
    try:
        supabase = get_supabase_client()
        limit = max(1, min(limit, 100))
        query_text = q.strip()

        try:
            response = (
                supabase.table(PLACES_TABLE)
                .select('*')
                .text_search('search_vector', query_text, config='english')
                .limit(limit * 3)  
                .execute()
            )
            rows = response.data or []
        except Exception:
            
            response = (
                supabase.table(PLACES_TABLE)
                .select('*')
                .ilike('name', f'%{query_text}%')
                .limit(limit * 3)
                .execute()
            )
            rows = response.data or []

        supabase_client = get_supabase_client()
        normalized = [_normalize_place_row(supabase_client, row) for row in rows]

        if latitude is not None and longitude is not None:
            normalized = [
                row for row in normalized
                if row.get('latitude') is not None
                and row.get('longitude') is not None
                and _haversine_km(
                    float(latitude), float(longitude),
                    float(row['latitude']), float(row['longitude'])
                ) <= radius_km
            ]

        return {'count': len(normalized[:limit]), 'places': normalized[:limit]}

    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f'Search failed: {exc}',
        ) from exc

@router.post('/google/search')
async def google_places_search(request: GooglePlacesSearchRequest):
    try:
        return google_places_service.search_places(request)
    except httpx.HTTPStatusError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f'Google Places search failed: {exc.response.text}',
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f'Google Places search error: {exc}',
        ) from exc


@router.get('/google/details/{place_id}')
async def google_place_details(place_id: str):
    try:
        return google_places_service.place_details(place_id)
    except httpx.HTTPStatusError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f'Google Place details failed: {exc.response.text}',
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f'Google Place details error: {exc}',
        ) from exc


@router.get('/photo/{place_id}')
async def google_place_photo(place_id: str):
    api_key = os.getenv('GOOGLE_MAPS_API_KEY', '').strip()
    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail='GOOGLE_MAPS_API_KEY is not configured.',
        )

    try:
        with httpx.Client(timeout=15.0, follow_redirects=True) as client:
            photo_url: str | None = None
            try:
                details_response = client.get(
                    f'https://places.googleapis.com/v1/places/{place_id}',
                    headers={
                        'X-Goog-Api-Key': api_key,
                        'X-Goog-FieldMask': 'photos',
                    },
                )
                details_response.raise_for_status()
                details = details_response.json()

                photos = details.get('photos') or []
                if photos:
                    photo_name = photos[0].get('name')
                    if isinstance(photo_name, str) and photo_name.strip():
                        photo_url = (
                            f'https://places.googleapis.com/v1/{photo_name}/media'
                            f'?maxHeightPx=600&maxWidthPx=900&key={api_key}'
                        )
            except httpx.HTTPStatusError as exc:
                if exc.response.status_code != 403:
                    raise

            if photo_url is None:
                photo_url = _legacy_place_photo_url(client, place_id, api_key)

            if photo_url is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail='No photo available for this place.',
                )

            return {
                'success': True,
                'photo_url': append_maxwidth(photo_url),
                'source': 'google_place_id',
            }
    except HTTPException:
        raise
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f'Failed to fetch Google place photo: {exc}',
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f'Failed to resolve Google place photo: {exc}',
        ) from exc


@router.get('/photo-from-google-url')
async def photo_from_google_url(
    url: str = Query(..., min_length=1),
    place_id: str | None = Query(default=None),
):
    try:
        supabase = get_supabase_client()
        normalized_url = url.strip()
        if not normalized_url.startswith(('http://', 'https://')):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail='google_url must be an absolute URL.',
            )

        if place_id:
            cached_row = {}
            try:
                existing = (
                    supabase.table(PLACES_TABLE)
                    .select('image_url, photo_public_urls')
                    .eq('place_id', place_id)
                    .limit(1)
                    .execute()
                )
                cached_row = (existing.data or [{}])[0]
            except Exception as exc:
                if not is_missing_column_error(exc):
                    raise
            cached_image = _first_non_empty(cached_row, ['image_url'])
            if is_valid_http_url(cached_image):
                return {
                    'success': True,
                    'photo_url': append_maxwidth(cached_image),
                    'source': 'cached_image_url',
                    'cached': True,
                }
            public_urls = _coerce_list(cached_row.get('photo_public_urls'))
            if public_urls:
                return {
                    'success': True,
                    'photo_url': append_maxwidth(public_urls[0]),
                    'source': 'photo_public_urls',
                    'cached': True,
                }

        resolved_url = resolve_photo_url_from_google_url(normalized_url)
        if resolved_url:
            if place_id:
                update_place_photo_cache(
                    supabase,
                    PLACES_TABLE,
                    place_id,
                    image_url=resolved_url,
                    image_source='google_url_resolved',
                )
            return {
                'success': True,
                'photo_url': resolved_url,
                'source': 'google_url_resolved',
                'cached': False,
            }

        if place_id:
            update_place_photo_cache(
                supabase,
                PLACES_TABLE,
                place_id,
                image_url=None,
                image_source='google_url_failed',
            )

        return {
            'success': False,
            'photo_url': None,
            'source': None,
            'cached': False,
        }
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f'Failed to resolve photo from google_url: {exc}',
        ) from exc


@router.get('/categories')
async def get_place_categories():
    return {
        'groups': PLACE_TAXONOMY,
        'all_categories': [category for categories in PLACE_TAXONOMY.values() for category in categories],
    }
