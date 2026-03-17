import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontScaleProvider extends ChangeNotifier {
  static const String _prefKey = 'font_scale_factor';

  double _scaleFactor = 1.0;

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
      _scaleFactor = _sanitizeScaleFactor(prefs.getDouble(_prefKey));
    } catch (_) {
      _scaleFactor = 1.0;
    }
    notifyListeners();
  }

  Future<void> setScaleFromLabel(String label) async {
    final requestedScale = switch (label) {
      'Large' => 1.3,
      'Small' => 0.85,
      _ => 1.0,
    };

    final nextScale = _sanitizeScaleFactor(requestedScale);
    if (nextScale == _scaleFactor) return;

    _scaleFactor = nextScale;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefKey, _scaleFactor);
    } catch (_) {}

    notifyListeners();
  }

  double _sanitizeScaleFactor(double? value) {
    const fallback = 1.0;
    final factor = value ?? fallback;
    if (!factor.isFinite || factor <= 0) {
      return fallback;
    }
    return factor.clamp(0.8, 1.5);
  }
}
