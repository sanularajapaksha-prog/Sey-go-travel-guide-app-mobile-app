import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/api_service.dart';
import '../../providers/user_data_provider.dart';
import '../../theme/app_theme.dart';
import 'profile_modals.dart';
import 'widgets/profile_badges_widget.dart';
import 'widgets/profile_activity_widget.dart';
import 'widgets/profile_preferences_widget.dart';
import 'widgets/profile_map_stats_widget.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── gamification data ────────────────────────────────────────────────────────
  final List<TravelBadge> _badges = [
    const TravelBadge(id: '1', title: 'Island Explorer', description: 'Visited 5 unique districts in Sri Lanka', iconData: Icons.explore, isUnlocked: true, progress: 1.0),
    const TravelBadge(id: '2', title: 'Beach Bum', description: 'Saved 10 coastal pristine locations', iconData: Icons.beach_access, isUnlocked: true, progress: 1.0),
    TravelBadge(id: '3', title: 'Mountain Goat', description: 'Hike 3 famous trails in the central province', iconData: Icons.landscape, isUnlocked: false, progress: 0.33),
    TravelBadge(id: '4', title: 'Culture Vulture', description: 'Review 5 historical temples and monuments', iconData: Icons.account_balance, isUnlocked: false, progress: 0.8),
  ];
  
  final List<UserActivity> _activities = [
    UserActivity(id: '1', type: ActivityType.trip, title: 'Completed Sigiriya Trek', description: 'An amazing morning hike observing the ancient rock fortress.', timestamp: DateTime.now().subtract(const Duration(hours: 4)), location: 'Sigiriya, Dambulla'),
    UserActivity(id: '2', type: ActivityType.review, title: 'Reviewed Ella Gap', description: 'Gave a 5-star rating to the spectacular views at Ella.', timestamp: DateTime.now().subtract(const Duration(days: 1)), location: 'Ella, Badulla'),
    UserActivity(id: '3', type: ActivityType.photo, title: 'Uploaded Photos', description: 'Added 12 new photos to the Galle Fort gallery.', timestamp: DateTime.now().subtract(const Duration(days: 3)), location: 'Galle, Southern Province'),
  ];

  // ── profile fields ──────────────────────────────────────────────────────────
  String _avatarPath = '';
  String _displayName = '';
  String _email = '';
  String _homeCity = '';
  String _bio = '';
  String _travelStyle = '';

  // ── loading flags ────────────────────────────────────────────────────────────
  bool _profileLoading = true;
  bool _playlistsLoading = true;
  bool _statsLoading = true;
  bool _avatarUploading = false;
  bool _initialized = false;

  // ── data ─────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _userPlaylists = [];
  Map<String, dynamic> _stats = {
    'playlists': 0,
    'places': 0,
    'reviews': 0,
    'photos': 0,
  };

  bool _isPrivatePlaylist = true;
  bool _isSideRailVisible = false;

  // ── theme constants ──────────────────────────────────────────────────────────
  static const Color _ink = AppTheme.secondaryLight;
  static const Color _accent = AppTheme.secondaryLight;
  static const Color _border = AppTheme.dividerLight;
  static const Color _text = AppTheme.tertiaryLight;
  static const Color _mutedText = AppTheme.neutralLight;
  static const Color _chipFill = Color(0xFFEAF4FA);

  // ── travel style → interest chip labels ─────────────────────────────────────
  static const _styleChips = <String, List<String>>{
    'Beach & Culture': ['Beach Side', 'Culture', 'History'],
    'Adventure & Hiking': ['Hiking', 'Mountains', 'Adventure'],
    'Urban Exploration': ['Cities', 'Urban', 'Nightlife'],
    'Nature & Wildlife': ['Nature', 'Wildlife', 'Camping'],
    'Relaxation & Spa': ['Wellness', 'Beach Side', 'Spa'],
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _seedFromCache();
      _loadAll();
    }
  }

  /// Instantly populates fields from pre-fetched cache so the screen renders
  /// without a spinner on first open. [_loadAll] still runs in background to
  /// get the freshest data from the server.
  void _seedFromCache() {
    final udp = Provider.of<UserDataProvider>(context, listen: false);
    final profile = udp.profile;
    if (profile != null) {
      _displayName = (profile['full_name'] as String?)?.isNotEmpty == true
          ? profile['full_name'] as String
          : (profile['email'] as String? ?? '');
      _email = profile['email'] as String? ?? '';
      _homeCity = profile['home_city'] as String? ?? '';
      _bio = profile['bio'] as String? ?? '';
      _travelStyle = profile['travel_style'] as String? ?? '';
      final av = profile['avatar_url'] as String?;
      if (av != null && av.isNotEmpty) _avatarPath = av;
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

  // ── load everything in parallel ──────────────────────────────────────────────
  Future<void> _loadAll() async {
    await Future.wait([_loadProfile(), _loadPlaylists(), _loadStats()]);
  }

  Future<void> _loadProfile() async {
    // Fast path: auth metadata
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && mounted) {
      final meta = user.userMetadata ?? {};
      setState(() {
        _displayName = meta['full_name'] as String? ?? user.email ?? '';
        _email = user.email ?? '';
      });
    }

    // Full profile — force refresh so changes from settings appear immediately
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final profile = await ApiService.fetchProfile(
      accessToken: token,
      forceRefresh: true,
    );
    if (!mounted) return;
    setState(() {
      if (profile != null) {
        _displayName = (profile['full_name'] as String?)?.isNotEmpty == true
            ? profile['full_name'] as String
            : _displayName;
        _email = (profile['email'] as String?)?.isNotEmpty == true
            ? profile['email'] as String
            : _email;
        _homeCity = profile['home_city'] as String? ?? '';
        _bio = profile['bio'] as String? ?? '';
        _travelStyle = profile['travel_style'] as String? ?? '';
        final av = profile['avatar_url'] as String?;
        if (av != null && av.isNotEmpty) _avatarPath = av;
      }
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

  // ── avatar: pick → upload → persist ─────────────────────────────────────────
  Future<void> _pickAndUploadAvatar() async {
    showAvatarPicker(context, (path) async {
      // Show local preview immediately
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
      } catch (_) {}

      if (!mounted) return;

      if (publicUrl != null) {
        final token = supabase.auth.currentSession?.accessToken;
        await ApiService.updateProfile(
          avatarUrl: publicUrl,
          accessToken: token,
        );
        ApiService.invalidateProfileCache();
        if (mounted) setState(() => _avatarPath = publicUrl!);
      } else {
        // Upload failed — show error, revert preview
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload photo'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      if (mounted) setState(() => _avatarUploading = false);
    });
  }

  // ── build ────────────────────────────────────────────────────────────────────
  /// =========================================================================
  /// REDESIGN: GAMIFIED CUSTOM SCROLL VIEW
  /// =========================================================================
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
              SliverAppBar(
                expandedHeight: isCompact ? 28.h : 32.h,
                pinned: true,
                stretch: true,
                backgroundColor: theme.colorScheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    _displayName.isNotEmpty ? _displayName : 'Traveller',
                    style: TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 10,
                        )
                      ]
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Premium Gradient Background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              AppTheme.primaryLight.withOpacity(0.15),
                              AppTheme.secondaryLight.withOpacity(0.05),
                              theme.scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: -30,
                        top: -20,
                        child: Icon(
                          Icons.travel_explore,
                          size: 200,
                          color: AppTheme.primaryLight.withOpacity(0.05),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                   IconButton(
                     icon: const Icon(Icons.settings_outlined),
                     onPressed: () {}, // Handled in later commits
                     color: _text,
                   )
                ]
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 8.w : 7.w,
                  2.h,
                  isCompact ? 6.w : 7.w,
                  12.h, // padding for floating assist
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProfileHero(isCompact),
                    SizedBox(height: isCompact ? 3.h : 3.5.h),
                    
                    // Gamification: Achievements
                    ProfileBadgesWidget(badges: _badges, isCompact: isCompact),
                    SizedBox(height: isCompact ? 3.h : 4.h),
                    
                    // Historical Map Timeline
                    ProfileActivityWidget(activities: _activities, isCompact: isCompact),
                    SizedBox(height: isCompact ? 3.h : 4.h),
                    
                    // Core Map Statistics
                    ProfileMapStatsWidget(isCompact: isCompact),
                    SizedBox(height: isCompact ? 3.h : 4.h),
                    
                    // Editable Preferences
                    ProfilePreferencesWidget(initialStyle: _travelStyle.isNotEmpty ? _travelStyle : 'Adventure & Hiking', isCompact: isCompact),
                    SizedBox(height: isCompact ? 3.h : 4.h),
                    
                    // Legacy Playlists Fallback
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
          
          // Original floating logic remains overlaying the ScrollView
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
                  padding: EdgeInsets.only(left: isCompact ? 4.w : 5.w),
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
                    padding: EdgeInsets.only(left: isCompact ? 4.w : 5.w),
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

  // ── hero section ─────────────────────────────────────────────────────────────
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
                'Welcome',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: isCompact ? 14.5.sp : 17.sp,
                  color: _mutedText,
                ),
              ),
              SizedBox(height: isCompact ? 0.4.h : 0.8.h),
              Text(
                _displayName.isNotEmpty ? _displayName : 'Traveller',
                style: TextStyle(
                  fontSize: isCompact ? 20.sp : 24.sp,
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
              ),
              SizedBox(height: isCompact ? 0.7.h : 1.h),
              Text(
                _homeCity.isNotEmpty
                    ? _homeCity
                    : (_email.isNotEmpty ? _email : 'Sri Lanka'),
                style: TextStyle(
                  fontSize: isCompact ? 12.5.sp : 15.sp,
                  color: _mutedText,
                ),
              ),
              if (_bio.isNotEmpty) ...[
                SizedBox(height: isCompact ? 0.5.h : 0.8.h),
                Text(
                  _bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isCompact ? 11.sp : 13.sp,
                    color: _mutedText,
                  ),
                ),
              ],
            ],
          ),
        ),
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
                  border: Border.all(color: _border),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: isCompact ? 9.7.w : 11.w,
                    backgroundColor: _accent.withOpacity(0.7),
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? Text(
                            'Photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isCompact ? 11.sp : 14.sp,
                            ),
                          )
                        : null,
                  ),
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
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
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: isCompact ? 3.5.w : 4.w,
                    color: _accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── your playlists (real data) ───────────────────────────────────────────────
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
            offset: const Offset(0, 8),
          ),
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
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                final title = playlist['name'] as String? ?? 'Playlist';
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

  // ── privacy toggle ───────────────────────────────────────────────────────────
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
            child: _privacyPill('Private', _isPrivatePlaylist, isCompact),
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

  // ── side rail ────────────────────────────────────────────────────────────────
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
            offset: const Offset(0, 10),
          ),
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
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: isCompact ? 5.2.w : 4.2.w,
                ),
              ),
            ),
          ),
          ...items.map((item) {
            return GestureDetector(
              onTap: item.$2,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: isCompact ? 0.95.h : 1.15.h,
                ),
                child: Text(
                  '- ${item.$1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 13.sp : 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
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
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          color: Colors.white,
          size: isCompact ? 5.4.w : 4.6.w,
        ),
      ),
    );
  }
}

