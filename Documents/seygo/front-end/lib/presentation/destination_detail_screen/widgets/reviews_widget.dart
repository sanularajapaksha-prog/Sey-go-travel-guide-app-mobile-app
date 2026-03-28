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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 4.w,
                        backgroundColor: AppTheme.secondaryLight.withValues(alpha: 0.2),
                        child: Text(
                          (r["user_name"] as String?)?.substring(0, 1).toUpperCase() ?? 'U',
                          style: TextStyle(color: AppTheme.secondaryLight, fontWeight: FontWeight.bold, fontSize: 10.sp),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r["user_name"] as String? ?? 'User', style: theme.textTheme.titleSmall),
                            _buildStars(r["rating"] as int? ?? 5),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  if ((r["review_text"] as String?)?.isNotEmpty == true)
                    Text(
                      r["review_text"] as String,
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
