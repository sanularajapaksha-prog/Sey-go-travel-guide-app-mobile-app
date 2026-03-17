import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../providers/font_scale_provider.dart';
import '../../../providers/theme_provider.dart';

class AppearancePopup extends StatefulWidget {
  const AppearancePopup({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AppearancePopup(),
    );
  }

  @override
  State<AppearancePopup> createState() => _AppearancePopupState();
}

class _AppearancePopupState extends State<AppearancePopup> {
  String _theme = 'System Default';
  String _fontSize = 'Medium (Default)';

  static const _themeOptions = ['Light mode', 'Dark mode', 'System Default'];
  static const _fontOptions = ['Large', 'Medium (Default)', 'Small'];

  @override
  void initState() {
    super.initState();
    final themeProv = Provider.of<ThemeProvider>(context, listen: false);
    final fontProv = Provider.of<FontScaleProvider>(context, listen: false);
    _theme = _themeModeToLabel(themeProv.themeMode);
    _fontSize = fontProv.currentLabel;
  }

  String _themeModeToLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light mode',
        ThemeMode.dark => 'Dark mode',
        _ => 'System Default',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Padding(
        padding: EdgeInsets.fromLTRB(5.w, 2.5.h, 5.w, 4.h),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.palette_outlined,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Appearance',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20.sp,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 26,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            SizedBox(height: 2.5.h),
            Divider(height: 1, color: theme.dividerColor),
            SizedBox(height: 3.h),

            // Theme section
            Text(
              'Theme',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            ..._themeOptions.map(
              (opt) => RadioListTile<String>(
                value: opt,
                groupValue: _theme,
                title: Text(opt),
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.colorScheme.primary,
                controlAffinity: ListTileControlAffinity.trailing,
                onChanged: (v) {
                  if (v != null) setState(() => _theme = v);
                },
              ),
            ),

            SizedBox(height: 3.h),

            // Font Size section
            Text(
              'Font Size',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            ..._fontOptions.map(
              (opt) => RadioListTile<String>(
                value: opt,
                groupValue: _fontSize,
                title: Text(opt),
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.colorScheme.primary,
                controlAffinity: ListTileControlAffinity.trailing,
                onChanged: (v) {
                  if (v != null) setState(() => _fontSize = v);
                },
              ),
            ),

            SizedBox(height: 4.h),

            // Apply button
            SizedBox(
              width: double.infinity,
              height: 6.5.h,
              child: ElevatedButton(
                onPressed: () {
                  final themeProv =
                      Provider.of<ThemeProvider>(context, listen: false);
                  final fontProv =
                      Provider.of<FontScaleProvider>(context, listen: false);

                  themeProv.setThemeMode(switch (_theme) {
                    'Light mode' => ThemeMode.light,
                    'Dark mode' => ThemeMode.dark,
                    _ => ThemeMode.system,
                  });

                  fontProv.setScaleFromLabel(_fontSize);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Appearance updated'),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Apply',
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
    );
  }
}
