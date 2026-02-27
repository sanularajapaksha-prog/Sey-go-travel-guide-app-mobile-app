import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../onboarding_widgets/onboarding_widgets.dart';

class PlannerIntroPage extends StatelessWidget {
  const PlannerIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 40, 30, 30),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                "Sri Lanka's\nBest Travel\nPlanner",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 50,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 130),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed_rounded, size: 32),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Radius based discovery',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111111),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  'SeyGo is an exclusive travel concierge, crafted for those who expect nothing but the extraordinary. Indulge in Sri Lanka’s finest escapes from secluded coastal hideaways and private mountain retreats to iconic cultural treasures and handpicked premium experiences. Powered by intelligent discovery and meticulously curated recommendations, every journey is seamlessly tailored to your preferences. Enjoy optimized routes, refined insights, and effortless planning designed with elegance in mind. Whether you are seeking a tranquil getaway or a distinguished adventure, SeyGo elevates every moment transforming travel into a truly first-class experience.',
                  textAlign: TextAlign.justify,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.45,
                    color: const Color(0xFF323232),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IndicatorDot(active: false),
                  SizedBox(width: 8),
                  IndicatorDot(active: true),
                  SizedBox(width: 8),
                  IndicatorDot(active: false),
                ],
              ),
              const SizedBox(height: 24),
              NextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.introFeature),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
