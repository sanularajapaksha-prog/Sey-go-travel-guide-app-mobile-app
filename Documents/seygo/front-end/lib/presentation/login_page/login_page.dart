import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/api_service.dart';
import '../../routes/app_routes.dart';
import '../onboarding_widgets/onboarding_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;

  String? _validateEmail(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    if (!normalized.endsWith('@gmail.com')) {
      return 'Email must end with @gmail.com';
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2B84B4);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get Started With your\nTravel Journey',
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
                onRight: () =>
                    Navigator.pushNamed(context, AppRoutes.registerPage),
              ),
              const SizedBox(height: 18),
              LabeledAuthField(
                label: 'Email',
                hintText: 'Enter your email',
                controller: _emailController,
                errorText: _emailError,
                onChanged: (value) {
                  setState(() {
                    _emailError = _validateEmail(value);
                  });
                },
              ),
              const SizedBox(height: 14),
              LabeledAuthField(
                label: 'Password',
                hintText: '********',
                obscure: !_isPasswordVisible,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                ),
                controller: _passwordController,
                errorText: _passwordError,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  style: TextButton.styleFrom(
                    foregroundColor: brandBlue,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: brandBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _sendLoginOtp,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: brandBlue, width: 1.3),
                    foregroundColor: brandBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'Login with OTP',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              if (_emailError != null || _passwordError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _emailError ?? _passwordError ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.red.shade600,
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
                      leading: Image.asset(
                        'assets/images/apple_logo.png',
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                      ),
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
                              color: brandBlue,
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

  Future<void> _submitLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailError = _validateEmail(email);
    String? passwordError;

    if (password.isEmpty) {
      passwordError = 'Password is required';
    } else if (password.length < 6) {
      passwordError = 'Password must be at least 6 characters';
    }

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });

    if (emailError != null || passwordError != null || email.isEmpty) {
      if (email.isEmpty) {
        setState(() {
          _emailError = 'Email is required';
        });
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await ApiService.login(email: email, password: password);
      await ApiService.persistBackendSession(response);
      ApiService.invalidateProfileCache();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.welcomeHomeScreen,
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      String displayMsg = msg;
      if (msg.toLowerCase().contains('invalid login credentials') ||
          msg.toLowerCase().contains('invalid credentials')) {
        displayMsg =
            'Incorrect email or password.\nIf you signed up with Google, use the Google button below.';
      } else if (msg.toLowerCase().contains('email not confirmed')) {
        displayMsg = 'Please verify your email first. Check your inbox for the OTP code.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMsg),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _sendLoginOtp() async {
    final email = _emailController.text.trim();
    final emailError = email.isEmpty ? 'Email is required' : _validateEmail(email);

    setState(() {
      _emailError = emailError;
      _passwordError = null;
    });

    if (emailError != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.sendLoginOtp(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your email for the login code.')),
      );
      Navigator.pushNamed(
        context,
        AppRoutes.otpPage,
        arguments: <String, dynamic>{
          'email': email,
          'mode': 'login',
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

class _SocialPill extends StatelessWidget {
  const _SocialPill({required this.label, required this.leading});

  final String label;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0x22000000),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20, height: 20, child: Center(child: leading)),
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
    const brandBlue = Color(0xFF2B84B4);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: active ? brandBlue : Colors.transparent,
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
