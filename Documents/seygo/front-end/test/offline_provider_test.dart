import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seygo_travel_app/data/models/offline_cache_item.dart';
import 'package:seygo_travel_app/providers/offline_provider.dart';

OfflineCacheItem _dest({String id = 'd1', String title = 'Place'}) =>
    OfflineCacheItem(
      id: id,
      type: OfflineCacheType.destination,
      title: title,
      savedAt: DateTime(2025, 1, 1),
    );

OfflineCacheItem _trip({String id = 't1', String title = 'Trip'}) =>
    OfflineCacheItem(
      id: id,
      type: OfflineCacheType.routeTrip,
      title: title,
      days: 2,
      stops: 4,
      distanceKm: 100.0,
      savedAt: DateTime(2025, 1, 1),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OfflineProvider — initial state', () {
    test('items is empty before load', () {
      final provider = OfflineProvider();
      expect(provider.items, isEmpty);
    });

    test('isLoading is false before any call', () {
      final provider = OfflineProvider();
      expect(provider.isLoading, isFalse);
    });

    test('trips is empty before load', () {
      final provider = OfflineProvider();
      expect(provider.trips, isEmpty);
    });

    test('destinations is empty before load', () {
      final provider = OfflineProvider();
      expect(provider.destinations, isEmpty);
    });

    test('isCached returns false for any id before load', () {
      final provider = OfflineProvider();
      expect(provider.isCached('anything'), isFalse);
    });
  });

  group('OfflineProvider — load()', () {
    test('loads empty cache', () async {
      final provider = OfflineProvider();
      await provider.load();
      expect(provider.items, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('loads previously saved items', () async {
      // Save via a first provider instance
      final p1 = OfflineProvider();
      await p1.save(_dest());
      // Load in a new instance (same SharedPreferences backing)
      final p2 = OfflineProvider();
      await p2.load();
      expect(p2.items.length, 1);
      expect(p2.items.first.id, 'd1');
    });

    test('isLoading transitions to false after load completes', () async {
      final provider = OfflineProvider();
      await provider.load();
      expect(provider.isLoading, isFalse);
    });

    test('notifies listeners after load', () async {
      final provider = OfflineProvider();
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.load();
      expect(notified, isTrue);
    });
  });

  group('OfflineProvider — save()', () {
    test('adds item to in-memory list', () async {
      final provider = OfflineProvider();
      await provider.save(_dest());
      expect(provider.items.length, 1);
    });

    test('notifies listeners on save', () async {
      final provider = OfflineProvider();
      var count = 0;
      provider.addListener(() => count++);
      await provider.save(_dest());
      expect(count, greaterThan(0));
    });

    test('replaces item with same id on save', () async {
      final provider = OfflineProvider();
      await provider.save(_dest(id: 'dup', title: 'Old'));
      await provider.save(_dest(id: 'dup', title: 'New'));
      expect(provider.items.length, 1);
      expect(provider.items.first.title, 'New');
    });

    test('isCached returns true after save', () async {
      final provider = OfflineProvider();
      await provider.save(_dest(id: 'abc'));
      expect(provider.isCached('abc'), isTrue);
    });

    test('isCached returns false for unsaved id', () async {
      final provider = OfflineProvider();
      await provider.save(_dest(id: 'abc'));
      expect(provider.isCached('xyz'), isFalse);
    });
  });

  group('OfflineProvider — trips / destinations getters', () {
    test('trips returns only routeTrip type items', () async {
      final provider = OfflineProvider();
      await provider.save(_trip(id: 't1'));
      await provider.save(_dest(id: 'd1'));
      await provider.save(_trip(id: 't2'));
      expect(provider.trips.length, 2);
      expect(provider.trips.every((i) => i.type == OfflineCacheType.routeTrip),
          isTrue);
    });

    test('destinations returns only destination type items', () async {
      final provider = OfflineProvider();
      await provider.save(_trip(id: 't1'));
      await provider.save(_dest(id: 'd1'));
      await provider.save(_dest(id: 'd2'));
      expect(provider.destinations.length, 2);
      expect(
          provider.destinations
              .every((i) => i.type == OfflineCacheType.destination),
          isTrue);
    });

    test('trips and destinations together equal items', () async {
      final provider = OfflineProvider();
      await provider.save(_trip(id: 't1'));
      await provider.save(_dest(id: 'd1'));
      await provider.save(_trip(id: 't2'));
      await provider.save(_dest(id: 'd2'));
      expect(provider.trips.length + provider.destinations.length,
          provider.items.length);
    });
  });

  group('OfflineProvider — deleteById()', () {
    test('removes item from in-memory list', () async {
      final provider = OfflineProvider();
      await provider.save(_dest(id: 'del'));
      await provider.save(_dest(id: 'keep'));
      await provider.deleteById('del');
      expect(provider.items.any((i) => i.id == 'del'), isFalse);
      expect(provider.items.any((i) => i.id == 'keep'), isTrue);
    });

    test('isCached returns false after delete', () async {
      final provider = OfflineProvider();
      await provider.save(_dest(id: 'target'));
      await provider.deleteById('target');
      expect(provider.isCached('target'), isFalse);
    });

    test('notifies listeners on delete', () async {
      final provider = OfflineProvider();
      await provider.save(_dest(id: 'x'));
      var count = 0;
      provider.addListener(() => count++);
      await provider.deleteById('x');
      expect(count, greaterThan(0));
    });

    test('deleteById is no-op for unknown id', () async {
      final provider = OfflineProvider();
      await provider.save(_dest(id: 'a'));
      await provider.deleteById('nonexistent');
      expect(provider.items.length, 1);
    });
  });

  group('OfflineProvider — clearAll()', () {
    test('empties in-memory list', () async {
      final provider = OfflineProvider();
      await provider.save(_dest(id: 'a'));
      await provider.save(_trip(id: 'b'));
      await provider.clearAll();
      expect(provider.items, isEmpty);
    });

    test('notifies listeners on clearAll', () async {
      final provider = OfflineProvider();
      await provider.save(_dest());
      var count = 0;
      provider.addListener(() => count++);
      await provider.clearAll();
      expect(count, greaterThan(0));
    });

    test('clearAll on empty provider is safe', () async {
      final provider = OfflineProvider();
      await provider.clearAll();
      expect(provider.items, isEmpty);
    });

    test('can save again after clearAll', () async {
      final provider = OfflineProvider();
      await provider.save(_dest(id: 'before'));
      await provider.clearAll();
      await provider.save(_dest(id: 'after'));
      expect(provider.items.length, 1);
      expect(provider.items.first.id, 'after');
    });
  });

  group('OfflineProvider — items immutability', () {
    test('items returns an unmodifiable view', () async {
      final provider = OfflineProvider();
      await provider.save(_dest());
      expect(
        () => (provider.items as List).add(_dest(id: 'hack')),
        throwsUnsupportedError,
      );
    });
  });

  group('OfflineProvider — listener notification count', () {
    test('save notifies at least once', () async {
      final provider = OfflineProvider();
      var count = 0;
      provider.addListener(() => count++);
      await provider.save(_dest());
      expect(count, greaterThanOrEqualTo(1));
    });

    test('load notifies at least twice (start + end)', () async {
      final provider = OfflineProvider();
      var count = 0;
      provider.addListener(() => count++);
      await provider.load();
      expect(count, greaterThanOrEqualTo(2));
    });
  });
}
