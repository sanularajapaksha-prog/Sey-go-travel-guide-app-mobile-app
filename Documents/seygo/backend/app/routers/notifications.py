import logging
import os

from fastapi import APIRouter, Depends, Query

from ..dependencies import get_current_user

logger = logging.getLogger(__name__)
router = APIRouter(prefix='/notifications', tags=['notifications'])
NOTIFICATIONS_TABLE = 'notifications'


def _sb():
    from supabase import create_client as _cc
    return _cc(os.environ['SUPABASE_URL'], os.environ['SUPABASE_SERVICE_ROLE_KEY'])


def create_notification(
    sb,
    user_id: str,
    type_: str,
    title: str,
    body: str | None = None,
    image_url: str | None = None,
    reference_id: str | None = None,
) -> None:
    """Insert a notification row. Silently swallows errors so it never breaks primary actions."""
    try:
        sb.table(NOTIFICATIONS_TABLE).insert({
            'user_id': user_id,
            'type': type_,
            'title': title,
            'body': body,
            'image_url': image_url,
            'reference_id': reference_id,
            'is_read': False,
        }).execute()
    except Exception as exc:
        logger.warning('create_notification failed (non-fatal): %s', exc)


def create_broadcast_notification(
    sb,
    type_: str,
    title: str,
    body: str | None = None,
    image_url: str | None = None,
    reference_id: str | None = None,
) -> None:
    """Insert a broadcast notification (user_id = NULL — visible to all users)."""
    try:
        sb.table(NOTIFICATIONS_TABLE).insert({
            'user_id': None,
            'type': type_,
            'title': title,
            'body': body,
            'image_url': image_url,
            'reference_id': reference_id,
            'is_read': False,
        }).execute()
    except Exception as exc:
        logger.warning('create_broadcast_notification failed (non-fatal): %s', exc)


_COLS = 'id,user_id,type,title,body,image_url,reference_id,is_read,created_at'


@router.get('/')
async def get_notifications(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    user=Depends(get_current_user),
):
    """Fetch the current user's personal notifications plus all broadcasts, newest first."""
    sb = _sb()
    uid = str(user.id)
    try:
        # Personal notifications for this user
        personal = (
            sb.table(NOTIFICATIONS_TABLE)
            .select(_COLS)
            .eq('user_id', uid)
            .order('created_at', desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        ).data or []

        # Broadcast notifications (user_id IS NULL)
        broadcasts = (
            sb.table(NOTIFICATIONS_TABLE)
            .select(_COLS)
            .is_('user_id', 'null')
            .order('created_at', desc=True)
            .limit(20)
            .execute()
        ).data or []

        # Merge and re-sort by created_at
        merged = sorted(
            personal + broadcasts,
            key=lambda n: n.get('created_at', ''),
            reverse=True,
        )
        return merged[:limit]
    except Exception as exc:
        logger.warning('get_notifications failed: %s', exc)
        return []


@router.get('/unread-count')
async def get_unread_count(user=Depends(get_current_user)):
    """Returns count of unread personal notifications."""
    sb = _sb()
    try:
        r = (
            sb.table(NOTIFICATIONS_TABLE)
            .select('id', count='exact')
            .eq('user_id', str(user.id))
            .eq('is_read', False)
            .execute()
        )
        return {'count': r.count or 0}
    except Exception as exc:
        logger.warning('get_unread_count failed: %s', exc)
        return {'count': 0}


@router.put('/read-all')
async def mark_all_read(user=Depends(get_current_user)):
    """Mark all of the current user's personal notifications as read."""
    sb = _sb()
    try:
        sb.table(NOTIFICATIONS_TABLE).update({'is_read': True}).eq('user_id', str(user.id)).eq('is_read', False).execute()
    except Exception as exc:
        logger.warning('mark_all_read failed: %s', exc)
    return {'ok': True}


@router.put('/{notification_id}/read')
async def mark_notification_read(notification_id: str, user=Depends(get_current_user)):
    """Mark a single notification as read."""
    sb = _sb()
    try:
        sb.table(NOTIFICATIONS_TABLE).update({'is_read': True}).eq('id', notification_id).eq('user_id', str(user.id)).execute()
    except Exception as exc:
        logger.warning('mark_notification_read failed: %s', exc)
    return {'ok': True}


@router.delete('/clear-all')
async def clear_all_notifications(user=Depends(get_current_user)):
    """Delete all personal notifications for the current user."""
    sb = _sb()
    try:
        sb.table(NOTIFICATIONS_TABLE).delete().eq('user_id', str(user.id)).execute()
    except Exception as exc:
        logger.warning('clear_all_notifications failed: %s', exc)
    return {'cleared': True}


@router.delete('/{notification_id}')
async def delete_notification(notification_id: str, user=Depends(get_current_user)):
    """Delete a single personal notification."""
    sb = _sb()
    try:
        sb.table(NOTIFICATIONS_TABLE).delete().eq('id', notification_id).eq('user_id', str(user.id)).execute()
    except Exception as exc:
        logger.warning('delete_notification failed: %s', exc)
    return {'deleted': True}
