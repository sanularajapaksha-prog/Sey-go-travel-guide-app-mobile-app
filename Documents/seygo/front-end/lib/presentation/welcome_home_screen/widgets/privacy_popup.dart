// lib/widgets/privacy_popup.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PrivacyPopup extends StatefulWidget {
  const PrivacyPopup({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PrivacyPopup(),
    );
  }

  @override
  State<PrivacyPopup> createState() => _PrivacyPopupState();
}

class _PrivacyPopupState extends State<PrivacyPopup> {
  String profileVisibility = 'public'; // 'public' or 'private'
  String reviewsVisibility = 'public'; // 'public' or 'private'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(6.w, 3.h, 6.w, 6.h),
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
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    "Privacy",
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
          const Divider(height: 1),
          SizedBox(height: 3.h),

          // Who can see your profile
          Text(
            "Who can see your profile",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.5.h),

          RadioGroup<String>(
            groupValue: profileVisibility,
            onChanged: (value) {
              if (value == null) return;
              setState(() => profileVisibility = value);
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'public',
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Public - Anyone can see"),
                  activeColor: theme.colorScheme.primary,
                ),
                RadioListTile<String>(
                  value: 'private',
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Private - Only me"),
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // Who can see your reviews
          Text(
            "Who can see your reviews",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.5.h),

          RadioGroup<String>(
            groupValue: reviewsVisibility,
            onChanged: (value) {
              if (value == null) return;
              setState(() => reviewsVisibility = value);
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'public',
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Public - Anyone can see"),
                  activeColor: theme.colorScheme.primary,
                ),
                RadioListTile<String>(
                  value: 'private',
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Private - Only me"),
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),

          SizedBox(height: 5.h),

          // Apply button (same style as Appearance)
          SizedBox(
            width: double.infinity,
            height: 6.5.h,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Save to backend / local storage / provider
                debugPrint(
                  "Privacy saved → Profile: $profileVisibility, Reviews: $reviewsVisibility",
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Privacy settings updated"),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Apply",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
