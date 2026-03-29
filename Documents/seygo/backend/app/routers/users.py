import logging
import os

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from supabase import create_client

from ..dependencies import get_current_user

logger = logging.getLogger(__name__)

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


def _safe_count(supabase, table: str, filters: dict) -> int:
    """Return a server-side COUNT(*) — avoids fetching all rows."""
    try:
        q = supabase.table(table).select('id', count='exact')
        for col, val in filters.items():
            q = q.eq(col, val)
        result = q.execute()
        return result.count or 0
    except Exception:
        logger.exception('_safe_count failed for table=%s filters=%s', table, filters)
        return 0


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
        logger.exception('_safe_playlist_rows failed for user=%s', uid)
        return []


@router.get('/me/stats')
async def get_user_stats(user=Depends(get_current_user)):
    """Return live activity counts for the current user."""
    supabase = _sb()
    uid = str(user.id)

    playlist_rows = _safe_playlist_rows(supabase, uid)
    review_count  = _safe_count(supabase, 'reviews', {'user_id': uid})
    photo_count   = _safe_count(supabase, 'photos',  {'user_id': uid})

    return {
        'playlists': len(playlist_rows),
        'places': sum(int(r.get('places_count') or 0) for r in playlist_rows),
        'reviews': review_count,
        'photos': photo_count,
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


@router.delete('/me', status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(user=Depends(get_current_user)):
    """Permanently delete the authenticated user's account."""
    supabase = _sb()
    try:
        supabase.auth.admin.delete_user(str(user.id))
    except Exception as exc:
        logger.error('delete_account failed for user=%s: %s', user.id, exc, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail='Account deletion failed. Please try again.',
        )
