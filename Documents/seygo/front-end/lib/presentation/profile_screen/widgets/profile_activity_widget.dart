import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

enum ActivityType { trip, review, photo, placeAdded }

class UserActivity {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? imageUrl;
  final String? location;

  const UserActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.imageUrl,
    this.location,
  });
}

/// =========================================================================
/// PROFILE ACTIVITY TIMELINE WIDGET
/// =========================================================================
/// A vertically sprawling timeline charting the user's travel history,
/// utilizing complex `CustomPainter` to draw connected nodes and stems.
class ProfileActivityWidget extends StatelessWidget {
  final List<UserActivity> activities;
  final bool isCompact;

  const ProfileActivityWidget({
    super.key,
    required this.activities,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 4.w : 5.w),
          child: Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: isCompact ? 16.sp : 18.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.tertiaryLight,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 4.w : 5.w),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            final isFirst = index == 0;
            final isLast = index == activities.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timeline visual element (Stem & Node)
                  SizedBox(
                    width: 10.w,
                    child: CustomPaint(
                      painter: _TimelinePainter(
                        isFirst: isFirst,
                        isLast: isLast,
                        context: context,
                        type: activity.type,
                      ),
                    ),
                  ),
                  
                  // Activity Card Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: isLast ? 0 : 3.h,
                        left: 2.w,
                      ),
                      child: _buildActivityCard(activity, context),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard(UserActivity activity, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activity.imageUrl != null)
            Image.network(
              activity.imageUrl!,
              height: 12.h,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 13.sp : 14.sp,
                          color: AppTheme.tertiaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatDate(activity.timestamp),
                      style: TextStyle(
                        fontSize: isCompact ? 9.sp : 10.sp,
                        color: AppTheme.neutralLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.8.h),
                Text(
                  activity.description,
                  style: TextStyle(
                    fontSize: isCompact ? 11.sp : 12.sp,
                    color: AppTheme.neutralLight.withOpacity(0.8),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (activity.location != null) ...[
                  SizedBox(height: 1.5.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppTheme.primaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.location!,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

/// Custom painter mapping out the vertical line and structural dots
class _TimelinePainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final BuildContext context;
  final ActivityType type;

  const _TimelinePainter({
    required this.isFirst,
    required this.isLast,
    required this.context,
    required this.type,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Determine colors
    Color nodeColor = AppTheme.primaryLight;
    if (type == ActivityType.review) nodeColor = AppTheme.secondaryLight;
    if (type == ActivityType.photo) nodeColor = const Color(0xFFE91E63);

    final linePaint = Paint()
      ..color = AppTheme.dividerLight
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = nodeColor
      ..style = PaintingStyle.fill;
      
    final shadowPaint = Paint()
      ..color = nodeColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final centerX = size.width / 2;
    final nodeY = 24.0; // Y offset for the circle to align with title

    // Draw the vertical stem
    if (!isFirst) {
      canvas.drawLine(Offset(centerX, 0), Offset(centerX, nodeY - 10), linePaint);
    }
    if (!isLast) {
      canvas.drawLine(Offset(centerX, nodeY + 10), Offset(centerX, size.height), linePaint);
    }

    // Draw Node shadow
    canvas.drawCircle(Offset(centerX, nodeY), 8, shadowPaint);
    
    // Draw Node Body
    canvas.drawCircle(Offset(centerX, nodeY), 6, nodePaint);
    
    // Draw Node Inner Ring
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(centerX, nodeY), 3, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.type != type;
  }
}
