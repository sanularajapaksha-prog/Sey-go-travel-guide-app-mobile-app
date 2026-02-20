import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/beach_background.jpg',
            fit: BoxFit.cover,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 0.84,
              child: ClipPath(
                clipper: _TopWhiteClipper(),
                child: Container(color: const Color(0xFFF9F9F9)),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Explore Sri Lanka',
                    style: GoogleFonts.roboto(
                      fontSize: 38,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2A353C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Beyond it's limit",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _OnboardingDots(),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.welcomeHomeScreen);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 34,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Next',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 8),
        _dot(),
        const SizedBox(width: 8),
        _dot(),
      ],
    );
  }

  Widget _dot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFFD8D8D8),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TopWhiteClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height * 0.80)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.92,
        size.width * 0.80,
        size.height * 0.77,
      )
      ..quadraticBezierTo(
        size.width * 0.93,
        size.height * 0.68,
        size.width,
        size.height * 0.73,
      )
      ..lineTo(size.width, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
