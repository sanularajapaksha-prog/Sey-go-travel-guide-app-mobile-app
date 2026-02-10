// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeKey = 'app_theme_mode';

  ThemeProvider() {
    _loadTheme();
  }

  // Getter for current theme mode
  ThemeMode get themeMode => _themeMode;

  // Helper to know if we're currently in dark mode
  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    // System mode → check system brightness
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  // Load saved theme from storage on init
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme != null) {
        _themeMode = _stringToThemeMode(savedTheme);
      }
    } catch (e) {
      // silent fail → keep system default
    }
    notifyListeners();
  }

  // Change and save theme
  Future<void> setThemeMode(ThemeMode newMode) async {
    if (newMode == _themeMode) return;

    _themeMode = newMode;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeModeToString(newMode));
    } catch (e) {
      // silent fail - theme will still change in current session
    }

    notifyListeners();
  }

  // ─── String ↔ ThemeMode conversion ────────────────────────────────────────

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
