// lib/presentation/welcome_home_screen/widgets/notifications_panel.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Padding(
            padding: EdgeInsets.fromLTRB(5.w, 2.h, 4.w, 1.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Notifications",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 28,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Unread / Read tabs
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                _buildTabButton(context, label: "Unread (2)", isSelected: true),
                SizedBox(width: 4.w),
                _buildTabButton(context, label: "Read (3)", isSelected: false),
              ],
            ),
          ),

          SizedBox(height: 1.5.h),

          // Notifications list
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              children: [
                _buildNotificationItem(
                  context,
                  title: "Safety Alert: Check local weather",
                  subtitle: "Dambulla",
                  time: "•",
                  imageUrl:
                      "https://images.unsplash.com/photo-1506905925346-21bda4d32df4", // placeholder
                  isUnread: true,
                ),
                SizedBox(height: 1.2.h),
                _buildNotificationItem(
                  context,
                  title: "Newly Added Spot: Coral Beach",
                  subtitle: "Hikkaduwa",
                  time: "•",
                  imageUrl:
                      "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
                  isUnread: true,
                ),
                // Add more items here...
              ],
            ),
          ),

          // Bottom clear button
          Padding(
            padding: EdgeInsets.all(4.w),
            child: ElevatedButton(
                  onPressed: () {
                    // TODO: clear all logic
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    minimumSize: Size(double.infinity, 6.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Clear All Notifications",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
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
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // TODO: switch tab logic (if you want real tabs later)
        },
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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
    required String title,
    required String subtitle,
    required String time,
    required String imageUrl,
    required bool isUnread,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isUnread ? theme.colorScheme.primary.withOpacity(0.08) : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 14.w,
              height: 14.w,
              fit: BoxFit.cover,
            ),
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
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isUnread
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
                  "$time $subtitle",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              // TODO: delete single notification
            },
          ),
        ],
      ),
    );
  }
}
