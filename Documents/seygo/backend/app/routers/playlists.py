from urllib.parse import quote_plus

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from ..dependencies import get_current_user, get_supabase_client

router = APIRouter(prefix='/playlists', tags=['playlists'])

PLAYLISTS_TABLE = 'playlists'
PLAYLIST_DESTINATIONS_TABLE = 'playlist_destinations'


class CreatePlaylistRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    description: str | None = None
    icon: str = 'playlist_play'
    is_default: bool = False


class UpdatePlaylistRequest(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    description: str | None = None
    icon: str | None = None


class AddDestinationRequest(BaseModel):
    destination_id: int


@router.get('/')
async def get_playlists():
    """Return active public playlists normalized for the mobile app."""
    supabase = get_supabase_client()
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


@router.get('/{playlist_id}/details')
async def get_playlist_details(playlist_id: str):
    supabase = get_supabase_client()
    playlist_response = (
        supabase.table(PLAYLISTS_TABLE)
        .select('*')
        .eq('id', playlist_id)
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
    raw_stops = _fetch_playlist_places(supabase, playlist_id)
    stops = [_normalize_playlist_stop(stop, index) for index, stop in enumerate(raw_stops)]

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
    supabase = get_supabase_client()
    payload = body.model_dump()
    payload['user_id'] = str(user.id)
    response = supabase.table(PLAYLISTS_TABLE).insert(payload).execute()
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
    supabase = get_supabase_client()
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
    supabase = get_supabase_client()
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
    supabase = get_supabase_client()
    _assert_owner(supabase, playlist_id, user)

    existing = (
        supabase.table(PLAYLIST_DESTINATIONS_TABLE)
        .select('id')
        .eq('playlist_id', playlist_id)
        .eq('destination_id', body.destination_id)
        .execute()
    )
    if existing.data:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail='Destination already in playlist.',
        )

    response = (
        supabase.table(PLAYLIST_DESTINATIONS_TABLE)
        .insert({'playlist_id': playlist_id, 'destination_id': body.destination_id})
        .execute()
    )
    if not response.data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='Failed to add destination.',
        )
    return response.data[0]


@router.delete('/{playlist_id}/destinations/{destination_id}', status_code=status.HTTP_204_NO_CONTENT)
async def remove_destination(
    playlist_id: str,
    destination_id: int,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    _assert_owner(supabase, playlist_id, user)
    supabase.table(PLAYLIST_DESTINATIONS_TABLE).delete().eq('playlist_id', playlist_id).eq('destination_id', destination_id).execute()


@router.get('/{playlist_id}/destinations')
async def get_playlist_destinations(
    playlist_id: str,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    _assert_owner(supabase, playlist_id, user)
    response = (
        supabase.table(PLAYLIST_DESTINATIONS_TABLE)
        .select('*, saved_destinations(*)')
        .eq('playlist_id', playlist_id)
        .execute()
    )
    return {'destinations': response.data or []}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _assert_owner(supabase, playlist_id: str, user) -> dict:
    result = (
        supabase.table(PLAYLISTS_TABLE)
        .select('id, is_default')
        .eq('id', playlist_id)
        .eq('user_id', str(user.id))
        .execute()
    )
    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Playlist not found or does not belong to you.',
        )
    return result.data[0]


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


def _fetch_playlist_places(supabase, playlist_id: str) -> list[dict]:
    select_variants = [
        '*, places(*)',
        '*, public_places(*)',
        '*',
    ]

    for select_clause in select_variants:
        try:
            response = (
                supabase.table('playlist_places')
                .select(select_clause)
                .eq('playlist_id', playlist_id)
                .execute()
            )
            return response.data or []
        except Exception:
            continue
    return []


def _normalize_playlist_stop(row: dict, index: int) -> dict:
    place_row = row.get('places') or row.get('public_places') or {}
    merged = {**place_row, **row} if isinstance(place_row, dict) else dict(row)

    name = str(
        merged.get('name')
        or merged.get('place_name')
        or merged.get('title')
        or f'Stop {index + 1}'
    )
    category = str(
        merged.get('category')
        or merged.get('primary_category')
        or merged.get('type')
        or 'Place'
    )
    description = (
        merged.get('description')
        or merged.get('details')
        or merged.get('summary')
        or ''
    )
    image_url = (
        merged.get('image_url')
        or merged.get('photo_url')
        or merged.get('cover_image')
        or _playlist_stop_cover_image(name, category, description)
    )
    distance_km = merged.get('distance_km') or merged.get('distance_from_previous_km') or 0

    return {
        'id': str(merged.get('id') or merged.get('place_id') or index),
        'name': name,
        'category': category,
        'description': description,
        'image_url': image_url,
        'imageUrl': image_url,
        'google_url': merged.get('google_url'),
        'googleUrl': merged.get('google_url'),
        'latitude': merged.get('latitude'),
        'longitude': merged.get('longitude'),
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


def _sum_stop_distance(stops: list[dict]) -> float:
    total = 0.0
    for stop in stops:
        try:
            total += float(stop.get('distance_km') or 0)
        except Exception:
            continue
    return round(total, 1)
