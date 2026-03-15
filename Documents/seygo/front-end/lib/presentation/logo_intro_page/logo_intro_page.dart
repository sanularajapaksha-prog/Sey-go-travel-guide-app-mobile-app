import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';

class LogoIntroPage extends StatefulWidget {
  const LogoIntroPage({super.key});

  @override
  State<LogoIntroPage> createState() => _LogoIntroPageState();
}

class _LogoIntroPageState extends State<LogoIntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _slideY;
  late final Animation<double> _tilt;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _slideY = Tween<double>(begin: 32, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _tilt = Tween<double>(begin: -0.05, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.introWelcome);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD6D8DC),
              Color(0xFF2F343A),
              Color(0xFF0D0F13),
            ],
            stops: [0.0, 0.48, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, child) => Opacity(
                opacity: _fade.value,
                child: Transform.translate(
                  offset: Offset(0, _slideY.value),
                  child: Transform.rotate(
                    angle: _tilt.value,
                    child: Transform.scale(
                      scale: 0.9 + (_scale.value * 0.18),
                      child: child,
                    ),
                  ),
                ),
              ),
              child: Text(
                'SeyGo',
                style: GoogleFonts.pacifico(
                  fontSize: 68,
                  color: Colors.white,
                  letterSpacing: 0.4,
                  shadows: const [
                    Shadow(
                      color: Color(0x55000000),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
