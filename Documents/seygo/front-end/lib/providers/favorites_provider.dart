import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritePlace {
  final String id;
  final String name;
  final String? imageUrl;
  final String? googleUrl;
  final String location;
  final String semanticLabel;

  const FavoritePlace({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.googleUrl,
    required this.location,
    required this.semanticLabel,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'googleUrl': googleUrl,
        'location': location,
        'semanticLabel': semanticLabel,
      };

  factory FavoritePlace.fromJson(Map<String, dynamic> json) => FavoritePlace(
        id: json['id'] as String,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String?,
        googleUrl: json['googleUrl'] as String?,
        location: json['location'] as String,
        semanticLabel: json['semanticLabel'] as String,
      );
}

class FavoritesProvider extends ChangeNotifier {
  static const _prefsKey = 'favorite_places';

  final List<FavoritePlace> _favorites = [];

  UnmodifiableListView<FavoritePlace> get favorites =>
      UnmodifiableListView(_favorites);

  int get count => _favorites.length;

  /// Call once at startup to restore persisted favorites.
  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _favorites
        ..clear()
        ..addAll(list.map(FavoritePlace.fromJson));
      notifyListeners();
    } catch (_) {
      // Ignore corrupt data
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(_favorites.map((f) => f.toJson()).toList()),
      );
    } catch (_) {}
  }

  bool isFavorite(String id) {
    return _favorites.any((place) => place.id == id);
  }

  void toggleFavorite(FavoritePlace place) {
    final existingIndex =
        _favorites.indexWhere((favorite) => favorite.id == place.id);
    if (existingIndex >= 0) {
      _favorites.removeAt(existingIndex);
    } else {
      _favorites.add(place);
    }
    notifyListeners();
    _persist();
  }

  void removeFavorite(String id) {
    _favorites.removeWhere((place) => place.id == id);
    notifyListeners();
    _persist();
  }

  void clearFavorites() {
    if (_favorites.isEmpty) return;
    _favorites.clear();
    notifyListeners();
    _persist();
  }
}
