// lib/presentation/profile_screen/widgets/profile_header_widget.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? avatarUrl; // local path or network URL
  final VoidCallback onEditProfile;
  final VoidCallback onAvatarTap;

  const ProfileHeaderWidget({
    super.key,
    required this.userName,
    required this.userEmail,
    this.avatarUrl,
    required this.onEditProfile,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ImageProvider? avatarImage = avatarUrl == null
        ? null
        : avatarUrl!.startsWith('http')
            ? NetworkImage(avatarUrl!)
            : FileImage(File(avatarUrl!));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with camera icon overlay
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 14.w,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  backgroundImage: avatarImage,
                  child: avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: 24.w,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 3.5.w,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 4.5.w,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.5.h),

          // Name
          Text(
            userName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 0.8.h),

          // Email
          Text(
            userEmail,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 3.h),

          // Edit Profile Button
          OutlinedButton.icon(
            onPressed: onEditProfile,
            icon: Icon(Icons.edit_outlined, size: 5.w),
            label: Text(
              "Edit Profile",
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
