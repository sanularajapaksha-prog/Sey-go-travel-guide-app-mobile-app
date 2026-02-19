import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class MapFilterWidget extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const MapFilterWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final categories = [
      {'name': 'All', 'icon': 'explore'},
      {'name': 'Camping', 'icon': 'camping'},
      {'name': 'Beach Side', 'icon': 'beach_access'},
      {'name': 'Mountains', 'icon': 'terrain'},
      {'name': 'Temples', 'icon': 'temple_buddhist'},
    ];

    return Container(
      height: 8.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1.0),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        itemCount: categories.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['name'];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onCategorySelected(category['name'] as String),
              borderRadius: BorderRadius.circular(24.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: category['icon'] as String,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      category['name'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
