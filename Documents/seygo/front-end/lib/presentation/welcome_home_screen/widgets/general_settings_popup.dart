// lib/presentation/welcome_home_screen/widgets/general_settings_popup.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class GeneralSettingsPopup extends StatefulWidget {
  const GeneralSettingsPopup({super.key});

  @override
  State<GeneralSettingsPopup> createState() => _GeneralSettingsPopupState();
}

class _GeneralSettingsPopupState extends State<GeneralSettingsPopup> {
  // Current values (you can later load from shared_preferences / provider)
  String _language = 'English (Sri Lanka)';
  String _countryRegion = 'Sri Lanka';
  String _timeZone = 'Asia/Colombo (GMT+05:30)';
  String _notificationPref = 'Unmute'; // Unmute or Mute
  String _units = 'Kilometres / Metres';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      backgroundColor: theme.scaffoldBackgroundColor,
      insetPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Padding(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 26,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        "General Settings",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              SizedBox(height: 2.h),
              const Divider(height: 1),
              SizedBox(height: 2.5.h),

              // Language
              ListTile(
                title: const Text("Language"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_language, style: theme.textTheme.bodyMedium),
                    SizedBox(width: 1.w),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                onTap: () {
                  // TODO: Open language picker
                },
              ),

              // Country / Region
              ListTile(
                title: const Text("Country / Region"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_countryRegion, style: theme.textTheme.bodyMedium),
                    SizedBox(width: 1.w),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                onTap: () {
                  // TODO: Open country picker
                },
              ),

              // Time Zone
              ListTile(
                title: const Text("Time Zone"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_timeZone, style: theme.textTheme.bodyMedium),
                    SizedBox(width: 1.w),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                onTap: () {
                  // TODO: Open timezone picker
                },
              ),

              SizedBox(height: 2.5.h),

              Text(
                "NOTIFICATION PREFERENCES",
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              SizedBox(height: 1.5.h),

              RadioListTile<String>(
                value: 'Unmute',
                groupValue: _notificationPref,
                title: const Text("Unmute (Receive all notifications)"),
                onChanged: (value) {
                  if (value != null) setState(() => _notificationPref = value);
                },
                dense: true,
                activeColor: theme.colorScheme.primary,
              ),

              RadioListTile<String>(
                value: 'Mute',
                groupValue: _notificationPref,
                title: const Text("Mute (Turn off all notifications)"),
                onChanged: (value) {
                  if (value != null) setState(() => _notificationPref = value);
                },
                dense: true,
                activeColor: theme.colorScheme.primary,
              ),

              SizedBox(height: 2.5.h),

              // Units
              ListTile(
                title: const Text("Units"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_units, style: theme.textTheme.bodyMedium),
                    SizedBox(width: 1.w),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                onTap: () {
                  // TODO: Open units picker (km/miles, etc.)
                },
              ),

              SizedBox(height: 4.h),

              // Apply button
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Save settings (shared_preferences / provider)
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("General settings updated")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Apply",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
