import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/api_service.dart';
import '../../providers/user_data_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import 'profile_modals.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── profile fields ─────────────────────────────────────────────────────────
  String _avatarPath = '';
  String _bannerUrl = '';
  String _displayName = '';
  String _email = '';
  String _homeCity = '';
  String _bio = '';
  String _aiDescription = '';
  String _travelStyle = '';
  String _travelPersonalityType = '';

  // ── loading flags ──────────────────────────────────────────────────────────
  bool _profileLoading = true;
  bool _playlistsLoading = true;
  bool _statsLoading = true;
  bool _avatarUploading = false;
  bool _bannerUploading = false;
  bool _initialized = false;

  // ── data ───────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _userPlaylists = [];
  Map<String, dynamic> _stats = {
    'playlists': 0,
    'places': 0,
    'reviews': 0,
    'photos': 0,
  };


  bool _isSideRailVisible = false;

  // ── theme ──────────────────────────────────────────────────────────────────
  static const Color _ink       = Color(0xFF0A0828);
  static const Color _accent    = AppTheme.secondaryLight;
  static const Color _border    = AppTheme.dividerLight;
  static const Color _text      = AppTheme.tertiaryLight;
  static const Color _mutedText = AppTheme.neutralLight;
  static const Color _chipFill  = Color(0xFFEAF4FA);



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _seedFromCache();
      _loadAll();
    }
  }

  // ── cache seed ─────────────────────────────────────────────────────────────
  void _seedFromCache() {
    final udp = Provider.of<UserDataProvider>(context, listen: false);
    final profile = udp.profile;
    if (profile != null) {
      _applyProfile(profile);
      _profileLoading = false;
    }
    if (udp.myPlaylistsLoaded) {
      _userPlaylists = udp.myPlaylists;
      _playlistsLoading = false;
    }
    if (udp.statsLoaded) {
      _stats = udp.stats;
      _statsLoading = false;
    }
  }

  void _applyProfile(Map<String, dynamic> profile) {
    _displayName = (profile['full_name'] as String?)?.isNotEmpty == true
        ? profile['full_name'] as String
        : (profile['email'] as String? ?? '');
    _email      = profile['email']       as String? ?? '';
    _homeCity   = profile['home_city']   as String? ?? '';
    _bio        = profile['bio']         as String? ?? '';
    _aiDescription         = profile['ai_description']          as String? ?? '';
    _travelStyle           = profile['travel_style']            as String? ?? '';
    _travelPersonalityType = profile['travel_personality_type'] as String? ?? '';
    final av = profile['avatar_url'] as String?;
    if (av != null && av.isNotEmpty) _avatarPath = av;
    final bn = profile['banner_url'] as String?;
    if (bn != null && bn.isNotEmpty) _bannerUrl = bn;
  }

  // ── load all ───────────────────────────────────────────────────────────────
  Future<void> _loadAll() async {
    await Future.wait([_loadProfile(), _loadPlaylists(), _loadStats()]);
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && mounted) {
      final meta = user.userMetadata ?? {};
      setState(() {
        _displayName = meta['full_name'] as String? ?? user.email ?? '';
        _email = user.email ?? '';
      });
    }
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final profile = await ApiService.fetchProfile(
      accessToken: token,
      forceRefresh: true,
    );
    if (!mounted) return;
    setState(() {
      if (profile != null) _applyProfile(profile);
      _profileLoading = false;
    });
  }

  Future<void> _loadPlaylists() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final data = await ApiService.fetchMyPlaylists(accessToken: token);
    if (!mounted) return;
    setState(() {
      _userPlaylists = data;
      _playlistsLoading = false;
    });
  }

  Future<void> _loadStats() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final data = await ApiService.fetchUserStats(accessToken: token);
    if (!mounted) return;
    setState(() {
      _stats = data;
      _statsLoading = false;
    });
  }



  // ── avatar upload ──────────────────────────────────────────────────────────
  Future<void> _pickAndUploadAvatar() async {
    showAvatarPicker(context, (path) async {
      setState(() {
        _avatarPath = path;
        _avatarUploading = true;
      });

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _avatarUploading = false);
        return;
      }

      final ext = path.split('.').last.toLowerCase();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'avatars/${userId}_$ts.$ext';
      String? publicUrl;
      String? errorMsg;
      try {
        await supabase.storage.from('profiles').upload(
              storagePath,
              File(path),
              fileOptions: const FileOptions(upsert: true),
            );
        publicUrl =
            supabase.storage.from('profiles').getPublicUrl(storagePath);
      } catch (e) {
        errorMsg = e.toString();
        if (kDebugMode) debugPrint('Avatar upload error: $e');
      }

      if (!mounted) return;

      if (publicUrl != null && publicUrl.isNotEmpty) {
        try {
          final token = supabase.auth.currentSession?.accessToken;
          await ApiService.updateProfile(
              avatarUrl: publicUrl, accessToken: token);
          ApiService.invalidateProfileCache();
          if (mounted) setState(() => _avatarPath = publicUrl!);
        } catch (e) {
          errorMsg = 'Profile update failed: $e';
          if (kDebugMode) debugPrint('Profile update error: $e');
        }
      }

      if (publicUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg ?? 'Failed to upload photo. Please try again.'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      if (mounted) setState(() => _avatarUploading = false);
    });
  }

  // ── banner upload ──────────────────────────────────────────────────────────
  Future<void> _pickAndUploadBanner() async {
    showAvatarPicker(context, (path) async {
      setState(() => _bannerUploading = true);

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _bannerUploading = false);
        return;
      }

      final ext = path.split('.').last.toLowerCase();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'banners/${userId}_$ts.$ext';
      String? publicUrl;
      String? errorMsg;
      try {
        await supabase.storage.from('profiles').upload(
              storagePath,
              File(path),
              fileOptions: const FileOptions(upsert: true),
            );
        publicUrl =
            supabase.storage.from('profiles').getPublicUrl(storagePath);
      } catch (e) {
        errorMsg = e.toString();
        if (kDebugMode) debugPrint('Banner upload error: $e');
      }

      if (!mounted) return;

      if (publicUrl != null && publicUrl.isNotEmpty) {
        try {
          await supabase
              .from('profiles')
              .update({'banner_url': publicUrl}).eq('id', userId);
          ApiService.invalidateProfileCache();
          if (mounted) setState(() => _bannerUrl = publicUrl!);
        } catch (e) {
          errorMsg = 'Profile update failed: $e';
          if (kDebugMode) debugPrint('Banner profile update error: $e');
        }
      }

      if (publicUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg ?? 'Failed to upload banner. Please try again.'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      if (mounted) setState(() => _bannerUploading = false);
    });
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  String get _effectiveBio {
    if (_bio.isNotEmpty) return _bio;
    if (_aiDescription.isNotEmpty) return _aiDescription;
    if (_travelPersonalityType.isNotEmpty) {
      return 'A passionate $_travelPersonalityType exploring the wonders of Sri Lanka.';
    }
    if (_travelStyle.isNotEmpty) {
      return 'Passionate traveller with a love for ${_travelStyle.toLowerCase()}.';
    }
    return 'Explorer of Sri Lanka\'s hidden gems and vibrant culture.';
  }



  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── scrollable content ───────────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Light App Bar ────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 0.5,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.menu, color: _text),
                  onPressed: () => setState(() => _isSideRailVisible = true),
                ),
                centerTitle: true,
                title: Text(
                  'SeyGo',
                  style: TextStyle(
                    color: _text,
                    fontSize: isCompact ? 17.sp : 18.sp,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: _text),
                    onPressed: () {},
                  ),
                ],
              ),

              // ── Content ─────────────────────────────────────────────────
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 4.w : 5.w,
                  2.h,
                  isCompact ? 4.w : 5.w,
                  14.h,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ① Profile row: name left, avatar right
                    _buildProfileRow(isCompact),
                    SizedBox(height: 2.h),

                    // ② Personality chip card (blue)
                    _buildPersonalityCard(isCompact),
                    SizedBox(height: 2.h),

                    // ③ Activity chips (Camping, Mountains, Beachside)
                    _buildActivityChips(isCompact),
                    SizedBox(height: 2.h),

                    // ④ Activity Summary stats
                    _buildActivitySummarySection(isCompact),
                    SizedBox(height: 3.h),

                    // ⑤ Your Tracks (horizontal scroll)
                    _buildYourTracksSection(isCompact),
                    SizedBox(height: 2.h),
                  ]),
                ),
              ),
            ],
          ),

          // ── Side rail (quick actions) ────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: isCompact ? 15.h : 13.h,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              offset:
                  _isSideRailVisible ? Offset.zero : const Offset(0, 1.15),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: isCompact ? 4.w : 5.w),
                  child: _buildSideRail(isCompact),
                ),
              ),
            ),
          ),

          // ── Floating action buttons ──────────────────────────────────────
          Positioned(
            left: isCompact ? 4.w : 5.w,
            right: isCompact ? 4.w : 5.w,
            bottom: isCompact ? 7.h : 6.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dark circle (assistive touch)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _isSideRailVisible ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: _isSideRailVisible,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _isSideRailVisible = true),
                      child: Container(
                        width: isCompact ? 12.w : 10.w,
                        height: isCompact ? 12.w : 10.w,
                        decoration: BoxDecoration(
                          color: _ink.withOpacity(0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 14,
                                offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Icon(Icons.more_horiz_rounded,
                            color: Colors.white,
                            size: isCompact ? 5.4.w : 4.6.w),
                      ),
                    ),
                  ),
                ),

                // ⊕ Profile button
                GestureDetector(
                  onTap: () => _showSettingsSheet(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 4.w : 5.w,
                      vertical: isCompact ? 1.2.h : 1.4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _ink,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isCompact ? 12.sp : 13.sp,
                            fontWeight: FontWeight.w700,
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ① Profile Row — name (left) + avatar (right)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProfileRow(bool isCompact) {
    final ImageProvider? avatarImage = _avatarPath.isEmpty
        ? null
        : _avatarPath.startsWith('http')
            ? NetworkImage(_avatarPath)
            : FileImage(File(_avatarPath));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Name / subtitle / bio ──────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName.isNotEmpty ? _displayName : 'Traveller',
                style: TextStyle(
                  fontSize: isCompact ? 20.sp : 24.sp,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                _homeCity.isNotEmpty
                    ? '📍 $_homeCity'
                    : (_email.isNotEmpty ? _email : '📍 Sri Lanka'),
                style: TextStyle(
                  fontSize: isCompact ? 11.sp : 12.sp,
                  color: _mutedText,
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: 3.w),

        // ── Avatar + Photo button ──────────────────────────────────────────
        Column(
          children: [
            GestureDetector(
              onTap: _pickAndUploadAvatar,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: isCompact ? 22.w : 24.w,
                    height: isCompact ? 22.w : 24.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _border, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: isCompact ? 9.w : 10.w,
                      backgroundColor: _accent.withOpacity(0.7),
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Icon(Icons.person_rounded,
                              color: Colors.white,
                              size: isCompact ? 10.w : 12.w)
                          : null,
                    ),
                  ),
                  if (_avatarUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                      ),
                    ),
                  // Camera badge
                  Positioned(
                    right: -1.w,
                    bottom: 2.w,
                    child: Container(
                      width: isCompact ? 7.w : 7.5.w,
                      height: isCompact ? 7.w : 7.5.w,
                      decoration: BoxDecoration(
                        color: _chipFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(Icons.camera_alt_rounded,
                          size: isCompact ? 3.5.w : 4.w, color: _accent),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 0.8.h),
            // "Photo" button
            GestureDetector(
              onTap: _pickAndUploadAvatar,
              child: Text(
                'Photo',
                style: TextStyle(
                  fontSize: isCompact ? 10.sp : 11.sp,
                  color: _mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  // ═══════════════════════════════════════════════════════════════════════════
  //  ② Personality Card (blue chip card)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPersonalityCard(bool isCompact) {
    final label = _travelPersonalityType.isNotEmpty
        ? _travelPersonalityType
        : 'Mountain Explorer';
    final desc = _effectiveBio;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 3.5.w : 4.w,
        vertical: isCompact ? 1.5.h : 1.8.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2F7BF2).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2F7BF2).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terrain_rounded,
                  size: isCompact ? 4.5.w : 5.w,
                  color: const Color(0xFF2F7BF2)),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isCompact ? 13.sp : 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.6.h),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCompact ? 11.sp : 12.sp,
              color: _mutedText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ③ Activity Chips
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildActivityChips(bool isCompact) {
    final chips = <String>['Camping', 'Mountains', 'Beachside'];
    if (_travelStyle.isNotEmpty && !chips.contains(_travelStyle)) {
      chips[0] = _travelStyle.split(' ').first;
    }
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: chips.map((label) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 3.5.w : 4.w,
            vertical: isCompact ? 0.7.h : 0.85.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 11.sp : 12.sp,
              color: _text,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ④ Activity Summary
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildActivitySummarySection(bool isCompact) {
    final playlists = (_stats['playlists'] as num?)?.toInt() ?? 0;
    final places    = (_stats['places']    as num?)?.toInt() ?? 0;
    final reviews   = (_stats['reviews']   as num?)?.toInt() ?? 0;
    final photos    = (_stats['photos']    as num?)?.toInt() ?? 0;
    final trips     = playlists;
    final kmExplored = places * 3;
    final daysActive = reviews + playlists;

    final items = [
      ('Trips',  '$trips'),
      ('Km',     '$kmExplored'),
      ('Days',   '$daysActive'),
      ('Photos', '$photos'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Summary',
          style: TextStyle(
            fontSize: isCompact ? 14.sp : 16.sp,
            fontWeight: FontWeight.w700,
            color: _text,
          ),
        ),
        SizedBox(height: 1.5.h),
        Container(
          padding: EdgeInsets.symmetric(
              vertical: isCompact ? 1.8.h : 2.2.h, horizontal: 2.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: _statsLoading
              ? const Center(
                  child: SizedBox(
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : Row(
                  children: items.map((item) {
                    return Expanded(
                      child: Column(
                        children: [
                          Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: isCompact ? 18.sp : 22.sp,
                              fontWeight: FontWeight.w800,
                              color: _text,
                            ),
                          ),
                          SizedBox(height: 0.3.h),
                          Text(
                            item.$1,
                            style: TextStyle(
                              fontSize: isCompact ? 10.sp : 11.sp,
                              color: _mutedText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ⑤ Your Tracks (horizontal scroll playlist cards)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildYourTracksSection(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Tracks',
          style: TextStyle(
            fontSize: isCompact ? 14.sp : 16.sp,
            fontWeight: FontWeight.w700,
            color: _text,
          ),
        ),
        SizedBox(height: 1.5.h),
        if (_playlistsLoading)
          const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_userPlaylists.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 3.h),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Icon(Icons.playlist_play,
                    size: 10.w, color: _mutedText.withOpacity(0.3)),
                SizedBox(height: 1.h),
                Text(
                  'No tracks yet.\nCreate one in the Playlists tab.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isCompact ? 12.sp : 13.sp,
                    color: _mutedText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: isCompact ? 16.h : 18.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _userPlaylists.length,
              separatorBuilder: (context, index) => SizedBox(width: 3.w),
              itemBuilder: (context, index) {
                final playlist = _userPlaylists[index];
                final title = playlist['name'] as String? ?? 'Playlist';
                final images = playlist['previewImages'] as List?;
                final imageUrl =
                    images?.isNotEmpty == true ? images!.first as String : null;
                return Container(
                  width: isCompact ? 30.w : 32.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                height: isCompact ? 10.h : 12.h,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _playlistPlaceholder(isCompact),
                              )
                            : _playlistPlaceholder(isCompact),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.8.h),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: isCompact ? 11.sp : 12.5.sp,
                            color: _text,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _playlistPlaceholder(bool isCompact) {
    return Container(
      height: isCompact ? 10.h : 12.h,
      width: double.infinity,
      color: _chipFill,
      child: Icon(Icons.playlist_play, color: _accent, size: 28),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Side Rail (Saved, Achievement, Reviews quick actions)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSideRail(bool isCompact) {
    final userMeta = Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    final isAdmin = userMeta['is_admin'] == true;
    final items = <(String, VoidCallback)>[
      ('Saved', () => showSavedRoutesModal(context)),
      ('Achievement', () => showAchievementsModal(context)),
      ('Reviews', () => showMyReviewsModal(context)),
      if (isAdmin)
        ('Admin Panel', () {
          setState(() => _isSideRailVisible = false);
          Navigator.of(context, rootNavigator: true)
              .pushNamed(AppRoutes.adminReviews);
        }),
    ];
    return Container(
      width: isCompact ? 42.w : 34.w,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 4.w : 3.2.w,
        isCompact ? 1.8.h : 2.2.h,
        isCompact ? 4.w : 3.2.w,
        isCompact ? 1.8.h : 2.2.h,
      ),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => setState(() => _isSideRailVisible = false),
              child: Padding(
                padding: EdgeInsets.only(bottom: isCompact ? 0.8.h : 0.9.h),
                child: Icon(Icons.close_rounded,
                    color: Colors.white,
                    size: isCompact ? 5.2.w : 4.2.w),
              ),
            ),
          ),
          ...items.map((item) => GestureDetector(
                onTap: item.$2,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 0.95.h : 1.15.h),
                  child: Text(
                    '- ${item.$1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 13.sp : 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Settings Bottom Sheet
  // ═══════════════════════════════════════════════════════════════════════════
  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD5D8DE),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined,
                  color: Color(0xFF2F7BF2)),
              title: const Text('Change Profile Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined,
                  color: Color(0xFF2F7BF2)),
              title: const Text('Change Banner Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadBanner();
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(ctx);
                showLogoutDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever_rounded,
                  color: Theme.of(ctx).colorScheme.error),
              title: Text('Delete Account',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                showDeleteAccountDialog(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
