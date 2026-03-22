import logging
import math
import os
from urllib.parse import quote_plus

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from supabase import create_client

from ..dependencies import get_current_user
from .places import PLACES_TABLE, _first_non_empty, _normalize_place_row


def _sb():
    """Fresh service-role client — bypasses RLS on every request."""
    return create_client(os.environ['SUPABASE_URL'], os.environ['SUPABASE_SERVICE_ROLE_KEY'])

logger = logging.getLogger(__name__)

router = APIRouter(prefix='/playlists', tags=['playlists'])

PLAYLISTS_TABLE = 'playlists'
PLAYLIST_DESTINATIONS_TABLE = 'playlist_places'


class CreatePlaylistRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    description: str | None = None
    icon: str = 'playlist_play'
    is_default: bool = False
    visibility: str = 'public'


class UpdatePlaylistRequest(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    description: str | None = None
    icon: str | None = None
    visibility: str | None = None


class AddDestinationRequest(BaseModel):
    destination_id: int | None = None
    place_id: str | None = None

    @property
    def resolved_place_id(self) -> str | None:
        if self.place_id:
            return self.place_id
        if self.destination_id is not None:
            return str(self.destination_id)
        return None


@router.get('/')
def get_playlists():
    """Return active public playlists normalized for the mobile app."""
    import os
    from supabase import create_client as _create_client
    supabase = _create_client(os.environ['SUPABASE_URL'], os.environ['SUPABASE_SERVICE_ROLE_KEY'])
    response = (
        supabase.table(PLAYLISTS_TABLE)
        .select('*')
        .eq('status', 'active')
        .eq('visibility', 'public')
        .order('is_featured', desc=True)
        .order('id', desc=False)
        .execute()
    )
    playlists = [_normalize_playlist_row(row) for row in (response.data or [])]
    return {'playlists': playlists}


@router.get('/mine')
async def get_my_playlists(
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=200),
    user=Depends(get_current_user),
):
    """Return playlists owned by the current user (paginated, default 50/page)."""
    supabase = _sb()
    start = (page - 1) * limit
    end = start + limit - 1
    try:
        response = (
            supabase.table(PLAYLISTS_TABLE)
            .select('*')
            .eq('user_id', str(user.id))
            .order('created_at', desc=True)
            .range(start, end)
            .execute()
        )
        rows = response.data or []
    except Exception:
        logger.exception('Failed to fetch playlists for user=%s', user.id)
        rows = []
    playlists = []
    for row in rows:
        p = _normalize_playlist_row(row)
        p['is_editable'] = True
        p['is_deletable'] = not bool(row.get('is_default'))
        playlists.append(p)
    return {'playlists': playlists, 'page': page, 'limit': limit}


@router.get('/{playlist_id}/details')
async def get_playlist_details(playlist_id: str):
    supabase = _sb()
    # Try the id as-is first; if that returns nothing, also try as integer (tables with bigint PKs)
    playlist_response = (
        supabase.table(PLAYLISTS_TABLE)
        .select('*')
        .eq('id', playlist_id)
        .limit(1)
        .execute()
    )
    playlist_rows = playlist_response.data or []
    if not playlist_rows and playlist_id.isdigit():
        playlist_response = (
            supabase.table(PLAYLISTS_TABLE)
            .select('*')
            .eq('id', int(playlist_id))
            .limit(1)
            .execute()
        )
        playlist_rows = playlist_response.data or []
    if not playlist_rows:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Playlist not found.',
        )

    playlist = _normalize_playlist_row(playlist_rows[0])
    # Use the actual id value from the DB row (not the URL string) so the
    # type matches whatever was stored in playlist_places.playlist_id.
    actual_playlist_id = playlist_rows[0].get('id', playlist_id)
    raw_stops = _fetch_playlist_places(supabase, actual_playlist_id)
    stops = [_normalize_playlist_stop(stop, index) for index, stop in enumerate(raw_stops)]
    _fill_leg_distances(stops)

    return {
        'playlist': playlist,
        'stops': stops,
        'total_distance_km': _sum_stop_distance(stops),
    }


@router.post('/', status_code=status.HTTP_201_CREATED)
async def create_playlist(
    body: CreatePlaylistRequest,
    user=Depends(get_current_user),
):
    import re as _re
    supabase = _sb()
    payload = body.model_dump()
    payload['user_id'] = str(user.id)

    # Retry loop: drop cosmetic columns rejected by PGRST204 (missing from schema cache).
    # NEVER strip 'user_id' — without it the playlist can't be queried back for this user.
    _REQUIRED_COLS = {'name', 'user_id'}
    for _ in range(10):
        try:
            response = supabase.table(PLAYLISTS_TABLE).insert(payload).execute()
            break
        except Exception as exc:
            exc_msg = str(exc)
            missing = _re.search(r"find the '(\w+)' column", exc_msg)
            if missing:
                col = missing.group(1)
                if col in _REQUIRED_COLS:
                    raise  # can't proceed without this column
                logger.debug('create_playlist: dropping unknown column %r', col)
                payload.pop(col, None)
            else:
                raise
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail='Could not insert playlist after stripping unknown columns.',
        )

    if not response.data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='Failed to create playlist.',
        )
    return response.data[0]


@router.put('/{playlist_id}')
async def update_playlist(
    playlist_id: str,
    body: UpdatePlaylistRequest,
    user=Depends(get_current_user),
):
    supabase = _sb()
    _assert_owner(supabase, playlist_id, user)

    fields = {k: v for k, v in body.model_dump().items() if v is not None}
    if not fields:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='No fields provided.',
        )
    response = (
        supabase.table(PLAYLISTS_TABLE)
        .update(fields)
        .eq('id', playlist_id)
        .eq('user_id', str(user.id))
        .execute()
    )
    return {'updated': True, 'data': response.data}


@router.delete('/{playlist_id}', status_code=status.HTTP_204_NO_CONTENT)
async def delete_playlist(
    playlist_id: str,
    user=Depends(get_current_user),
):
    supabase = _sb()
    row = _assert_owner(supabase, playlist_id, user)
    if row.get('is_default'):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail='Cannot delete a default playlist.',
        )
    supabase.table(PLAYLISTS_TABLE).delete().eq('id', playlist_id).eq('user_id', str(user.id)).execute()


@router.post('/{playlist_id}/destinations', status_code=status.HTTP_201_CREATED)
async def add_destination(
    playlist_id: str,
    body: AddDestinationRequest,
    user=Depends(get_current_user),
):
    supabase = _sb()
    logger.info('add_destination: playlist_id=%r user=%s', playlist_id, getattr(user, 'id', '?'))
    owner_row = _assert_owner(supabase, playlist_id, user)
    # Use the actual id value from the DB row so the type (UUID vs int) is correct.
    actual_playlist_id = owner_row.get('id', playlist_id)
    logger.info('add_destination: owner found, actual_playlist_id=%r', actual_playlist_id)

    pid = body.resolved_place_id
    logger.info('add_destination: resolved place_id=%r', pid)
    if not pid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='Provide place_id or destination_id.',
        )

    # playlist_places.playlist_id is TEXT (works with both UUID and bigint playlists).
    # Always use the string form.  Try place_id as string first; if numeric, also try int.
    _pl_str = str(actual_playlist_id)   # e.g. "28" or "uuid-string"
    _pid_int = int(pid) if str(pid).strip().isdigit() else None
    _candidates = [
        (_pl_str, pid),             # primary attempt: string playlist_id, string place_id
    ]
    if _pid_int is not None:
        _candidates.append((_pl_str, _pid_int))   # string playlist_id, int place_id

    last_exc: Exception | None = None
    for pl_id_val, place_id_val in _candidates:
        try:
            # Duplicate check (use select * + limit 1 in case there is no 'id' column)
            existing = (
                supabase.table(PLAYLIST_DESTINATIONS_TABLE)
                .select('*')
                .eq('playlist_id', pl_id_val)
                .eq('place_id', place_id_val)
                .limit(1)
                .execute()
            )
            if existing.data:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail='Destination already in playlist.',
                )
            response = (
                supabase.table(PLAYLIST_DESTINATIONS_TABLE)
                .insert({'playlist_id': pl_id_val, 'place_id': place_id_val})
                .execute()
            )
            logger.info(
                'add_destination: inserted playlist=%r place=%r → rows=%d',
                pl_id_val, place_id_val, len(response.data or []),
            )
            if response.data:
                return response.data[0]
            # Insert succeeded but returned no data — still treat as success
            return {'playlist_id': pl_id_val, 'place_id': place_id_val}
        except HTTPException:
            raise
        except Exception as exc:
            last_exc = exc
            logger.warning(
                'add_destination attempt (pl=%r place=%r) failed: %s',
                pl_id_val, place_id_val, exc,
            )
            continue

    # All attempts failed — surface the real error so we can diagnose it
    logger.error(
        'add_destination all attempts failed playlist=%s place=%s last_error=%s',
        playlist_id, pid, last_exc,
    )
    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail='Failed to add destination to playlist. Please try again.',
    )


@router.delete('/{playlist_id}/destinations/{destination_id}', status_code=status.HTTP_204_NO_CONTENT)
async def remove_destination(
    playlist_id: str,
    destination_id: int,
    user=Depends(get_current_user),
):
    supabase = _sb()
    _assert_owner(supabase, playlist_id, user)
    supabase.table(PLAYLIST_DESTINATIONS_TABLE).delete().eq('playlist_id', playlist_id).eq('place_id', str(destination_id)).execute()


@router.get('/{playlist_id}/destinations')
async def get_playlist_destinations(
    playlist_id: str,
    user=Depends(get_current_user),
):
    supabase = _sb()
    owner_row = _assert_owner(supabase, playlist_id, user)
    # Use the actual DB id value (same as add_destination does) so the
    # TEXT playlist_id column is matched correctly for both UUID and bigint PKs.
    actual_playlist_id = str(owner_row.get('id', playlist_id))
    response = (
        supabase.table(PLAYLIST_DESTINATIONS_TABLE)
        .select(f'*, {PLACES_TABLE}(*)')
        .eq('playlist_id', actual_playlist_id)
        .execute()
    )
    return {'destinations': response.data or []}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _assert_owner(supabase, playlist_id: str, user) -> dict:
    """Return the playlist row if the user owns it, else raise 404.

    Handles both UUID and integer primary keys, and tolerates missing
    columns (e.g. is_default not yet added via migration) by selecting *.
    """
    def _run(pid_value):
        try:
            return supabase.table(PLAYLISTS_TABLE).select('*').eq('id', pid_value).eq('user_id', str(user.id)).execute()
        except Exception:
            return None

    result = _run(playlist_id)
    rows = (result.data if result else None) or []

    if not rows and playlist_id.isdigit():
        result = _run(int(playlist_id))
        rows = (result.data if result else None) or []

    if not rows:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Playlist not found or does not belong to you.',
        )
    return rows[0]


def _normalize_playlist_row(row: dict) -> dict:
    places_count = row.get('places_count') or row.get('destination_count') or 0
    name = row.get('name') or 'Playlist'
    description = row.get('description')
    creator_name = row.get('creator_name')
    is_featured = bool(row.get('is_featured'))
    visibility = row.get('visibility') or 'public'
    status = row.get('status') or 'active'

    semantic_labels = [name]
    if description:
        semantic_labels.append(description)

    return {
        **row,
        'id': str(row.get('id')),
        'icon': row.get('icon') or ('star' if is_featured else 'playlist_play'),
        'destination_count': int(places_count),
        'destinationCount': int(places_count),
        'previewImages': row.get('previewImages') or [_playlist_cover_image(name, description)],
        'semanticLabels': semantic_labels,
        'is_default': False,
        'is_editable': False,
        'is_deletable': False,
        'creator_name': creator_name,
        'is_featured': is_featured,
        'visibility': visibility,
        'status': status,
    }


def _playlist_cover_image(name: str, description: str | None) -> str:
    text = f'{name} {description or ""}'.lower()

    if any(keyword in text for keyword in ('camp', 'forest', 'escape', 'wild')):
        return 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80'
    if any(keyword in text for keyword in ('coast', 'beach', 'chill', 'south', 'ocean')):
        return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80'
    if any(keyword in text for keyword in ('hik', 'mountain', 'trail', 'peak', 'weekend')):
        return 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1200&q=80'
    if any(keyword in text for keyword in ('historic', 'culture', 'temple', 'heritage')):
        return 'https://images.unsplash.com/photo-1548013146-72479768bada?auto=format&fit=crop&w=1200&q=80'

    query = quote_plus(name.strip() or 'travel landscape')
    return f'https://source.unsplash.com/featured/1200x800/?{query}'


def _fetch_playlist_places(supabase, playlist_id) -> list[dict]:
    # playlist_places.playlist_id is TEXT — always query with string form.
    pl_id_str = str(playlist_id)
    try:
        relation_rows = (
            supabase.table('playlist_places')
            .select('*')
            .eq('playlist_id', pl_id_str)
            .execute()
            .data
            or []
        )
    except Exception as exc:
        logger.warning('playlist_places query failed for %s: %s', pl_id_str, exc)
        return []

    if not relation_rows:
        return []

    place_lookup: dict[str, dict] = {}
    place_keys = _extract_playlist_place_keys(relation_rows)

    for key_name, values in place_keys.items():
        if not values:
            continue
        try:
            rows = (
                supabase.table(PLACES_TABLE)
                .select('*')
                .in_(key_name, values)
                .execute()
                .data
                or []
            )
        except Exception as exc:
            logger.warning('place lookup failed key=%s values=%s: %s', key_name, values, exc)
            rows = []

        # If string lookup returned nothing and the values look like integers,
        # retry with int-coerced values (tourist_places.id is bigint in production).
        if not rows and key_name == 'id':
            int_values = [int(v) for v in values if str(v).strip().isdigit()]
            if int_values:
                try:
                    rows = (
                        supabase.table(PLACES_TABLE)
                        .select('*')
                        .in_(key_name, int_values)
                        .execute()
                        .data
                        or []
                    )
                except Exception as exc:
                    logger.warning('int place lookup failed key=%s values=%s: %s', key_name, int_values, exc)
                    rows = []

        for row in rows:
            normalized = _normalize_place_row(supabase, row)
            for lookup_key in _candidate_place_lookup_keys(normalized):
                place_lookup[lookup_key] = normalized

    merged_rows: list[dict] = []
    for relation_row in relation_rows:
        place_row = _match_place_row(place_lookup, relation_row)
        merged_rows.append(
            {
                **relation_row,
                '_place': place_row or {},
            }
        )
    return merged_rows


def _normalize_playlist_stop(row: dict, index: int) -> dict:
    place_row = row.get('_place') or {}
    merged = {**row, **place_row}

    name = str(_first_non_empty(merged, ['name', 'place_name', 'title']) or f'Stop {index + 1}')
    category = str(
        _first_non_empty(merged, ['category', 'primary_category', 'type', 'primary_type']) or 'Place'
    )
    description = _first_non_empty(merged, ['description', 'details', 'summary']) or ''
    location = _first_non_empty(merged, ['location', 'formatted_address', 'address']) or ''
    primary_gallery_photo = (
        place_row.get('photo_public_urls')[0]
        if isinstance(place_row.get('photo_public_urls'), list) and place_row.get('photo_public_urls')
        else None
    )
    image_url = (
        primary_gallery_photo
        or _first_non_empty(merged, ['image_url', 'photo_url', 'cover_image'])
        or _playlist_stop_cover_image(name, category, description)
    )
    distance_km = _coerce_playlist_distance(
        _first_non_empty(row, ['distance_km', 'distance_from_previous_km', 'distance'])
    )
    avg_rating = _coerce_playlist_distance(_first_non_empty(merged, ['avg_rating', 'rating'])) or 0.0
    review_count = int(_first_non_empty(merged, ['review_count', 'reviews', 'user_rating_count']) or 0)

    return {
        'id': str(merged.get('id') or merged.get('place_id') or index),
        'place_id': str(_first_non_empty(merged, ['place_id', 'id']) or ''),
        'name': name,
        'category': category,
        'description': description,
        'location': location,
        'image_url': image_url,
        'imageUrl': image_url,
        'photo_public_urls': place_row.get('photo_public_urls') or [],
        'photo_url': _first_non_empty(merged, ['photo_url', 'image_url']),
        'google_url': _first_non_empty(merged, ['google_url']),
        'googleUrl': _first_non_empty(merged, ['google_url']),
        'latitude': _first_non_empty(merged, ['latitude', 'lat']),
        'longitude': _first_non_empty(merged, ['longitude', 'lng', 'lon']),
        'avg_rating': avg_rating,
        'review_count': review_count,
        'tags': merged.get('tags') or [],
        'playlist_notes': _first_non_empty(row, ['notes', 'description']),
        'distance_km': float(distance_km or 0),
        'stop_number': index + 1,
    }


def _playlist_stop_cover_image(name: str, category: str, description: str | None) -> str:
    text = f'{name} {category} {description or ""}'.lower()

    if any(keyword in text for keyword in ('camp', 'forest', 'nature', 'wild')):
        return 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80'
    if any(keyword in text for keyword in ('waterfall', 'falls', 'river', 'lake')):
        return 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80'
    if any(keyword in text for keyword in ('beach', 'coast', 'ocean', 'sea')):
        return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80'
    if any(keyword in text for keyword in ('mountain', 'hike', 'trail', 'peak')):
        return 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1200&q=80'
    if any(keyword in text for keyword in ('temple', 'heritage', 'historic', 'culture')):
        return 'https://images.unsplash.com/photo-1548013146-72479768bada?auto=format&fit=crop&w=1200&q=80'

    query = quote_plus(f'{name} sri lanka')
    return f'https://source.unsplash.com/featured/1200x800/?{query}'


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371.0
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = math.sin(d_lat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lng / 2) ** 2
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _fill_leg_distances(stops: list[dict]) -> None:
    """Compute haversine distance from the previous stop and write it into each stop dict."""
    for i, stop in enumerate(stops):
        if i == 0:
            stop['distance_km'] = 0.0
            continue
        prev = stops[i - 1]
        try:
            lat1 = float(prev['latitude'])
            lng1 = float(prev['longitude'])
            lat2 = float(stop['latitude'])
            lng2 = float(stop['longitude'])
            stop['distance_km'] = round(_haversine_km(lat1, lng1, lat2, lng2), 2)
        except (TypeError, ValueError):
            stop['distance_km'] = 0.0


def _sum_stop_distance(stops: list[dict]) -> float:
    total = 0.0
    for stop in stops:
        try:
            total += float(stop.get('distance_km') or 0)
        except Exception:
            continue
    return round(total, 1)


def _extract_playlist_place_keys(rows: list[dict]) -> dict[str, list]:
    keys: dict[str, set] = {
        'id': set(),
        'place_id': set(),
    }
    for row in rows:
        for field in ['place_id', 'destination_id', 'places_id', 'place_ref']:
            value = row.get(field)
            if value is not None and str(value).strip():
                keys['id'].add(value)
                keys['place_id'].add(str(value))
        for field in ['google_place_id', 'external_place_id']:
            value = row.get(field)
            if value is not None and str(value).strip():
                keys['place_id'].add(str(value))
    return {
        key: list(values)
        for key, values in keys.items()
    }


def _candidate_place_lookup_keys(row: dict) -> list[str]:
    keys = []
    for field in ['id', 'place_id']:
        value = row.get(field)
        if value is not None and str(value).strip():
            keys.append(str(value))
    return keys


def _match_place_row(place_lookup: dict[str, dict], relation_row: dict) -> dict | None:
    for field in ['place_id', 'destination_id', 'places_id', 'place_ref', 'google_place_id', 'external_place_id']:
        value = relation_row.get(field)
        if value is None:
            continue
        matched = place_lookup.get(str(value))
        if matched is not None:
            return matched
    return None


def _coerce_playlist_distance(value) -> float | None:
    if value is None:
        return None
    try:
        return float(value)
    except Exception:
        return None
