import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo: fade + scale
  late final AnimationController _logoController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  // Tagline: slide up + fade
  late final AnimationController _taglineController;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  // Progress bar
  late final AnimationController _progressController;

  // Pulse glow on logo card
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // ── Logo ──────────────────────────────────────────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoController.forward();

    // ── Tagline (starts after logo settles) ───────────────────────────────
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _taglineFade =
        CurvedAnimation(parent: _taglineController, curve: Curves.easeIn);
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 600),
        () => _taglineController.forward());

    // ── Progress bar (fills over 2.5 s) ───────────────────────────────────
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    // ── Pulse glow ─────────────────────────────────────────────────────────
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 3000));
      if (!mounted) return;
      final session = Supabase.instance.client.auth.currentSession;
      Navigator.of(context, rootNavigator: true).pushReplacementNamed(
        session != null ? AppRoutes.welcomeHome : AppRoutes.introWelcome,
      );
    } catch (_) {
      if (!mounted) return;
      final session = Supabase.instance.client.auth.currentSession;
      Navigator.of(context, rootNavigator: true).pushReplacementNamed(
        session != null ? AppRoutes.welcomeHome : AppRoutes.introWelcome,
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _taglineController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A2E44),
                  Color(0xFF0D1B2A),
                  Color(0xFF061420),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Decorative top-right glow orb ──────────────────────────────
          Positioned(
            top: -8.h,
            right: -10.w,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.lerp(const Color(0x221A6FD4),
                          const Color(0x441A6FD4), _pulse.value)!,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Decorative bottom-left glow orb ───────────────────────────
          Positioned(
            bottom: -6.h,
            left: -8.w,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.lerp(const Color(0x1A1A6FD4),
                          const Color(0x331A6FD4), _pulse.value)!,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo card with glow
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, child) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Color.lerp(
                                const Color(0x401A6FD4),
                                const Color(0x701A6FD4),
                                _pulse.value,
                              )!,
                              blurRadius: 40 + (_pulse.value * 20),
                              spreadRadius: 4 + (_pulse.value * 8),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: Container(
                        width: 64.w,
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Image.asset(
                          'assets/images/seygo_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 5.h),

                // Tagline
                SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _taglineFade,
                    child: Column(
                      children: [
                        Text(
                          'explore the world, your way',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Progress bar at bottom
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressController.value,
                        minHeight: 3,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1A6FD4),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 4.h),

                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 9.sp,
                    letterSpacing: 0.5,
                  ),
                ),

                SizedBox(height: 3.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
