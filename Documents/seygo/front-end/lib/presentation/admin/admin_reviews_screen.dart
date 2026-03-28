import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/api_service.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final reviews = await ApiService.fetchPendingReviews(accessToken: token);
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _loading = false;
    });
  }

  Future<void> _approve(String reviewId) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final ok = await ApiService.approveReview(reviewId, accessToken: token);
    if (!mounted) return;
    if (ok) {
      setState(() => _reviews.removeWhere((r) => r['id']?.toString() == reviewId));
      Fluttertoast.showToast(msg: 'Review approved');
    } else {
      Fluttertoast.showToast(msg: 'Failed to approve');
    }
  }

  Future<void> _reject(String reviewId) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final ok = await ApiService.rejectReview(reviewId, accessToken: token);
    if (!mounted) return;
    if (ok) {
      setState(() => _reviews.removeWhere((r) => r['id']?.toString() == reviewId));
      Fluttertoast.showToast(msg: 'Review rejected');
    } else {
      Fluttertoast.showToast(msg: 'Failed to reject');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0828),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Panel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Pending Reviews',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 14.w,
                          color: Colors.green.shade400),
                      SizedBox(height: 2.h),
                      Text('All caught up!',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 0.8.h),
                      Text('No pending reviews to moderate.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.w, vertical: 2.h),
                    itemCount: _reviews.length,
                    separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
                    itemBuilder: (context, index) {
                      final r = _reviews[index];
                      return _ReviewCard(
                        review: r,
                        onApprove: () => _approve(r['id']?.toString() ?? ''),
                        onReject: () => _reject(r['id']?.toString() ?? ''),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ReviewCard({
    required this.review,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = (review['rating'] as num?)?.toInt() ?? 5;
    final userName = review['user_name'] as String? ?? 'User';
    final placeName = review['place_name'] as String? ?? '—';
    final text = review['review_text'] as String? ?? '';
    final createdAt = review['created_at'] as String? ?? '';
    final dateStr = createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0828).withOpacity(0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 4.5.w,
                  backgroundColor:
                      const Color(0xFF2F7BF2).withOpacity(0.15),
                  child: Text(
                    userName.isNotEmpty
                        ? userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        color: Color(0xFF2F7BF2),
                        fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(placeName,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 3.5.w,
                        ),
                      ),
                    ),
                    Text(dateStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 9.sp)),
                  ],
                ),
              ],
            ),
          ),

          // Review text
          if (text.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 1.4.h, 4.w, 1.4.h),
              child: Text(text, style: theme.textTheme.bodyMedium),
            )
          else
            SizedBox(height: 1.h),

          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(3.w, 0, 3.w, 1.4.h),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
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
}
