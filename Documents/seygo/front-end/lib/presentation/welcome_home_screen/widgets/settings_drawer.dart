import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_localizer.dart';
import '../../../data/services/api_service.dart';
import './appearance_popup.dart';
import './general_settings_popup.dart';
import './help_support_popup.dart';
import './privacy_popup.dart';
import './profile_settings_popup.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  String _displayName = '';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    // Fast: use auth metadata first
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final meta = user.userMetadata ?? {};
      final name = meta['full_name'] as String? ?? user.email ?? '';
      if (mounted) setState(() => _displayName = name);
    }

    // Fetch full profile for avatar + latest name
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final profile = await ApiService.fetchProfile(accessToken: token);
    if (profile != null && mounted) {
      setState(() {
        _displayName = (profile['full_name'] as String?)?.isNotEmpty == true
            ? profile['full_name'] as String
            : _displayName;
        _avatarUrl = profile['avatar_url'] as String?;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/login-page', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final bool darkMode = Theme.of(context).brightness == Brightness.dark;
    final _DrawerPalette colors = _DrawerPalette.forMode(darkMode);
    final t = AppLocalizer.of(context);

    return SizedBox(
      width: 82.w,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0.8.h, 2.w, 0.8.h),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.panelTop, colors.panelBottom],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.34),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Column(
                      children: [
                        _buildHeader(colors, t),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(6.w, 1.2.h, 6.w, 1.6.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(t.t('main'), colors),
                                SizedBox(height: 1.2.h),
                                _buildMenuItem(
                                  colors,
                                  icon: Icons.person_outline_rounded,
                                  title: t.t('profile_settings'),
                                  subtitle: t.t('account_details_identity'),
                                  highlighted: true,
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final saved = await _showSettingsDialog(
                                      context,
                                      barrierLabel: t.t('profile_settings'),
                                      child: const ProfileSettingsPopup(),
                                    );
                                    if (saved == true) _loadUserName();
                                  },
                                ),
                                _buildMenuItem(
                                  colors,
                                  icon: Icons.settings_outlined,
                                  title: t.t('general_settings'),
                                  subtitle: t.t('notifications_preferences'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showSettingsDialog(
                                      context,
                                      barrierLabel: t.t('general_settings'),
                                      child: GeneralSettingsPopup(),
                                    );
                                  },
                                ),
                                _buildMenuItem(
                                  colors,
                                  icon: Icons.security_outlined,
                                  title: t.t('privacy'),
                                  subtitle: t.t('permissions_security'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    PrivacyPopup.show(context);
                                  },
                                ),
                                _buildMenuItem(
                                  colors,
                                  icon: Icons.palette_outlined,
                                  title: t.t('appearance'),
                                  subtitle: t.t('theme_visual_style'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showSettingsDialog(
                                      context,
                                      barrierLabel: t.t('appearance'),
                                      child: AppearancePopup(),
                                    );
                                  },
                                ),
                                _buildMenuItem(
                                  colors,
                                  icon: Icons.help_outline_rounded,
                                  title: t.t('help_support'),
                                  subtitle: t.t('faqs_contact_support'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    HelpSupportPopup.show(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildFooter(colors, context, t),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 9.2.h,
                    right: -4.w,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(100),
                        child: Ink(
                          width: 9.w,
                          height: 9.w,
                          decoration: BoxDecoration(
                            color: colors.floatingChip,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: colors.text.withValues(alpha: 0.72),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(_DrawerPalette colors, AppLocalizer t) {
    return Padding(
      padding: EdgeInsets.fromLTRB(6.3.w, 2.5.h, 6.3.w, 2.1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 1.h),
          Row(
            children: [
              CircleAvatar(
                radius: 6.w,
                backgroundColor: colors.avatarBackground,
                backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                    ? Icon(
                        Icons.person,
                        size: 5.8.w,
                        color: colors.text.withValues(alpha: 0.70),
                      )
                    : null,
              ),
              SizedBox(width: 2.8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEYGO USER',
                      style: TextStyle(
                        fontSize: 11.6.sp,
                        color: colors.mutedText,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.2.h),
                    Text(
                      _displayName.isNotEmpty ? _displayName : t.t('welcome'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.2.sp,
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    _DrawerPalette colors,
    BuildContext context,
    AppLocalizer t,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(5.6.w, 1.2.h, 5.6.w, 2.4.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(4.8.w, 2.4.h, 4.8.w, 2.4.h),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          children: [
            Text(
              t.t('ready_to_customize'),
              style: TextStyle(
                fontSize: 15.8.sp,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              t.t('personalize_experience'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.4.sp,
                height: 1.45,
                color: colors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.8.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(t.t('logout')),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.35.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: TextStyle(
                    fontSize: 13.4.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, _DrawerPalette colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11.6.sp,
        color: colors.mutedText,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildMenuItem(
    _DrawerPalette colors, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.45.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: EdgeInsets.fromLTRB(3.4.w, 1.5.h, 3.4.w, 1.5.h),
            decoration: BoxDecoration(
              color: highlighted
                  ? colors.selectedCard
                  : colors.card.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.cardBorder.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10.2.w,
                  height: 10.2.w,
                  decoration: BoxDecoration(
                    color: colors.avatarBackground.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: colors.text.withValues(alpha: highlighted ? 0.95 : 0.78),
                  ),
                ),
                SizedBox(width: 3.2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                      SizedBox(height: 0.3.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.8.sp,
                          fontWeight: FontWeight.w500,
                          color: colors.text.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: colors.text.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> _showSettingsDialog(
    BuildContext context, {
    required String barrierLabel,
    required Widget child,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black.withValues(alpha: 0.50),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) => child,
      transitionBuilder: (context, anim1, anim2, dialogChild) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: dialogChild),
        );
      },
    );
  }
}

class _DrawerPalette {
  const _DrawerPalette({
    required this.panelTop,
    required this.panelBottom,
    required this.card,
    required this.cardBorder,
    required this.selectedCard,
    required this.text,
    required this.mutedText,
    required this.accent,
    required this.avatarBackground,
    required this.floatingChip,
    required this.shadow,
  });

  final Color panelTop;
  final Color panelBottom;
  final Color card;
  final Color cardBorder;
  final Color selectedCard;
  final Color text;
  final Color mutedText;
  final Color accent;
  final Color avatarBackground;
  final Color floatingChip;
  final Color shadow;

  factory _DrawerPalette.forMode(bool darkMode) {
    if (darkMode) {
      return const _DrawerPalette(
        panelTop: Color(0xFF1E293B),
        panelBottom: Color(0xFF0F172A),
        card: Color(0xFF1F3448),
        cardBorder: Color(0xFF334155),
        selectedCard: Color(0xFF23435C),
        text: Color(0xFFF8FAFC),
        mutedText: Color(0xFF94A3B8),
        accent: Color(0xFF2B84B4),
        avatarBackground: Color(0xFF334155),
        floatingChip: Color(0xFF2A3F53),
        shadow: Color(0xFF000000),
      );
    }
    return const _DrawerPalette(
      panelTop: Color(0xFFF8FAFC),
      panelBottom: Color(0xFFEEF6F7),
      card: Color(0xFFFFFFFF),
      cardBorder: Color(0xFFE2E8F0),
      selectedCard: Color(0xFFEAF4FA),
      text: Color(0xFF0F172A),
      mutedText: Color(0xFF64748B),
      accent: Color(0xFF2B84B4),
      avatarBackground: Color(0xFFEAF4FA),
      floatingChip: Color(0xFFE4F0F8),
      shadow: Color(0x1A0F172A),
    );
  }
}
