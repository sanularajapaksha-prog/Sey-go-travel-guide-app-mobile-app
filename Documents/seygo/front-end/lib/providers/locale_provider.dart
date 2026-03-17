import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String preferenceKey = 'pref_language';

  static const Map<String, Locale> supportedLanguageLocales = {
    'English (Sri Lanka)': Locale('en', 'LK'),
    'English (US)': Locale('en', 'US'),
    'Sinhala': Locale('si', 'LK'),
    'Tamil': Locale('ta', 'LK'),
  };

  String _languageLabel = 'English (Sri Lanka)';
  Locale _locale = const Locale('en', 'LK');

  LocaleProvider() {
    _load();
  }

  String get languageLabel => _languageLabel;
  Locale get locale => _locale;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(preferenceKey);
    if (saved != null && supportedLanguageLocales.containsKey(saved)) {
      _languageLabel = saved;
      _locale = supportedLanguageLocales[saved]!;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageLabel) async {
    final locale = supportedLanguageLocales[languageLabel];
    if (locale == null) return;
    _languageLabel = languageLabel;
    _locale = locale;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferenceKey, languageLabel);
    notifyListeners();
  }
}
