import 'dart:collection';

import 'package:flutter/foundation.dart';

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
}

class FavoritesProvider extends ChangeNotifier {
  final List<FavoritePlace> _favorites = [];

  UnmodifiableListView<FavoritePlace> get favorites =>
      UnmodifiableListView(_favorites);

  int get count => _favorites.length;

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
  }

  void removeFavorite(String id) {
    _favorites.removeWhere((place) => place.id == id);
    notifyListeners();
  }

  void clearFavorites() {
    if (_favorites.isEmpty) {
      return;
    }
    _favorites.clear();
    notifyListeners();
  }
}
