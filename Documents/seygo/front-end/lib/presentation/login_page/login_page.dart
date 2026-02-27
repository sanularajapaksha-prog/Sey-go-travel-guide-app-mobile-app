import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../onboarding_widgets/onboarding_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentBlue = Color(0xFF2B84B4);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get Started With your\nFitness Journey',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1F1F),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to your Account',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7B8794),
                ),
              ),
              const SizedBox(height: 18),
              _SegmentedAuth(
                leftLabel: 'Login',
                rightLabel: 'Register',
                leftActive: true,
                onLeft: () {},
                onRight: () => Navigator.pushNamed(
                  context,
                  AppRoutes.registerPage,
                ),
              ),
              const SizedBox(height: 18),
              LabeledAuthField(
                label: 'Email',
                hintText: 'Enter your email',
                controller: _emailController,
                errorText: _emailError,
                onChanged: (value) {
                  final trimmed = value.trim();
                  setState(() {
                    if (trimmed.isEmpty) {
                      _emailError = null;
                    } else if (!trimmed.endsWith('@gmail.com')) {
                      _emailError = 'Email must end with @gmail.com';
                    } else {
                      _emailError = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 14),
              const LabeledAuthField(
                label: 'Password',
                hintText: '********',
                obscure: true,
                suffixIcon: Icon(Icons.visibility_off_outlined, size: 18),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.welcomeHomeScreen,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE2E6EC))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'or continue with',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF8A94A6),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE2E6EC))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SocialPill(
                      label: 'Google',
                      leading: Image.asset(
                        'assets/images/google_logo.png',
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SocialPill(
                      label: 'Apple',
                      leading: const Icon(Icons.apple, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: const Color(0xFF7B8794),
                    ),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.registerPage,
                          ),
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: accentBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _SocialPill extends StatelessWidget {
  const _SocialPill({required this.label, required this.leading});

  final String label;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Center(child: leading),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0x22000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

class _SegmentedAuth extends StatelessWidget {
  const _SegmentedAuth({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftActive,
    required this.onLeft,
    required this.onRight,
  });

  final String leftLabel;
  final String rightLabel;
  final bool leftActive;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    const accentBlue = Color(0xFF2B84B4);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: leftLabel,
              active: leftActive,
              onTap: onLeft,
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: rightLabel,
              active: !leftActive,
              onTap: onRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accentBlue = Color(0xFF2B84B4);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: active ? accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : const Color(0xFF6C7685),
            ),
          ),
        ),
      ),
    );
  }
}
