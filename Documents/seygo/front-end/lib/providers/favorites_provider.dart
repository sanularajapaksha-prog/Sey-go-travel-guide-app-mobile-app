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
  String _userId = '';
  final List<FavoritePlace> _favorites = [];

  static String _key(String userId) =>
      userId.isNotEmpty ? 'favorite_places_$userId' : 'favorite_places_guest';

  UnmodifiableListView<FavoritePlace> get favorites =>
      UnmodifiableListView(_favorites);

  int get count => _favorites.length;

  /// Load favorites for [userId]. Call this after login.
  Future<void> loadForUser(String userId) async {
    _userId = userId;
    _favorites.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(_userId));
      if (raw == null || raw.trim().isEmpty) {
        notifyListeners();
        return;
      }
      final dynamic decoded = jsonDecode(raw);
      if (decoded is List) {
        _favorites.addAll(
            decoded.cast<Map<String, dynamic>>().map(FavoritePlace.fromJson));
      } else {
        await prefs.remove(_key(_userId));
      }
    } catch (e, stack) {
      if (kDebugMode) debugPrint('Favorites decoding failed for user $_userId: $e\n$stack');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_key(_userId));
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Legacy: load from the old keyless slot (used at app startup before login).
  Future<void> loadFromPrefs() async {
    await loadForUser('');
  }

  /// Clears in-memory favorites without touching disk. Call on logout.
  void clearMemory() {
    _userId = '';
    _favorites.clear();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(_userId),
        jsonEncode(_favorites.map((f) => f.toJson()).toList()),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Serialization failed for favorites: $e');
    }
  }

  bool isFavorite(String id) => _favorites.any((place) => place.id == id);

  void toggleFavorite(FavoritePlace place) {
    final idx = _favorites.indexWhere((f) => f.id == place.id);
    if (idx >= 0) {
      _favorites.removeAt(idx);
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
