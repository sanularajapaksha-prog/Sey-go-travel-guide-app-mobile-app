from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from ..dependencies import get_current_user, get_supabase_client

router = APIRouter(prefix='/destinations', tags=['destinations'])

SAVED_TABLE = 'saved_destinations'


# ── Schemas (inline since they only serve this router) ──────────────────────

class SaveDestinationRequest(BaseModel):
    name: str
    latitude: float
    longitude: float
    address: str | None = None
    google_place_id: str | None = None
    category: str | None = None
    place_type: str | None = None
    rating: float | None = Field(default=None, ge=0, le=5)
    is_offline_available: bool = False


class UpdateDestinationRequest(BaseModel):
    name: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    address: str | None = None
    google_place_id: str | None = None
    category: str | None = None
    place_type: str | None = None
    rating: float | None = Field(default=None, ge=0, le=5)
    is_offline_available: bool | None = None


# ── Endpoints ───────────────────────────────────────────────────────────────

@router.post('/save', status_code=status.HTTP_201_CREATED)
async def save_destination(
    place: SaveDestinationRequest,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    payload = place.model_dump()
    payload['user_id'] = str(user.id)

    response = supabase.table(SAVED_TABLE).insert(payload).execute()
    if not response.data:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='Failed to save destination.')
    return {'saved': True, 'data': response.data[0]}


@router.get('/me')
async def get_my_destinations(user=Depends(get_current_user)):
    supabase = get_supabase_client()
    response = supabase.table(SAVED_TABLE).select('*').eq('user_id', str(user.id)).execute()
    return {'destinations': response.data}


@router.get('/me/paginated')
async def get_my_destinations_paginated(
    page: int = 1,
    limit: int = 10,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    start = (page - 1) * limit
    end = start + limit - 1
    response = (
        supabase.table(SAVED_TABLE)
        .select('*')
        .eq('user_id', str(user.id))
        .range(start, end)
        .execute()
    )
    return {'page': page, 'limit': limit, 'destinations': response.data}


@router.put('/{destination_id}')
async def update_destination(
    destination_id: int,
    update: UpdateDestinationRequest,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()

    existing = (
        supabase.table(SAVED_TABLE)
        .select('id')
        .eq('id', destination_id)
        .eq('user_id', str(user.id))
        .execute()
    )
    if not existing.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Destination not found or does not belong to you.')

    fields = {k: v for k, v in update.model_dump().items() if v is not None}
    if not fields:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='No fields provided to update.')

    response = (
        supabase.table(SAVED_TABLE)
        .update(fields)
        .eq('id', destination_id)
        .eq('user_id', str(user.id))
        .execute()
    )
    return {'message': 'Destination updated successfully', 'data': response.data}


@router.delete('/{destination_id}')
async def delete_destination(
    destination_id: int,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()

    existing = (
        supabase.table(SAVED_TABLE)
        .select('id')
        .eq('id', destination_id)
        .eq('user_id', str(user.id))
        .execute()
    )
    if not existing.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Destination not found or does not belong to you.')

    supabase.table(SAVED_TABLE).delete().eq('id', destination_id).eq('user_id', str(user.id)).execute()
    return {'message': 'Destination deleted successfully'}

