import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/toggle_settings_item_widget.dart';

/// Profile screen for user account management and app preferences
/// Accessed via bottom tab navigation with Profile tab active
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User data
  final String _userName = "Sarah Johnson";
  final String _userEmail = "sarah.johnson@example.com";
  String _avatarUrl =
      "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png";

  // Settings states
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _offlineDownloads = true;
  bool _wifiOnlyDownloads = true;
  bool _locationSharing = true;
  bool _profileVisibility = false;
  bool _darkMode = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Custom app bar
        CustomAppBar(
          title: 'Profile',
          centerTitle: true,
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'settings',
                color: theme.colorScheme.onSurface,
                size: 6.w,
              ),
              onPressed: () {
                _showSettingsInfo(context);
              },
            ),
          ],
        ),
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 2.h),
                // Profile header
                ProfileHeaderWidget(
                  userName: _userName,
                  userEmail: _userEmail,
                  avatarUrl: _avatarUrl,
                  onEditProfile: () => _navigateToEditProfile(context),
                  onAvatarTap: () => _changeProfilePicture(context),
                ),
                SizedBox(height: 2.h),
                // Account section
                SettingsSectionWidget(
                  title: 'Account',
                  items: [
                    SettingsItemData(
                      iconName: 'person',
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      onTap: () => _navigateToEditProfile(context),
                    ),
                    SettingsItemData(
                      iconName: 'lock',
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      onTap: () => _showChangePassword(context),
                    ),
                    SettingsItemData(
                      iconName: 'email',
                      title: 'Email Preferences',
                      subtitle: 'Manage email communications',
                      onTap: () => _showEmailPreferences(context),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                // Notifications section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                        child: Text(
                          'Notifications',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ToggleSettingsItemWidget(
                        iconName: 'notifications',
                        title: 'Push Notifications',
                        subtitle: 'Receive app notifications',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() => _pushNotifications = value);
                        },
                      ),
                      Divider(height: 1, indent: 4.w, endIndent: 4.w),
                      ToggleSettingsItemWidget(
                        iconName: 'email',
                        title: 'Email Notifications',
                        subtitle: 'Receive email updates',
                        value: _emailNotifications,
                        onChanged: (value) {
                          setState(() => _emailNotifications = value);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                // App preferences section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                        child: Text(
                          'App Preferences',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ToggleSettingsItemWidget(
                        iconName: 'download',
                        title: 'Offline Downloads',
                        subtitle: 'Save destinations for offline viewing',
                        value: _offlineDownloads,
                        onChanged: (value) {
                          setState(() => _offlineDownloads = value);
                        },
                      ),
                      Divider(height: 1, indent: 4.w, endIndent: 4.w),
                      ToggleSettingsItemWidget(
                        iconName: 'wifi',
                        title: 'WiFi Only Downloads',
                        subtitle: 'Download only on WiFi',
                        value: _wifiOnlyDownloads,
                        onChanged: (value) {
                          setState(() => _wifiOnlyDownloads = value);
                        },
                      ),
                      Divider(height: 1, indent: 4.w, endIndent: 4.w),
                      ToggleSettingsItemWidget(
                        iconName: 'dark_mode',
                        title: 'Dark Mode',
                        subtitle: 'Use dark theme',
                        value: _darkMode,
                        onChanged: (value) {
                          setState(() => _darkMode = value);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                // Travel preferences section
                SettingsSectionWidget(
                  title: 'Travel Preferences',
                  items: [
                    SettingsItemData(
                      iconName: 'explore',
                      title: 'Destination Recommendations',
                      subtitle: 'Customize your discovery feed',
                      onTap: () => _showRecommendations(context),
                    ),
                    SettingsItemData(
                      iconName: 'category',
                      title: 'Preferred Categories',
                      subtitle: 'Beach Side, Mountains, Temples',
                      onTap: () => _showCategories(context),
                    ),
                    SettingsItemData(
                      iconName: 'straighten',
                      title: 'Distance Units',
                      subtitle: 'Kilometers',
                      onTap: () => _showDistanceUnits(context),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                // Privacy section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                        child: Text(
                          'Privacy',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ToggleSettingsItemWidget(
                        iconName: 'location_on',
                        title: 'Location Sharing',
                        subtitle: 'Share location for recommendations',
                        value: _locationSharing,
                        onChanged: (value) {
                          setState(() => _locationSharing = value);
                        },
                      ),
                      Divider(height: 1, indent: 4.w, endIndent: 4.w),
                      ToggleSettingsItemWidget(
                        iconName: 'visibility',
                        title: 'Profile Visibility',
                        subtitle: 'Make profile public',
                        value: _profileVisibility,
                        onChanged: (value) {
                          setState(() => _profileVisibility = value);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                // Support section
                SettingsSectionWidget(
                  title: 'Support',
                  items: [
                    SettingsItemData(
                      iconName: 'help',
                      title: 'Help Center',
                      subtitle: 'Get help and support',
                      onTap: () => _showHelpCenter(context),
                    ),
                    SettingsItemData(
                      iconName: 'feedback',
                      title: 'Send Feedback',
                      subtitle: 'Share your thoughts',
                      onTap: () => _showFeedback(context),
                    ),
                    SettingsItemData(
                      iconName: 'info',
                      title: 'App Version',
                      subtitle: 'Version 1.0.0 (Build 100)',
                      onTap: null,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                // Logout button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: ElevatedButton(
                    onPressed: () => _showLogoutDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      minimumSize: Size(double.infinity, 6.h),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'logout',
                          color: theme.colorScheme.onError,
                          size: 5.w,
                        ),
                        SizedBox(width: 2.w),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                // Delete account button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: TextButton(
                    onPressed: () => _showDeleteAccountDialog(context),
                    child: Text(
                      'Delete Account',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _changeProfilePicture(BuildContext context) async {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change Profile Picture',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'camera_alt',
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                );
                if (photo != null) {
                  setState(() => _avatarUrl = photo.path);
                }
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'photo_library',
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                );
                if (photo != null) {
                  setState(() => _avatarUrl = photo.path);
                }
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit profile feature coming soon')));
  }

  void _showChangePassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Change password feature coming soon')),
    );
  }

  void _showEmailPreferences(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Email preferences feature coming soon')),
    );
  }

  void _showRecommendations(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recommendations settings coming soon')),
    );
  }

  void _showCategories(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Category preferences coming soon')));
  }

  void _showDistanceUnits(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Distance Units'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Kilometers'),
              value: 'km',
              groupValue: 'km',
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              title: Text('Miles'),
              value: 'mi',
              groupValue: 'km',
              onChanged: (value) => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpCenter(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Help center feature coming soon')));
  }

  void _showFeedback(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Feedback feature coming soon')));
  }

  void _showSettingsInfo(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Additional settings coming soon')));
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamedAndRemoveUntil('/splash-screen', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone. All your data will be permanently deleted.',
            ),
            SizedBox(height: 2.h),
            Text(
              'Are you sure you want to delete your account?',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Account deletion requires email verification'),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
