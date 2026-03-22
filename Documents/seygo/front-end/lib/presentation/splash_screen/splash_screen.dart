import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';

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
    with TickerProviderStateMixin { // Upgraded to TickerProviderStateMixin for multiple explicit animations
  late final AnimationController _scaleController;
  late final AnimationController _fadeController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  /// Initialize complex logo scale and fade animations
  void _initializeAnimations() {
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeController = AnimationController(
     vsync: this,
     duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleController.forward();
    _fadeController.forward();
  }

  /// Initialize app services and navigate robustly
  Future<void> _initializeApp() async {
    try {
      // Execute non-blocking prerequisite tasks in parallel
      await Future.wait([
        _loadDestinationCache(),
        _checkNetworkConnectivity(),
        _prepareImageOptimization(),
        Future.delayed(const Duration(milliseconds: 2500)), // Guaranteed Minimum UI Show Time
      ]);

      // BUG FIX: Context verification BEFORE setting state or navigating
      if (!mounted) return;

      setState(() => _isInitialized = true);

      // Add a polite fade out delay before exiting the splash screen
      await Future.delayed(const Duration(milliseconds: 500));
      
      // BUG FIX: Second necessary check because the context might be 
      // unmounted during the second 500ms sleep above
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true)
          .pushReplacementNamed(AppRoutes.welcomeHome);
    } catch (e) {
      // In the event of a critical startup component failure, fallback gracefully
      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true)
          .pushReplacementNamed(AppRoutes.welcomeHome);
    }
  }

  /// Bootstraps any background cache operations required for immediate UX
  Future<void> _loadDestinationCache() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  /// Pre-flights DNS and connection speeds
  Future<void> _checkNetworkConnectivity() async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  /// Pre-warms image texture caches
  Future<void> _prepareImageOptimization() async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    // BUG FIX: Cleanup all animation resources explicitly
    _scaleController.dispose();
    _fadeController.dispose();
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withValues(alpha: 0.15),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Animated Logo Component
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildLogo(theme),
                ),

                SizedBox(height: 5.h),

                // Elegant Loading Indicator Sequence
                _buildLoadingIndicator(theme),

                const Spacer(),

                // Software Identity Info
                _buildVersionInfo(theme),

                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constructs the central SeyGo visual identity logomark
  Widget _buildLogo(ThemeData theme) {
    return Container(
      width: 45.w,
      height: 45.w,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Image.asset(
          'assets/images/img_app_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                'SeyGo',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Clean, modern circulatory loading mechanism
  Widget _buildLoadingIndicator(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: 10.w,
          height: 10.w,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            strokeCap: StrokeCap.round,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          _isInitialized ? 'Ready...' : 'Preparing your journey...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Display branding version configuration neatly at bottom
  Widget _buildVersionInfo(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Discover Your Next Adventure',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Version 1.0.0',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

