import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_localizer.dart';
import '../../../providers/locale_provider.dart';

class GeneralSettingsPopup extends StatefulWidget {
  const GeneralSettingsPopup({super.key});

  @override
  State<GeneralSettingsPopup> createState() => _GeneralSettingsPopupState();
}

class _GeneralSettingsPopupState extends State<GeneralSettingsPopup> {
  static const _prefLanguage = 'pref_language';
  static const _prefCountry = 'pref_country';
  static const _prefTimezone = 'pref_timezone';
  static const _prefNotifications = 'pref_notifications';
  static const _prefUnits = 'pref_units';

  String _language = 'English (Sri Lanka)';
  String _country = 'Sri Lanka';
  String _timezone = 'Asia/Colombo (GMT+05:30)';
  String _notificationPref = 'Unmute';
  String _units = 'Kilometres / Metres';
  bool _loading = true;
  bool _saving = false;

  static const _languages = [
    'English (Sri Lanka)',
    'English (US)',
    'Sinhala',
    'Tamil',
  ];

  static const _countries = [
    'Sri Lanka',
    'India',
    'Maldives',
    'United Kingdom',
    'United States',
    'Australia',
  ];

  static const _timezones = [
    'Asia/Colombo (GMT+05:30)',
    'Asia/Kolkata (GMT+05:30)',
    'Asia/Dubai (GMT+04:00)',
    'Europe/London (GMT+00:00)',
    'America/New_York (GMT-05:00)',
    'Australia/Sydney (GMT+11:00)',
  ];

  static const _unitOptions = [
    'Kilometres / Metres',
    'Miles / Feet',
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _language = prefs.getString(_prefLanguage) ?? _language;
      _country = prefs.getString(_prefCountry) ?? _country;
      _timezone = prefs.getString(_prefTimezone) ?? _timezone;
      _notificationPref = prefs.getString(_prefNotifications) ?? _notificationPref;
      _units = prefs.getString(_prefUnits) ?? _units;
      _loading = false;
    });
  }

  Future<void> _savePrefs() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCountry, _country);
    await prefs.setString(_prefTimezone, _timezone);
    await prefs.setString(_prefNotifications, _notificationPref);
    await prefs.setString(_prefUnits, _units);
    await context.read<LocaleProvider>().setLanguage(_language);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizer.of(context).t('settings_saved')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showPicker({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 1.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10.w,
                height: 0.5.h,
                margin: EdgeInsets.only(bottom: 1.5.h),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 1.h),
              ...options.map(
                (opt) => ListTile(
                  title: Text(opt),
                  trailing: opt == current
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => onSelected(opt));
                  },
                ),
              ),
              SizedBox(height: 1.h),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizer.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      backgroundColor: theme.scaffoldBackgroundColor,
      insetPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Padding(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        child: _loading
            ? SizedBox(
                height: 15.h,
                child: const Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
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
                              t.t('general_settings'),
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
                    SizedBox(height: 2.h),

                    _buildPickerTile(
                      theme,
                      label: t.t('language'),
                      value: _language,
                      onTap: () => _showPicker(
                        title: t.t('select_language'),
                        options: _languages,
                        current: _language,
                        onSelected: (v) => _language = v,
                      ),
                    ),

                    _buildPickerTile(
                      theme,
                      label: t.t('country_region'),
                      value: _country,
                      onTap: () => _showPicker(
                        title: t.t('select_country'),
                        options: _countries,
                        current: _country,
                        onSelected: (v) => _country = v,
                      ),
                    ),

                    _buildPickerTile(
                      theme,
                      label: t.t('time_zone'),
                      value: _timezone,
                      onTap: () => _showPicker(
                        title: t.t('select_time_zone'),
                        options: _timezones,
                        current: _timezone,
                        onSelected: (v) => _timezone = v,
                      ),
                    ),

                    SizedBox(height: 2.h),

                    Text(
                      t.t('notification_preferences'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    SizedBox(height: 1.h),

                    RadioListTile<String>(
                      value: 'Unmute',
                      groupValue: _notificationPref,
                      title: Text(t.t('unmute_notifications')),
                      onChanged: (v) {
                        if (v != null) setState(() => _notificationPref = v);
                      },
                      dense: true,
                      activeColor: theme.colorScheme.primary,
                    ),

                    RadioListTile<String>(
                      value: 'Mute',
                      groupValue: _notificationPref,
                      title: Text(t.t('mute_notifications')),
                      onChanged: (v) {
                        if (v != null) setState(() => _notificationPref = v);
                      },
                      dense: true,
                      activeColor: theme.colorScheme.primary,
                    ),

                    SizedBox(height: 2.h),

                    _buildPickerTile(
                      theme,
                      label: t.t('units'),
                      value: _units,
                      onTap: () => _showPicker(
                        title: t.t('select_units'),
                        options: _unitOptions,
                        current: _units,
                        onSelected: (v) => _units = v,
                      ),
                    ),

                    SizedBox(height: 3.h),

                    SizedBox(
                      width: double.infinity,
                      height: 6.h,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _savePrefs,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                t.t('apply'),
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

  Widget _buildPickerTile(
    ThemeData theme, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 1.w),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}
