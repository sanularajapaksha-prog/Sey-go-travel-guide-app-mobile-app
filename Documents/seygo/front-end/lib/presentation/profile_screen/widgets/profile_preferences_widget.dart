import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// Travel DNA widget — shows travel style chip selector only.
class ProfilePreferencesWidget extends StatefulWidget {
  final String initialStyle;
  final bool isCompact;

  const ProfilePreferencesWidget({
    super.key,
    this.initialStyle = 'Adventure & Hiking',
    this.isCompact = false,
  });

  @override
  State<ProfilePreferencesWidget> createState() =>
      _ProfilePreferencesWidgetState();
}

class _ProfilePreferencesWidgetState
    extends State<ProfilePreferencesWidget> {
  late String _selectedStyle;

  final List<String> _availableStyles = [
    'Beach & Culture',
    'Adventure & Hiking',
    'Urban Exploration',
    'Nature & Wildlife',
    'Relaxation & Spa',
    'Historical Trails',
    'Culinary Tours',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.initialStyle;
  }

  @override
  void didUpdateWidget(ProfilePreferencesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStyle != widget.initialStyle &&
        widget.initialStyle.isNotEmpty) {
      _selectedStyle = widget.initialStyle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Travel DNA',
              style: TextStyle(
                fontSize: widget.isCompact ? 16.sp : 18.sp,
                fontWeight: FontWeight.w800,
                color: AppTheme.tertiaryLight,
              ),
            ),
            Text(
              'Edit',
              style: TextStyle(
                fontSize: widget.isCompact ? 12.sp : 13.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'Travel Style',
          style: TextStyle(
            fontSize: widget.isCompact ? 12.sp : 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutralLight,
          ),
        ),
        SizedBox(height: 1.2.h),
        SizedBox(
          height: 5.5.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _availableStyles.length,
            separatorBuilder: (_, _) => SizedBox(width: 2.w),
            itemBuilder: (context, index) {
              final style = _availableStyles[index];
              final isSelected = _selectedStyle == style;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: ChoiceChip(
                  label: Text(style),
                  selected: isSelected,
                  onSelected: (sel) {
                    if (sel) setState(() => _selectedStyle = style);
                  },
                  labelStyle: TextStyle(
                    color:
                        isSelected ? Colors.white : AppTheme.neutralLight,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                    fontSize: widget.isCompact ? 11.sp : 12.sp,
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.secondaryLight,
                  elevation: isSelected ? 3 : 0,
                  padding: EdgeInsets.symmetric(
                      horizontal: 3.w, vertical: 1.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.secondaryLight
                          : AppTheme.dividerLight,
                      width: 1.5,
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
