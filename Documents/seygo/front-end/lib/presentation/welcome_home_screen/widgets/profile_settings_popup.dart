// lib/presentation/welcome_home_screen/widgets/profile_settings_popup.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ProfileSettingsPopup extends StatefulWidget {
  const ProfileSettingsPopup({super.key});

  @override
  State<ProfileSettingsPopup> createState() => _ProfileSettingsPopupState();
}

class _ProfileSettingsPopupState extends State<ProfileSettingsPopup> {
  final _formKey = GlobalKey<FormState>();

  String _fullName = 'Sarah Johnson';
  String _bio = 'Travel enthusiast exploring Sri Lanka 🌴';
  String _homeCity = 'Colombo, Sri Lanka';
  String _preferredTravelStyle = 'Beach & Culture';

  final List<String> _travelStyles = [
    'Beach & Culture',
    'Adventure & Hiking',
    'Urban Exploration',
    'Nature & Wildlife',
    'Relaxation & Spa',
  ];

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
          // ← Key fix: makes content scrollable
          child: Form(
            key: _formKey,
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
                          Icons.person_outline,
                          size: 26,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          "Profile Settings",
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

                // Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 20.w,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.person,
                          size: 35.w,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.camera_alt_outlined, size: 22),
                            onPressed: () => print("Upload photo"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 3.h),

                Text(
                  "BASIC INFORMATION",
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                SizedBox(height: 2.h),

                TextFormField(
                  initialValue: _fullName,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                  onChanged: (v) => _fullName = v,
                ),

                SizedBox(height: 2.h),

                TextFormField(
                  initialValue: _bio,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Bio",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  onChanged: (v) => _bio = v,
                ),

                SizedBox(height: 2.h),

                TextFormField(
                  initialValue: _homeCity,
                  decoration: InputDecoration(
                    labelText: "Home City",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                  onChanged: (v) => _homeCity = v,
                ),

                SizedBox(height: 2.h),

                DropdownButtonFormField<String>(
                  initialValue: _preferredTravelStyle,
                  decoration: InputDecoration(
                    labelText: "Preferred Travel Style",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _travelStyles.map((style) {
                    return DropdownMenuItem(value: style, child: Text(style));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _preferredTravelStyle = v);
                  },
                ),

                SizedBox(height: 4.h),

                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Profile updated")),
                        );
                      }
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
      ),
    );
  }
}
