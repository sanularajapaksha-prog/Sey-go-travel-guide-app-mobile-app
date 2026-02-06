import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A class that contains all theme configurations for the SeyGo travel discovery application.
/// Implements Contemporary Tropical Minimalism with Ocean-Inspired Clarity color scheme.
class AppTheme {
  AppTheme._();

  // Ocean-Inspired Clarity Color Palette
  // Primary colors
  static const Color primaryLight = Color(
    0xFFFFFFFF,
  ); // Clean foundation optimized for content visibility
  static const Color primaryDark = Color(
    0xFF1E293B,
  ); // Deep tone for dark mode providing visual weight

  // Secondary colors
  static const Color secondaryLight = Color(
    0xFF2DD4BF,
  ); // Teal accent for interactive elements
  static const Color secondaryDark = Color(
    0xFF2DD4BF,
  ); // Consistent teal across themes

  // Tertiary colors
  static const Color tertiaryLight = Color(
    0xFF000000,
  ); // High-contrast text for readability
  static const Color tertiaryDark = Color(
    0xFFFFFFFF,
  ); // High-contrast text for dark mode

  // Surface colors
  static const Color surfaceLight = Color(
    0xFFF8FAFC,
  ); // Subtle background variation for card elevation
  static const Color surfaceDark = Color(
    0xFF0F172A,
  ); // Dark surface for elevated content

  // Accent colors
  static const Color accentLight = Color(
    0xFFEF4444,
  ); // Red for active carousel indicators
  static const Color accentDark = Color(
    0xFFEF4444,
  ); // Consistent accent across themes

  // Neutral colors
  static const Color neutralLight = Color(
    0xFF64748B,
  ); // Mid-tone gray for secondary text
  static const Color neutralDark = Color(
    0xFF94A3B8,
  ); // Lighter neutral for dark mode

  // Light gray
  static const Color lightGray = Color(
    0xFFE2E8F0,
  ); // Soft gray for category pill backgrounds
  static const Color lightGrayDark = Color(
    0xFF334155,
  ); // Darker variant for dark mode

  // Background colors
  static const Color backgroundLight = Color(
    0xFFFFFFFF,
  ); // Clean white background
  static const Color backgroundDark = Color(
    0xFF1E293B,
  ); // Deep background for dark mode

  // Success and warning colors
  static const Color successLight = Color(
    0xFF10B981,
  ); // Green for confirmation states
  static const Color successDark = Color(
    0xFF10B981,
  ); // Consistent success color

  static const Color warningLight = Color(
    0xFFF59E0B,
  ); // Amber for attention states
  static const Color warningDark = Color(
    0xFFF59E0B,
  ); // Consistent warning color

  // Error colors
  static const Color errorLight = Color(0xFFEF4444); // Red for error states
  static const Color errorDark = Color(0xFFEF4444); // Consistent error color

  // Card and dialog colors
  static const Color cardLight = Color(0xFFF8FAFC);
  static const Color cardDark = Color(0xFF0F172A);
  static const Color dialogLight = Color(0xFFFFFFFF);
  static const Color dialogDark = Color(0xFF1E293B);

  // Shadow colors - subtle elevation
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowDark = Color(0x1AFFFFFF);

  // Divider colors - minimal border usage
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);

  // Text colors with proper emphasis levels
  static const Color textHighEmphasisLight = Color(
    0xFF000000,
  ); // 100% opacity for primary text
  static const Color textMediumEmphasisLight = Color(
    0xFF64748B,
  ); // 60% emphasis for secondary text
  static const Color textDisabledLight = Color(
    0xFFCBD5E1,
  ); // 38% emphasis for disabled text

  static const Color textHighEmphasisDark = Color(
    0xFFFFFFFF,
  ); // 100% opacity for primary text
  static const Color textMediumEmphasisDark = Color(
    0xFF94A3B8,
  ); // 60% emphasis for secondary text
  static const Color textDisabledDark = Color(
    0xFF475569,
  ); // 38% emphasis for disabled text

  /// Light theme - Contemporary Tropical Minimalism
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: secondaryLight,
      onPrimary: primaryLight,
      primaryContainer: secondaryLight,
      onPrimaryContainer: primaryLight,
      secondary: accentLight,
      onSecondary: primaryLight,
      secondaryContainer: accentLight,
      onSecondaryContainer: primaryLight,
      tertiary: tertiaryLight,
      onTertiary: primaryLight,
      tertiaryContainer: neutralLight,
      onTertiaryContainer: primaryLight,
      error: errorLight,
      onError: primaryLight,
      surface: surfaceLight,
      onSurface: tertiaryLight,
      onSurfaceVariant: neutralLight,
      outline: dividerLight,
      outlineVariant: lightGray,
      shadow: shadowLight,
      scrim: shadowLight,
      inverseSurface: surfaceDark,
      onInverseSurface: tertiaryDark,
      inversePrimary: secondaryDark,
      surfaceTint: secondaryLight,
    ),
    scaffoldBackgroundColor: backgroundLight,
    cardColor: cardLight,
    dividerColor: dividerLight,

    // AppBar theme - minimal elevation for clean look
    appBarTheme: AppBarThemeData(
      backgroundColor: primaryLight,
      foregroundColor: tertiaryLight,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: tertiaryLight,
        letterSpacing: 0.15,
      ),
      iconTheme: IconThemeData(color: tertiaryLight),
    ),

    // Card theme - subtle elevation without heavy shadows
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 1.0,
      shadowColor: shadowLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.all(8.0),
    ),

    // Bottom navigation - spatial design with generous touch targets
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: primaryLight,
      selectedItemColor: secondaryLight,
      unselectedItemColor: neutralLight,
      type: BottomNavigationBarType.fixed,
      elevation: 4.0,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Floating action button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryLight,
      foregroundColor: primaryLight,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),

    // Button themes - 200-300ms transitions
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: primaryLight,
        backgroundColor: secondaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: BorderSide(color: secondaryLight, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Text theme - Inter font family with proper weights
    textTheme: _buildTextTheme(isLight: true),

    // Input decoration - minimal borders with focus states
    inputDecorationTheme: InputDecorationThemeData(
      fillColor: surfaceLight,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: lightGray, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: lightGray, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: secondaryLight, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorLight, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorLight, width: 2.0),
      ),
      labelStyle: GoogleFonts.inter(
        color: neutralLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.inter(
        color: textDisabledLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      prefixIconColor: neutralLight,
      suffixIconColor: neutralLight,
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return secondaryLight;
        }
        return neutralLight;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return secondaryLight.withValues(alpha: 0.5);
        }
        return lightGray;
      }),
    ),

    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return secondaryLight;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(primaryLight),
      side: BorderSide(color: lightGray, width: 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
    ),

    // Radio theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return secondaryLight;
        }
        return neutralLight;
      }),
    ),

    // Progress indicator
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: secondaryLight,
      linearTrackColor: lightGray,
      circularTrackColor: lightGray,
    ),

    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: secondaryLight,
      thumbColor: secondaryLight,
      overlayColor: secondaryLight.withValues(alpha: 0.2),
      inactiveTrackColor: lightGray,
      trackHeight: 4.0,
    ),

    // Tab bar theme
    tabBarTheme: TabBarThemeData(
      labelColor: secondaryLight,
      unselectedLabelColor: neutralLight,
      indicatorColor: secondaryLight,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
    ),

    // Tooltip theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tertiaryLight.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8.0),
      ),
      textStyle: GoogleFonts.inter(
        color: primaryLight,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tertiaryLight,
      contentTextStyle: GoogleFonts.inter(
        color: primaryLight,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: secondaryLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2.0,
    ),

    // Chip theme - for category pills
    chipTheme: ChipThemeData(
      backgroundColor: lightGray,
      selectedColor: secondaryLight,
      disabledColor: lightGray.withValues(alpha: 0.5),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: tertiaryLight,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryLight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      elevation: 0,
    ), dialogTheme: DialogThemeData(backgroundColor: dialogLight),
  );

  /// Dark theme - Contemporary Tropical Minimalism (Dark Mode)
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: secondaryDark,
      onPrimary: primaryDark,
      primaryContainer: secondaryDark,
      onPrimaryContainer: primaryDark,
      secondary: accentDark,
      onSecondary: primaryDark,
      secondaryContainer: accentDark,
      onSecondaryContainer: primaryDark,
      tertiary: tertiaryDark,
      onTertiary: primaryDark,
      tertiaryContainer: neutralDark,
      onTertiaryContainer: primaryDark,
      error: errorDark,
      onError: primaryDark,
      surface: surfaceDark,
      onSurface: tertiaryDark,
      onSurfaceVariant: neutralDark,
      outline: dividerDark,
      outlineVariant: lightGrayDark,
      shadow: shadowDark,
      scrim: shadowDark,
      inverseSurface: surfaceLight,
      onInverseSurface: tertiaryLight,
      inversePrimary: secondaryLight,
      surfaceTint: secondaryDark,
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardColor: cardDark,
    dividerColor: dividerDark,

    // AppBar theme
    appBarTheme: AppBarThemeData(
      backgroundColor: primaryDark,
      foregroundColor: tertiaryDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: tertiaryDark,
        letterSpacing: 0.15,
      ),
      iconTheme: IconThemeData(color: tertiaryDark),
    ),

    // Card theme
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 1.0,
      shadowColor: shadowDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.all(8.0),
    ),

    // Bottom navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: primaryDark,
      selectedItemColor: secondaryDark,
      unselectedItemColor: neutralDark,
      type: BottomNavigationBarType.fixed,
      elevation: 4.0,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Floating action button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryDark,
      foregroundColor: primaryDark,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: primaryDark,
        backgroundColor: secondaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: BorderSide(color: secondaryDark, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Text theme
    textTheme: _buildTextTheme(isLight: false),

    // Input decoration
    inputDecorationTheme: InputDecorationThemeData(
      fillColor: surfaceDark,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: lightGrayDark, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: lightGrayDark, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: secondaryDark, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorDark, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorDark, width: 2.0),
      ),
      labelStyle: GoogleFonts.inter(
        color: neutralDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.inter(
        color: textDisabledDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      prefixIconColor: neutralDark,
      suffixIconColor: neutralDark,
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return secondaryDark;
        }
        return neutralDark;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return secondaryDark.withValues(alpha: 0.5);
        }
        return lightGrayDark;
      }),
    ),

    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return secondaryDark;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(primaryDark),
      side: BorderSide(color: lightGrayDark, width: 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
    ),

    // Radio theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return secondaryDark;
        }
        return neutralDark;
      }),
    ),

    // Progress indicator
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: secondaryDark,
      linearTrackColor: lightGrayDark,
      circularTrackColor: lightGrayDark,
    ),

    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: secondaryDark,
      thumbColor: secondaryDark,
      overlayColor: secondaryDark.withValues(alpha: 0.2),
      inactiveTrackColor: lightGrayDark,
      trackHeight: 4.0,
    ),

    // Tab bar theme
    tabBarTheme: TabBarThemeData(
      labelColor: secondaryDark,
      unselectedLabelColor: neutralDark,
      indicatorColor: secondaryDark,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
    ),

    // Tooltip theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tertiaryDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8.0),
      ),
      textStyle: GoogleFonts.inter(
        color: primaryDark,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tertiaryDark,
      contentTextStyle: GoogleFonts.inter(
        color: primaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: secondaryDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2.0,
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: lightGrayDark,
      selectedColor: secondaryDark,
      disabledColor: lightGrayDark.withValues(alpha: 0.5),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: tertiaryDark,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryDark,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      elevation: 0,
    ), dialogTheme: DialogThemeData(backgroundColor: dialogDark),
  );

  /// Helper method to build text theme based on brightness
  /// Uses Inter font family with proper weights for headings, body, and captions
  static TextTheme _buildTextTheme({required bool isLight}) {
    final Color textHighEmphasis = isLight
        ? textHighEmphasisLight
        : textHighEmphasisDark;
    final Color textMediumEmphasis = isLight
        ? textMediumEmphasisLight
        : textMediumEmphasisDark;
    final Color textDisabled = isLight ? textDisabledLight : textDisabledDark;

    return TextTheme(
      // Display styles - large headings
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),

      // Headline styles - section headings
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),

      // Title styles - card titles and list items
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0.1,
      ),

      // Body styles - main content text
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: textMediumEmphasis,
        letterSpacing: 0.4,
      ),

      // Label styles - buttons and captions
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMediumEmphasis,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textDisabled,
        letterSpacing: 0.5,
      ),
    );
  }
}



