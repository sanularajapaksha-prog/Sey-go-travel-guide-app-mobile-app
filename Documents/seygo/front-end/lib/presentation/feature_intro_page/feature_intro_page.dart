
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';

class FeatureIntroPage extends StatelessWidget {
  const FeatureIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/onboard_3.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: height * 0.52,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Find perfect\ndestination for\nevery mood',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1E1E),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Explore you’ve never seen\nbefore & Discover just for you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6A7682),
                  height: 1.45,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _Dot(isActive: false),
                  SizedBox(width: 8),
                  _Dot(isActive: false),
                  SizedBox(width: 8),
                  _Dot(isActive: true),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.signupPage),
                  style: ElevatedButton.styleFrom(
                    elevation: 6,
                    shadowColor: const Color(0x33000000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    backgroundColor: const Color(0xFF2B84B4),
                  ),
                  child: Text(
                    'Get Started',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotRing extends StatelessWidget {
  const _DotRing({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color ringColor =
        isActive ? const Color(0xFF2B84B4) : const Color(0xFFBFC7D1);
    return Container(
      width: isActive ? 28 : 24,
      height: isActive ? 28 : 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2),
      ),
      child: Center(
        child: Container(
          width: isActive ? 8 : 5,
          height: isActive ? 8 : 5,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2B84B4) : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return Container(
        width: 22,
        height: 6,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFD3D7DC),
        shape: BoxShape.circle,
      ),
    );
  }
}
