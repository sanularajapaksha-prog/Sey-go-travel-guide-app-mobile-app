import html
import logging
import re
from datetime import datetime, timezone
from typing import Any

import httpx

logger = logging.getLogger(__name__)

GOOGLE_IMAGE_HEADERS = {
    'User-Agent': (
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/122.0.0.0 Safari/537.36'
    ),
    'Accept-Language': 'en-US,en;q=0.9',
}


def is_direct_image_url(url: str | None) -> bool:
    if not isinstance(url, str):
        return False
    normalized = url.strip().lower()
    if not normalized.startswith(('http://', 'https://')):
        return False
    image_hosts = (
        'googleusercontent.com',
        'ggpht.com',
        'streetviewpixels-pa.googleapis.com',
        'gstatic.com',
        # Common image CDNs stored directly in the DB
        'images.unsplash.com',
        'unsplash.com',
        'imgur.com',
        'i.imgur.com',
        'cloudinary.com',
        'res.cloudinary.com',
        'supabase.co/storage',
    )
    return any(host in normalized for host in image_hosts)


def is_valid_http_url(url: str | None) -> bool:
    return isinstance(url, str) and url.strip().startswith(('http://', 'https://'))


def extract_google_photo_url_from_page(page: str) -> str | None:
    og_match = re.search(
        r'<meta[^>]+property=["\']og:image["\'][^>]+content=["\']([^"\']+)["\']',
        page,
        flags=re.IGNORECASE,
    )
    if og_match:
        url = html.unescape(og_match.group(1))
        if is_direct_image_url(url):
            return url

    for pattern in [
        r'https://[^"\']*(?:googleusercontent|ggpht\.com|streetviewpixels-pa\.googleapis\.com)[^"\']+',
        r'https://[^"\']*gstatic[^"\']*(?:/p/|=w\d+|=s\d+)[^"\']*',
    ]:
        for match in re.finditer(pattern, page, flags=re.IGNORECASE):
            candidate = html.unescape(match.group(0))
            if is_direct_image_url(candidate):
                return candidate

    return None


def append_maxwidth(url: str | None, max_width: int = 800) -> str | None:
    if not is_valid_http_url(url):
        return None
    parsed = httpx.URL(url)
    if 'maxwidth' in parsed.params:
        return str(parsed)
    return str(parsed.copy_add_param('maxwidth', str(max_width)))


def _resolve_via_google_places_api(google_url: str, api_key: str, timeout_seconds: float = 10.0) -> str | None:
    """Resolve a Google Maps URL to a photo URL using the Google Places API.

    Supports both CID-based URLs (maps.google.com/?cid=...) and
    query-based URLs (maps.google.com/?q=...).
    """
    try:
        parsed = httpx.URL(google_url)
        params = dict(parsed.params)
        cid = params.get('cid', '').strip()
        q = params.get('q', '').strip()

        if cid:
            search_input = f'cid:{cid}'
        elif q:
            search_input = q
        else:
            return None

        with httpx.Client(timeout=timeout_seconds, headers=GOOGLE_IMAGE_HEADERS) as client:
            # Step 1: Find Place → get place_id
            find_resp = client.get(
                'https://maps.googleapis.com/maps/api/place/findplacefromtext/json',
                params={
                    'input': search_input,
                    'inputtype': 'textquery',
                    'fields': 'place_id',
                    'key': api_key,
                },
            )
            find_resp.raise_for_status()
            find_data = find_resp.json()
            candidates = find_data.get('candidates') or []
            if not candidates:
                return None
            place_id = (candidates[0] or {}).get('place_id', '').strip()
            if not place_id:
                return None

            # Step 2: Get photo_reference from Place Details
            details_resp = client.get(
                'https://maps.googleapis.com/maps/api/place/details/json',
                params={
                    'place_id': place_id,
                    'fields': 'photos',
                    'key': api_key,
                },
            )
            details_resp.raise_for_status()
            details_data = details_resp.json()
            photos = ((details_data.get('result') or {}).get('photos') or [])
            if not photos:
                return None
            photo_ref = (photos[0] or {}).get('photo_reference', '').strip()
            if not photo_ref:
                return None

            # Step 3: Build the photo URL
            return (
                'https://maps.googleapis.com/maps/api/place/photo'
                f'?maxwidth=800&photoreference={photo_ref}&key={api_key}'
            )
    except Exception as exc:
        logger.warning('Google Places API resolution failed for %s: %s', google_url, exc)
        return None


def resolve_photo_url_from_google_url(
    google_url: str,
    timeout_seconds: float = 12.0,
    api_key: str = '',
) -> str | None:
    import os
    normalized_url = (google_url or '').strip()
    if not is_valid_http_url(normalized_url):
        return None

    if is_direct_image_url(normalized_url):
        return append_maxwidth(normalized_url)

    # Try Google Places API first (reliable, works for both ?cid= and ?q= URLs)
    resolved_api_key = api_key or os.getenv('GOOGLE_MAPS_API_KEY', '').strip()
    if resolved_api_key:
        result = _resolve_via_google_places_api(normalized_url, resolved_api_key, timeout_seconds)
        if result:
            return result

    # Fallback: HTML scraping (works when Google embeds og:image in page HTML)
    try:
        with httpx.Client(
            timeout=timeout_seconds,
            follow_redirects=True,
            headers=GOOGLE_IMAGE_HEADERS,
        ) as client:
            response = client.get(normalized_url)
            response.raise_for_status()

            content_type = response.headers.get('content-type', '').lower()
            if content_type.startswith('image/'):
                return append_maxwidth(str(response.url))

            resolved = extract_google_photo_url_from_page(response.text)
            return append_maxwidth(resolved)
    except httpx.HTTPError as exc:
        logger.warning('Failed to resolve google photo url %s: %s', normalized_url, exc)
        return None
    except Exception as exc:
        logger.exception('Unexpected error resolving google photo url %s: %s', normalized_url, exc)
        return None


def update_place_photo_cache(
    supabase,
    table_name: str,
    place_id: str,
    *,
    image_url: str | None,
    image_source: str | None,
) -> None:
    if not place_id:
        return

    payload: dict[str, Any] = {
        'photo_last_checked': datetime.now(timezone.utc).isoformat(),
    }
    # image_url and image_source are omitted — these columns may not exist in all
    # deployments (e.g. the 'placses' table). Add them via SQL if you want caching:
    #   ALTER TABLE placses
    #     ADD COLUMN IF NOT EXISTS image_url TEXT,
    #     ADD COLUMN IF NOT EXISTS image_source TEXT,
    #     ADD COLUMN IF NOT EXISTS photo_last_checked TIMESTAMPTZ,
    #     ADD COLUMN IF NOT EXISTS photo_public_urls TEXT[];

    try:
        supabase.table(table_name).update(payload).eq('place_id', place_id).execute()
    except Exception as exc:
        if is_missing_column_error(exc):
            logger.debug('Photo cache columns missing in %s — skipping cache write', table_name)
        else:
            logger.warning('Failed to update photo cache for %s: %s', place_id, exc)


def is_missing_column_error(exc: Exception) -> bool:
    message = str(exc).lower()
    # Covers: "column does not exist", "could not find the '...' column", PGRST204
    return (
        ('column' in message and 'does not exist' in message)
        or ('could not find' in message and 'column' in message)
        or 'pgrst204' in message
    )
