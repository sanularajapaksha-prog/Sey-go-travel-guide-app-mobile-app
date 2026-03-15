from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from ..dependencies import get_current_user, get_supabase_client

router = APIRouter(prefix='/playlists', tags=['playlists'])

PLAYLISTS_TABLE = 'playlists'
PLAYLIST_PLACES_TABLE = 'playlist_places'
PLACES_TABLE = 'placses'

class PlaylistCreate(BaseModel):
    name: str
    description: str | None = None


class PlaylistUpdate(BaseModel):
    name: str | None = None
    description: str | None = None


class AddPlaceRequest(BaseModel):
    place_id: str        
    position: int = 0


class ReorderRequest(BaseModel):

    ordered_place_ids: list[str]

def _get_playlist_or_404(supabase, playlist_id: int, user_id: str) -> dict:
    response = (
        supabase.table(PLAYLISTS_TABLE)
        .select('*')
        .eq('id', playlist_id)
        .eq('user_id', user_id)
        .execute()
    )
    if not response.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Playlist not found or does not belong to you.',
        )
    return response.data[0]

@router.post('/', status_code=status.HTTP_201_CREATED)
async def create_playlist(
    body: PlaylistCreate,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    response = supabase.table(PLAYLISTS_TABLE).insert({
        'user_id': str(user.id),
        'name': body.name,
        'description': body.description,
    }).execute()

    if not response.data:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='Failed to create playlist.')
    return response.data[0]


@router.get('/')
async def get_my_playlists(user=Depends(get_current_user)):
    supabase = get_supabase_client()
    response = (
        supabase.table(PLAYLISTS_TABLE)
        .select('*')
        .eq('user_id', str(user.id))
        .order('created_at', desc=True)
        .execute()
    )
    return {'playlists': response.data}


@router.get('/{playlist_id}')
async def get_playlist_with_places(
    playlist_id: int,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    playlist = _get_playlist_or_404(supabase, playlist_id, str(user.id))

    entries = (
        supabase.table(PLAYLIST_PLACES_TABLE)
        .select(f'position, created_at, {PLACES_TABLE}(*)')
        .eq('playlist_id', playlist_id)
        .order('position')
        .execute()
    )

    return {
        'playlist': playlist,
        'places': entries.data,
    }


@router.patch('/{playlist_id}')
async def update_playlist(
    playlist_id: int,
    body: PlaylistUpdate,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    _get_playlist_or_404(supabase, playlist_id, str(user.id))

    fields = {k: v for k, v in body.model_dump().items() if v is not None}
    if not fields:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='No fields provided to update.')

    response = (
        supabase.table(PLAYLISTS_TABLE)
        .update(fields)
        .eq('id', playlist_id)
        .eq('user_id', str(user.id))
        .execute()
    )
    return {'message': 'Playlist updated.', 'data': response.data}


@router.delete('/{playlist_id}')
async def delete_playlist(
    playlist_id: int,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    _get_playlist_or_404(supabase, playlist_id, str(user.id))

    supabase.table(PLAYLISTS_TABLE).delete().eq('id', playlist_id).eq('user_id', str(user.id)).execute()
    return {'message': 'Playlist deleted.'}


@router.post('/{playlist_id}/places', status_code=status.HTTP_201_CREATED)
async def add_place_to_playlist(
    playlist_id: int,
    body: AddPlaceRequest,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    _get_playlist_or_404(supabase, playlist_id, str(user.id))

    place_check = (
        supabase.table(PLACES_TABLE)
        .select('id')
        .eq('id', body.place_id)
        .execute()
    )
    if not place_check.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Place not found.')
        
    duplicate = (
        supabase.table(PLAYLIST_PLACES_TABLE)
        .select('id')
        .eq('playlist_id', playlist_id)
        .eq('place_id', body.place_id)
        .execute()
    )
    if duplicate.data:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail='This place is already in the playlist.')

    response = supabase.table(PLAYLIST_PLACES_TABLE).insert({
        'playlist_id': playlist_id,
        'place_id': body.place_id,
        'position': body.position,
    }).execute()

    return {'added': True, 'data': response.data[0]}


@router.delete('/{playlist_id}/places/{place_id}')
async def remove_place_from_playlist(
    playlist_id: int,
    place_id: str,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    _get_playlist_or_404(supabase, playlist_id, str(user.id))

    supabase.table(PLAYLIST_PLACES_TABLE).delete().eq('playlist_id', playlist_id).eq(
        'place_id', place_id
    ).execute()
    return {'message': 'Place removed from playlist.'}


@router.put('/{playlist_id}/places/reorder')
async def reorder_playlist_places(
    playlist_id: int,
    body: ReorderRequest,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    _get_playlist_or_404(supabase, playlist_id, str(user.id))

    for index, place_id in enumerate(body.ordered_place_ids):
        supabase.table(PLAYLIST_PLACES_TABLE).update({'position': index}).eq(
            'playlist_id', playlist_id
        ).eq('place_id', place_id).execute()

    return {'message': 'Playlist reordered.', 'order': body.ordered_place_ids}
```
