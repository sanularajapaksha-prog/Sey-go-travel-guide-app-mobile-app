from fastapi import APIRouter, Depends
from pydantic import BaseModel

from ..dependencies import get_current_user, get_supabase_client

router = APIRouter(prefix='/users', tags=['users'])

PROFILES_TABLE = 'profiles'


class UpdateProfileRequest(BaseModel):
    full_name: str | None = None
    bio: str | None = None
    home_city: str | None = None
    travel_style: str | None = None
    avatar_url: str | None = None


@router.get('/me')
async def get_profile(user=Depends(get_current_user)):
    """Return the current user's profile row plus auth metadata."""
    supabase = get_supabase_client()
    result = (
        supabase.table(PROFILES_TABLE)
        .select('*')
        .eq('id', str(user.id))
        .maybe_single()
        .execute()
    )
    profile = result.data or {}

    # Fall back to auth user_metadata if profile row is sparse
    meta = getattr(user, 'user_metadata', {}) or {}
    return {
        'id': str(user.id),
        'email': getattr(user, 'email', ''),
        'full_name': profile.get('full_name') or meta.get('full_name', ''),
        'bio': profile.get('bio', ''),
        'home_city': profile.get('home_city', ''),
        'travel_style': profile.get('travel_style', ''),
        'avatar_url': profile.get('avatar_url', ''),
    }


@router.put('/me')
async def update_profile(
    body: UpdateProfileRequest,
    user=Depends(get_current_user),
):
    supabase = get_supabase_client()
    fields = {k: v for k, v in body.model_dump().items() if v is not None}

    # Upsert so the row is created if it doesn't exist yet
    fields['id'] = str(user.id)
    supabase.table(PROFILES_TABLE).upsert(fields).execute()

    # Also sync full_name into auth user_metadata so it shows everywhere
    if 'full_name' in fields:
        supabase.auth.admin.update_user_by_id(
            str(user.id),
            {'user_metadata': {'full_name': fields['full_name']}},
        )

    return {'updated': True}
