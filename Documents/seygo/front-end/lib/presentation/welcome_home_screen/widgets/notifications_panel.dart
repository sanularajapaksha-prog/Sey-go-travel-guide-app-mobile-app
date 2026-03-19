// lib/presentation/welcome_home_screen/widgets/notifications_panel.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class _NotificationItem {
  _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.isUnread,
  });
  final String title;
  final String subtitle;
  final String imageUrl;
  final bool isUnread;
}

class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key});

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  bool _showUnread = true;

  final List<_NotificationItem> _unread = [
    _NotificationItem(
      title: 'Safety Alert: Check local weather',
      subtitle: 'Dambulla',
      imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=200&q=80&fit=crop',
      isUnread: true,
    ),
    _NotificationItem(
      title: 'Newly Added Spot: Coral Beach',
      subtitle: 'Hikkaduwa',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=200&q=80&fit=crop',
      isUnread: true,
    ),
  ];

  final List<_NotificationItem> _read = [
    _NotificationItem(
      title: 'New place added near you',
      subtitle: 'Kandy',
      imageUrl: 'https://images.unsplash.com/photo-1548013146-72479768bada?w=200&q=80&fit=crop',
      isUnread: false,
    ),
    _NotificationItem(
      title: 'Your review was approved',
      subtitle: 'Sigiriya',
      imageUrl: 'https://images.unsplash.com/photo-1683295657287-86c908b256f8?w=200&q=80&fit=crop',
      isUnread: false,
    ),
    _NotificationItem(
      title: 'Weekend travel tip: Ella',
      subtitle: 'Ella',
      imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=200&q=80&fit=crop',
      isUnread: false,
    ),
  ];

  List<_NotificationItem> get _active => _showUnread ? _unread : _read;

  void _deleteItem(int index) {
    setState(() => _active.removeAt(index));
  }

  void _clearAll() {
    setState(() => _active.clear());
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
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(5.w, 2.h, 4.w, 1.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 28,
                      color: theme.colorScheme.onSurfaceVariant),
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
                _buildTabButton(
                  context,
                  label: 'Unread (${_unread.length})',
                  isSelected: _showUnread,
                  onTap: () => setState(() => _showUnread = true),
                ),
                SizedBox(width: 4.w),
                _buildTabButton(
                  context,
                  label: 'Read (${_read.length})',
                  isSelected: !_showUnread,
                  onTap: () => setState(() => _showUnread = false),
                ),
              ],
            ),
          ),

          SizedBox(height: 1.5.h),

          // List
          Flexible(
            child: _active.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Text(
                      'No notifications',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    itemCount: _active.length,
                    separatorBuilder: (_, _) => SizedBox(height: 1.2.h),
                    itemBuilder: (context, index) => _buildNotificationItem(
                      context,
                      item: _active[index],
                      onDelete: () => _deleteItem(index),
                    ),
                  ),
          ),

          // Clear all button
          if (_active.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: ElevatedButton(
                onPressed: _clearAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: Size(double.infinity, 6.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Clear All Notifications',
                  style: TextStyle(
                      fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.2.h),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    required _NotificationItem item,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: item.isUnread
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.imageUrl,
              width: 14.w,
              height: 14.w,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 14.w,
                height: 14.w,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(Icons.image_not_supported_outlined,
                    size: 20, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsets.only(right: 2.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: item.isUnread
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.4.h),
                Text(
                  item.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
