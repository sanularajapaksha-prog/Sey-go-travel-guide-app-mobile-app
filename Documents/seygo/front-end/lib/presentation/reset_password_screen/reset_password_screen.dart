import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/api_service.dart';
import '../../routes/app_routes.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2B84B4);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
        foregroundColor: const Color(0xFF1F1F1F),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset Password',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set a new password for your account.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF7B8794),
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _decoration(
                  label: 'New Password',
                  errorText: _passwordError,
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmController,
                obscureText: !_isConfirmVisible,
                decoration: _decoration(
                  label: 'Confirm Password',
                  errorText: _confirmError,
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        _isConfirmVisible = !_isConfirmVisible;
                      });
                    },
                    icon: Icon(
                      _isConfirmVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
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
                          'Update Password',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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

  InputDecoration _decoration({
    required String label,
    required String? errorText,
    required Widget trailing,
  }) {
    const brandBlue = Color(0xFF2B84B4);
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: trailing,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE3E7ED)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE3E7ED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: brandBlue, width: 1.4),
      ),
    );
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    String? passwordError;
    String? confirmError;

    if (password.isEmpty) {
      passwordError = 'Password is required';
    } else if (password.length < 6) {
      passwordError = 'Password must be at least 6 characters';
    }

    if (confirm.isEmpty) {
      confirmError = 'Please confirm your password';
    } else if (password != confirm) {
      confirmError = 'Passwords do not match';
    }

    setState(() {
      _passwordError = passwordError;
      _confirmError = confirmError;
    });

    if (passwordError != null || confirmError != null) {
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    final refreshToken = session?.refreshToken;
    if (session == null || refreshToken == null || refreshToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset session not found. Open the reset link again.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.resetPassword(
        accessToken: session.accessToken,
        refreshToken: refreshToken,
        newPassword: password,
      );
      if (!mounted) return;
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Log in with your new password.')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.loginPage,
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
          _isSubmitting = false;
        });
      }
    }
  }
}
