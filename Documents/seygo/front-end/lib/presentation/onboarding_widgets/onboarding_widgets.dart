import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEFEFEF),
          elevation: 6,
          shadowColor: const Color(0x26000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1F1F1F),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NextButton extends StatelessWidget {
  const NextButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 122,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF11171A),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: const Color(0x33000000),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Next',
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 16),
          ],
        ),
      ),
    );
  }
}

class IndicatorDot extends StatelessWidget {
  const IndicatorDot({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 18 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? Colors.black : const Color(0xFFCACACA),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.hintText,
    this.obscure = false,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.onChanged,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.readOnly = false,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.onTap,
  });

  final String hintText;
  final bool obscure;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction ?? TextInputAction.next,
      readOnly: readOnly,
      enabled: enabled,
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      enableInteractiveSelection: true,
      autocorrect: true,
      enableSuggestions: true,
      cursorColor: const Color(0xFF1F1F1F),
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: const Color(0xFF1F1F1F),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFF9D9D9D),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        errorText: errorText,
        filled: true,
        fillColor: const Color(0xFFF0F2F4),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 10, right: 6),
                child: prefixIcon,
              ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
        suffixIcon: suffixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 10),
                child: suffixIcon,
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class LabeledAuthField extends StatelessWidget {
  const LabeledAuthField({
    super.key,
    required this.label,
    required this.hintText,
    this.obscure = false,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.onChanged,
    this.errorText,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.onTap,
  });

  final String label;
  final String hintText;
  final bool obscure;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 8),
        AuthField(
          hintText: hintText,
          obscure: obscure,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          controller: controller,
          onChanged: onChanged,
          errorText: errorText,
          focusNode: focusNode,
          autofocus: autofocus,
          textInputAction: textInputAction,
          onTap: onTap,
        ),
      ],
    );
  }
}

class SecondaryAuthButton extends StatelessWidget {
  const SecondaryAuthButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE4E7ED),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF1F1F1F),
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
