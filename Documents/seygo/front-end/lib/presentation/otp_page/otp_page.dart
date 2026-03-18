import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/services/api_service.dart';
import '../../routes/app_routes.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers = List.generate(
    8,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(8, (_) => FocusNode());
  bool _isResending = false;
  bool _isVerifying = false;
  int _resendCountdown = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2B84B4);
    final double height = MediaQuery.of(context).size.height;
    final args = ModalRoute.of(context)?.settings.arguments;
    String email = '';
    String mode = 'register';
    if (args is Map<String, dynamic>) {
      email = (args['email'] as String?)?.trim() ?? '';
      mode = (args['mode'] as String?) ?? 'register';
    } else if (args is String) {
      email = args.trim();
    }
    final isLoginFlow = mode == 'login';
    final isForgotPassword = mode == 'forgot-password';

    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!keyboardVisible) ...[
                Image.asset(
                  'assets/images/OTP.jpg',
                  height: height * 0.30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
              ] else
                const SizedBox(height: 20),
              Text(
                'Enter Code',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'An 8-digit code was sent to\n$email',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF7B8794),
                ),
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final boxSize = (constraints.maxWidth - 28) / 8;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(8, (index) {
                      return _OtpBox(
                        size: boxSize.clamp(34.0, 46.0),
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        onChanged: (value) {
                          if (value.length == 1 && index < 7) {
                            _focusNodes[index + 1].requestFocus();
                          }
                          if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        },
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: (_isResending || _resendCountdown > 0)
                      ? null
                      : () => _resendCode(
                            email: email,
                            isLogin: isLoginFlow || isForgotPassword,
                          ),
                  child: Text(
                    _isResending
                        ? 'Sending...'
                        : _resendCountdown > 0
                            ? 'Resend in ${_resendCountdown}s'
                            : 'Request again',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: (_isResending || _resendCountdown > 0)
                          ? const Color(0xFFB0BEC5)
                          : brandBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifying
                      ? null
                      : () => _verifyOtp(email, isLoginFlow, isForgotPassword),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Confirm',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resendCode({
    required String email,
    required bool isLogin,
  }) async {
    if (email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not found. Go back and register again.'),
        ),
      );
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      if (isLogin) {
        await ApiService.sendLoginOtp(email: email);
      } else {
        await ApiService.resendVerificationCode(email: email);
      }
      if (!mounted) return;
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLogin
                ? 'Login code sent again.'
                : 'Verification code sent again.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _verifyOtp(String email, bool isLogin, bool isForgotPassword) async {
    if (email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not found. Go back and register again.'),
        ),
      );
      return;
    }

    final code = _controllers.map((c) => c.text.trim()).join();
    if (code.length != 8 || code.contains(RegExp(r'[^0-9]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 8 digits.')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      Map<String, dynamic> response;
      if (isLogin || isForgotPassword) {
        response = await ApiService.verifyLoginOtp(email: email, code: code);
      } else {
        response = await ApiService.verifyOtp(email: email, code: code);
      }
      await ApiService.persistBackendSession(response);
      ApiService.invalidateProfileCache();
      if (!mounted) return;

      if (isForgotPassword) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.resetPassword,
          (route) => false,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLogin ? 'Login successful.' : 'Email verified successfully.',
          ),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        isLogin ? AppRoutes.welcomeHomeScreen : AppRoutes.userPreferences,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.size = 52,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2B84B4);
    return SizedBox(
      width: size,
      height: size,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE3E7ED)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE3E7ED)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: brandBlue, width: 1.5),
          ),
        ),
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1F1F1F),
        ),
      ),
    );
  }
}
