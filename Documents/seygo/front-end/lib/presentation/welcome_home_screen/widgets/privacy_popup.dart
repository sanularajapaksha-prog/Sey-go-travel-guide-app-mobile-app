import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const _prefProfileVisibility = 'pref_profile_visibility';
  static const _prefReviewsVisibility = 'pref_reviews_visibility';

  String _profileVisibility = 'public';
  String _reviewsVisibility = 'public';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _profileVisibility =
          prefs.getString(_prefProfileVisibility) ?? 'public';
      _reviewsVisibility =
          prefs.getString(_prefReviewsVisibility) ?? 'public';
      _loading = false;
    });
  }

  Future<void> _savePrefs() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefProfileVisibility, _profileVisibility);
    await prefs.setString(_prefReviewsVisibility, _reviewsVisibility);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Privacy settings updated'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(6.w, 3.h, 6.w, 6.h),
      child: _loading
          ? SizedBox(
              height: 15.h,
              child: const Center(child: CircularProgressIndicator()),
            )
          : Column(
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
                            color:
                                theme.colorScheme.primary.withValues(alpha: 0.1),
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
                          'Privacy',
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
                  'Who can see your profile',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                RadioListTile<String>(
                  value: 'public',
                  groupValue: _profileVisibility,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Public — Anyone can see'),
                  activeColor: theme.colorScheme.primary,
                  onChanged: (v) {
                    if (v != null) setState(() => _profileVisibility = v);
                  },
                ),
                RadioListTile<String>(
                  value: 'private',
                  groupValue: _profileVisibility,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Private — Only me'),
                  activeColor: theme.colorScheme.primary,
                  onChanged: (v) {
                    if (v != null) setState(() => _profileVisibility = v);
                  },
                ),

                SizedBox(height: 3.h),

                // Who can see your reviews
                Text(
                  'Who can see your reviews',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                RadioListTile<String>(
                  value: 'public',
                  groupValue: _reviewsVisibility,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Public — Anyone can see'),
                  activeColor: theme.colorScheme.primary,
                  onChanged: (v) {
                    if (v != null) setState(() => _reviewsVisibility = v);
                  },
                ),
                RadioListTile<String>(
                  value: 'private',
                  groupValue: _reviewsVisibility,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Private — Only me'),
                  activeColor: theme.colorScheme.primary,
                  onChanged: (v) {
                    if (v != null) setState(() => _reviewsVisibility = v);
                  },
                ),

                SizedBox(height: 4.h),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  height: 6.5.h,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _savePrefs,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
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
    );
  }
}
