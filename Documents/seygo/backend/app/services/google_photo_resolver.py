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


def resolve_photo_url_from_google_url(google_url: str, timeout_seconds: float = 12.0) -> str | None:
    normalized_url = (google_url or '').strip()
    if not is_valid_http_url(normalized_url):
        return None

    if is_direct_image_url(normalized_url):
        return append_maxwidth(normalized_url)

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
    if image_url:
        payload['image_url'] = image_url
    if image_source:
        payload['image_source'] = image_source

    try:
        supabase.table(table_name).update(payload).eq('place_id', place_id).execute()
    except Exception as exc:
        logger.warning('Failed to update photo cache for %s: %s', place_id, exc)


def is_missing_column_error(exc: Exception) -> bool:
    message = str(exc).lower()
    return 'column' in message and 'does not exist' in message
