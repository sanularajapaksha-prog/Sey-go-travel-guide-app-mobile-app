import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

/// =========================================================================
/// TRAVEL DNA WIDGET
/// =========================================================================
/// Lets users set their travel style and working type.
/// Budget slider removed — replaced by a meaningful working-type selector.
/// AI-ready: working_type and travel_style are stored in Supabase profiles.
class ProfilePreferencesWidget extends StatefulWidget {
  final String initialStyle;
  final String initialWorkingType;
  final ValueChanged<String>? onWorkingTypeChanged;
  final bool isCompact;

  const ProfilePreferencesWidget({
    super.key,
    this.initialStyle = 'Adventure & Hiking',
    this.initialWorkingType = '',
    this.onWorkingTypeChanged,
    this.isCompact = false,
  });

  @override
  State<ProfilePreferencesWidget> createState() =>
      _ProfilePreferencesWidgetState();
}

class _ProfilePreferencesWidgetState
    extends State<ProfilePreferencesWidget> {
  late String _selectedStyle;
  late String _selectedWorkingType;

  final List<String> _availableStyles = [
    'Beach & Culture',
    'Adventure & Hiking',
    'Urban Exploration',
    'Nature & Wildlife',
    'Relaxation & Spa',
    'Historical Trails',
    'Culinary Tours',
  ];

  /// Working types with icon + label pairs.
  static const List<({String type, IconData icon})> _workingTypes = [
    (type: 'Solo Traveler', icon: Icons.person_rounded),
    (type: 'Couple', icon: Icons.favorite_rounded),
    (type: 'Family', icon: Icons.family_restroom_rounded),
    (type: 'Group', icon: Icons.groups_rounded),
    (type: 'Digital Nomad', icon: Icons.laptop_mac_rounded),
    (type: 'Business', icon: Icons.business_center_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.initialStyle;
    _selectedWorkingType = widget.initialWorkingType;
  }

  @override
  void didUpdateWidget(ProfilePreferencesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialWorkingType != widget.initialWorkingType &&
        widget.initialWorkingType.isNotEmpty) {
      _selectedWorkingType = widget.initialWorkingType;
    }
    if (oldWidget.initialStyle != widget.initialStyle &&
        widget.initialStyle.isNotEmpty) {
      _selectedStyle = widget.initialStyle;
    }
  }

  void _selectWorkingType(String type) {
    setState(() => _selectedWorkingType = type);
    widget.onWorkingTypeChanged?.call(type);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ───────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 0 : 0),
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
        SizedBox(height: 2.h),

        // ── Travel Style chips ────────────────────────────────────────────
        Text(
          'Travel Style',
          style: TextStyle(
            fontSize: widget.isCompact ? 12.sp : 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutralLight,
          ),
        ),
        SizedBox(height: 1.2.h),
        _buildStyleSelector(),
        SizedBox(height: 3.h),

        // ── Working Type ──────────────────────────────────────────────────
        Text(
          'How do you travel?',
          style: TextStyle(
            fontSize: widget.isCompact ? 12.sp : 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutralLight,
          ),
        ),
        SizedBox(height: 1.5.h),
        _buildWorkingTypeGrid(),
      ],
    );
  }

  Widget _buildStyleSelector() {
    return SizedBox(
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
                color: isSelected ? Colors.white : AppTheme.neutralLight,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.normal,
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
    );
  }

  Widget _buildWorkingTypeGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2.h,
        crossAxisSpacing: 3.w,
        childAspectRatio: 1.1,
      ),
      itemCount: _workingTypes.length,
      itemBuilder: (context, index) {
        final item = _workingTypes[index];
        final isSelected = _selectedWorkingType == item.type;
        return GestureDetector(
          onTap: () => _selectWorkingType(item.type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.secondaryLight
                  : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppTheme.secondaryLight
                    : AppTheme.dividerLight,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color:
                            AppTheme.secondaryLight.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: widget.isCompact ? 7.w : 8.w,
                  color: isSelected
                      ? Colors.white
                      : AppTheme.neutralLight,
                ),
                SizedBox(height: 1.h),
                Text(
                  item.type,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: widget.isCompact ? 11.sp : 12.sp,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.tertiaryLight,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
