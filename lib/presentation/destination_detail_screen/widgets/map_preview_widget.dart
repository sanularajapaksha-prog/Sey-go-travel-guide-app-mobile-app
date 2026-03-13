import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Map preview section with navigation button
class MapPreviewWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String locationName;
  final VoidCallback onNavigate;

  const MapPreviewWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location', style: theme.textTheme.titleLarge),
          SizedBox(height: 2.h),

          // Map preview container
          Container(
            height: 25.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(3.w),
              border: Border.all(color: theme.dividerColor, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3.w),
              child: Stack(
                children: [
                  // Static map preview image
                  CustomImageWidget(
                    imageUrl:
                    'https://maps.googleapis.com/maps/api/staticmap?center=$latitude,$longitude&zoom=14&size=600x400&markers=color:red%7C$latitude,$longitude&key=YOUR_GOOGLE_MAPS_API_KEY_HERE',
                    width: double.infinity,
                    height: 25.h,
                    fit: BoxFit.cover,
                    semanticLabel: 'Map showing location of $locationName',
                  ),

                  // Navigate button overlay
                  Positioned(
                    bottom: 2.h,
                    right: 3.w,
                    child: ElevatedButton.icon(
                      onPressed: onNavigate,
                      icon: CustomIconWidget(
                        iconName: 'directions',
                        color: theme.colorScheme.onPrimary,
                        size: 5.w,
                      ),
                      label: Text('Navigate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.5.h,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
