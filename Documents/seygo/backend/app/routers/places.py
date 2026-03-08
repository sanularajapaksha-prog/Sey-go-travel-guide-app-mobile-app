import os
import json
import html
import re
import urllib.parse
import urllib.request
from functools import lru_cache

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import RedirectResponse

from ..dependencies import get_current_user, get_supabase_client
from ..schemas.place import PlaceCreate

router = APIRouter(prefix='/places', tags=['places'])


@lru_cache(maxsize=8192)
def _get_first_photo_reference(place_id: str, api_key: str) -> str | None:
    query = urllib.parse.urlencode(
        {
            'place_id': place_id,
            'fields': 'photos',
            'key': api_key,
        }
    )
    url = (
        'https://maps.googleapis.com/maps/api/place/details/json'
        f'?{query}'
    )
    with urllib.request.urlopen(url, timeout=12) as response:
        payload = json.loads(response.read().decode('utf-8'))

    status_value = payload.get('status', 'UNKNOWN')
    if status_value != 'OK':
        error_message = payload.get('error_message', status_value)
        raise RuntimeError(f'Google Places error: {error_message}')

    photos = payload.get('result', {}).get('photos') or []
    if not photos:
        return None
    return photos[0].get('photo_reference')


@lru_cache(maxsize=8192)
def _resolve_google_maps_photo_url(google_url: str) -> str | None:
    req = urllib.request.Request(
        google_url,
        headers={'User-Agent': 'Mozilla/5.0'},
    )
    with urllib.request.urlopen(req, timeout=15) as response:
        page_html = response.read().decode('utf-8', errors='ignore')

    link_match = re.search(r'<link href="(/maps/preview/place\?[^"]+)"', page_html)
    if not link_match:
        return None

    preview_url = f"https://www.google.com{html.unescape(link_match.group(1))}"
    preview_req = urllib.request.Request(
        preview_url,
        headers={'User-Agent': 'Mozilla/5.0'},
    )
    with urllib.request.urlopen(preview_req, timeout=15) as response:
        preview_payload = response.read().decode('utf-8', errors='ignore')

    candidates = set()
    for match in re.findall(
        r'https://lh[0-9]+\.googleusercontent\.com/[^\s"\\]+',
        preview_payload,
    ):
        normalized = (
            match.replace('\\u003d', '=')
            .replace('\\u0026', '&')
            .replace('\\/', '/')
        )
        if 'w86-h86' in normalized:
            continue
        candidates.add(normalized)

    if not candidates:
        return None

    def score(url: str) -> int:
        size_match = re.search(r'w(\d+)-h(\d+)', url)
        if not size_match:
            return 0
        return int(size_match.group(1)) * int(size_match.group(2))

    return max(candidates, key=score)


@router.get('/')
async def get_places():
    try:
        supabase = get_supabase_client()
        table_name = os.getenv('PLACES_READ_TABLE', 'placses').strip() or 'placses'
        page_size = 1000
        offset = 0
        rows = []

        while True:
            response = (
                supabase.table(table_name)
                .select('*')
                .range(offset, offset + page_size - 1)
                .execute()
            )
            chunk = response.data or []
            if not chunk:
                break

            rows.extend(chunk)
            if len(chunk) < page_size:
                break

            offset += page_size

        return rows
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f'Failed to fetch places: {exc}',
        ) from exc


@router.get('/photo/{place_id}')
async def get_place_photo(place_id: str):
    api_key = os.getenv('GOOGLE_MAPS_API_KEY', '').strip()
    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail='GOOGLE_MAPS_API_KEY is not configured on backend.',
        )

    try:
        photo_reference = _get_first_photo_reference(place_id, api_key)
        if not photo_reference:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail='No photo found for this place.',
            )

        query = urllib.parse.urlencode(
            {
                'maxwidth': 900,
                'photo_reference': photo_reference,
                'key': api_key,
            }
        )
        photo_url = (
            'https://maps.googleapis.com/maps/api/place/photo'
            f'?{query}'
        )
        return RedirectResponse(url=photo_url, status_code=307)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f'Failed to fetch Google place photo: {exc}',
        ) from exc


@router.get('/photo-from-google-url')
async def get_place_photo_from_google_url(url: str):
    if not url:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='Missing url query parameter.',
        )

    normalized = url.strip()
    if not normalized.startswith('http') or 'google.' not in normalized:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='Expected a valid Google Maps URL.',
        )

    try:
        photo_url = _resolve_google_maps_photo_url(normalized)
        if not photo_url:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail='No photo resolved from google_url.',
            )
        return RedirectResponse(url=photo_url, status_code=307)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f'Failed to resolve photo from google_url: {exc}',
        ) from exc


@router.post('/')
async def create_place(
    place: PlaceCreate,
    user=Depends(get_current_user),
):
    try:
        supabase = get_supabase_client()
        table_name = os.getenv('PLACES_WRITE_TABLE', 'places').strip() or 'places'
        payload = place.model_dump()
        payload['created_by'] = str(user.id)

        response = supabase.table(table_name).insert(payload).execute()
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
