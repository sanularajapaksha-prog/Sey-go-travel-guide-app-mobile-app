from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from ..dependencies import get_current_user, get_supabase_client

router = APIRouter(prefix='/playlists', tags=['playlists'])

PLAYLISTS_TABLE = 'playlists'
PLAYLIST_DEST_TABLE = 'playlist_places'
SAVED_TABLE = 'saved_destinations'

class PlaylistCreate(BaseModel):
    name: str
    description: str | None = None


class PlaylistUpdate(BaseModel):
    name: str | None = None
    description: str | None = None


class AddDestinationRequest(BaseModel):
    saved_destination_id: int
    position: int = 0


class ReorderRequest(BaseModel):
    ordered_destination_ids: list[int]

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
    payload = {
        'user_id': str(user.id),
        'name': body.name,
        'description': body.description,
    }
    response = supabase.table(PLAYLISTS_TABLE).insert(payload).execute()
    if not response.data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='Failed to create playlist.',
        )
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
async def get_playlist_with_destinations(
    playlist_id: int,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    playlist = _get_playlist_or_404(supabase, playlist_id, str(user.id))

    entries = (
        supabase.table(PLAYLIST_DEST_TABLE)
        .select('position, added_at, saved_destinations(*)')
        .eq('playlist_id', playlist_id)
        .order('position')
        .execute()
    )

    return {
        'playlist': playlist,
        'destinations': entries.data,
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
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='No fields provided to update.',
        )

    fields['updated_at'] = 'now()'
    response = (
        supabase.table(PLAYLISTS_TABLE)
        .update(fields)
        .eq('id', playlist_id)
        .eq('user_id', str(user.id))
        .execute()
    )
    return {'message': 'Playlist updated.', 'data': response.data}


@router.delete('/{playlist_id}', status_code=status.HTTP_200_OK)
async def delete_playlist(
    playlist_id: int,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    _get_playlist_or_404(supabase, playlist_id, str(user.id))

    supabase.table(PLAYLISTS_TABLE).delete().eq('id', playlist_id).eq('user_id', str(user.id)).execute()
    return {'message': 'Playlist deleted.'}

@router.post('/{playlist_id}/destinations', status_code=status.HTTP_201_CREATED)
async def add_destination_to_playlist(
    playlist_id: int,
    body: AddDestinationRequest,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    _get_playlist_or_404(supabase, playlist_id, str(user.id))

    dest_check = (
        supabase.table(SAVED_TABLE)
        .select('id')
        .eq('id', body.saved_destination_id)
        .eq('user_id', str(user.id))
        .execute()
    )
    if not dest_check.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Saved destination not found or does not belong to you.',
        )

    duplicate = (
        supabase.table(PLAYLIST_DEST_TABLE)
        .select('id')
        .eq('playlist_id', playlist_id)
        .eq('saved_destination_id', body.saved_destination_id)
        .execute()
    )
    if duplicate.data:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail='This destination is already in the playlist.',
        )

    response = supabase.table(PLAYLIST_DEST_TABLE).insert({
        'playlist_id': playlist_id,
        'saved_destination_id': body.saved_destination_id,
        'position': body.position,
    }).execute()

    return {'added': True, 'data': response.data[0]}

@router.delete('/{playlist_id}/destinations/{saved_destination_id}')
async def remove_destination_from_playlist(
    playlist_id: int,
    saved_destination_id: int,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    _get_playlist_or_404(supabase, playlist_id, str(user.id))

    supabase.table(PLAYLIST_DEST_TABLE).delete().eq('playlist_id', playlist_id).eq(
        'saved_destination_id', saved_destination_id
    ).execute()

    return {'message': 'Destination removed from playlist.'}


@router.put('/{playlist_id}/destinations/reorder')
async def reorder_playlist_destinations(
    playlist_id: int,
    body: ReorderRequest,
    user=Depends(get_current_user),
):

    supabase = get_supabase_client()
    _get_playlist_or_404(supabase, playlist_id, str(user.id))

    for index, dest_id in enumerate(body.ordered_destination_ids):
        supabase.table(PLAYLIST_DEST_TABLE).update({'position': index}).eq(
            'playlist_id', playlist_id
        ).eq('saved_destination_id', dest_id).execute()

    return {'message': 'Playlist reordered.', 'order': body.ordered_destination_ids}
