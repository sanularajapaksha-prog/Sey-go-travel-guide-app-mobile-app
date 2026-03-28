import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/services/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class ReviewsWidget extends StatefulWidget {
  final Map<String, dynamic> destinationData;

  const ReviewsWidget({
    super.key,
    required this.destinationData,
  });

  @override
  State<ReviewsWidget> createState() => _ReviewsWidgetState();
}

class _ReviewsWidgetState extends State<ReviewsWidget> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final allReviews = await ApiService.fetchCommunityReviews();
    final placeId = (widget.destinationData["place_id"] ?? widget.destinationData["id"])?.toString() ?? '';

    if (mounted) {
      setState(() {
        _reviews = allReviews
            .where((r) =>
                (r["status"] == null || r["status"] == 'approved') &&
                (r["place_id"]?.toString() == placeId ||
                    r["place_name"] == widget.destinationData["name"]))
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    final text = _reviewController.text.trim();
    if (text.isEmpty) {
      Fluttertoast.showToast(msg: "Please write a review");
      return;
    }

    setState(() => _isSubmitting = true);

    final placeId = (widget.destinationData["place_id"] ?? widget.destinationData["id"])?.toString() ?? '';
    final token = Supabase.instance.client.auth.currentSession?.accessToken;

    final ok = await ApiService.submitReview(
      placeName: widget.destinationData["name"] ?? 'Unknown Place',
      rating: _rating,
      placeId: placeId,
      reviewText: text,
      accessToken: token,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (ok) {
        Fluttertoast.showToast(
          msg: "Your review has been submitted and is awaiting approval.",
          toastLength: Toast.LENGTH_LONG,
        );
        _reviewController.clear();
        setState(() => _rating = 5);
      } else {
        Fluttertoast.showToast(msg: "Failed to submit review. Please try again.");
      }
    }
  }

  Widget _buildStars(int currentRating, {bool interactive = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: interactive ? () => setState(() => _rating = index + 1) : null,
          child: Icon(
            index < currentRating ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.amber,
            size: interactive ? 7.w : 4.5.w,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reviews', style: theme.textTheme.titleMedium),
            if (_reviews.isNotEmpty)
              Text(
                '${_reviews.length} reviews',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        SizedBox(height: 2.h),

        // Write Review Box
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(4.w),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Write a Review', style: theme.textTheme.titleSmall),
              SizedBox(height: 1.5.h),
              _buildStars(_rating, interactive: true),
              SizedBox(height: 1.5.h),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(2.w)),
                  contentPadding: EdgeInsets.all(3.w),
                ),
              ),
              SizedBox(height: 1.5.h),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryLight,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSubmitting ? null : _submitReview,
                  child: _isSubmitting
                      ? SizedBox(width: 4.w, height: 4.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit for Review'),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // List of Reviews
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Text(
                'No reviews yet. Be the first to review!',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (context, index) => Divider(height: 4.h),
            itemBuilder: (context, index) {
              final r = _reviews[index];
              return _ReviewCard(review: r, theme: theme);
            },
          ),
      ],
    );
  }
}

// ── Per-review card with like + comment ──────────────────────────────────────

class _ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  final ThemeData theme;

  const _ReviewCard({required this.review, required this.theme});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  late int _likes;
  late int _comments;
  bool _liked = false;
  bool _likingInProgress = false;
  bool _showComments = false;
  bool _commentsLoading = false;
  List<Map<String, dynamic>> _commentList = [];
  final TextEditingController _commentCtrl = TextEditingController();
  bool _postingComment = false;

  @override
  void initState() {
    super.initState();
    _likes = (widget.review['likes_count'] as num?)?.toInt() ?? 0;
    _comments = (widget.review['comments_count'] as num?)?.toInt() ?? 0;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_likingInProgress) return;
    setState(() {
      _likingInProgress = true;
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
    final reviewId = widget.review['id']?.toString() ?? '';
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final newCount = await ApiService.likeReview(reviewId, accessToken: token);
    if (mounted) {
      setState(() {
        if (newCount != null) _likes = newCount;
        _likingInProgress = false;
      });
    }
  }

  Future<void> _loadComments() async {
    if (_commentsLoading) return;
    setState(() => _commentsLoading = true);
    final reviewId = widget.review['id']?.toString() ?? '';
    final items = await ApiService.fetchReviewComments(reviewId);
    if (mounted) {
      setState(() {
        _commentList = items;
        _commentsLoading = false;
      });
    }
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _postingComment) return;
    setState(() => _postingComment = true);
    final reviewId = widget.review['id']?.toString() ?? '';
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final result = await ApiService.addReviewComment(reviewId, text, accessToken: token);
    if (mounted) {
      setState(() {
        _postingComment = false;
        if (result != null) {
          _commentCtrl.clear();
          _commentList.add(result);
          _comments++;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    final theme = widget.theme;
    final rating = (r['rating'] as num?)?.toInt() ?? 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Author row
        Row(
          children: [
            CircleAvatar(
              radius: 4.w,
              backgroundColor: AppTheme.secondaryLight.withValues(alpha: 0.2),
              child: Text(
                (r['user_name'] as String?)
                        ?.substring(0, 1)
                        .toUpperCase() ??
                    'U',
                style: TextStyle(
                    color: AppTheme.secondaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.sp),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['user_name'] as String? ?? 'User',
                      style: theme.textTheme.titleSmall),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 3.5.w,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Review text
        if ((r['review_text'] as String?)?.isNotEmpty == true) ...[
          SizedBox(height: 1.h),
          Text(r['review_text'] as String, style: theme.textTheme.bodyMedium),
        ],

        SizedBox(height: 1.2.h),

        // Like + Comment action row
        Row(
          children: [
            // Like button
            GestureDetector(
              onTap: _toggleLike,
              child: Row(
                children: [
                  Icon(
                    _liked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                    size: 4.5.w,
                    color: _liked
                        ? AppTheme.secondaryLight
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '$_likes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _liked
                          ? AppTheme.secondaryLight
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          _liked ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 5.w),
            // Comment button
            GestureDetector(
              onTap: () {
                setState(() => _showComments = !_showComments);
                if (_showComments && _commentList.isEmpty) _loadComments();
              },
              child: Row(
                children: [
                  Icon(
                    _showComments
                        ? Icons.chat_bubble_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 4.5.w,
                    color: _showComments
                        ? AppTheme.secondaryLight
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '$_comments',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _showComments
                          ? AppTheme.secondaryLight
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Comment section
        if (_showComments) ...[
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment list
                if (_commentsLoading)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2)))
                else if (_commentList.isEmpty)
                  Text('No comments yet.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant))
                else
                  ...(_commentList.map((c) => Padding(
                        padding: EdgeInsets.only(bottom: 1.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 3.w,
                              backgroundColor:
                                  AppTheme.secondaryLight.withValues(alpha: 0.15),
                              child: Text(
                                (c['user_name'] as String?)
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    'U',
                                style: TextStyle(
                                    fontSize: 9.sp,
                                    color: AppTheme.secondaryLight),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['user_name'] as String? ?? 'User',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    c['comment_text'] as String? ?? '',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ))),

                SizedBox(height: 1.h),

                // Add comment input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        style: TextStyle(fontSize: 12.sp),
                        decoration: InputDecoration(
                          hintText: 'Add a comment…',
                          hintStyle: TextStyle(fontSize: 12.sp),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 3.w, vertical: 1.h),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                  color: theme.dividerColor)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                  color: theme.dividerColor)),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    _postingComment
                        ? SizedBox(
                            width: 7.w,
                            height: 7.w,
                            child: const CircularProgressIndicator(
                                strokeWidth: 2))
                        : IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.send_rounded,
                                size: 5.5.w,
                                color: AppTheme.secondaryLight),
                            onPressed: _postComment,
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
