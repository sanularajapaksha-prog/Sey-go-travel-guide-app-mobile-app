import os

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from supabase import create_client

from ..dependencies import get_current_user

router = APIRouter(prefix='/users', tags=['users'])


def _sb():
    return create_client(os.environ['SUPABASE_URL'], os.environ['SUPABASE_SERVICE_ROLE_KEY'])

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
    supabase = _sb()
    result = (
        supabase.table(PROFILES_TABLE)
        .select('*')
        .eq('id', str(user.id))
        .maybe_single()
        .execute()
    )
    profile = (result.data if result is not None else None) or {}

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


def _safe_count(supabase, table: str, filters: dict) -> list:
    try:
        q = supabase.table(table).select('id')
        for col, val in filters.items():
            q = q.eq(col, val)
        return q.execute().data or []
    except Exception:
        return []


def _safe_playlist_rows(supabase, uid: str) -> list:
    try:
        return (
            supabase.table('playlists')
            .select('id, places_count')
            .eq('user_id', uid)
            .eq('status', 'active')
            .execute()
            .data or []
        )
    except Exception:
        return []


@router.get('/me/stats')
async def get_user_stats(user=Depends(get_current_user)):
    """Return live activity counts for the current user."""
    supabase = _sb()
    uid = str(user.id)

    playlist_rows = _safe_playlist_rows(supabase, uid)
    review_rows  = _safe_count(supabase, 'reviews', {'user_id': uid})
    photo_rows   = _safe_count(supabase, 'photos',  {'user_id': uid})

    return {
        'playlists': len(playlist_rows),
        'places': sum(int(r.get('places_count') or 0) for r in playlist_rows),
        'reviews': len(review_rows),
        'photos': len(photo_rows),
    }

@router.put('/me')
async def update_profile(
    body: UpdateProfileRequest,
    user=Depends(get_current_user),
):
    supabase = _sb()
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
