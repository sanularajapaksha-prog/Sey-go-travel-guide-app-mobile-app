// lib/presentation/profile_screen/profile_sections.dart

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'profile_modals.dart';
import './widgets/toggle_settings_item_widget.dart';

// Activity Stats
Widget buildActivityStats(
  BuildContext context, {
  required int places,
  required int reviews,
  required int photos,
  required int journeys,
  VoidCallback? onReviewsTap,
}) {
  final theme = Theme.of(context);
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: EdgeInsets.all(5.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statColumn(theme, places.toString(), "Places"),
          _statColumn(
            theme,
            reviews.toString(),
            "Reviews",
            onTap: onReviewsTap,
          ),
          _statColumn(theme, photos.toString(), "Photos"),
          _statColumn(theme, journeys.toString(), "Journeys"),
        ],
      ),
    ),
  );
}

Widget _statColumn(
  ThemeData theme,
  String value,
  String label, {
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

// Achievement Badge
Widget buildAchievementBadge(
  BuildContext context, {
  required String title,
  required String description,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  return GestureDetector(
    onTap: onTap,
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.cardColor,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.orange, size: 10.w),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Activity Chips
Widget buildActivityChips(BuildContext context) {
  return Wrap(
    spacing: 2.w,
    runSpacing: 1.5.h,
    children: const [
      Chip(label: Text("Camping"), backgroundColor: Colors.teal),
      Chip(label: Text("Mountains"), backgroundColor: Colors.teal),
      Chip(label: Text("Beachside"), backgroundColor: Colors.teal),
    ],
  );
}

// Playlists Carousel
Widget buildPlaylistsCarousel(
  BuildContext context, {
  required bool isPublic,
  required ValueChanged<bool> onVisibilityChanged,
}) {
  final theme = Theme.of(context);

  final playlists = [
    {
      "title": "Hill Country Adventures",
      "image": "https://images.unsplash.com/photo-1564507592333-c3f5c5026d8f",
    },
    {
      "title": "Beach Relax Trip",
      "image": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
    },
    {
      "title": "Weekend Short Trip",
      "image": "https://images.unsplash.com/photo-1501785888041-af3ef285b470",
    },
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Your Playlists",
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 2.h),
      SizedBox(
        height: 20.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: playlists.length,
          separatorBuilder: (context, index) => SizedBox(width: 3.w),
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return SizedBox(
              width: 72.w,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(playlist['image']!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Text(
                      playlist['title']!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(blurRadius: 4, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      SizedBox(height: 2.h),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Public", style: theme.textTheme.bodyMedium),
          Switch(
            value: isPublic,
            onChanged: onVisibilityChanged,
            activeColor: theme.colorScheme.primary,
          ),
          Text("Private", style: theme.textTheme.bodyMedium),
        ],
      ),
    ],
  );
}

// Logout Button
Widget buildLogoutButton(BuildContext context) {
  final theme = Theme.of(context);
  return ElevatedButton(
    onPressed: () => showLogoutDialog(context),
    style: ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.error,
      minimumSize: Size(double.infinity, 6.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Text(
      "Logout",
      style: TextStyle(color: theme.colorScheme.onError, fontSize: 16.sp),
    ),
  );
}

// Delete Account Button
Widget buildDeleteAccountButton(BuildContext context) {
  final theme = Theme.of(context);
  return TextButton(
    onPressed: () => showDeleteAccountDialog(context),
    child: Text(
      "Delete Account",
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.error,
        decoration: TextDecoration.underline,
      ),
    ),
  );
}

// Notifications Section
Widget buildNotificationsSection(
  BuildContext context, {
  required bool push,
  required bool email,
  required ValueChanged<bool> onPushChanged,
  required ValueChanged<bool> onEmailChanged,
}) {
  final theme = Theme.of(context);
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 1.5.h),
          child: Text(
            "Notifications",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ToggleSettingsItemWidget(
          icon: Icons.notifications_outlined,
          title: "Push Notifications",
          subtitle: "Receive app notifications",
          value: push,
          onChanged: onPushChanged,
        ),
        Divider(height: 1, indent: 5.w, endIndent: 5.w),
        ToggleSettingsItemWidget(
          icon: Icons.email_outlined,
          title: "Email Notifications",
          subtitle: "Receive email updates",
          value: email,
          onChanged: onEmailChanged,
        ),
      ],
    ),
  );
}

// App Preferences Section
Widget buildAppPreferencesSection(
  BuildContext context, {
  required bool offline,
  required bool wifiOnly,
  required bool darkMode,
  required ValueChanged<bool> onOfflineChanged,
  required ValueChanged<bool> onWifiChanged,
  required ValueChanged<bool> onDarkModeChanged,
}) {
  final theme = Theme.of(context);
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 1.5.h),
          child: Text(
            "App Preferences",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ToggleSettingsItemWidget(
          icon: Icons.download_outlined,
          title: "Offline Downloads",
          subtitle: "Save destinations offline",
          value: offline,
          onChanged: onOfflineChanged,
        ),
        Divider(height: 1, indent: 5.w, endIndent: 5.w),
        ToggleSettingsItemWidget(
          icon: Icons.wifi_outlined,
          title: "WiFi Only Downloads",
          subtitle: "Download only on WiFi",
          value: wifiOnly,
          onChanged: onWifiChanged,
        ),
        Divider(height: 1, indent: 5.w, endIndent: 5.w),
        ToggleSettingsItemWidget(
          icon: Icons.dark_mode_outlined,
          title: "Dark Mode",
          subtitle: "Use dark theme",
          value: darkMode,
          onChanged: onDarkModeChanged,
        ),
      ],
    ),
  );
}

// Privacy Section
Widget buildPrivacySection(
  BuildContext context, {
  required bool locationSharing,
  required bool profileVisibility,
  required ValueChanged<bool> onLocationChanged,
  required ValueChanged<bool> onProfileVisibilityChanged,
}) {
  final theme = Theme.of(context);
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 1.5.h),
          child: Text(
            "Privacy",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ToggleSettingsItemWidget(
          icon: Icons.location_on_outlined,
          title: "Location Sharing",
          subtitle: "Share location for recommendations",
          value: locationSharing,
          onChanged: onLocationChanged,
        ),
        Divider(height: 1, indent: 5.w, endIndent: 5.w),
        ToggleSettingsItemWidget(
          icon: Icons.visibility_outlined,
          title: "Profile Visibility",
          subtitle: "Make profile public",
          value: profileVisibility,
          onChanged: onProfileVisibilityChanged,
        ),
      ],
    ),
  );
}
