import os
import html
import json
import re

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
import httpx

from ..dependencies import get_current_user, get_supabase_client
from ..schemas.google_places import GooglePlacesSearchRequest
from ..schemas.place import PlaceCreate
from ..schemas.recommendation import PlaceRecommendationRequest
from ..services.google_places import GooglePlacesService
from ..services.place_taxonomy import PLACE_TAXONOMY, infer_taxonomy
from ..services.recommender import PlaceFeature, PlaceRecommender, _haversine_km

router = APIRouter(prefix='/places', tags=['places'])
recommender = PlaceRecommender()
google_places_service = GooglePlacesService()
# Default table name corrected to the expected `places`.
PLACES_TABLE = os.getenv('SUPABASE_PLACES_TABLE', 'places')
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


def _normalize_place_row(supabase, row: dict) -> dict:
    normalized = dict(row)
    photo_path = _extract_photo_path(row) or _guess_photo_path_from_row(row)
    photo_url = _storage_public_url(supabase, photo_path) if photo_path else None
    if photo_url:
        normalized['photo_url'] = photo_url
    normalized['name'] = str(_first_non_empty(row, ['name', 'place_name', 'title']) or '')
    normalized['primary_category'] = _resolve_primary_category(row)
    normalized['category'] = normalized['primary_category']
    normalized['categories'] = _parse_categories(_first_non_empty(row, ['categories', 'category_list']))
    normalized['description'] = _first_non_empty(row, ['description', 'details', 'summary']) or ''
    normalized['location'] = _first_non_empty(row, ['location', 'formatted_address', 'address']) or ''
    normalized['tags'] = _parse_tags(_first_non_empty(row, ['tags', 'keywords', 'labels']))
    normalized['latitude'] = _coerce_float(_first_non_empty(row, ['latitude', 'lat']))
    normalized['longitude'] = _coerce_float(_first_non_empty(row, ['longitude', 'lng', 'lon']))
    normalized['avg_rating'] = _coerce_float(_first_non_empty(row, ['avg_rating', 'rating']), 0.0) or 0.0
    normalized['review_count'] = int(_first_non_empty(row, ['review_count', 'reviews', 'user_rating_count']) or 0)
    return normalized


def _extract_google_photo_url_from_page(page: str) -> str | None:
    og_match = re.search(
        r'<meta[^>]+property=["\']og:image["\'][^>]+content=["\']([^"\']+)["\']',
        page,
        flags=re.IGNORECASE,
    )
    if og_match:
        url = html.unescape(og_match.group(1))
        if _is_google_photo_candidate(url):
            return url

    for pattern in [
        r'https://[^"\']*(?:googleusercontent|ggpht\.com|streetviewpixels-pa\.googleapis\.com)[^"\']+',
        r'https://[^"\']*gstatic[^"\']*(?:/p/|=w\d+|=s\d+)[^"\']*',
    ]:
        for match in re.finditer(pattern, page, flags=re.IGNORECASE):
            url = html.unescape(match.group(0))
            if _is_google_photo_candidate(url):
                return url

    return None


def _is_google_photo_candidate(url: str) -> bool:
    lowered = url.lower()
    blocked_parts = [
        'fonts.gstatic.com',
        '/maps/_/',
        '/maps/vt',
        '/mapfiles/',
        'googlelogo',
        'gstatic.com/images',
    ]
    if any(part in lowered for part in blocked_parts):
        return False

    allowed_hosts = (
        'googleusercontent.com',
        'ggpht.com',
        'streetviewpixels-pa.googleapis.com',
        'gstatic.com',
    )
    return any(host in lowered for host in allowed_hosts)


def _proxy_image_response(client: httpx.Client, image_url: str) -> Response:
    image_response = client.get(image_url, headers=GOOGLE_IMAGE_HEADERS)
    image_response.raise_for_status()
    media_type = image_response.headers.get('content-type', '').split(';', 1)[0].strip()
    if not media_type.startswith('image/'):
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail='Resolved Google photo URL did not return image content.',
        )
    return Response(content=image_response.content, media_type=media_type)


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
async def get_places():
    try:
        supabase = get_supabase_client()
        rows = _fetch_all_places_rows(supabase)
        return [_normalize_place_row(supabase, row) for row in rows]
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
        rows = _fetch_all_places_rows(supabase)
        normalized_rows = [_normalize_place_row(supabase, row) for row in rows]
        query_text = q.lower().strip()
        matched_rows = []
        for row in normalized_rows:
            search_text = ' '.join(
                [
                    str(row.get('name', '')),
                    str(row.get('category', '')),
                    str(row.get('description', '')),
                    str(row.get('location', '')),
                    ' '.join(row.get('tags', [])),
                ]
            ).lower()
            if query_text in search_text:
                matched_rows.append(row)
        normalized_rows = matched_rows

        if latitude is not None and longitude is not None:
            filtered = []
            for row in normalized_rows:
                lat = row.get('latitude')
                lon = row.get('longitude')
                if lat is None or lon is None:
                    continue
                if _haversine_km(float(latitude), float(longitude), float(lat), float(lon)) <= radius_km:
                    filtered.append(row)
            normalized_rows = filtered

        normalized_rows = normalized_rows[: max(1, min(limit, 100))]
        return {'count': len(normalized_rows), 'places': normalized_rows}
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f'Failed to search places from Supabase: {exc}',
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

            return _proxy_image_response(client, photo_url)
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
async def photo_from_google_url(url: str = Query(..., min_length=1)):
    try:
        normalized_url = url.strip()
        if not normalized_url.startswith(('http://', 'https://')):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail='google_url must be an absolute URL.',
            )

        with httpx.Client(timeout=15.0, follow_redirects=True) as client:
            if _is_google_photo_candidate(normalized_url):
                return _proxy_image_response(client, normalized_url)

            response = client.get(
                normalized_url,
                headers=GOOGLE_IMAGE_HEADERS,
            )
            response.raise_for_status()
            page = response.text
            image_url = _extract_google_photo_url_from_page(page)
            if image_url:
                return _proxy_image_response(client, image_url)

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Could not resolve a photo from google_url.',
        )
    except HTTPException:
        raise
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f'Failed to fetch google_url: {exc}',
        ) from exc
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
