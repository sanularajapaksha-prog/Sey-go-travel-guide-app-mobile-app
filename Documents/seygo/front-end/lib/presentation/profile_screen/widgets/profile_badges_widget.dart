import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class TravelBadge {
  final String id;
  final String title;
  final String description;
  final IconData iconData;
  final bool isUnlocked;
  final double progress;

  const TravelBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconData,
    this.isUnlocked = false,
    this.progress = 0.0,
  });
}

/// =========================================================================
/// PROFILE BADGES WIDGET (GAMIFICATION)
/// =========================================================================
/// A sophisticated horizontal scrolling list of user achievements to 
/// encourage deeper app engagement.
class ProfileBadgesWidget extends StatefulWidget {
  final List<TravelBadge> badges;
  final bool isCompact;

  const ProfileBadgesWidget({
    super.key,
    required this.badges,
    this.isCompact = false,
  });

  @override
  State<ProfileBadgesWidget> createState() => _ProfileBadgesWidgetState();
}

class _ProfileBadgesWidgetState extends State<ProfileBadgesWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.badges.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.isCompact ? 4.w : 5.w),
          child: Text(
            'Achievements',
            style: TextStyle(
              fontSize: widget.isCompact ? 16.sp : 18.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.tertiaryLight,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: widget.isCompact ? 20.h : 22.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: widget.isCompact ? 4.w : 5.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.badges.length,
            separatorBuilder: (context, index) => SizedBox(width: 4.w),
            itemBuilder: (context, index) {
              final badge = widget.badges[index];
              return ScaleTransition(
                scale: _entranceAnimation,
                child: _buildBadgeCard(badge, theme),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(TravelBadge badge, ThemeData theme) {
    final cardWidth = widget.isCompact ? 40.w : 38.w;
    
    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: badge.isUnlocked ? AppTheme.surfaceLight : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: badge.isUnlocked ? AppTheme.primaryLight.withOpacity(0.4) : AppTheme.dividerLight,
          width: badge.isUnlocked ? 2 : 1,
        ),
        boxShadow: badge.isUnlocked
            ? [
                BoxShadow(
                  color: AppTheme.primaryLight.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (badge.isUnlocked)
              Positioned(
                right: -20,
                top: -20,
                child: Transform.rotate(
                  angle: pi / 6,
                  child: Icon(
                    badge.iconData,
                    size: 100,
                    color: AppTheme.primaryLight.withOpacity(0.05),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(widget.isCompact ? 12.0 : 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      color: badge.isUnlocked 
                          ? AppTheme.primaryLight 
                          : AppTheme.neutralLight.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      badge.iconData,
                      color: badge.isUnlocked ? Colors.white : AppTheme.neutralLight,
                      size: 7.w,
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  Text(
                    badge.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: widget.isCompact ? 12.sp : 14.sp,
                      color: badge.isUnlocked ? AppTheme.tertiaryLight : AppTheme.neutralLight,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    badge.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: widget.isCompact ? 9.5.sp : 11.sp,
                      color: AppTheme.neutralLight,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  if (!badge.isUnlocked)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: badge.progress,
                        backgroundColor: AppTheme.dividerLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.secondaryLight.withOpacity(0.6),
                        ),
                        minHeight: 6,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
