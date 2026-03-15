import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

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
  final routes = <_SavedRoute>[
    const _SavedRoute(
      imageUrl: 'https://images.unsplash.com/photo-1548013146-72479768bada',
      title: 'Kandy to Nuwara Eliya',
      date: '12 Aug\n2025',
      distance: '124\nkm',
      duration: '3h\n10m',
      tag: 'Hill Country',
      stops: '5 stops',
      isPublic: true,
      meta: '342 views | 28\nlikes',
    ),
    const _SavedRoute(
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
      title: 'Colombo to Galle',
      date: '18 Aug\n2025',
      distance: '156\nkm',
      duration: '2h\n45m',
      tag: 'Coastal Drive',
      stops: '7 stops',
      isPublic: false,
      meta: 'Only you can see this',
    ),
    const _SavedRoute(
      imageUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
      title: 'Ella to Arugam Bay',
      date: '25 Aug\n2025',
      distance: '198\nkm',
      duration: '4h\n20m',
      tag: 'Weekend Trip',
      stops: '8 stops',
      isPublic: true,
      meta: '567 views | 45\nlikes',
    ),
  ];

  _showProfileDialog(
    context,
    width: 84.w,
    height: 68.h,
    child: StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogHeader(
              context,
              title: 'Saved Routes',
              icon: Icons.route_outlined,
              iconColor: const Color(0xFF2F7BF2),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: ListView.separated(
                itemCount: routes.length,
                separatorBuilder: (_, __) => SizedBox(height: 1.7.h),
                itemBuilder: (context, index) {
                  final route = routes[index];
                  return _savedRouteCard(
                    route,
                    onToggle: () => setState(() {
                      routes[index] = route.copyWith(isPublic: !route.isPublic);
                    }),
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}

void showAchievementsModal(BuildContext context) {
  const achievements = [
    _AchievementData(
      title: 'Mountain Explorer',
      subtitle: 'Level 2 | 8/10 places',
      progress: 0.7,
      color: Color(0xFFFF7308),
      icon: Icons.landscape_outlined,
    ),
    _AchievementData(
      title: 'Beach Lover',
      subtitle: 'Level 3 | 12/15 places',
      progress: 0.68,
      color: Color(0xFF19B5D8),
      icon: Icons.beach_access_outlined,
    ),
    _AchievementData(
      title: 'City Hopper',
      subtitle: 'Level 1 | 4/5 places',
      progress: 0.7,
      color: Color(0xFF9D46F8),
      icon: Icons.apartment_outlined,
    ),
    _AchievementData(
      title: 'Local Guide',
      subtitle: 'Level 2 | 6/8 places',
      progress: 0.68,
      color: Color(0xFF11C0B2),
      icon: Icons.explore_outlined,
    ),
    _AchievementData(
      title: 'Hidden Gem Finder',
      subtitle: 'Level 1 | 3/6 places',
      progress: 0.52,
      color: Color(0xFFFFA008),
      icon: Icons.workspace_premium_outlined,
    ),
    _AchievementData(
      title: 'Route Master',
      subtitle: 'Level 2 | 7/10 places',
      progress: 0.68,
      color: Color(0xFF367AF1),
      icon: Icons.map_outlined,
    ),
  ];

  _showProfileDialog(
    context,
    width: 84.w,
    height: 70.h,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dialogHeader(
          context,
          title: 'Achievements',
          icon: Icons.emoji_events_outlined,
          iconColor: const Color(0xFFFF9800),
        ),
        SizedBox(height: 2.h),
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
        Text(
          'Next milestone',
          style: TextStyle(fontSize: 16.sp, color: const Color(0xFF6F788D)),
        ),
        SizedBox(height: 0.8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Visit 2 more mountains',
              style: TextStyle(
                fontSize: 16.5.sp,
                color: const Color(0xFF334055),
              ),
            ),
            Text(
              '80%',
              style: TextStyle(fontSize: 16.sp, color: const Color(0xFF6F788D)),
            ),
          ],
        ),
        SizedBox(height: 1.1.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            minHeight: 1.1.h,
            value: 0.8,
            backgroundColor: const Color(0xFFD0D3DB),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF0E0B29)),
          ),
        ),
      ],
    ),
  );
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
  const myReviews = [
    _MyReview(
      imageUrl: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa',
      place: 'Sigiriya Rock Fortress',
      rating: 5,
      review:
          'Absolutely breathtaking views from the top! The climb is worth every step.',
      date: '15 Dec 2024',
      likes: '24',
      comments: '5',
    ),
    _MyReview(
      imageUrl: 'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429',
      place: 'Ella Rock Hike',
      rating: 4,
      review:
          'Beautiful trail through tea plantations. Early morning start recommended.',
      date: '08 Dec 2024',
      likes: '18',
      comments: '3',
    ),
    _MyReview(
      imageUrl: 'https://images.unsplash.com/photo-1470770841072-f978cf4d019e',
      place: 'Yala National Park',
      rating: 4,
      review:
          'Saw leopards and elephants! Great safari experience with knowledgeable guide.',
      date: '28 Nov 2024',
      likes: '42',
      comments: '9',
    ),
  ];

  const community = [
    _CommunityReview(
      user: 'Sarah Johnson',
      badge: 'Explorer',
      timeAgo: '2 days ago',
      title: "Adam's Peak (Sri Paada)",
      body:
          "Started the climb at 2 AM to catch sunrise. The view from the top is absolutely worth the challenging hike. Don't miss it.",
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
      likes: '127',
      comments: '23',
      rating: 5,
    ),
    _CommunityReview(
      user: 'Mike Chen',
      badge: 'Adventurer',
      timeAgo: '5 days ago',
      title: 'Horton Plains',
      body:
          "World's End is spectacular! Arrive early to avoid crowds and mist. Saw endemic wildlife. The cloud forest is magical.",
      imageUrl: 'https://images.unsplash.com/photo-1504593811423-6dd665756598',
      likes: '89',
      comments: '15',
      rating: 5,
    ),
    _CommunityReview(
      user: 'Emma Williams',
      badge: 'Local Guide',
      timeAgo: '1 week ago',
      title: 'Sigiriya Rock Fortress',
      body:
          'Ancient fortress is impressive! The frescoes halfway up are stunning. Can get crowded, so arrive early. Bring water and sun protection.',
      imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d',
      likes: '156',
      comments: '31',
      rating: 4,
    ),
  ];

  _showProfileDialog(
    context,
    width: 84.w,
    height: 69.h,
    child: _ReviewsDialog(
      initialTab: initialTab,
      myReviews: myReviews,
      communityReviews: community,
    ),
  );
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

Widget _savedRouteCard(_SavedRoute route, {required VoidCallback onToggle}) {
  return Container(
    padding: EdgeInsets.all(2.3.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE3E7ED)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                route.imageUrl,
                width: 22.w,
                height: 10.2.h,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 2.5.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.title,
                    style: TextStyle(
                      fontSize: 17.5.sp,
                      color: const Color(0xFF1F2639),
                    ),
                  ),
                  SizedBox(height: 0.8.h),
                  Row(
                    children: [
                      _routeMetric(Icons.calendar_today_outlined, route.date),
                      _dot(),
                      _routeMetric(null, route.distance),
                      _dot(),
                      _routeMetric(Icons.access_time_outlined, route.duration),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 0.7.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8E6FB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          route.tag,
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            color: const Color(0xFF1855E5),
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        route.stops,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF6D7587),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9BA4B6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 1.4.h),
        Row(
          children: [
            Icon(
              route.isPublic ? Icons.public : Icons.lock_outline_rounded,
              color: route.isPublic
                  ? const Color(0xFF337AF3)
                  : const Color(0xFF737B8E),
              size: 3.1.w,
            ),
            SizedBox(width: 2.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.isPublic ? 'Public' : 'Private',
                  style: TextStyle(
                    fontSize: 15.5.sp,
                    color: const Color(0xFF1B2235),
                  ),
                ),
                Text(
                  route.meta,
                  style: TextStyle(
                    fontSize: 11.8.sp,
                    color: const Color(0xFF6E778A),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (route.isPublic) ...[
              const Icon(Icons.share_outlined, color: Color(0xFF596275)),
              SizedBox(width: 1.5.w),
              Text(
                'Share',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFF596275),
                ),
              ),
              SizedBox(width: 4.w),
            ],
            Switch(
              value: route.isPublic,
              onChanged: (_) => onToggle(),
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
          style: TextStyle(
            fontSize: 15.sp,
            color: const Color(0xFF20283A),
          ),
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

Widget _myReviewCard(_MyReview review) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          review.imageUrl,
          width: 20.w,
          height: 10.5.h,
          fit: BoxFit.cover,
        ),
      ),
      SizedBox(width: 3.2.w),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              review.place,
              style: TextStyle(
                fontSize: 18.sp,
                color: const Color(0xFF1D2438),
              ),
            ),
            SizedBox(height: 0.6.h),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  Icons.star_rounded,
                  size: 2.5.w,
                  color: index < review.rating
                      ? const Color(0xFFFFC107)
                      : const Color(0xFFE4E7ED),
                );
              }),
            ),
            SizedBox(height: 0.8.h),
            Text(
              review.review,
              style: TextStyle(
                fontSize: 13.7.sp,
                height: 1.45,
                color: const Color(0xFF576276),
              ),
            ),
            SizedBox(height: 0.8.h),
            Row(
              children: [
                Text(
                  review.date,
                  style: TextStyle(
                    fontSize: 11.7.sp,
                    color: const Color(0xFF98A2B5),
                  ),
                ),
                SizedBox(width: 4.w),
                const Icon(
                  Icons.thumb_up_alt_outlined,
                  color: Color(0xFF9DA7B8),
                ),
                SizedBox(width: 1.w),
                Text(
                  review.likes,
                  style: const TextStyle(color: Color(0xFF8A94A7)),
                ),
                SizedBox(width: 3.w),
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF9DA7B8),
                ),
                SizedBox(width: 1.w),
                Text(
                  review.comments,
                  style: const TextStyle(color: Color(0xFF8A94A7)),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _communityReviewCard(_CommunityReview review) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            review.user,
            style: TextStyle(
              fontSize: 15.3.sp,
              color: const Color(0xFF1B2234),
            ),
          ),
          SizedBox(width: 1.6.w),
          const CircleAvatar(
            radius: 10,
            backgroundColor: Color(0xFF347AF1),
            child: Icon(Icons.check, color: Colors.white, size: 14),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              review.badge,
              style: TextStyle(
                fontSize: 10.8.sp,
                color: const Color(0xFF556075),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            review.timeAgo,
            style: TextStyle(
              fontSize: 11.8.sp,
              color: const Color(0xFF96A0B2),
            ),
          ),
        ],
      ),
      SizedBox(height: 1.2.h),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              review.imageUrl,
              width: 18.w,
              height: 9.4.h,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.title,
                  style: TextStyle(
                    fontSize: 16.8.sp,
                    color: const Color(0xFF20283A),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star_rounded,
                      size: 2.3.w,
                      color: index < review.rating
                          ? const Color(0xFFFFC107)
                          : const Color(0xFFE4E7ED),
                    );
                  }),
                ),
                SizedBox(height: 0.6.h),
                Text(
                  review.body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.4.sp,
                    height: 1.45,
                    color: const Color(0xFF556075),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      SizedBox(height: 1.1.h),
      Row(
        children: [
          const Icon(Icons.thumb_up_alt_outlined, color: Color(0xFF717B91)),
          SizedBox(width: 1.2.w),
          Text(review.likes, style: const TextStyle(color: Color(0xFF717B91))),
          SizedBox(width: 5.w),
          const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Color(0xFF717B91),
          ),
          SizedBox(width: 1.2.w),
          Text(
            review.comments,
            style: const TextStyle(color: Color(0xFF717B91)),
          ),
        ],
      ),
    ],
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

class _ReviewsDialog extends StatefulWidget {
  final int initialTab;
  final List<_MyReview> myReviews;
  final List<_CommunityReview> communityReviews;

  const _ReviewsDialog({
    required this.initialTab,
    required this.myReviews,
    required this.communityReviews,
  });

  @override
  State<_ReviewsDialog> createState() => _ReviewsDialogState();
}

class _ReviewsDialogState extends State<_ReviewsDialog> {
  late int activeTab = widget.initialTab;

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
        if (activeTab == 0) ...[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 3.w,
            runSpacing: 1.2.h,
            children: [
              Text(
                'Your Reviews',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D2538),
                ),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.8.w,
                    vertical: 1.h,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Write Review',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: ListView.separated(
              itemCount: widget.myReviews.length,
              separatorBuilder: (_, __) => SizedBox(height: 2.2.h),
              itemBuilder: (context, index) =>
                  _myReviewCard(widget.myReviews[index]),
            ),
          ),
        ] else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Community Reviews',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D2538),
              ),
            ),
          ),
          SizedBox(height: 1.2.h),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ListView.separated(
                padding: EdgeInsets.all(3.2.w),
                itemCount: widget.communityReviews.length,
                separatorBuilder: (_, __) => Divider(
                  height: 3.h,
                  color: const Color(0xFFE6E8ED),
                ),
                itemBuilder: (context, index) =>
                    _communityReviewCard(widget.communityReviews[index]),
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
              color: selected
                  ? const Color(0xFF4783BC)
                  : const Color(0xFF35363B),
            ),
          ),
          SizedBox(height: 0.7.h),
          Container(
            width: 8.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF4783BC)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ],
      ),
    );
  }
}

class _WriteReviewDialog extends StatefulWidget {
  final TextEditingController controller;

  const _WriteReviewDialog({required this.controller});

  @override
  State<_WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<_WriteReviewDialog> {
  int rating = 0;
  String selectedPlace = 'Sigiriya Rock Fortress';

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
                  'Select Place',
                  style: TextStyle(fontSize: 13.5.sp, color: const Color(0xFF5C6579)),
                ),
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCE0E8)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedPlace,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'Sigiriya Rock Fortress',
                          child: Text('Sigiriya Rock Fortress'),
                        ),
                        DropdownMenuItem(
                          value: 'Ella Rock Hike',
                          child: Text('Ella Rock Hike'),
                        ),
                        DropdownMenuItem(
                          value: 'Yala National Park',
                          child: Text('Yala National Park'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedPlace = value);
                      },
                    ),
                  ),
                ),
                SizedBox(height: 2.4.h),
                Text(
                  'Rating',
                  style: TextStyle(fontSize: 13.5.sp, color: const Color(0xFF5C6579)),
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
                  style: TextStyle(fontSize: 13.5.sp, color: const Color(0xFF5C6579)),
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
                  style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF7F8798)),
                ),
                SizedBox(height: 1.7.h),
                OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 6.h),
                    side: const BorderSide(color: Color(0xFFD6DCE6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    'Add Photos (Optional)',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
                const Spacer(),
                SizedBox(height: 1.8.h),
                ElevatedButton.icon(
                  onPressed: rating == 0
                      ? null
                      : () {
                          _closeOverlay(context);
                          showSnackBar(context, 'Review published');
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 6.h),
                    backgroundColor: const Color(0xFFA6ACB6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.send_outlined),
                  label: Text(
                    'Publish Review',
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

class _SavedRoute {
  final String imageUrl;
  final String title;
  final String date;
  final String distance;
  final String duration;
  final String tag;
  final String stops;
  final bool isPublic;
  final String meta;

  const _SavedRoute({
    required this.imageUrl,
    required this.title,
    required this.date,
    required this.distance,
    required this.duration,
    required this.tag,
    required this.stops,
    required this.isPublic,
    required this.meta,
  });

  _SavedRoute copyWith({bool? isPublic}) {
    final nextPublic = isPublic ?? this.isPublic;
    return _SavedRoute(
      imageUrl: imageUrl,
      title: title,
      date: date,
      distance: distance,
      duration: duration,
      tag: tag,
      stops: stops,
      isPublic: nextPublic,
      meta: nextPublic ? '342 views | 28\nlikes' : 'Only you can see this',
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

class _MyReview {
  final String imageUrl;
  final String place;
  final int rating;
  final String review;
  final String date;
  final String likes;
  final String comments;

  const _MyReview({
    required this.imageUrl,
    required this.place,
    required this.rating,
    required this.review,
    required this.date,
    required this.likes,
    required this.comments,
  });
}

class _CommunityReview {
  final String user;
  final String badge;
  final String timeAgo;
  final String title;
  final String body;
  final String imageUrl;
  final String likes;
  final String comments;
  final int rating;

  const _CommunityReview({
    required this.user,
    required this.badge,
    required this.timeAgo,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.rating,
  });
}
