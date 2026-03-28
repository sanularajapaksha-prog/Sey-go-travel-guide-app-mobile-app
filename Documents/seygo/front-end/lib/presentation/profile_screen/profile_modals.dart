import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/api_service.dart';
import '../playlist_details/playlist_details_screen.dart';

void showAvatarPicker(BuildContext context, ValueChanged<String> onPicked) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 3.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: const Color(0xFFD5D8DE),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          SizedBox(height: 2.2.h),
          Text(
            'Change Profile Photo',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 2.h),
          _pickerTile(
            icon: Icons.camera_alt_outlined,
            title: 'Take Photo',
            onTap: () async {
              Navigator.pop(context);
              final image = await ImagePicker().pickImage(
                source: ImageSource.camera,
              );
              if (image != null) onPicked(image.path);
            },
          ),
          _pickerTile(
            icon: Icons.photo_library_outlined,
            title: 'Choose from Gallery',
            onTap: () async {
              Navigator.pop(context);
              final image = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (image != null) onPicked(image.path);
            },
          ),
        ],
      ),
    ),
  );
}

void showSavedRoutesModal(BuildContext context) {
  _showProfileDialog(
    context,
    width: 84.w,
    height: 68.h,
    child: _SavedRoutesContent(),
  );
}

class _SavedRoutesContent extends StatefulWidget {
  @override
  State<_SavedRoutesContent> createState() => _SavedRoutesContentState();
}

class _SavedRoutesContentState extends State<_SavedRoutesContent> {
  List<Map<String, dynamic>> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final data = await ApiService.fetchMyPlaylists(accessToken: token);
    if (mounted) setState(() { _playlists = data; _loading = false; });
  }

  Future<void> _toggleVisibility(int index) async {
    final p = _playlists[index];
    final playlistId = (p['id'] ?? '').toString();
    final wasPublic = (p['visibility'] ?? 'public') == 'public';
    final newVisibility = wasPublic ? 'private' : 'public';

    // Optimistic update
    setState(() => _playlists[index] = {...p, 'visibility': newVisibility});

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final ok = await ApiService.updatePlaylist(
      playlistId: playlistId,
      visibility: newVisibility,
      accessToken: token,
    );
    if (!ok && mounted) {
      // Revert on failure
      setState(() => _playlists[index] = {...p, 'visibility': wasPublic ? 'public' : 'private'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update visibility')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dialogHeader(context, title: 'Saved Routes', icon: Icons.route_outlined, iconColor: const Color(0xFF2F7BF2)),
        SizedBox(height: 2.h),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_playlists.isEmpty)
          Expanded(child: Center(child: Text('No saved routes yet.\nCreate one from a trip.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6D7587), height: 1.6))))
        else
          Expanded(
            child: ListView.separated(
              itemCount: _playlists.length,
              separatorBuilder: (_, _) => SizedBox(height: 1.7.h),
              itemBuilder: (context, i) {
                final p = _playlists[i];
                final isPublic = (p['visibility'] ?? 'public') == 'public';
                final stops = (p['places_count'] ?? p['destination_count'] ?? 0) as int;
                final name = p['name'] as String? ?? 'Route';
                final desc = p['description'] as String? ?? '';
                final playlistId = (p['id'] ?? '').toString();
                final createdAt = (p['created_at'] as String? ?? '').split('T').first;
                return Container(
                  padding: EdgeInsets.all(2.3.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE3E7ED)),
                  ),
                  child: Column(
                    children: [
                      // Top row: icon/info + chevron tap target
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => PlaylistDetailsScreen(
                                playlistId: playlistId,
                                initialPlaylist: p,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 12.w, height: 12.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD8E6FB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.route_outlined, color: const Color(0xFF2F7BF2), size: 6.w),
                            ),
                            SizedBox(width: 2.5.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: TextStyle(fontSize: 17.5.sp, color: const Color(0xFF1F2639))),
                                  SizedBox(height: 0.8.h),
                                  Row(
                                    children: [
                                      if (createdAt.isNotEmpty) ...[
                                        _routeMetric(Icons.calendar_today_outlined, createdAt),
                                        _dot(),
                                      ],
                                      _routeMetric(Icons.place_outlined, '$stops stops'),
                                    ],
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    SizedBox(height: 0.8.h),
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.7.h),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD8E6FB),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12.5.sp, color: const Color(0xFF1855E5))),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9BA4B6)),
                          ],
                        ),
                      ),
                      SizedBox(height: 1.4.h),
                      // Bottom row: public/private toggle
                      Row(
                        children: [
                          Icon(
                            isPublic ? Icons.public : Icons.lock_outline_rounded,
                            color: isPublic ? const Color(0xFF337AF3) : const Color(0xFF737B8E),
                            size: 3.1.w,
                          ),
                          SizedBox(width: 2.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPublic ? 'Public' : 'Private',
                                style: TextStyle(fontSize: 15.5.sp, color: const Color(0xFF1B2235)),
                              ),
                              Text(
                                isPublic ? 'Anyone can view this' : 'Only you can see this',
                                style: TextStyle(fontSize: 11.8.sp, color: const Color(0xFF6E778A)),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (isPublic) ...[
                            const Icon(Icons.share_outlined, color: Color(0xFF596275)),
                            SizedBox(width: 1.5.w),
                            Text('Share', style: TextStyle(fontSize: 15.sp, color: const Color(0xFF596275))),
                            SizedBox(width: 4.w),
                          ],
                          Switch(
                            value: isPublic,
                            onChanged: (_) => _toggleVisibility(i),
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF0A0828),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFD1D4DB),
                          ),
                        ],
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
}

void showAchievementsModal(BuildContext context) {
  _showProfileDialog(
    context,
    width: 84.w,
    height: 70.h,
    child: _AchievementsContent(),
  );
}

class _AchievementsContent extends StatefulWidget {
  @override
  State<_AchievementsContent> createState() => _AchievementsContentState();
}

class _AchievementsContentState extends State<_AchievementsContent> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final data = await ApiService.fetchUserStats(accessToken: token);
    if (mounted) setState(() { _stats = data; _loading = false; });
  }

  List<_AchievementData> _buildAchievements() {
    final playlists = (_stats['playlists'] ?? 0) as int;
    final places = (_stats['places'] ?? 0) as int;
    final reviews = (_stats['reviews'] ?? 0) as int;
    final trips = (_stats['photos'] ?? 0) as int;

    return [
      _AchievementData(
        title: 'Route Master',
        subtitle: '$playlists / 10 routes',
        progress: (playlists / 10).clamp(0.0, 1.0),
        color: const Color(0xFF367AF1),
        icon: Icons.map_outlined,
      ),
      _AchievementData(
        title: 'Explorer',
        subtitle: '$places / 20 places',
        progress: (places / 20).clamp(0.0, 1.0),
        color: const Color(0xFF11C0B2),
        icon: Icons.explore_outlined,
      ),
      _AchievementData(
        title: 'Critic',
        subtitle: '$reviews / 10 reviews',
        progress: (reviews / 10).clamp(0.0, 1.0),
        color: const Color(0xFFFF7308),
        icon: Icons.rate_review_outlined,
      ),
      _AchievementData(
        title: 'Traveller',
        subtitle: '$trips / 5 trips',
        progress: (trips / 5).clamp(0.0, 1.0),
        color: const Color(0xFF9D46F8),
        icon: Icons.luggage_outlined,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final achievements = _buildAchievements();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dialogHeader(
          context,
          title: 'Achievements',
          icon: Icons.emoji_events_outlined,
          iconColor: const Color(0xFFFF9800),
        ),
        SizedBox(height: 2.h),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else ...[
          Expanded(
            child: GridView.builder(
              itemCount: achievements.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 1.8.h,
                crossAxisSpacing: 4.w,
                childAspectRatio: 0.83,
              ),
              itemBuilder: (context, index) => _achievementCard(achievements[index]),
            ),
          ),
          SizedBox(height: 1.h),
          () {
            final best = achievements.reduce((a, b) => a.progress > b.progress ? a : b);
            final remaining = ((1.0 - best.progress) * 10).ceil();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next milestone', style: TextStyle(fontSize: 16.sp, color: const Color(0xFF6F788D))),
                SizedBox(height: 0.8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$remaining more to complete ${best.title}',
                      style: TextStyle(fontSize: 14.sp, color: const Color(0xFF334055))),
                    Text('${(best.progress * 100).round()}%',
                      style: TextStyle(fontSize: 16.sp, color: const Color(0xFF6F788D))),
                  ],
                ),
                SizedBox(height: 1.1.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    minHeight: 1.1.h,
                    value: best.progress,
                    backgroundColor: const Color(0xFFD0D3DB),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF0E0B29)),
                  ),
                ),
              ],
            );
          }(),
        ],
      ],
    );
  }
}

void showMyReviewsModal(BuildContext context) {
  _showReviewsModal(context, initialTab: 0);
}

void showCommunityReviewsModal(BuildContext context) {
  _showReviewsModal(context, initialTab: 1);
}

void showWriteReviewModal(BuildContext context) {
  final controller = TextEditingController();

  _showProfileDialog(
    context,
    width: 84.w,
    height: 72.h,
    child: _WriteReviewDialog(controller: controller),
  );
}

void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            showSnackBar(context, 'Logout action pending');
          },
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}

void showDeleteAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Account'),
      content: const Text(
        'This action cannot be undone. All data will be permanently deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            showSnackBar(context, 'Account deletion requires verification');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _closeOverlay(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.pop();
  }
}

void _showReviewsModal(BuildContext context, {required int initialTab}) {
  _showProfileDialog(
    context,
    width: 84.w,
    height: 69.h,
    child: _ReviewsContent(initialTab: initialTab),
  );
}

class _ReviewsContent extends StatefulWidget {
  final int initialTab;
  const _ReviewsContent({required this.initialTab});

  @override
  State<_ReviewsContent> createState() => _ReviewsContentState();
}

class _ReviewsContentState extends State<_ReviewsContent> {
  late int activeTab = widget.initialTab;
  List<Map<String, dynamic>> _myReviews = [];
  List<Map<String, dynamic>> _communityReviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final results = await Future.wait([
      ApiService.fetchMyReviews(accessToken: token),
      ApiService.fetchCommunityReviews(),
    ]);
    if (mounted) {
      setState(() {
        _myReviews = results[0];
        _communityReviews = results[1]
            .where((r) => r['status'] == null || r['status'] == 'approved')
            .toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _tabButton('My Reviews', 0),
            SizedBox(width: 6.w),
            _tabButton('Community Reviews', 1),
            const Spacer(),
            IconButton(
              onPressed: () => _closeOverlay(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else if (activeTab == 0) ...[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 3.w,
            runSpacing: 1.2.h,
            children: [
              Text(
                'Your Reviews',
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1D2538)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _closeOverlay(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showWriteReviewModal(context);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A485F),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 2.8.w, vertical: 1.h),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Write Review', style: TextStyle(fontSize: 12.sp)),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_myReviews.isEmpty)
            Expanded(child: Center(child: Text('No reviews yet.\nWrite one after a trip.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6D7587), height: 1.6))))
          else
            Expanded(
              child: ListView.separated(
                itemCount: _myReviews.length,
                separatorBuilder: (_, _) => SizedBox(height: 2.2.h),
                itemBuilder: (context, index) => _myReviewCardFromMap(_myReviews[index]),
              ),
            ),
        ] else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Community Reviews',
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1D2538)),
            ),
          ),
          SizedBox(height: 1.2.h),
          if (_communityReviews.isEmpty)
            Expanded(child: Center(child: Text('No community reviews yet.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6D7587)))))
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: ListView.separated(
                  padding: EdgeInsets.all(3.2.w),
                  itemCount: _communityReviews.length,
                  separatorBuilder: (_, _) => Divider(height: 3.h, color: const Color(0xFFE6E8ED)),
                  itemBuilder: (context, index) => _communityReviewCardFromMap(_communityReviews[index]),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => activeTab = index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFF4783BC) : const Color(0xFF35363B),
            ),
          ),
          SizedBox(height: 0.7.h),
          Container(
            width: 8.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF4783BC) : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _myReviewCardFromMap(Map<String, dynamic> r) {
    final rating = (r['rating'] as num?)?.toInt() ?? 0;
    final date = (r['created_at'] as String? ?? '').split('T').first;
    final likes = (r['likes_count'] ?? 0).toString();
    final comments = (r['comments_count'] ?? 0).toString();
    final status = r['status'] as String? ?? 'approved';
    final isPending = status == 'pending';
    final isRejected = status == 'rejected';
    final rejectionReason = r['rejection_reason'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isPending)
          Container(
            margin: EdgeInsets.only(bottom: 1.h),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD54F)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    size: 14, color: Color(0xFFB7860B)),
                SizedBox(width: 1.5.w),
                Text(
                  'Awaiting admin approval',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF7A5C00),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        if (isRejected)
          Container(
            margin: EdgeInsets.only(bottom: 1.h),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEF9A9A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cancel_outlined,
                        size: 14, color: Color(0xFFC62828)),
                    SizedBox(width: 1.5.w),
                    Text(
                      'Not approved by admin',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFFC62828),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
                  SizedBox(height: 0.3.h),
                  Text(
                    'Reason: $rejectionReason',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: const Color(0xFF8B0000),
                    ),
                  ),
                ],
              ],
            ),
          ),
        Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20.w,
          height: 10.5.h,
          decoration: BoxDecoration(
            color: const Color(0xFFD8E6FB),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.place_outlined, color: const Color(0xFF2F7BF2), size: 8.w),
        ),
        SizedBox(width: 3.2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r['place_name'] as String? ?? 'Place',
                style: TextStyle(fontSize: 18.sp, color: const Color(0xFF1D2438))),
              SizedBox(height: 0.6.h),
              Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 2.5.w,
                color: i < rating ? const Color(0xFFFFC107) : const Color(0xFFE4E7ED)))),
              SizedBox(height: 0.8.h),
              Text(r['review_text'] as String? ?? '',
                style: TextStyle(fontSize: 13.7.sp, height: 1.45, color: const Color(0xFF576276))),
              SizedBox(height: 0.8.h),
              Row(children: [
                Text(date, style: TextStyle(fontSize: 11.7.sp, color: const Color(0xFF98A2B5))),
                SizedBox(width: 4.w),
                const Icon(Icons.thumb_up_alt_outlined, color: Color(0xFF9DA7B8)),
                SizedBox(width: 1.w),
                Text(likes, style: const TextStyle(color: Color(0xFF8A94A7))),
                SizedBox(width: 3.w),
                const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF9DA7B8)),
                SizedBox(width: 1.w),
                Text(comments, style: const TextStyle(color: Color(0xFF8A94A7))),
              ]),
            ],
          ),
        ),
      ],
    ),
      ],
    );
  }

  Widget _communityReviewCardFromMap(Map<String, dynamic> r) {
    final rating = (r['rating'] as num?)?.toInt() ?? 0;
    final likes = (r['likes_count'] ?? 0).toString();
    final comments = (r['comments_count'] ?? 0).toString();
    final createdAt = r['created_at'] as String? ?? '';
    final timeAgo = createdAt.isEmpty ? '' : createdAt.split('T').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(r['user_name'] as String? ?? 'User',
            style: TextStyle(fontSize: 15.3.sp, color: const Color(0xFF1B2234))),
          SizedBox(width: 1.6.w),
          const CircleAvatar(radius: 10, backgroundColor: Color(0xFF347AF1),
            child: Icon(Icons.check, color: Colors.white, size: 14)),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
            decoration: BoxDecoration(color: const Color(0xFFF0F1F5), borderRadius: BorderRadius.circular(14)),
            child: Text(r['user_badge'] as String? ?? 'Explorer',
              style: TextStyle(fontSize: 10.8.sp, color: const Color(0xFF556075))),
          ),
          SizedBox(width: 3.w),
          Text(timeAgo, style: TextStyle(fontSize: 11.8.sp, color: const Color(0xFF96A0B2))),
        ]),
        SizedBox(height: 1.2.h),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 18.w, height: 9.4.h,
            decoration: BoxDecoration(color: const Color(0xFFD8E6FB), borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.place_outlined, color: const Color(0xFF2F7BF2), size: 7.w),
          ),
          SizedBox(width: 3.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r['place_name'] as String? ?? 'Place',
              style: TextStyle(fontSize: 16.8.sp, color: const Color(0xFF20283A))),
            SizedBox(height: 0.5.h),
            Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 2.3.w,
              color: i < rating ? const Color(0xFFFFC107) : const Color(0xFFE4E7ED)))),
            SizedBox(height: 0.6.h),
            Text(r['review_text'] as String? ?? '', maxLines: 4, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.4.sp, height: 1.45, color: const Color(0xFF556075))),
          ])),
        ]),
        SizedBox(height: 1.1.h),
        Row(children: [
          const Icon(Icons.thumb_up_alt_outlined, color: Color(0xFF717B91)),
          SizedBox(width: 1.2.w),
          Text(likes, style: const TextStyle(color: Color(0xFF717B91))),
          SizedBox(width: 5.w),
          const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF717B91)),
          SizedBox(width: 1.2.w),
          Text(comments, style: const TextStyle(color: Color(0xFF717B91))),
        ]),
      ],
    );
  }
}

Future<void> _showProfileDialog(
  BuildContext context, {
  required double width,
  required double height,
  required Widget child,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'profile-dialog',
    barrierColor: Colors.black.withOpacity(0.25),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: width,
            height: height,
            padding: EdgeInsets.fromLTRB(4.4.w, 2.3.h, 4.4.w, 2.3.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFDFC),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Widget _dialogHeader(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Color iconColor,
}) {
  return Row(
    children: [
      Icon(icon, color: iconColor, size: 4.3.w),
      SizedBox(width: 2.2.w),
      Text(
        title,
        style: TextStyle(
          fontSize: 18.5.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1C2438),
        ),
      ),
      const Spacer(),
      IconButton(
        onPressed: () => _closeOverlay(context),
        icon: const Icon(Icons.close_rounded),
      ),
    ],
  );
}

Widget _pickerTile({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return ListTile(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    leading: Icon(icon, color: const Color(0xFF2F7BF2)),
    title: Text(title),
    onTap: onTap,
  );
}


Widget _achievementCard(_AchievementData item) {
  return Container(
    padding: EdgeInsets.all(2.5.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: CircleAvatar(
            radius: 5.3.w,
            backgroundColor: item.color,
            child: Icon(item.icon, color: Colors.white, size: 5.8.w),
          ),
        ),
        SizedBox(height: 2.2.h),
        Text(
          item.title,
          style: TextStyle(fontSize: 15.sp, color: const Color(0xFF20283A)),
        ),
        SizedBox(height: 0.8.h),
        Text(
          item.subtitle,
          style: TextStyle(fontSize: 11.3.sp, color: const Color(0xFF737A8C)),
        ),
        const Spacer(),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            minHeight: 1.1.h,
            value: item.progress,
            backgroundColor: const Color(0xFFCBCDD4),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF0E0B29)),
          ),
        ),
      ],
    ),
  );
}



Widget _routeMetric(IconData? icon, String value) {
  return Row(
    children: [
      if (icon != null) ...[
        Icon(icon, size: 14, color: const Color(0xFF7C8495)),
        SizedBox(width: 0.7.w),
      ],
      Text(
        value,
        style: TextStyle(fontSize: 11.5.sp, color: const Color(0xFF657083)),
      ),
    ],
  );
}

Widget _dot() {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 1.8.w),
    child: const Text('|', style: TextStyle(color: Color(0xFF788194))),
  );
}

class _WriteReviewDialog extends StatefulWidget {
  final TextEditingController controller;

  const _WriteReviewDialog({required this.controller});

  @override
  State<_WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<_WriteReviewDialog> {
  int rating = 0;
  final _placeController = TextEditingController();
  bool _submitting = false;
  List<XFile> _pickedImages = [];

  @override
  void dispose() {
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Write a Review',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _closeOverlay(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  'Place Name',
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    color: const Color(0xFF5C6579),
                  ),
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: _placeController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'e.g. Sigiriya Rock Fortress',
                    hintStyle: const TextStyle(color: Color(0xFF8A90A1)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFDCE0E8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF9FBDE6)),
                    ),
                  ),
                ),
                SizedBox(height: 2.4.h),
                Text(
                  'Rating',
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    color: const Color(0xFF5C6579),
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: List.generate(5, (index) {
                    final filled = index < rating;
                    return GestureDetector(
                      onTap: () => setState(() => rating = index + 1),
                      child: Padding(
                        padding: EdgeInsets.only(right: 1.8.w),
                        child: Icon(
                          Icons.star_rounded,
                          size: 5.2.w,
                          color: filled
                              ? const Color(0xFFFFC107)
                              : const Color(0xFFE4E7ED),
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 2.2.h),
                Text(
                  'Your Review',
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    color: const Color(0xFF5C6579),
                  ),
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: widget.controller,
                  maxLines: 5,
                  maxLength: 500,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Share your experience...',
                    hintStyle: const TextStyle(color: Color(0xFF8A90A1)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFDCE0E8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF9FBDE6)),
                    ),
                  ),
                ),
                SizedBox(height: 0.6.h),
                Text(
                  '${widget.controller.text.length}/500 characters',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    color: const Color(0xFF7F8798),
                  ),
                ),
                SizedBox(height: 1.7.h),
                OutlinedButton.icon(
                  onPressed: () async {
                    final images = await ImagePicker().pickMultiImage();
                    if (images.isNotEmpty) {
                      setState(() => _pickedImages = images);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 6.h),
                    side: const BorderSide(color: Color(0xFFD6DCE6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    _pickedImages.isEmpty
                        ? 'Add Photos (Optional)'
                        : '${_pickedImages.length} photo${_pickedImages.length == 1 ? '' : 's'} selected',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
                const Spacer(),
                SizedBox(height: 1.8.h),
                ElevatedButton.icon(
                  onPressed: (rating == 0 || _placeController.text.trim().isEmpty || _submitting)
                      ? null
                      : () async {
                          setState(() => _submitting = true);
                          final token = Supabase.instance.client.auth.currentSession?.accessToken;
                          final ok = await ApiService.submitReview(
                            placeName: _placeController.text.trim(),
                            rating: rating,
                            reviewText: widget.controller.text.trim().isEmpty ? null : widget.controller.text.trim(),
                            accessToken: token,
                          );
                          if (!mounted) return;
                          setState(() => _submitting = false);
                          _closeOverlay(context);
                          showSnackBar(
                            context,
                            ok
                                ? 'Your review has been submitted and is awaiting approval.'
                                : 'Failed to submit review. Please try again.',
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 6.h),
                    backgroundColor: (rating == 0 || _placeController.text.trim().isEmpty) ? const Color(0xFFA6ACB6) : const Color(0xFF2F7BF2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    'Submit Review',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
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


class _AchievementData {
  final String title;
  final String subtitle;
  final double progress;
  final Color color;
  final IconData icon;

  const _AchievementData({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
    required this.icon,
  });
}


