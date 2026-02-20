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
          Container(color: Colors.white.withValues(alpha: 0.86)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  children: [
                    const SizedBox(height: 110),
                    Text(
                      "Sri Lanka’s\nBest Travel\nPlanner",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 54,
                        height: 1.04,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 90),
                    const _FeatureItem(),
                    const Spacer(),
                    const _BottomControls(),
                    const SizedBox(height: 52),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.8),
          ),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.6),
            ),
            child: const Center(
              child: Icon(Icons.circle, size: 3.5, color: Colors.black),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Radius based discovery',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Discover everything around you from\nhidden beaches to mountain trails',
              style: GoogleFonts.roboto(
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(inactive: true),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 8),
            _dot(inactive: true),
            const SizedBox(width: 8),
            _dot(inactive: true),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 50,
          width: 170,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.welcomeHomeScreen);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1C1C1C),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NEXT',
                  style: GoogleFonts.roboto(
                    fontSize: 19,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot({required bool inactive}) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: inactive ? Colors.white.withValues(alpha: 0.65) : Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
