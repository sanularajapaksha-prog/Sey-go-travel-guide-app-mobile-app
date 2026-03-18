import os

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from supabase import create_client

from ..dependencies import get_current_user
from ..services.google_places import GooglePlacesService
from ..services.place_taxonomy import infer_taxonomy

google_places_service = GooglePlacesService()

router = APIRouter(prefix='/destinations', tags=['destinations'])


def _sb():
    return create_client(os.environ['SUPABASE_URL'], os.environ['SUPABASE_SERVICE_ROLE_KEY'])

SAVED_TABLE = 'saved_destinations'

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

class SaveFromGoogleRequest(BaseModel):
    google_place_id: str

@router.post('/save', status_code=status.HTTP_201_CREATED)
async def save_destination(
    place: SaveDestinationRequest,
    user=Depends(get_current_user),
):
    supabase = _sb()
    payload = place.model_dump()
    payload['user_id'] = str(user.id)

    response = supabase.table(SAVED_TABLE).insert(payload).execute()
    if not response.data:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='Failed to save destination.')
    return {'saved': True, 'data': response.data[0]}

@router.post('/save-from-google', status_code=status.HTTP_201_CREATED)
async def save_from_google(
    request: SaveFromGoogleRequest,
    user=Depends(get_current_user),
):

    try:
        details = google_places_service.place_details(request.google_place_id)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f'Failed to fetch place details from Google: {exc}',
        )

    supabase = _sb()
    existing = (
        supabase.table(SAVED_TABLE)
        .select('id')
        .eq('user_id', str(user.id))
        .eq('google_place_id', request.google_place_id)
        .execute()
    )
    if existing.data:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail='You have already saved this place.',
        )

    payload = {
        'user_id': str(user.id),
        'name': details.get('name', ''),
        'latitude': details.get('latitude'),
        'longitude': details.get('longitude'),
        'address': details.get('formatted_address'),
        'google_place_id': request.google_place_id,
        'place_type': details.get('primary_type'),
        'category': details.get('taxonomy_category'),
        'rating': details.get('rating'),
        'is_offline_available': False,
    }

    response = supabase.table(SAVED_TABLE).insert(payload).execute()
    if not response.data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='Failed to save destination.',
        )

    return {'saved': True, 'data': response.data[0]}

@router.get('/me')
async def get_my_destinations(user=Depends(get_current_user)):
    supabase = _sb()
    response = supabase.table(SAVED_TABLE).select('*').eq('user_id', str(user.id)).execute()
    return {'destinations': response.data}


@router.get('/me/paginated')
async def get_my_destinations_paginated(
    page: int = 1,
    limit: int = 10,
    user=Depends(get_current_user),
):
    supabase = _sb()
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
    supabase = _sb()

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
    supabase = _sb()

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


