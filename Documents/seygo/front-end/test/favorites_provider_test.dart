import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seygo_travel_app/providers/favorites_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

FavoritePlace _place(String id, {String name = 'Place'}) => FavoritePlace(
      id: id,
      name: name,
      imageUrl: 'https://cdn.net/$id.jpg',
      googleUrl: 'https://maps.google.com/?cid=$id',
      location: 'Sri Lanka',
      semanticLabel: name,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── Initial state ─────────────────────────────────────────────────────────
  group('FavoritesProvider — initial state', () {
    test('favorites list is empty', () {
      final provider = FavoritesProvider();
      expect(provider.favorites, isEmpty);
    });

    test('count is 0', () {
      final provider = FavoritesProvider();
      expect(provider.count, 0);
    });

    test('isFavorite returns false for any id', () {
      final provider = FavoritesProvider();
      expect(provider.isFavorite('any-id'), isFalse);
    });
  });

  // ── toggleFavorite ────────────────────────────────────────────────────────
  group('FavoritesProvider.toggleFavorite', () {
    test('adds place when not a favorite', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('p1'));
      expect(provider.count, 1);
      expect(provider.isFavorite('p1'), isTrue);
    });

    test('removes place when already a favorite (toggle off)', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('p1'));
      provider.toggleFavorite(_place('p1'));
      expect(provider.count, 0);
      expect(provider.isFavorite('p1'), isFalse);
    });

    test('can add multiple different places', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('a'));
      provider.toggleFavorite(_place('b'));
      provider.toggleFavorite(_place('c'));
      expect(provider.count, 3);
    });

    test('toggling one does not affect others', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('a'));
      provider.toggleFavorite(_place('b'));
      provider.toggleFavorite(_place('a')); // remove a
      expect(provider.isFavorite('a'), isFalse);
      expect(provider.isFavorite('b'), isTrue);
    });

    test('notifies listeners when adding', () {
      final provider = FavoritesProvider();
      var notified = false;
      provider.addListener(() => notified = true);
      provider.toggleFavorite(_place('x'));
      expect(notified, isTrue);
    });

    test('notifies listeners when removing', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('x'));
      var notified = false;
      provider.addListener(() => notified = true);
      provider.toggleFavorite(_place('x'));
      expect(notified, isTrue);
    });

    test('double-toggle results in count unchanged from zero', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('p'));
      provider.toggleFavorite(_place('p'));
      expect(provider.count, 0);
    });
  });

  // ── isFavorite ────────────────────────────────────────────────────────────
  group('FavoritesProvider.isFavorite', () {
    test('returns true for added place', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('abc'));
      expect(provider.isFavorite('abc'), isTrue);
    });

    test('returns false for non-added place', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('abc'));
      expect(provider.isFavorite('xyz'), isFalse);
    });

    test('returns false after place is toggled off', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('abc'));
      provider.toggleFavorite(_place('abc'));
      expect(provider.isFavorite('abc'), isFalse);
    });

    test('is case-sensitive', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('ABC'));
      expect(provider.isFavorite('abc'), isFalse);
      expect(provider.isFavorite('ABC'), isTrue);
    });
  });

  // ── removeFavorite ────────────────────────────────────────────────────────
  group('FavoritesProvider.removeFavorite', () {
    test('removes the correct place', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('keep'));
      provider.toggleFavorite(_place('remove'));
      provider.removeFavorite('remove');
      expect(provider.isFavorite('remove'), isFalse);
      expect(provider.isFavorite('keep'), isTrue);
    });

    test('count decreases by 1', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('a'));
      provider.toggleFavorite(_place('b'));
      provider.removeFavorite('a');
      expect(provider.count, 1);
    });

    test('is a no-op for unknown id', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('a'));
      provider.removeFavorite('nonexistent');
      expect(provider.count, 1);
    });

    test('notifies listeners on removal', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('x'));
      var notified = false;
      provider.addListener(() => notified = true);
      provider.removeFavorite('x');
      expect(notified, isTrue);
    });

    test('removing from empty list is safe', () {
      final provider = FavoritesProvider();
      expect(() => provider.removeFavorite('any'), returnsNormally);
    });
  });

  // ── clearFavorites ────────────────────────────────────────────────────────
  group('FavoritesProvider.clearFavorites', () {
    test('empties the list', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('a'));
      provider.toggleFavorite(_place('b'));
      provider.clearFavorites();
      expect(provider.favorites, isEmpty);
    });

    test('count becomes 0', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('a'));
      provider.clearFavorites();
      expect(provider.count, 0);
    });

    test('is a no-op when list is already empty', () {
      final provider = FavoritesProvider();
      expect(() => provider.clearFavorites(), returnsNormally);
      expect(provider.count, 0);
    });

    test('notifies listeners when clearing non-empty list', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('a'));
      var notified = false;
      provider.addListener(() => notified = true);
      provider.clearFavorites();
      expect(notified, isTrue);
    });

    test('does not notify listeners when list is already empty', () {
      final provider = FavoritesProvider();
      var notified = false;
      provider.addListener(() => notified = true);
      provider.clearFavorites();
      expect(notified, isFalse);
    });

    test('can add items again after clear', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('a'));
      provider.clearFavorites();
      provider.toggleFavorite(_place('b'));
      expect(provider.count, 1);
      expect(provider.isFavorite('b'), isTrue);
    });
  });

  // ── favorites list immutability ───────────────────────────────────────────
  group('FavoritesProvider — favorites list immutability', () {
    test('favorites is an UnmodifiableListView', () {
      final provider = FavoritesProvider();
      provider.toggleFavorite(_place('a'));
      expect(
        () => (provider.favorites as List).add(_place('hack')),
        throwsUnsupportedError,
      );
    });
  });

  // ── loadFromPrefs ─────────────────────────────────────────────────────────
  group('FavoritesProvider.loadFromPrefs', () {
    test('loads nothing when prefs is empty', () async {
      final provider = FavoritesProvider();
      await provider.loadFromPrefs();
      expect(provider.favorites, isEmpty);
    });

    test('loads previously saved favorites', () async {
      // Simulate data saved in prefs by a previous session
      final data = jsonEncode([
        {
          'id': 'p1',
          'name': 'Ella',
          'imageUrl': 'https://cdn.net/ella.jpg',
          'googleUrl': null,
          'location': 'Badulla',
          'semanticLabel': 'Mountain town',
        }
      ]);
      SharedPreferences.setMockInitialValues(
          {'favorite_places': data});

      final provider = FavoritesProvider();
      await provider.loadFromPrefs();

      expect(provider.count, 1);
      expect(provider.favorites.first.id, 'p1');
      expect(provider.favorites.first.name, 'Ella');
    });

    test('loads multiple favorites from prefs', () async {
      final data = jsonEncode([
        {
          'id': 'a',
          'name': 'A',
          'imageUrl': null,
          'googleUrl': null,
          'location': 'L',
          'semanticLabel': 'S',
        },
        {
          'id': 'b',
          'name': 'B',
          'imageUrl': null,
          'googleUrl': null,
          'location': 'L',
          'semanticLabel': 'S',
        },
      ]);
      SharedPreferences.setMockInitialValues({'favorite_places': data});

      final provider = FavoritesProvider();
      await provider.loadFromPrefs();

      expect(provider.count, 2);
    });

    test('handles corrupted JSON gracefully (does not throw)', () async {
      SharedPreferences.setMockInitialValues(
          {'favorite_places': 'not valid json {{{{'});

      final provider = FavoritesProvider();
      await expectLater(provider.loadFromPrefs(), completes);
      expect(provider.favorites, isEmpty);
    });

    test('handles non-list JSON gracefully (does not throw)', () async {
      SharedPreferences.setMockInitialValues(
          {'favorite_places': '{"not":"a-list"}'});

      final provider = FavoritesProvider();
      await expectLater(provider.loadFromPrefs(), completes);
      expect(provider.favorites, isEmpty);
    });

    test('handles empty string in prefs gracefully', () async {
      SharedPreferences.setMockInitialValues({'favorite_places': ''});

      final provider = FavoritesProvider();
      await expectLater(provider.loadFromPrefs(), completes);
      expect(provider.favorites, isEmpty);
    });

    test('handles whitespace-only string in prefs gracefully', () async {
      SharedPreferences.setMockInitialValues({'favorite_places': '   '});

      final provider = FavoritesProvider();
      await expectLater(provider.loadFromPrefs(), completes);
      expect(provider.favorites, isEmpty);
    });

    test('notifies listeners after loading', () async {
      final data = jsonEncode([
        {
          'id': 'x',
          'name': 'X',
          'imageUrl': null,
          'googleUrl': null,
          'location': 'L',
          'semanticLabel': 'S',
        }
      ]);
      SharedPreferences.setMockInitialValues({'favorite_places': data});

      final provider = FavoritesProvider();
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.loadFromPrefs();
      expect(notified, isTrue);
    });
  });

  // ── persistence across toggle ─────────────────────────────────────────────
  group('FavoritesProvider — persistence', () {
    test('toggle persists to SharedPreferences (loadFromPrefs reads it back)',
        () async {
      final provider1 = FavoritesProvider();
      provider1.toggleFavorite(_place('persist-me', name: 'Persisted Place'));
      // Give _persist() time to complete (it's fire-and-forget in toggleFavorite)
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final provider2 = FavoritesProvider();
      await provider2.loadFromPrefs();
      expect(provider2.isFavorite('persist-me'), isTrue);
    });

    test('removeFavorite persists removal', () async {
      final provider1 = FavoritesProvider();
      provider1.toggleFavorite(_place('r1'));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      provider1.removeFavorite('r1');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final provider2 = FavoritesProvider();
      await provider2.loadFromPrefs();
      expect(provider2.isFavorite('r1'), isFalse);
    });
  });
}
