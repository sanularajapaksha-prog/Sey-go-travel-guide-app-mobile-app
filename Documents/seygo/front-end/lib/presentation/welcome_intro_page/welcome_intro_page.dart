import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../onboarding_widgets/onboarding_widgets.dart';

class WelcomeIntroPage extends StatelessWidget {
  const WelcomeIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          child: Column(
            children: [
              const SizedBox(height: 8),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.60,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/onboard_2.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Best Travel app for you',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore top Destinations, Create\npersonalized itineraries, and enjoy a hassle-\nfree journey with our smart travel tool.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IndicatorDot(active: true),
                  SizedBox(width: 8),
                  IndicatorDot(active: false),
                  SizedBox(width: 8),
                  IndicatorDot(active: false),
                ],
              ),
              const SizedBox(height: 18),
              NextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.introPlanner),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
