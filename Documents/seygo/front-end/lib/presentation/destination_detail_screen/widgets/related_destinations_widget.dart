import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Related destinations horizontal carousel
class RelatedDestinationsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> destinations;
  final Function(Map<String, dynamic>) onDestinationTap;

  const RelatedDestinationsWidget({
    super.key,
    required this.destinations,
    required this.onDestinationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(left: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: Text(
              'Related Destinations',
              style: theme.textTheme.titleLarge,
            ),
          ),
          SizedBox(height: 2.h),

          // Horizontal scrolling list
          SizedBox(
            height: 28.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: destinations.length,
              separatorBuilder: (context, index) => SizedBox(width: 3.w),
              itemBuilder: (context, index) {
                final destination = destinations[index];
                return GestureDetector(
                  onTap: () => onDestinationTap(destination),
                  child: Container(
                    width: 45.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(4.w),
                      border: Border.all(color: theme.dividerColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Destination image
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4.w),
                            topRight: Radius.circular(4.w),
                          ),
                          child: CustomImageWidget(
                            imageUrl: destination["image"] as String,
                            width: 45.w,
                            height: 18.h,
                            fit: BoxFit.cover,
                            semanticLabel:
                            destination["semanticLabel"] as String,
                          ),
                        ),

                        // Destination info
                        Padding(
                          padding: EdgeInsets.all(3.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destination["name"] as String,
                                style: theme.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 0.5.h),
                              Row(
                                children: [
                                  CustomIconWidget(
                                    iconName: 'location_on',
                                    color: theme.colorScheme.onSurfaceVariant,
                                    size: 4.w,
                                  ),
                                  SizedBox(width: 1.w),
                                  Expanded(
                                    child: Text(
                                      destination["location"] as String,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}
