// lib/presentation/welcome_home_screen/widgets/appearance_popup.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AppearancePopup extends StatefulWidget {
  const AppearancePopup({super.key});

  @override
  State<AppearancePopup> createState() => _AppearancePopupState();
}

class _AppearancePopupState extends State<AppearancePopup> {
  String _themeMode =
      'Light mode'; // Light mode, Dark mode, System Default, Custom
  String _fontSize = 'Large'; // Large, Medium, Small

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      backgroundColor: theme.scaffoldBackgroundColor,
      insetPadding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Padding(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 26,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      "Appearance",
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

            SizedBox(height: 1.5.h),
            const Divider(height: 1),

            SizedBox(height: 2.5.h),

            // Theme section
            Text(
              "Theme",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.2.h),

            _buildRadio("Light mode", _themeMode == "Light mode", (v) {
              if (v == true) setState(() => _themeMode = "Light mode");
            }),
            _buildRadio("Dark mode", _themeMode == "Dark mode", (v) {
              if (v == true) setState(() => _themeMode = "Dark mode");
            }),
            _buildRadio("System Default", _themeMode == "System Default", (v) {
              if (v == true) setState(() => _themeMode = "System Default");
            }),
            _buildRadio("Custom", _themeMode == "Custom", (v) {
              if (v == true) setState(() => _themeMode = "Custom");
            }),

            SizedBox(height: 3.h),

            // Font Size section
            Text(
              "Font Size",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.2.h),

            _buildRadio("Large", _fontSize == "Large", (v) {
              if (v == true) setState(() => _fontSize = "Large");
            }),
            _buildRadio("Medium (Default)", _fontSize == "Medium", (v) {
              if (v == true) setState(() => _fontSize = "Medium");
            }),
            _buildRadio("Small", _fontSize == "Small", (v) {
              if (v == true) setState(() => _fontSize = "Small");
            }),

            SizedBox(height: 4.h),

            // Apply button
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Save & apply theme/font changes (use Provider / ThemeMode / TextScaler)
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Appearance updated")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
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
      groupValue: label.contains("mode") ? _themeMode : _fontSize,
      onChanged: (value) {
        onChanged(value != null);
      },
      title: Text(label, style: const TextStyle(fontSize: 15)),
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}
