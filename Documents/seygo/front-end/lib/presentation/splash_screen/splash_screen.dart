import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';

/// Splash Screen - Branded app launch experience with initialization
/// Displays SeyGo logo with subtle animation during 2-3 second initialization
/// Handles background tasks: cache loading, network check, image optimization
/// Navigates to Welcome/Home screen after initialization
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeApp();
  }

  /// Initialize logo scale animation
  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  /// Initialize app services and navigate
  Future<void> _initializeApp() async {
    try {
      // Simulate initialization tasks
      await Future.wait([
        _loadDestinationCache(),
        _checkNetworkConnectivity(),
        _prepareImageOptimization(),
        Future.delayed(const Duration(milliseconds: 2500)),
      ]);

      setState(() => _isInitialized = true);

      // Navigate to Welcome/Home screen
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/welcome-home-screen');
      }
    } catch (e) {
      // Handle initialization errors gracefully
      if (mounted) {
        await Future.delayed(const Duration(seconds: 3));
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/welcome-home-screen');
      }
    }
  }

  /// Load destination cache
  Future<void> _loadDestinationCache() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  /// Check network connectivity
  Future<void> _checkNetworkConnectivity() async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  /// Prepare image optimization
  Future<void> _prepareImageOptimization() async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Logo
              ScaleTransition(scale: _scaleAnimation, child: _buildLogo(theme)),

              SizedBox(height: 4.h),

              // Loading Indicator
              _buildLoadingIndicator(theme),

              const Spacer(),

              // Version Info
              _buildVersionInfo(theme),

              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Build SeyGo logo
  Widget _buildLogo(ThemeData theme) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(20.w),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'explore',
              color: theme.colorScheme.tertiary,
              size: 15.w,
            ),
            SizedBox(height: 1.h),
            Text(
              'SeyGo',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator(ThemeData theme) {
    return SizedBox(
      width: 8.w,
      height: 8.w,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
      ),
    );
  }

  /// Build version info
  Widget _buildVersionInfo(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Discover Your Next Adventure',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Version 1.0.0',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
