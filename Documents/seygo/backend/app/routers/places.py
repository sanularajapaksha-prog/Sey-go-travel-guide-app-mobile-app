from fastapi import APIRouter, Depends, HTTPException, status

from ..dependencies import get_current_user, get_supabase_client
from ..schemas.place import PlaceCreate

router = APIRouter(prefix='/places', tags=['places'])


@router.get('/')
async def get_places():
    try:
        supabase = get_supabase_client()
        response = supabase.table('places').select('*').execute()
        return response.data or []
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

        response = supabase.table('places').insert(payload).execute()
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
