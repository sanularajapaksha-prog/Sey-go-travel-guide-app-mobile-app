import logging
import os
import re as _re

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel

from ..dependencies import get_current_user

logger = logging.getLogger(__name__)
router = APIRouter(prefix='/reviews', tags=['reviews'])
REVIEWS_TABLE = 'reviews'


def _sb():
    from supabase import create_client as _cc
    return _cc(os.environ['SUPABASE_URL'], os.environ['SUPABASE_SERVICE_ROLE_KEY'])


def _safe_insert(sb, table: str, payload: dict) -> dict | None:
    """Insert dropping unknown columns one by one on PGRST204."""
    for _ in range(10):
        try:
            r = sb.table(table).insert(payload).execute()
            return (r.data or [None])[0]
        except Exception as exc:
            m = _re.search(r"find the '(\w+)' column", str(exc))
            if m:
                payload.pop(m.group(1), None)
            else:
                raise
    return None


class CreateReviewRequest(BaseModel):
    place_id: str | None = None
    place_name: str
    rating: int
    review_text: str | None = None


@router.get('/')
def get_community_reviews(limit: int = Query(20, ge=1, le=100), offset: int = Query(0, ge=0)):
    """Approved community reviews."""
    sb = _sb()
    try:
        cols = 'id,user_id,place_id,place_name,rating,review_text,status,likes_count,comments_count,user_name,user_badge,created_at'
        r = sb.table(REVIEWS_TABLE).select(cols).eq('status', 'approved').order('created_at', desc=True).range(offset, offset + limit - 1).execute()
        return r.data or []
    except Exception as exc:
        logger.warning('community reviews failed: %s', exc)
        return []


@router.get('/mine')
async def get_my_reviews(user=Depends(get_current_user)):
    """Current user's own reviews (all statuses)."""
    sb = _sb()
    try:
        cols = 'id,place_id,place_name,rating,review_text,status,likes_count,comments_count,created_at'
        r = sb.table(REVIEWS_TABLE).select(cols).eq('user_id', str(user.id)).order('created_at', desc=True).execute()
        return r.data or []
    except Exception as exc:
        logger.warning('my reviews failed: %s', exc)
        return []


@router.post('/', status_code=status.HTTP_201_CREATED)
async def create_review(body: CreateReviewRequest, user=Depends(get_current_user)):
    sb = _sb()
    meta = getattr(user, 'user_metadata', {}) or {}
    user_name = meta.get('full_name') or getattr(user, 'email', '') or 'Traveller'
    payload = {
        'user_id': str(user.id),
        'place_id': body.place_id,
        'place_name': body.place_name,
        'rating': max(1, min(5, body.rating)),
        'review_text': body.review_text,
        'status': 'pending',  # Explicitly require admin approval
        'user_name': user_name,
        'user_badge': 'Explorer',
        'likes_count': 0,
        'comments_count': 0,
    }
    row = _safe_insert(sb, REVIEWS_TABLE, payload)
    if not row:
        raise HTTPException(status_code=400, detail='Failed to create review.')
    return row


@router.put('/{review_id}/approve')
async def approve_review(review_id: str, user=Depends(get_current_user)):
    """Approve a pending review. Restricted to admin users only."""
    sb = _sb()
    meta = getattr(user, 'user_metadata', {}) or {}
    if not meta.get('is_admin'):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='Admin access required.')
    r = sb.table(REVIEWS_TABLE).select('id').eq('id', review_id).maybe_single().execute()
    if not r or not r.data:
        raise HTTPException(status_code=404, detail='Review not found.')
    sb.table(REVIEWS_TABLE).update({'status': 'approved'}).eq('id', review_id).execute()
    return {'approved': True}


@router.put('/{review_id}/like')
async def like_review(review_id: str, user=Depends(get_current_user)):
    sb = _sb()
    r = sb.table(REVIEWS_TABLE).select('likes_count').eq('id', review_id).maybe_single().execute()
    if not r or not r.data:
        raise HTTPException(status_code=404, detail='Review not found.')
    new_count = int(r.data.get('likes_count') or 0) + 1
    sb.table(REVIEWS_TABLE).update({'likes_count': new_count}).eq('id', review_id).execute()
    return {'likes_count': new_count}
