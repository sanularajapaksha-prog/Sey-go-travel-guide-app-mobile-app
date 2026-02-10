// lib/presentation/welcome_home_screen/widgets/appearance_popup.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../providers/theme_provider.dart'; // from lib/providers/
import '../../../providers/font_scale_provider.dart'; // from lib/providers/

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
  String _theme = "System Default";
  String _fontSize = "Medium (Default)";

  @override
  void initState() {
    super.initState();
    final themeProv = Provider.of<ThemeProvider>(context, listen: false);
    final fontProv = Provider.of<FontScaleProvider>(context, listen: false);

    _theme = _themeModeToString(themeProv.themeMode);
    _fontSize = fontProv.currentLabel;
  }

  String _themeModeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => "Light mode",
      ThemeMode.dark => "Dark mode",
      _ => "System Default",
    };
  }

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
            // Header - matches your screenshot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.palette_outlined,
                        color: Color(0xFF2DD4BF),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      "Appearance",
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

            // Theme
            Text(
              "Theme",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.5.h),

            _buildRadio("Light mode", _theme == "Light mode", (v) {
              if (v == true) setState(() => _theme = "Light mode");
            }),
            _buildRadio("Dark mode", _theme == "Dark mode", (v) {
              if (v == true) setState(() => _theme = "Dark mode");
            }),
            _buildRadio("System Default", _theme == "System Default", (v) {
              if (v == true) setState(() => _theme = "System Default");
            }),
            _buildRadio("Custom", _theme == "Custom", (v) {
              if (v == true) setState(() => _theme = "Custom");
            }),

            SizedBox(height: 4.h),

            // Font Size
            Text(
              "Font Size",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.5.h),

            _buildRadio("Large", _fontSize == "Large", (v) {
              if (v == true) setState(() => _fontSize = "Large");
            }),
            _buildRadio("Medium (Default)", _fontSize == "Medium (Default)", (
              v,
            ) {
              if (v == true) setState(() => _fontSize = "Medium (Default)");
            }),
            _buildRadio("Small", _fontSize == "Small", (v) {
              if (v == true) setState(() => _fontSize = "Small");
            }),

            SizedBox(height: 5.h),

            // Apply button - teal color from your palette
            SizedBox(
              width: double.infinity,
              height: 6.5.h,
              child: ElevatedButton(
                onPressed: () {
                  final themeProv = Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  );
                  final fontProv = Provider.of<FontScaleProvider>(
                    context,
                    listen: false,
                  );

                  // Apply theme
                  final newMode = switch (_theme) {
                    "Light mode" => ThemeMode.light,
                    "Dark mode" => ThemeMode.dark,
                    _ => ThemeMode.system,
                  };
                  themeProv.setThemeMode(newMode);

                  // Apply font size
                  fontProv.setScaleFromLabel(_fontSize);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Appearance updated"),
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
    );
  }

  Widget _buildRadio(
    String label,
    bool selected,
    ValueChanged<bool?> onChanged,
  ) {
    return RadioListTile<String>(
      value: label,
      groupValue: label.contains("mode") || label == "Custom"
          ? _theme
          : _fontSize,
      onChanged: (value) {
        onChanged(value != null);
      },
      title: Text(label),
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: Theme.of(context).colorScheme.primary,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
