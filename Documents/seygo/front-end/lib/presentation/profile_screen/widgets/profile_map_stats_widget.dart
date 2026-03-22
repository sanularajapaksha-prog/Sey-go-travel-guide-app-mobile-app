import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class ProvinceStat {
  final String name;
  final double exploredPercentage; // 0.0 to 1.0
  final int placesVisited;
  final IconData landmarkIcon;

  const ProvinceStat({
    required this.name,
    required this.exploredPercentage,
    required this.placesVisited,
    required this.landmarkIcon,
  });
}

/// =========================================================================
/// PROFILE MAP STATS WIDGET
/// =========================================================================
/// A visual representation of how much of Sri Lanka the user has explored.
/// Features complex animated progress bars and province-specific breakdown grids.
class ProfileMapStatsWidget extends StatefulWidget {
  final double overallExplored; // 0.0 to 1.0 representing total country covered
  final List<ProvinceStat> activeProvinces;
  final bool isCompact;

  const ProfileMapStatsWidget({
    super.key,
    this.overallExplored = 0.0,
    this.activeProvinces = const [],
    this.isCompact = false,
  });

  @override
  State<ProfileMapStatsWidget> createState() => _ProfileMapStatsWidgetState();
}

class _ProfileMapStatsWidgetState extends State<ProfileMapStatsWidget> 
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _animation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.isCompact ? 4.w : 5.w),
          child: Text(
            'Exploration Stats',
            style: TextStyle(
              fontSize: widget.isCompact ? 16.sp : 18.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.tertiaryLight,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.isCompact ? 4.w : 5.w),
          child: Container(
            padding: EdgeInsets.all(widget.isCompact ? 16.0 : 20.0),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.dividerLight),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryLight.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ]
            ),
            child: Column(
              children: [
                _buildOverallProgress(),
                SizedBox(height: 3.h),
                const Divider(height: 1, color: AppTheme.dividerLight),
                SizedBox(height: 2.5.h),
                _buildProvinceGrid(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverallProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sri Lanka Conquered',
                  style: TextStyle(
                    fontSize: widget.isCompact ? 11.sp : 12.sp,
                    color: AppTheme.neutralLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(widget.overallExplored * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: widget.isCompact ? 22.sp : 26.sp,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.tertiaryLight,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'of 9 Provinces',
                      style: TextStyle(
                        fontSize: widget.isCompact ? 9.sp : 10.sp,
                        color: AppTheme.neutralLight,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.map_rounded,
                color: AppTheme.primaryLight,
                size: 28,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.5.h),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: widget.overallExplored * _animation.value,
                minHeight: 12,
                backgroundColor: AppTheme.dividerLight,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProvinceGrid() {
    if (widget.activeProvinces.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Visit destinations to unlock province stats',
          style: TextStyle(
            fontSize: 11.sp,
            color: AppTheme.neutralLight,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: widget.isCompact ? 12.0 : 16.0,
        mainAxisSpacing: widget.isCompact ? 12.0 : 16.0,
        childAspectRatio: 2.1,
      ),
      itemCount: widget.activeProvinces.length,
      itemBuilder: (context, index) {
        final theme = Theme.of(context);
        final province = widget.activeProvinces[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerLight.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  province.landmarkIcon,
                  color: AppTheme.secondaryLight,
                  size: widget.isCompact ? 16 : 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      province.name,
                      style: TextStyle(
                        fontSize: widget.isCompact ? 9.5.sp : 10.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.tertiaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${province.placesVisited} Places',
                      style: TextStyle(
                        fontSize: widget.isCompact ? 8.sp : 9.sp,
                        color: AppTheme.neutralLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
