import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// =========================================================================
/// PROFILE PREFERENCES WIDGET
/// =========================================================================
/// An interactive component allowing users to mutate their travel style
/// and budget affinities directly from their public profile view, leveraging
/// smooth animations and ChoiceChips.
class ProfilePreferencesWidget extends StatefulWidget {
  final String initialStyle;
  final double initialBudgetMax;
  final bool isCompact;

  const ProfilePreferencesWidget({
    super.key,
    this.initialStyle = 'Adventure & Hiking',
    this.initialBudgetMax = 500.0,
    this.isCompact = false,
  });

  @override
  State<ProfilePreferencesWidget> createState() => _ProfilePreferencesWidgetState();
}

class _ProfilePreferencesWidgetState extends State<ProfilePreferencesWidget> {
  late String _selectedStyle;
  late double _currentBudget;

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
    _currentBudget = widget.initialBudgetMax;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.isCompact ? 4.w : 5.w),
          child: Row(
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
        ),
        SizedBox(height: 2.5.h),
        
        // Travel Style Chips (Horizontal Scroll)
        _buildStyleSelector(),
        
        SizedBox(height: 3.5.h),
        
        // Budget Slider Configuration
        _buildBudgetSlider(),
      ],
    );
  }

  Widget _buildStyleSelector() {
    return SizedBox(
      height: 6.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: widget.isCompact ? 4.w : 5.w),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _availableStyles.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final style = _availableStyles[index];
          final isSelected = _selectedStyle == style;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: ChoiceChip(
              label: Text(style),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedStyle = style);
                }
              },
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.neutralLight,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: widget.isCompact ? 11.sp : 12.sp,
              ),
              backgroundColor: Colors.white,
              selectedColor: AppTheme.secondaryLight,
              elevation: isSelected ? 4 : 0,
              padding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.2.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isSelected ? AppTheme.secondaryLight : AppTheme.dividerLight,
                  width: 1.5,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBudgetSlider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.isCompact ? 4.w : 5.w),
      child: Container(
        padding: EdgeInsets.all(widget.isCompact ? 16.0 : 20.0),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerLight),
          boxShadow: [
             BoxShadow(
               color: AppTheme.primaryLight.withOpacity(0.04),
               blurRadius: 10,
               offset: const Offset(0, 4),
             )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Comfort Budget',
                  style: TextStyle(
                    fontSize: widget.isCompact ? 12.sp : 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.tertiaryLight,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${_currentBudget.toInt()}',
                    style: TextStyle(
                      fontSize: widget.isCompact ? 13.sp : 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.primaryLight,
                inactiveTrackColor: AppTheme.dividerLight,
                trackHeight: 6.0,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                overlayColor: AppTheme.primaryLight.withOpacity(0.2),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                valueIndicatorShape: const RectangularSliderValueIndicatorShape(),
                valueIndicatorColor: AppTheme.primaryLight,
              ),
              child: Slider(
                value: _currentBudget,
                min: 50,
                max: 1000,
                divisions: 19,
                label: '\$${_currentBudget.toInt()}/day',
                onChanged: (value) {
                  setState(() => _currentBudget = value);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Backpacker (\$50)',
                  style: TextStyle(
                    fontSize: widget.isCompact ? 9.sp : 10.sp,
                    color: AppTheme.neutralLight,
                  ),
                ),
                Text(
                  'Luxury (\$1000+)',
                  style: TextStyle(
                    fontSize: widget.isCompact ? 9.sp : 10.sp,
                    color: AppTheme.neutralLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
