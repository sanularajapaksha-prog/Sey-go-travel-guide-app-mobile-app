import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Profile header widget displaying user avatar, name, and edit button
class ProfileHeaderWidget extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String avatarUrl;
  final VoidCallback onEditProfile;
  final VoidCallback onAvatarTap;

  const ProfileHeaderWidget({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.avatarUrl,
    required this.onEditProfile,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Avatar with edit indicator
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                Container(
                  width: 25.w,
                  height: 25.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: CustomImageWidget(
                      imageUrl: avatarUrl,
                      width: 25.w,
                      height: 25.w,
                      fit: BoxFit.cover,
                      semanticLabel: "Profile photo of $userName",
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'edit',
                        color: theme.colorScheme.onPrimary,
                        size: 4.w,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          // User name
          Text(
            userName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.5.h),
          // User email
          Text(
            userEmail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          // Edit profile button
          OutlinedButton.icon(
            onPressed: onEditProfile,
            icon: CustomIconWidget(
              iconName: 'edit',
              color: theme.colorScheme.primary,
              size: 4.w,
            ),
            label: Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
            ),
          ),
        ],
      ),
    );
  }
}
