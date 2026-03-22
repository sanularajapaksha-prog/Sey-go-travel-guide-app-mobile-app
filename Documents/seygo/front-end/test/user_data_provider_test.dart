import 'package:flutter_test/flutter_test.dart';
import 'package:seygo_travel_app/providers/user_data_provider.dart';

/// Tests for [UserDataProvider].
///
/// Network calls are not mocked — tests that call [preload] / [refreshPlaylists]
/// will hit a non-existent backend and fail gracefully (all errors are swallowed
/// by the provider), letting us verify the silent-error contract.
void main() {
  // ── Initial state ─────────────────────────────────────────────────────────
  group('UserDataProvider — initial state', () {
    test('profile is null', () {
      final provider = UserDataProvider();
      expect(provider.profile, isNull);
    });

    test('myPlaylists is empty', () {
      final provider = UserDataProvider();
      expect(provider.myPlaylists, isEmpty);
    });

    test('featuredPlaylists is empty', () {
      final provider = UserDataProvider();
      expect(provider.featuredPlaylists, isEmpty);
    });

    test('stats has expected zero defaults', () {
      final provider = UserDataProvider();
      expect(provider.stats['playlists'], 0);
      expect(provider.stats['places'], 0);
      expect(provider.stats['reviews'], 0);
      expect(provider.stats['photos'], 0);
    });

    test('profileLoaded is false', () {
      final provider = UserDataProvider();
      expect(provider.profileLoaded, isFalse);
    });

    test('myPlaylistsLoaded is false', () {
      final provider = UserDataProvider();
      expect(provider.myPlaylistsLoaded, isFalse);
    });

    test('featuredPlaylistsLoaded is false', () {
      final provider = UserDataProvider();
      expect(provider.featuredPlaylistsLoaded, isFalse);
    });

    test('statsLoaded is false', () {
      final provider = UserDataProvider();
      expect(provider.statsLoaded, isFalse);
    });
  });

  // ── invalidate ────────────────────────────────────────────────────────────
  group('UserDataProvider.invalidate', () {
    test('resets profile to null', () {
      final provider = UserDataProvider();
      provider.invalidate();
      expect(provider.profile, isNull);
    });

    test('resets myPlaylists to empty', () {
      final provider = UserDataProvider();
      provider.invalidate();
      expect(provider.myPlaylists, isEmpty);
    });

    test('resets featuredPlaylists to empty', () {
      final provider = UserDataProvider();
      provider.invalidate();
      expect(provider.featuredPlaylists, isEmpty);
    });

    test('resets stats to all zeros', () {
      final provider = UserDataProvider();
      provider.invalidate();
      expect(provider.stats['playlists'], 0);
      expect(provider.stats['places'], 0);
      expect(provider.stats['reviews'], 0);
      expect(provider.stats['photos'], 0);
    });

    test('resets profileLoaded to false', () {
      final provider = UserDataProvider();
      provider.invalidate();
      expect(provider.profileLoaded, isFalse);
    });

    test('resets myPlaylistsLoaded to false', () {
      final provider = UserDataProvider();
      provider.invalidate();
      expect(provider.myPlaylistsLoaded, isFalse);
    });

    test('resets featuredPlaylistsLoaded to false', () {
      final provider = UserDataProvider();
      provider.invalidate();
      expect(provider.featuredPlaylistsLoaded, isFalse);
    });

    test('resets statsLoaded to false', () {
      final provider = UserDataProvider();
      provider.invalidate();
      expect(provider.statsLoaded, isFalse);
    });

    test('calls notifyListeners', () {
      final provider = UserDataProvider();
      var notified = false;
      provider.addListener(() => notified = true);
      provider.invalidate();
      expect(notified, isTrue);
    });

    test('can be called multiple times without throwing', () {
      final provider = UserDataProvider();
      expect(() {
        provider.invalidate();
        provider.invalidate();
        provider.invalidate();
      }, returnsNormally);
    });

    test('stats map after invalidate has exactly 4 keys', () {
      final provider = UserDataProvider();
      provider.invalidate();
      expect(provider.stats.length, 4);
    });
  });

  // ── preload with bad token (network failure is silent) ────────────────────
  group('UserDataProvider.preload — network failure is silent', () {
    test('completes without throwing when backend is unreachable', () async {
      final provider = UserDataProvider();
      await expectLater(
        provider.preload('fake-token-that-wont-work'),
        completes,
      );
    });

    test('loaded flags remain false when network fails', () async {
      final provider = UserDataProvider();
      await provider.preload('bad-token');
      // All fetches failed silently — flags should still be false
      expect(provider.profileLoaded, isFalse);
      expect(provider.myPlaylistsLoaded, isFalse);
      expect(provider.featuredPlaylistsLoaded, isFalse);
      expect(provider.statsLoaded, isFalse);
    });

    test('data remains at defaults when network fails', () async {
      final provider = UserDataProvider();
      await provider.preload('bad-token');
      expect(provider.profile, isNull);
      expect(provider.myPlaylists, isEmpty);
      expect(provider.featuredPlaylists, isEmpty);
      expect(provider.stats['places'], 0);
    });
  });

  // ── refreshPlaylists with bad token ───────────────────────────────────────
  group('UserDataProvider.refreshPlaylists — network failure is silent', () {
    test('completes without throwing when backend is unreachable', () async {
      final provider = UserDataProvider();
      await expectLater(
        provider.refreshPlaylists('fake-token'),
        completes,
      );
    });

    test('completes without throwing with empty token', () async {
      final provider = UserDataProvider();
      await expectLater(
        provider.refreshPlaylists(''),
        completes,
      );
    });

    test('completes without throwing with null token', () async {
      final provider = UserDataProvider();
      await expectLater(
        provider.refreshPlaylists(null),
        completes,
      );
    });
  });

  // ── invalidate after preload attempt ─────────────────────────────────────
  group('UserDataProvider — invalidate after preload attempt', () {
    test('invalidate after failed preload still resets everything', () async {
      final provider = UserDataProvider();
      await provider.preload('bad-token');
      provider.invalidate();
      expect(provider.profileLoaded, isFalse);
      expect(provider.profile, isNull);
      expect(provider.stats['playlists'], 0);
    });
  });

  // ── listener notification ─────────────────────────────────────────────────
  group('UserDataProvider — listener notifications', () {
    test('invalidate always notifies listeners', () {
      final provider = UserDataProvider();
      var count = 0;
      provider.addListener(() => count++);
      provider.invalidate();
      expect(count, 1);
    });

    test('multiple invalidate calls each notify once', () {
      final provider = UserDataProvider();
      var count = 0;
      provider.addListener(() => count++);
      provider.invalidate();
      provider.invalidate();
      expect(count, 2);
    });
  });
}
