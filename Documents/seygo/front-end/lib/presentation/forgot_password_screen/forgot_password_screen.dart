import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/services/api_service.dart';
import '../../routes/app_routes.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _emailError;

  String? _validateEmail(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return 'Email is required';
    if (!normalized.contains('@') || !normalized.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2B84B4);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
        foregroundColor: const Color(0xFF1F1F1F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: brandBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: brandBlue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Forgot Password?',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email address. We\'ll send a verification code to reset your password.',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: const Color(0xFF7B8794),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              // Info box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: brandBlue.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: brandBlue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A 6-digit OTP will be sent to your email. Use it to verify and set a new password.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF1A6FA0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Email field
              Text(
                'Email Address',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFFB0BEC5),
                  ),
                  errorText: _emailError,
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: Color(0xFF9DB4C0), size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE3E7ED)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE3E7ED)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: brandBlue, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: Colors.red.shade400, width: 1.5),
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: brandBlue.withOpacity(0.4),
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Send OTP Code',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
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

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final emailError = _validateEmail(email);
    setState(() => _emailError = emailError);
    if (emailError != null) return;

    setState(() => _isSubmitting = true);

    try {
      // Send login OTP to the email for password reset
      await ApiService.sendLoginOtp(email: email);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to $email'),
          backgroundColor: Colors.green.shade600,
        ),
      );

      // Navigate to OTP page with forgot-password mode
      Navigator.pushNamed(
        context,
        AppRoutes.otpPage,
        arguments: <String, dynamic>{
          'email': email,
          'mode': 'forgot-password',
        },
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.contains('user not found') || msg.contains('Invalid')
                ? 'No account found with this email.'
                : msg,
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
