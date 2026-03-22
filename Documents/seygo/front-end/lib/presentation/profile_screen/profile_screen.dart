import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/api_service.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/user_data_provider.dart';
import '../../theme/app_theme.dart';
import 'profile_modals.dart';
import 'widgets/profile_activity_widget.dart';
import 'widgets/profile_badges_widget.dart';
import 'widgets/profile_map_stats_widget.dart';
import 'widgets/profile_preferences_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── gamification (static for now) ────────────────────────────────────────────
  final List<TravelBadge> _badges = [
    const TravelBadge(
        id: '1',
        title: 'Island Explorer',
        description: 'Visited 5 unique districts in Sri Lanka',
        iconData: Icons.explore,
        isUnlocked: true,
        progress: 1.0),
    const TravelBadge(
        id: '2',
        title: 'Beach Bum',
        description: 'Saved 10 coastal pristine locations',
        iconData: Icons.beach_access,
        isUnlocked: true,
        progress: 1.0),
    TravelBadge(
        id: '3',
        title: 'Mountain Goat',
        description: 'Hike 3 famous trails in the central province',
        iconData: Icons.landscape,
        isUnlocked: false,
        progress: 0.33),
    TravelBadge(
        id: '4',
        title: 'Culture Vulture',
        description: 'Review 5 historical temples and monuments',
        iconData: Icons.account_balance,
        isUnlocked: false,
        progress: 0.8),
  ];

  // ── profile fields ────────────────────────────────────────────────────────────
  String _avatarPath = '';
  String _bannerUrl = '';
  String _displayName = '';
  String _email = '';
  String _homeCity = '';
  String _bio = '';
  String _aiDescription = '';
  String _travelStyle = '';
  String _workingType = '';
  String _travelPersonalityType = '';

  // ── loading flags ─────────────────────────────────────────────────────────────
  bool _profileLoading = true;
  bool _playlistsLoading = true;
  bool _statsLoading = true;
  bool _avatarUploading = false;
  bool _bannerUploading = false;
  bool _initialized = false;

  // ── data ──────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _userPlaylists = [];
  Map<String, dynamic> _stats = {
    'playlists': 0,
    'places': 0,
    'reviews': 0,
    'photos': 0,
  };
  List<UserActivity> _activities = [];

  bool _isPrivatePlaylist = true;
  bool _isSideRailVisible = false;

  // ── theme ─────────────────────────────────────────────────────────────────────
  static const Color _ink = AppTheme.secondaryLight;
  static const Color _accent = AppTheme.secondaryLight;
  static const Color _border = AppTheme.dividerLight;
  static const Color _text = AppTheme.tertiaryLight;
  static const Color _mutedText = AppTheme.neutralLight;
  static const Color _chipFill = Color(0xFFEAF4FA);

  // ── banner gradient per travel style (AI-ready personalisation) ───────────────
  static const Map<String, List<Color>> _styleGradients = {
    'Beach & Culture': [Color(0xFF0077B6), Color(0xFF00B4D8)],
    'Adventure & Hiking': [Color(0xFF2D6A4F), Color(0xFF74C69D)],
    'Urban Exploration': [Color(0xFF4361EE), Color(0xFF7209B7)],
    'Nature & Wildlife': [Color(0xFF1B4332), Color(0xFF52B788)],
    'Relaxation & Spa': [Color(0xFF9B5DE5), Color(0xFFF15BB5)],
    'Historical Trails': [Color(0xFF6D4C41), Color(0xFFBCAAA4)],
    'Culinary Tours': [Color(0xFFE63946), Color(0xFFF4A261)],
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _seedFromCache();
      _loadAll();
    }
  }

  // ── cache seed (instant render) ───────────────────────────────────────────────
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
    _email = profile['email'] as String? ?? '';
    _homeCity = profile['home_city'] as String? ?? '';
    _bio = profile['bio'] as String? ?? '';
    _aiDescription = profile['ai_description'] as String? ?? '';
    _travelStyle = profile['travel_style'] as String? ?? '';
    _workingType = profile['working_type'] as String? ?? '';
    _travelPersonalityType =
        profile['travel_personality_type'] as String? ?? '';
    final av = profile['avatar_url'] as String?;
    if (av != null && av.isNotEmpty) _avatarPath = av;
    final bn = profile['banner_url'] as String?;
    if (bn != null && bn.isNotEmpty) _bannerUrl = bn;
  }

  // ── load all ──────────────────────────────────────────────────────────────────
  Future<void> _loadAll() async {
    await Future.wait([_loadProfile(), _loadPlaylists(), _loadStats()]);
    _buildActivities();
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

  /// Derives real activities from playlists + local favorites.
  /// No new DB tables required.
  void _buildActivities() {
    if (!mounted) return;
    final activities = <UserActivity>[];

    // From playlists
    for (final pl in _userPlaylists.take(3)) {
      final count = (pl['destination_count'] as num?)?.toInt() ?? 0;
      final createdRaw = pl['created_at'] as String?;
      final ts = createdRaw != null
          ? DateTime.tryParse(createdRaw) ?? DateTime.now()
          : DateTime.now();
      activities.add(UserActivity(
        id: 'pl_${pl['id']}',
        type: ActivityType.trip,
        title: 'Created: ${pl['name'] as String? ?? 'Playlist'}',
        description:
            'Trip playlist with $count destination${count == 1 ? '' : 's'}',
        timestamp: ts,
      ));
    }

    // From local favorites
    final favs =
        Provider.of<FavoritesProvider>(context, listen: false).favorites;
    for (final fav in favs.take(3)) {
      activities.add(UserActivity(
        id: 'fav_${fav.id}',
        type: ActivityType.placeAdded,
        title: 'Saved: ${fav.name}',
        description: 'Added to your favorites collection',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        location: fav.location,
      ));
    }

    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    setState(() => _activities = activities.take(5).toList());
  }

  // ── avatar upload ─────────────────────────────────────────────────────────────
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
      final storagePath = 'avatars/$userId.$ext';
      String? publicUrl;
      try {
        await supabase.storage.from('profiles').upload(
              storagePath,
              File(path),
              fileOptions: const FileOptions(upsert: true),
            );
        publicUrl =
            supabase.storage.from('profiles').getPublicUrl(storagePath);
      } catch (e) {
        if (kDebugMode) debugPrint('Avatar upload error: $e');
      }

      if (!mounted) return;

      if (publicUrl != null) {
        final token = supabase.auth.currentSession?.accessToken;
        await ApiService.updateProfile(
            avatarUrl: publicUrl, accessToken: token);
        ApiService.invalidateProfileCache();
        if (mounted) setState(() => _avatarPath = publicUrl!);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload photo. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      if (mounted) setState(() => _avatarUploading = false);
    });
  }

  // ── banner upload ─────────────────────────────────────────────────────────────
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
      final storagePath = 'banners/$userId.$ext';
      String? publicUrl;
      try {
        await supabase.storage.from('profiles').upload(
              storagePath,
              File(path),
              fileOptions: const FileOptions(upsert: true),
            );
        publicUrl =
            supabase.storage.from('profiles').getPublicUrl(storagePath);
      } catch (e) {
        if (kDebugMode) debugPrint('Banner upload error: $e');
      }

      if (!mounted) return;

      if (publicUrl != null) {
        // Update banner_url directly via Supabase (new field, backend may not know it yet)
        try {
          await supabase
              .from('profiles')
              .update({'banner_url': publicUrl})
              .eq('id', userId);
          ApiService.invalidateProfileCache();
          if (mounted) setState(() => _bannerUrl = publicUrl!);
        } catch (e) {
          if (kDebugMode) debugPrint('Banner profile update error: $e');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload banner. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      if (mounted) setState(() => _bannerUploading = false);
    });
  }

  // ── helpers ───────────────────────────────────────────────────────────────────

  /// Effective bio: prefer user bio, fall back to AI description, then a
  /// generated placeholder based on travel style.
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

  List<Color> get _bannerGradientColors {
    return _styleGradients[_travelStyle] ??
        [AppTheme.secondaryLight, AppTheme.primaryLight];
  }

  // ── build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Banner SliverAppBar ────────────────────────────────────────
              SliverAppBar(
                expandedHeight: isCompact ? 30.h : 34.h,
                pinned: true,
                stretch: true,
                backgroundColor: theme.colorScheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  titlePadding:
                      const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    _displayName.isNotEmpty ? _displayName : 'Traveller',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      shadows: const [
                        Shadow(color: Colors.black38, blurRadius: 8),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Banner: real image or gradient
                      _bannerUrl.isNotEmpty
                          ? Image.network(
                              _bannerUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _buildGradientBanner(),
                            )
                          : _buildGradientBanner(),

                      // Scrim for readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.45),
                            ],
                          ),
                        ),
                      ),

                      // Banner edit button
                      Positioned(
                        top: 48,
                        right: 16,
                        child: GestureDetector(
                          onTap: _pickAndUploadBanner,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: _bannerUploading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.white),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.camera_alt_outlined,
                                          size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('Banner',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),

              // ── Content ───────────────────────────────────────────────────
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 4.w : 5.w,
                  2.h,
                  isCompact ? 4.w : 5.w,
                  12.h,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile hero
                    _buildProfileHero(isCompact),
                    SizedBox(height: isCompact ? 3.h : 3.5.h),

                    // Stats row
                    _buildStatsRow(isCompact),
                    SizedBox(height: isCompact ? 3.h : 4.h),

                    // Badges
                    ProfileBadgesWidget(
                        badges: _badges, isCompact: isCompact),
                    SizedBox(height: isCompact ? 3.h : 4.h),

                    // Recent activity (real data)
                    _buildActivitiesSection(isCompact),
                    SizedBox(height: isCompact ? 3.h : 4.h),

                    // Map stats
                    ProfileMapStatsWidget(isCompact: isCompact),
                    SizedBox(height: isCompact ? 3.h : 4.h),

                    // Travel DNA
                    ProfilePreferencesWidget(
                      initialStyle: _travelStyle.isNotEmpty
                          ? _travelStyle
                          : 'Adventure & Hiking',
                      initialWorkingType: _workingType,
                      onWorkingTypeChanged: _saveWorkingType,
                      isCompact: isCompact,
                    ),
                    SizedBox(height: isCompact ? 3.h : 4.h),

                    // Playlists card
                    _buildPlaylistsCard(isCompact),
                    SizedBox(height: isCompact ? 2.4.h : 3.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildPrivacyToggle(isCompact),
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // Side rail (quick actions)
          Positioned(
            left: 0,
            right: 0,
            bottom: isCompact ? 15.h : 13.h,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              offset: _isSideRailVisible
                  ? Offset.zero
                  : const Offset(0, 1.15),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding:
                      EdgeInsets.only(left: isCompact ? 4.w : 5.w),
                  child: _buildSideRail(isCompact),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: isCompact ? 7.h : 6.h,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _isSideRailVisible ? 0 : 1,
              child: IgnorePointer(
                ignoring: _isSideRailVisible,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: isCompact ? 4.w : 5.w),
                    child: _buildAssistiveTouch(isCompact),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── gradient banner fallback ──────────────────────────────────────────────────
  Widget _buildGradientBanner() {
    final colors = _bannerGradientColors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -20,
            child: Icon(
              Icons.travel_explore,
              size: 220,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Icon(
              Icons.landscape_rounded,
              size: 180,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }

  // ── profile hero ──────────────────────────────────────────────────────────────
  Widget _buildProfileHero(bool isCompact) {
    final ImageProvider? avatarImage = _avatarPath.isEmpty
        ? null
        : _avatarPath.startsWith('http')
            ? NetworkImage(_avatarPath)
            : FileImage(File(_avatarPath));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: isCompact ? 13.sp : 15.sp,
                  color: _mutedText,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                _displayName.isNotEmpty ? _displayName : 'Traveller',
                style: TextStyle(
                  fontSize: isCompact ? 20.sp : 24.sp,
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                _homeCity.isNotEmpty
                    ? _homeCity
                    : (_email.isNotEmpty ? _email : 'Sri Lanka'),
                style: TextStyle(
                  fontSize: isCompact ? 12.sp : 13.5.sp,
                  color: _mutedText,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                _effectiveBio,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 11.sp : 12.5.sp,
                  color: _mutedText,
                  height: 1.5,
                ),
              ),
              if (_travelPersonalityType.isNotEmpty) ...[
                SizedBox(height: 1.h),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _accent.withOpacity(0.25), width: 1),
                  ),
                  child: Text(
                    _travelPersonalityType,
                    style: TextStyle(
                      fontSize: isCompact ? 10.sp : 11.sp,
                      color: _accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 3.w),

        // Avatar
        GestureDetector(
          onTap: _pickAndUploadAvatar,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: isCompact ? 24.w : 27.w,
                height: isCompact ? 24.w : 27.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _border, width: 2),
                ),
                child: CircleAvatar(
                  radius: isCompact ? 9.7.w : 11.w,
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
              Positioned(
                right: -1.w,
                bottom: 2.w,
                child: Container(
                  width: isCompact ? 7.2.w : 8.w,
                  height: isCompact ? 7.2.w : 8.w,
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
      ],
    );
  }

  // ── stats row ─────────────────────────────────────────────────────────────────
  Widget _buildStatsRow(bool isCompact) {
    final items = [
      ('Playlists', '${_stats['playlists'] ?? 0}'),
      ('Places', '${_stats['places'] ?? 0}'),
      ('Reviews', '${_stats['reviews'] ?? 0}'),
      ('Photos', '${_stats['photos'] ?? 0}'),
    ];

    return Container(
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
    );
  }

  // ── recent activities section ─────────────────────────────────────────────────
  Widget _buildActivitiesSection(bool isCompact) {
    if (_activities.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: isCompact ? 16.sp : 18.sp,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                vertical: 3.h, horizontal: 4.w),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Icon(Icons.history_rounded,
                    size: 12.w,
                    color: _mutedText.withOpacity(0.3)),
                SizedBox(height: 1.5.h),
                Text(
                  'No recent activity yet',
                  style: TextStyle(
                      fontSize: 13.sp, color: _mutedText),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Start saving places and creating playlists',
                  style: TextStyle(
                      fontSize: 11.sp,
                      color: _mutedText.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ProfileActivityWidget(
        activities: _activities, isCompact: isCompact);
  }

  // ── save working type via Supabase direct ─────────────────────────────────────
  Future<void> _saveWorkingType(String type) async {
    setState(() => _workingType = type);
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await supabase
          .from('profiles')
          .update({'working_type': type})
          .eq('id', userId);
      ApiService.invalidateProfileCache();
    } catch (e) {
      if (kDebugMode) debugPrint('Working type save error: $e');
    }
  }

  // ── playlists card ────────────────────────────────────────────────────────────
  Widget _buildPlaylistsCard(bool isCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 3.2.w : 4.w,
        isCompact ? 1.8.h : 2.2.h,
        isCompact ? 3.2.w : 4.w,
        isCompact ? 1.8.h : 2.2.h,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your Playlists',
            style: TextStyle(
              fontSize: isCompact ? 15.5.sp : 17.sp,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          SizedBox(height: isCompact ? 1.5.h : 2.1.h),
          if (_playlistsLoading)
            const SizedBox(
              height: 80,
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_userPlaylists.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Text(
                'No playlists yet.\nCreate one in the Playlists tab.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isCompact ? 12.sp : 13.5.sp,
                  color: _mutedText,
                  height: 1.5,
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _userPlaylists.take(3).map((playlist) {
                final title =
                    playlist['name'] as String? ?? 'Playlist';
                final images = playlist['previewImages'] as List?;
                final imageUrl = images?.isNotEmpty == true
                    ? images!.first as String
                    : null;
                return Container(
                  width: isCompact ? 25.w : 25.5.w,
                  padding: EdgeInsets.fromLTRB(
                    1.5.w,
                    isCompact ? 0.9.h : 1.1.h,
                    1.5.w,
                    isCompact ? 1.h : 1.3.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                height: isCompact ? 7.4.h : 8.6.h,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _playlistPlaceholder(isCompact),
                              )
                            : _playlistPlaceholder(isCompact),
                      ),
                      SizedBox(height: isCompact ? 0.9.h : 1.2.h),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isCompact ? 11.5.sp : 13.7.sp,
                          height: 1.25,
                          color: _text,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _playlistPlaceholder(bool isCompact) {
    return Container(
      height: isCompact ? 7.4.h : 8.6.h,
      width: double.infinity,
      color: _chipFill,
      child: Icon(Icons.playlist_play, color: _accent, size: 28),
    );
  }

  // ── privacy toggle ────────────────────────────────────────────────────────────
  Widget _buildPrivacyToggle(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(0.5.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isPrivatePlaylist = false),
            child: _privacyPill('Public', !_isPrivatePlaylist, isCompact),
          ),
          GestureDetector(
            onTap: () => setState(() => _isPrivatePlaylist = true),
            child:
                _privacyPill('Private', _isPrivatePlaylist, isCompact),
          ),
        ],
      ),
    );
  }

  Widget _privacyPill(String label, bool selected, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4.w : 4.5.w,
        vertical: isCompact ? 0.65.h : 0.8.h,
      ),
      decoration: BoxDecoration(
        color: selected ? _accent : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isCompact ? 12.sp : 13.3.sp,
          color: selected ? Colors.white : _text,
        ),
      ),
    );
  }

  // ── side rail ─────────────────────────────────────────────────────────────────
  Widget _buildSideRail(bool isCompact) {
    final items = <(String, VoidCallback)>[
      ('Saved', () => showSavedRoutesModal(context)),
      ('Achievement', () => showAchievementsModal(context)),
      ('Reviews', () => showMyReviewsModal(context)),
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
                padding: EdgeInsets.only(
                    bottom: isCompact ? 0.8.h : 0.9.h),
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

  Widget _buildAssistiveTouch(bool isCompact) {
    return GestureDetector(
      onTap: () => setState(() => _isSideRailVisible = true),
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
    );
  }
}
