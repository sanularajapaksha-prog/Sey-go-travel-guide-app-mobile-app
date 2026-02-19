import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class DestinationBottomSheetWidget extends StatelessWidget {
  final Map<String, dynamic> destination;
  final VoidCallback onViewDetails;
  final VoidCallback onAddToPlaylist;

  const DestinationBottomSheetWidget({
    super.key,
    required this.destination,
    required this.onViewDetails,
    required this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 2.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),

          SizedBox(height: 2.h),

          // Destination image
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: CustomImageWidget(
              imageUrl: destination['image'] as String,
              width: 90.w,
              height: 25.h,
              fit: BoxFit.cover,
              semanticLabel: destination['semanticLabel'] as String,
            ),
          ),

          SizedBox(height: 2.h),

          // Destination details
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        destination['name'] as String,
                        style: theme.textTheme.headlineSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'star',
                            color: Color(0xFFF59E0B),
                            size: 16,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${destination['rating']}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 1.h),

                Row(
                  children: [
                    CustomIconWidget(
                      iconName: _getCategoryIcon(
                        destination['category'] as String,
                      ),
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      destination['category'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    CustomIconWidget(
                      iconName: 'rate_review',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '${destination['reviews']} reviews',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                Text(
                  destination['description'] as String,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 3.h),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAddToPlaylist,
                        icon: CustomIconWidget(
                          iconName: 'playlist_add',
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        label: Text('Add to Cart'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onViewDetails,
                        icon: CustomIconWidget(
                          iconName: 'info',
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                        label: Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 3.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'Beach Side':
        return 'beach_access';
      case 'Mountains':
        return 'terrain';
      case 'Temples':
        return 'temple_buddhist';
      case 'Camping':
        return 'camping';
      default:
        return 'place';
    }
  }
}
