// lib/widgets/settings_drawer.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import './appearance_popup.dart';
import './profile_settings_popup.dart';
import './general_settings_popup.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      elevation: 16,
      width: 80.w,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Settings",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
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

            const Divider(height: 1),

            // Settings items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                children: [
                  _buildItem(
                    context,
                    icon: Icons.person_outline,
                    title: "Profile Settings",
                    onTap: () {
                      Navigator.pop(context); // close drawer

                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: "Profile Settings",
                        barrierColor: Colors.black.withOpacity(0.5),
                        transitionDuration: const Duration(milliseconds: 400),
                        pageBuilder: (context, anim1, anim2) {
                          return ProfileSettingsPopup();
                        },
                        transitionBuilder: (context, anim1, anim2, child) {
                          return ScaleTransition(
                            scale: CurvedAnimation(
                              parent: anim1,
                              curve: Curves
                                  .easeOutBack, // scale from center with slight overshoot
                            ),
                            child: FadeTransition(opacity: anim1, child: child),
                          );
                        },
                      );
                    },
                  ),
                  _buildItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: "General Settings",
                    onTap: () {
                      Navigator.pop(context); // close drawer

                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: "General Settings",
                        barrierColor: Colors.black.withOpacity(0.5),
                        transitionDuration: const Duration(milliseconds: 400),
                        pageBuilder: (context, anim1, anim2) {
                          return GeneralSettingsPopup();
                        },
                        transitionBuilder: (context, anim1, anim2, child) {
                          return ScaleTransition(
                            scale: CurvedAnimation(
                              parent: anim1,
                              curve: Curves.easeOutBack,
                            ),
                            child: FadeTransition(opacity: anim1, child: child),
                          );
                        },
                      );
                    },
                  ),
                  _buildItem(
                    context,
                    icon: Icons.security_outlined,
                    title: "Privacy",
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildItem(
                    context,
                    icon: Icons.palette_outlined,
                    title: "Appearance",
                    onTap: () {
                      Navigator.pop(context); // close drawer

                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: "Appearance",
                        barrierColor: Colors.black.withOpacity(0.5),
                        transitionDuration: const Duration(milliseconds: 400),
                        pageBuilder: (context, anim1, anim2) {
                          return AppearancePopup();
                        },
                        transitionBuilder: (context, anim1, anim2, child) {
                          return ScaleTransition(
                            scale: CurvedAnimation(
                              parent: anim1,
                              curve: Curves
                                  .easeOutBack, // nice overshoot animation
                            ),
                            child: FadeTransition(opacity: anim1, child: child),
                          );
                        },
                      );
                    },
                  ),
                  _buildItem(
                    context,
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // User profile & logout
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10.w,
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.12,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 18.w,
                          color: theme.colorScheme.primary,
                        ),
                        // If you have real photo later:
                        // backgroundImage: NetworkImage('https://...'),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sarah Johnson",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 0.2.h),
                            Text(
                              "sarahjohnson@email.com",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.5.h),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: real logout logic
                      // Example: await authService.signOut();
                      // Navigator.pushReplacementNamed(context, '/login');
                      print("Logout tapped");
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: theme.colorScheme.error,
                            size: 22,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            "Logout",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 26),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.4.h),
      minLeadingWidth: 6.w,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
