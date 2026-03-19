import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/api_service.dart';
import '../../routes/app_routes.dart';
import '../onboarding_widgets/onboarding_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  bool _isSubmitting = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  StreamSubscription<AuthState>? _authSubscription;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  String? _validateEmail(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(normalized)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((data) {
            if (!mounted) return;
            if (data.event == AuthChangeEvent.signedIn) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.welcomeHomeScreen,
                (route) => false,
              );
            }
          });
    } catch (_) {
      // Supabase not initialized; email/password flow can still work via backend API.
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
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
                'Create an account',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Already have an account? ',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: const Color(0xFF7B8794),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.loginPage),
                    child: Text(
                      'Log in',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: brandBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SegmentedAuth(
                leftLabel: 'Login',
                rightLabel: 'Register',
                leftActive: false,
                onLeft: () => Navigator.pushNamed(context, AppRoutes.loginPage),
                onRight: () {},
              ),
              const SizedBox(height: 18),
              LabeledAuthField(
                label: 'Full Name',
                hintText: 'Enter your name',
                controller: _nameController,
                focusNode: _nameFocus,
                autofocus: true,
                textInputAction: TextInputAction.next,
                onTap: () => _nameFocus.requestFocus(),
              ),
              const SizedBox(height: 14),
              LabeledAuthField(
                label: 'Email',
                hintText: 'Enter your email',
                controller: _emailController,
                focusNode: _emailFocus,
                textInputAction: TextInputAction.next,
                onTap: () => _emailFocus.requestFocus(),
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
                focusNode: _passwordFocus,
                textInputAction: TextInputAction.next,
                onTap: () => _passwordFocus.requestFocus(),
                errorText: _passwordError,
              ),
              const SizedBox(height: 14),
              LabeledAuthField(
                label: 'Confirm Password',
                hintText: '********',
                obscure: !_isConfirmVisible,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isConfirmVisible = !_isConfirmVisible;
                    });
                  },
                  icon: Icon(
                    _isConfirmVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                ),
                controller: _confirmController,
                focusNode: _confirmFocus,
                textInputAction: TextInputAction.done,
                onTap: () => _confirmFocus.requestFocus(),
                errorText: _confirmError,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRegister,
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
                          'Create account',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              if (_emailError != null ||
                  _passwordError != null ||
                  _confirmError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _emailError ?? _passwordError ?? _confirmError ?? '',
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
                      onPressed: _isGoogleLoading || _isAppleLoading
                          ? null
                          : _signInWithGoogle,
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
                      onPressed: _isGoogleLoading || _isAppleLoading
                          ? null
                          : _signInWithApple,
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRegister() async {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmController.text;

    final emailError = email.isEmpty ? 'Email is required' : _validateEmail(email);
    String? passwordError;
    String? confirmError;

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Full name is required.')));
      return;
    }

    if (password.isEmpty) {
      passwordError = 'Password is required';
    } else if (password.length < 6) {
      passwordError = 'Password must be at least 6 characters';
    }

    if (confirmPassword.isEmpty) {
      confirmError = 'Please confirm your password';
    } else if (password != confirmPassword) {
      confirmError = 'Passwords do not match';
    }

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
    });

    if (emailError != null || passwordError != null || confirmError != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await ApiService.register(
        fullName: fullName,
        email: email,
        password: password,
      );

      final hasTokens =
          (response['refresh_token']?.toString().isNotEmpty ?? false);

      if (hasTokens) {
        await ApiService.persistBackendSession(response);
        ApiService.invalidateProfileCache();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.welcomeHomeScreen,
          (route) => false,
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['verification_email_sent'] == true
                ? 'Account created. Enter the verification code sent to your email.'
                : 'Account created. Verify your email to continue.',
          ),
        ),
      );
      Navigator.pushNamed(
        context,
        AppRoutes.otpPage,
        arguments: <String, dynamic>{
          'email': email,
          'mode': 'register',
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isAppleLoading = true;
    });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAppleLoading = false;
        });
      }
    }
  }
}

class _SocialPill extends StatelessWidget {
  const _SocialPill({
    required this.label,
    required this.leading,
    required this.onPressed,
  });

  final String label;
  final Widget leading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
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
