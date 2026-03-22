import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seygo_travel_app/data/models/offline_cache_item.dart';
import 'package:seygo_travel_app/data/services/offline_cache_service.dart';

OfflineCacheItem _makeItem({
  String id = 'item-1',
  OfflineCacheType type = OfflineCacheType.destination,
  String title = 'Test Place',
}) =>
    OfflineCacheItem(
      id: id,
      type: type,
      title: title,
      savedAt: DateTime(2025, 1, 1),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OfflineCacheService.loadAll', () {
    test('returns empty list when nothing is stored', () async {
      final items = await OfflineCacheService.loadAll();
      expect(items, isEmpty);
    });

    test('returns saved items after save()', () async {
      final item = _makeItem();
      await OfflineCacheService.save(item);
      final items = await OfflineCacheService.loadAll();
      expect(items.length, 1);
      expect(items.first.id, 'item-1');
    });

    test('returns multiple items in insertion order (newest first)', () async {
      final a = _makeItem(id: 'a', title: 'Alpha');
      final b = _makeItem(id: 'b', title: 'Beta');
      await OfflineCacheService.save(a);
      await OfflineCacheService.save(b);
      final items = await OfflineCacheService.loadAll();
      expect(items.length, 2);
      // b was saved last → b should be first
      expect(items[0].id, 'b');
      expect(items[1].id, 'a');
    });

    test('returns empty list after clearAll()', () async {
      await OfflineCacheService.save(_makeItem());
      await OfflineCacheService.clearAll();
      expect(await OfflineCacheService.loadAll(), isEmpty);
    });
  });

  group('OfflineCacheService.save', () {
    test('adds a new item', () async {
      await OfflineCacheService.save(_makeItem(id: 'new'));
      final items = await OfflineCacheService.loadAll();
      expect(items.any((i) => i.id == 'new'), isTrue);
    });

    test('replaces existing item with same id', () async {
      final original = _makeItem(id: 'dup', title: 'Original');
      final updated = _makeItem(id: 'dup', title: 'Updated');
      await OfflineCacheService.save(original);
      await OfflineCacheService.save(updated);
      final items = await OfflineCacheService.loadAll();
      expect(items.length, 1);
      expect(items.first.title, 'Updated');
    });

    test('saves both routeTrip and destination types', () async {
      await OfflineCacheService.save(
          _makeItem(id: 'trip', type: OfflineCacheType.routeTrip));
      await OfflineCacheService.save(
          _makeItem(id: 'dest', type: OfflineCacheType.destination));
      final items = await OfflineCacheService.loadAll();
      expect(items.any((i) => i.type == OfflineCacheType.routeTrip), isTrue);
      expect(items.any((i) => i.type == OfflineCacheType.destination), isTrue);
    });

    test('preserves routeData through save/load', () async {
      final item = OfflineCacheItem(
        id: 'trip-data',
        type: OfflineCacheType.routeTrip,
        title: 'Trip',
        routeData: {
          'origin': {'latitude': 7.87, 'longitude': 80.77},
          'optimizedStops': [
            {'name': 'Stop A'}
          ],
        },
        savedAt: DateTime(2025, 1, 1),
      );
      await OfflineCacheService.save(item);
      final loaded = await OfflineCacheService.loadAll();
      expect(loaded.first.routeData, isNotNull);
      final origin = loaded.first.routeData!['origin'] as Map;
      expect(origin['latitude'], 7.87);
    });

    test('preserves placeData through save/load', () async {
      final item = OfflineCacheItem(
        id: 'place-data',
        type: OfflineCacheType.destination,
        title: 'Ella',
        placeData: {'rating': 4.9, 'reviews': 200},
        savedAt: DateTime(2025, 1, 1),
      );
      await OfflineCacheService.save(item);
      final loaded = await OfflineCacheService.loadAll();
      expect(loaded.first.placeData!['rating'], 4.9);
      expect(loaded.first.placeData!['reviews'], 200);
    });
  });

  group('OfflineCacheService.contains', () {
    test('returns false when cache is empty', () async {
      expect(await OfflineCacheService.contains('missing'), isFalse);
    });

    test('returns true after saving item with that id', () async {
      await OfflineCacheService.save(_makeItem(id: 'target'));
      expect(await OfflineCacheService.contains('target'), isTrue);
    });

    test('returns false for a different id', () async {
      await OfflineCacheService.save(_makeItem(id: 'target'));
      expect(await OfflineCacheService.contains('other'), isFalse);
    });

    test('returns false after item is deleted', () async {
      await OfflineCacheService.save(_makeItem(id: 'target'));
      await OfflineCacheService.deleteById('target');
      expect(await OfflineCacheService.contains('target'), isFalse);
    });
  });

  group('OfflineCacheService.deleteById', () {
    test('removes item with matching id', () async {
      await OfflineCacheService.save(_makeItem(id: 'del-me'));
      await OfflineCacheService.save(_makeItem(id: 'keep-me'));
      await OfflineCacheService.deleteById('del-me');
      final items = await OfflineCacheService.loadAll();
      expect(items.any((i) => i.id == 'del-me'), isFalse);
      expect(items.any((i) => i.id == 'keep-me'), isTrue);
    });

    test('is a no-op when id does not exist', () async {
      await OfflineCacheService.save(_makeItem(id: 'keep'));
      await OfflineCacheService.deleteById('nonexistent');
      final items = await OfflineCacheService.loadAll();
      expect(items.length, 1);
    });

    test('leaves empty list after deleting only item', () async {
      await OfflineCacheService.save(_makeItem(id: 'only'));
      await OfflineCacheService.deleteById('only');
      expect(await OfflineCacheService.loadAll(), isEmpty);
    });

    test('correctly removes middle item from a 3-item list', () async {
      await OfflineCacheService.save(_makeItem(id: 'first'));
      await OfflineCacheService.save(_makeItem(id: 'second'));
      await OfflineCacheService.save(_makeItem(id: 'third'));
      await OfflineCacheService.deleteById('second');
      final items = await OfflineCacheService.loadAll();
      expect(items.length, 2);
      expect(items.map((i) => i.id), isNot(contains('second')));
    });
  });

  group('OfflineCacheService.clearAll', () {
    test('removes all items', () async {
      await OfflineCacheService.save(_makeItem(id: 'a'));
      await OfflineCacheService.save(_makeItem(id: 'b'));
      await OfflineCacheService.save(_makeItem(id: 'c'));
      await OfflineCacheService.clearAll();
      expect(await OfflineCacheService.loadAll(), isEmpty);
    });

    test('clearAll on empty cache is a no-op', () async {
      await OfflineCacheService.clearAll();
      expect(await OfflineCacheService.loadAll(), isEmpty);
    });

    test('can save new items after clearAll', () async {
      await OfflineCacheService.save(_makeItem(id: 'before'));
      await OfflineCacheService.clearAll();
      await OfflineCacheService.save(_makeItem(id: 'after'));
      final items = await OfflineCacheService.loadAll();
      expect(items.length, 1);
      expect(items.first.id, 'after');
    });
  });

  group('OfflineCacheService — persistence across calls', () {
    test('data survives multiple loadAll calls', () async {
      await OfflineCacheService.save(_makeItem(id: 'persist'));
      final first = await OfflineCacheService.loadAll();
      final second = await OfflineCacheService.loadAll();
      expect(first.first.id, second.first.id);
    });

    test('10 items can all be saved and retrieved', () async {
      for (var i = 0; i < 10; i++) {
        await OfflineCacheService.save(_makeItem(id: 'item-$i', title: 'Place $i'));
      }
      final items = await OfflineCacheService.loadAll();
      expect(items.length, 10);
    });
  });
}
