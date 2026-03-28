import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/services/api_service.dart';

class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key});

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  bool _showUnread = true;
  bool _loading = true;
  List<Map<String, dynamic>> _all = [];

  List<Map<String, dynamic>> get _unread =>
      _all.where((n) => n['is_read'] != true).toList();
  List<Map<String, dynamic>> get _read =>
      _all.where((n) => n['is_read'] == true).toList();
  List<Map<String, dynamic>> get _active => _showUnread ? _unread : _read;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final items = await ApiService.fetchNotifications(accessToken: token);
    if (!mounted) return;
    setState(() {
      _all = items;
      _loading = false;
    });
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['is_read'] == true) return;
    // Broadcast notifications (user_id == null) cannot be marked per-user server-side
    if (item['user_id'] == null) {
      setState(() => item['is_read'] = true);
      return;
    }
    final id = item['id']?.toString() ?? '';
    setState(() => item['is_read'] = true);
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    await ApiService.markNotificationRead(id, accessToken: token);
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    setState(() => _all.remove(item));
    if (item['user_id'] != null) {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      await ApiService.deleteNotification(id, accessToken: token);
    }
  }

  Future<void> _markAllRead() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    setState(() {
      for (final n in _all) {
        n['is_read'] = true;
      }
    });
    await ApiService.markAllNotificationsRead(accessToken: token);
  }

  Future<void> _clearAll() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final personal = _active.where((n) => n['user_id'] != null).toList();
    setState(() {
      for (final n in personal) {
        _all.remove(n);
      }
    });
    await ApiService.clearAllNotifications(accessToken: token);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 10.w,
            height: 0.5.h,
            margin: EdgeInsets.only(top: 1.2.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(100),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(5.w, 1.5.h, 2.w, 0.5.h),
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (_unread.isNotEmpty)
                  TextButton(
                    onPressed: _markAllRead,
                    child: Text('Mark all read',
                        style: TextStyle(fontSize: 11.sp)),
                  ),
                IconButton(
                  icon: Icon(Icons.close,
                      size: 24, color: theme.colorScheme.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tabs
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                _tabBtn(context, 'Unread (${_unread.length})', _showUnread,
                    () => setState(() => _showUnread = true)),
                SizedBox(width: 3.w),
                _tabBtn(context, 'Read (${_read.length})', !_showUnread,
                    () => setState(() => _showUnread = false)),
              ],
            ),
          ),

          SizedBox(height: 1.h),

          // Content
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : _active.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none_rounded,
                                size: 12.w,
                                color: theme.colorScheme.outlineVariant),
                            SizedBox(height: 1.h),
                            Text(
                              _showUnread
                                  ? 'All caught up!'
                                  : 'No read notifications',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        itemCount: _active.length,
                        separatorBuilder: (_, __) => SizedBox(height: 0.8.h),
                        itemBuilder: (context, index) {
                          final item = _active[index];
                          return _buildItem(context, item);
                        },
                      ),
          ),

          // Clear / Refresh row
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 0.5.h, 4.w, 3.h),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                if (_active.any((n) => n['user_id'] != null)) ...[
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                      label: const Text('Clear All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final isUnread = item['is_read'] != true;
    final title = item['title'] as String? ?? '';
    final body = item['body'] as String? ?? '';
    final imageUrl = item['image_url'] as String?;
    final type = item['type'] as String? ?? '';
    final createdAt = item['created_at'] as String? ?? '';
    final dateStr = createdAt.length >= 10 ? createdAt.substring(0, 10) : '';

    return GestureDetector(
      onTap: () => _markRead(item),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isUnread
              ? theme.colorScheme.primary.withOpacity(0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isUnread
              ? Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.18))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon or image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 13.w,
                      height: 13.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _typeIcon(type, theme),
                    )
                  : _typeIcon(type, theme),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isUnread)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 6, top: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    SizedBox(height: 0.3.h),
                    Text(
                      body,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (dateStr.isNotEmpty) ...[
                    SizedBox(height: 0.4.h),
                    Text(dateStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9.sp,
                            color: theme.colorScheme.outline)),
                  ],
                ],
              ),
            ),
            // Delete button (only for personal notifications)
            if (item['user_id'] != null)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.close_rounded,
                    size: 16, color: theme.colorScheme.outline),
                onPressed: () => _delete(item),
              ),
          ],
        ),
      ),
    );
  }

  Widget _typeIcon(String type, ThemeData theme) {
    final (icon, color) = switch (type) {
      'like' => (Icons.thumb_up_rounded, const Color(0xFF2F7BF2)),
      'comment' => (Icons.chat_bubble_rounded, const Color(0xFF43A047)),
      'review_approved' => (Icons.check_circle_rounded, const Color(0xFF00897B)),
      'new_place' => (Icons.place_rounded, const Color(0xFFE53935)),
      'playlist_public' => (Icons.playlist_add_check_rounded, const Color(0xFF8E24AA)),
      _ => (Icons.notifications_rounded, theme.colorScheme.primary),
    };
    return Container(
      width: 13.w,
      height: 13.w,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 6.w),
    );
  }

  Widget _tabBtn(
      BuildContext context, String label, bool selected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.1.h),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
