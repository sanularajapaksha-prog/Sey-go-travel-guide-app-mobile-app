import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Key highlights section with icon-based cards
class HighlightsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> highlights;

  const HighlightsWidget({super.key, required this.highlights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Key Highlights', style: theme.textTheme.titleLarge),
          SizedBox(height: 2.h),

          // Highlights grid
          Wrap(
            spacing: 3.w,
            runSpacing: 2.h,
            children: highlights.map((highlight) {
              return Container(
                width: 42.w,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(3.w),
                  border: Border.all(color: theme.dividerColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: highlight["icon"] as String,
                          color: theme.colorScheme.secondary,
                          size: 6.w,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.5.h),
                    Text(
                      highlight["title"] as String,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      highlight["description"] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
}
