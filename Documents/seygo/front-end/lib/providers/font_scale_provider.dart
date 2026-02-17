import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontScaleProvider extends ChangeNotifier {
  double _scaleFactor = 1.0;
  static const String _prefKey = 'font_scale_factor';

  FontScaleProvider() {
    _load();
  }

  double get scaleFactor => _scaleFactor;

  String get currentLabel {
    if (_scaleFactor >= 1.3) return 'Large';
    if (_scaleFactor <= 0.85) return 'Small';
    return 'Medium (Default)';
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _scaleFactor = prefs.getDouble(_prefKey) ?? 1.0;
      notifyListeners();
    } catch (_) {
      // silent fail → default to 1.0
    }
  }

  Future<void> setScaleFromLabel(String label) async {
    final newScale = switch (label) {
      'Large' => 1.3,
      'Small' => 0.85,
      _ => 1.0,
    };

    if (newScale == _scaleFactor) return;

    _scaleFactor = newScale;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefKey, _scaleFactor);
    } catch (_) {
      // silent fail
    }

    notifyListeners();
  }
}
