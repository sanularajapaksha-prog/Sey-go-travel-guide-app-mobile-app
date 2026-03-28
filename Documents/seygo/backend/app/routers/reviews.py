import logging
import os
import re as _re
from datetime import datetime, timezone

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
            r = sb.table(table).insert(payload).select().execute()
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
        cols = 'id,place_id,place_name,rating,review_text,status,likes_count,comments_count,created_at,rejection_reason,approved_at,approved_by'
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


@router.get('/pending')
async def get_pending_reviews(
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    user=Depends(get_current_user),
):
    """Pending reviews for admin moderation."""
    meta = getattr(user, 'user_metadata', {}) or {}
    if not meta.get('is_admin'):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='Admin access required.')
    sb = _sb()
    try:
        cols = 'id,user_id,place_id,place_name,rating,review_text,status,user_name,created_at,rejection_reason'
        r = (
            sb.table(REVIEWS_TABLE)
            .select(cols)
            .eq('status', 'pending')
            .order('created_at', desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )
        return r.data or []
    except Exception as exc:
        logger.warning('pending reviews failed: %s', exc)
        return []


class RejectReviewRequest(BaseModel):
    reason: str | None = None


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
    now = datetime.now(timezone.utc).isoformat()
    approved_by = getattr(user, 'email', '') or str(user.id)
    review_row = sb.table(REVIEWS_TABLE).select('user_id,place_name').eq('id', review_id).maybe_single().execute()
    sb.table(REVIEWS_TABLE).update({
        'status': 'approved',
        'approved_at': now,
        'approved_by': approved_by,
        'rejection_reason': None,
    }).eq('id', review_id).execute()

    # Notify the review author
    if review_row and review_row.data:
        from .notifications import create_notification
        author_id = review_row.data.get('user_id', '')
        place_name = review_row.data.get('place_name', 'a place')
        if author_id:
            create_notification(
                sb,
                user_id=author_id,
                type_='review_approved',
                title='Your review was approved!',
                body=f'Your review of {place_name} is now visible to the community.',
                reference_id=review_id,
            )
    return {'approved': True}


@router.put('/{review_id}/reject')
async def reject_review(review_id: str, body: RejectReviewRequest = RejectReviewRequest(), user=Depends(get_current_user)):
    """Reject a pending review. Restricted to admin users only."""
    sb = _sb()
    meta = getattr(user, 'user_metadata', {}) or {}
    if not meta.get('is_admin'):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='Admin access required.')
    r = sb.table(REVIEWS_TABLE).select('id').eq('id', review_id).maybe_single().execute()
    if not r or not r.data:
        raise HTTPException(status_code=404, detail='Review not found.')
    sb.table(REVIEWS_TABLE).update({
        'status': 'rejected',
        'rejection_reason': body.reason,
        'approved_at': None,
        'approved_by': None,
    }).eq('id', review_id).execute()
    return {'rejected': True}


@router.delete('/{review_id}')
async def delete_review(review_id: str, user=Depends(get_current_user)):
    """Hard delete a review. Restricted to admin users only."""
    sb = _sb()
    meta = getattr(user, 'user_metadata', {}) or {}
    if not meta.get('is_admin'):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='Admin access required.')
    r = sb.table(REVIEWS_TABLE).select('id').eq('id', review_id).maybe_single().execute()
    if not r or not r.data:
        raise HTTPException(status_code=404, detail='Review not found.')
    sb.table(REVIEWS_TABLE).delete().eq('id', review_id).execute()
    return {'deleted': True}


class CreateCommentRequest(BaseModel):
    comment_text: str


@router.put('/{review_id}/like')
async def like_review(review_id: str, user=Depends(get_current_user)):
    sb = _sb()
    r = sb.table(REVIEWS_TABLE).select('likes_count,user_id,place_name').eq('id', review_id).maybe_single().execute()
    if not r or not r.data:
        raise HTTPException(status_code=404, detail='Review not found.')
    new_count = int(r.data.get('likes_count') or 0) + 1
    sb.table(REVIEWS_TABLE).update({'likes_count': new_count}).eq('id', review_id).execute()

    # Notify review author (skip self-likes)
    review_author_id = r.data.get('user_id', '')
    if review_author_id and review_author_id != str(user.id):
        from .notifications import create_notification
        meta = getattr(user, 'user_metadata', {}) or {}
        liker_name = meta.get('full_name') or getattr(user, 'email', '') or 'Someone'
        place_name = r.data.get('place_name', 'a place')
        create_notification(
            sb,
            user_id=review_author_id,
            type_='like',
            title=f'{liker_name} liked your review',
            body=f'Your review of {place_name} received a like.',
            reference_id=review_id,
        )
    return {'likes_count': new_count}


@router.get('/{review_id}/comments')
async def get_review_comments(
    review_id: str,
    limit: int = Query(30, ge=1, le=100),
):
    sb = _sb()
    try:
        r = (
            sb.table('review_comments')
            .select('id,user_id,user_name,comment_text,created_at')
            .eq('review_id', review_id)
            .order('created_at', desc=False)
            .limit(limit)
            .execute()
        )
        return r.data or []
    except Exception as exc:
        logger.warning('get_review_comments failed: %s', exc)
        return []


@router.post('/{review_id}/comments', status_code=status.HTTP_201_CREATED)
async def add_review_comment(
    review_id: str,
    body: CreateCommentRequest,
    user=Depends(get_current_user),
):
    sb = _sb()
    meta = getattr(user, 'user_metadata', {}) or {}
    user_name = meta.get('full_name') or getattr(user, 'email', '') or 'Traveller'

    # Insert comment
    row = (
        sb.table('review_comments')
        .insert({
            'review_id': review_id,
            'user_id': str(user.id),
            'user_name': user_name,
            'comment_text': body.comment_text.strip(),
        })
        .select()
        .execute()
    ).data
    if not row:
        raise HTTPException(status_code=400, detail='Failed to add comment.')

    # Increment comments_count on review
    review = (
        sb.table(REVIEWS_TABLE)
        .select('user_id,place_name,comments_count')
        .eq('id', review_id)
        .maybe_single()
        .execute()
    )
    if review and review.data:
        new_count = int(review.data.get('comments_count') or 0) + 1
        sb.table(REVIEWS_TABLE).update({'comments_count': new_count}).eq('id', review_id).execute()

        review_author_id = review.data.get('user_id', '')
        if review_author_id and review_author_id != str(user.id):
            from .notifications import create_notification
            place_name = review.data.get('place_name', 'your review')
            create_notification(
                sb,
                user_id=review_author_id,
                type_='comment',
                title=f'{user_name} commented on your review',
                body=f'"{body.comment_text[:80]}"',
                reference_id=review_id,
            )
    return row[0]
