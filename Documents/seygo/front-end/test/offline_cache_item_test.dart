import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:seygo_travel_app/data/models/offline_cache_item.dart';

void main() {
  group('OfflineCacheType enum', () {
    test('has routeTrip and destination values', () {
      expect(OfflineCacheType.values.length, 2);
      expect(OfflineCacheType.values, contains(OfflineCacheType.routeTrip));
      expect(OfflineCacheType.values, contains(OfflineCacheType.destination));
    });

    test('enum names match expected strings', () {
      expect(OfflineCacheType.routeTrip.name, 'routeTrip');
      expect(OfflineCacheType.destination.name, 'destination');
    });
  });

  group('OfflineCacheItem — construction', () {
    test('creates with required fields only', () {
      final now = DateTime(2025, 1, 1);
      final item = OfflineCacheItem(
        id: 'test-id',
        type: OfflineCacheType.destination,
        title: 'Ella',
        savedAt: now,
      );

      expect(item.id, 'test-id');
      expect(item.type, OfflineCacheType.destination);
      expect(item.title, 'Ella');
      expect(item.savedAt, now);
      // Optional fields are null
      expect(item.imageUrl, isNull);
      expect(item.description, isNull);
      expect(item.category, isNull);
      expect(item.location, isNull);
      expect(item.latitude, isNull);
      expect(item.longitude, isNull);
      expect(item.dateRange, isNull);
      expect(item.days, isNull);
      expect(item.stops, isNull);
      expect(item.distanceKm, isNull);
      expect(item.budgetLKR, isNull);
      expect(item.transportMode, isNull);
      expect(item.travelTime, isNull);
      expect(item.emergencyContact, isNull);
      expect(item.routeData, isNull);
      expect(item.placeData, isNull);
    });

    test('creates with all fields for destination', () {
      final now = DateTime(2025, 6, 15, 10, 30);
      final item = OfflineCacheItem(
        id: 'dest-1',
        type: OfflineCacheType.destination,
        title: 'Sigiriya',
        imageUrl: 'https://example.com/img.jpg',
        description: 'Ancient rock fortress',
        category: 'Heritage',
        location: 'Matale District',
        latitude: 7.9572,
        longitude: 80.7603,
        placeData: {'key': 'value'},
        savedAt: now,
      );

      expect(item.imageUrl, 'https://example.com/img.jpg');
      expect(item.description, 'Ancient rock fortress');
      expect(item.category, 'Heritage');
      expect(item.location, 'Matale District');
      expect(item.latitude, closeTo(7.9572, 0.0001));
      expect(item.longitude, closeTo(80.7603, 0.0001));
      expect(item.placeData, {'key': 'value'});
    });

    test('creates with all fields for route trip', () {
      final now = DateTime(2025, 3, 20);
      final item = OfflineCacheItem(
        id: 'trip-1',
        type: OfflineCacheType.routeTrip,
        title: 'Colombo to Galle',
        dateRange: '20-22 Mar',
        days: 3,
        stops: 5,
        distanceKm: 130.5,
        budgetLKR: 15000.0,
        transportMode: 'Car',
        travelTime: '3h 15m',
        emergencyContact: '+94771234567',
        routeData: {
          'origin': {'latitude': 6.9, 'longitude': 79.8},
          'routePoints': [],
          'optimizedStops': [],
        },
        savedAt: now,
      );

      expect(item.dateRange, '20-22 Mar');
      expect(item.days, 3);
      expect(item.stops, 5);
      expect(item.distanceKm, 130.5);
      expect(item.budgetLKR, 15000.0);
      expect(item.transportMode, 'Car');
      expect(item.travelTime, '3h 15m');
      expect(item.emergencyContact, '+94771234567');
      expect(item.routeData!['origin'], isNotNull);
    });
  });

  group('OfflineCacheItem — toJson', () {
    test('serialises required fields', () {
      final now = DateTime(2025, 1, 1, 12, 0, 0);
      final item = OfflineCacheItem(
        id: 'abc',
        type: OfflineCacheType.destination,
        title: 'Test Place',
        savedAt: now,
      );

      final json = item.toJson();

      expect(json['id'], 'abc');
      expect(json['type'], 'destination');
      expect(json['title'], 'Test Place');
      expect(json['savedAt'], now.toIso8601String());
    });

    test('serialises null optional fields as null', () {
      final item = OfflineCacheItem(
        id: 'x',
        type: OfflineCacheType.destination,
        title: 'T',
        savedAt: DateTime.now(),
      );

      final json = item.toJson();
      expect(json['imageUrl'], isNull);
      expect(json['description'], isNull);
      expect(json['latitude'], isNull);
      expect(json['routeData'], isNull);
      expect(json['placeData'], isNull);
    });

    test('routeData is JSON-encoded string in toJson', () {
      final item = OfflineCacheItem(
        id: 'trip',
        type: OfflineCacheType.routeTrip,
        title: 'My Trip',
        routeData: {'origin': 'Colombo', 'stops': 3},
        savedAt: DateTime.now(),
      );

      final json = item.toJson();
      expect(json['routeData'], isA<String>());
      final decoded = jsonDecode(json['routeData'] as String);
      expect(decoded['origin'], 'Colombo');
      expect(decoded['stops'], 3);
    });

    test('placeData is JSON-encoded string in toJson', () {
      final item = OfflineCacheItem(
        id: 'place',
        type: OfflineCacheType.destination,
        title: 'Ella',
        placeData: {'name': 'Ella', 'rating': 4.5},
        savedAt: DateTime.now(),
      );

      final json = item.toJson();
      expect(json['placeData'], isA<String>());
      final decoded = jsonDecode(json['placeData'] as String);
      expect(decoded['name'], 'Ella');
      expect(decoded['rating'], 4.5);
    });

    test('numeric fields are preserved', () {
      final item = OfflineCacheItem(
        id: 'trip',
        type: OfflineCacheType.routeTrip,
        title: 'Trip',
        latitude: 6.927,
        longitude: 79.861,
        days: 2,
        stops: 4,
        distanceKm: 55.5,
        budgetLKR: 8000.75,
        savedAt: DateTime.now(),
      );

      final json = item.toJson();
      expect(json['latitude'], 6.927);
      expect(json['longitude'], 79.861);
      expect(json['days'], 2);
      expect(json['stops'], 4);
      expect(json['distanceKm'], 55.5);
      expect(json['budgetLKR'], 8000.75);
    });
  });

  group('OfflineCacheItem — fromJson', () {
    test('round-trips required fields', () {
      final now = DateTime(2025, 5, 10, 8, 0, 0);
      final original = OfflineCacheItem(
        id: 'round-trip',
        type: OfflineCacheType.destination,
        title: 'Kandy',
        savedAt: now,
      );

      final restored = OfflineCacheItem.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.title, original.title);
      expect(restored.savedAt.toIso8601String(),
          original.savedAt.toIso8601String());
    });

    test('round-trips all destination fields', () {
      final now = DateTime(2025, 7, 20, 14, 30);
      final original = OfflineCacheItem(
        id: 'dest-full',
        type: OfflineCacheType.destination,
        title: 'Galle',
        imageUrl: 'https://img.example.com/galle.jpg',
        description: 'Southern coastal fort city',
        category: 'Heritage',
        location: 'Southern Province',
        latitude: 6.0535,
        longitude: 80.2210,
        placeData: {'name': 'Galle', 'rating': 4.8, 'nested': {'a': 1}},
        savedAt: now,
      );

      final restored = OfflineCacheItem.fromJson(original.toJson());

      expect(restored.imageUrl, original.imageUrl);
      expect(restored.description, original.description);
      expect(restored.category, original.category);
      expect(restored.location, original.location);
      expect(restored.latitude, closeTo(original.latitude!, 0.0001));
      expect(restored.longitude, closeTo(original.longitude!, 0.0001));
      expect(restored.placeData!['name'], 'Galle');
      expect(restored.placeData!['rating'], 4.8);
      expect((restored.placeData!['nested'] as Map)['a'], 1);
    });

    test('round-trips all trip fields', () {
      final now = DateTime(2025, 12, 1);
      final routeData = {
        'origin': {'latitude': 7.873, 'longitude': 80.771},
        'routePoints': [
          {'latitude': 7.0, 'longitude': 80.0}
        ],
        'optimizedStops': [
          {'name': 'Kandy', 'order': 1}
        ],
      };
      final original = OfflineCacheItem(
        id: 'trip-full',
        type: OfflineCacheType.routeTrip,
        title: 'Island Tour',
        dateRange: '1-3 Dec',
        days: 3,
        stops: 6,
        distanceKm: 250.0,
        budgetLKR: 45000.0,
        transportMode: 'Bus',
        travelTime: '8h',
        emergencyContact: '+9477000000',
        routeData: routeData,
        savedAt: now,
      );

      final restored = OfflineCacheItem.fromJson(original.toJson());

      expect(restored.dateRange, '1-3 Dec');
      expect(restored.days, 3);
      expect(restored.stops, 6);
      expect(restored.distanceKm, 250.0);
      expect(restored.budgetLKR, 45000.0);
      expect(restored.transportMode, 'Bus');
      expect(restored.travelTime, '8h');
      expect(restored.emergencyContact, '+9477000000');
      expect(restored.routeData!['origin'], isNotNull);
      final origin = restored.routeData!['origin'] as Map;
      expect(origin['latitude'], 7.873);
      final stops = restored.routeData!['optimizedStops'] as List;
      expect(stops[0]['name'], 'Kandy');
    });

    test('unknown type falls back to destination', () {
      final json = {
        'id': 'x',
        'type': 'unknownType',
        'title': 'T',
        'savedAt': DateTime.now().toIso8601String(),
      };

      final item = OfflineCacheItem.fromJson(json);
      expect(item.type, OfflineCacheType.destination);
    });

    test('missing title defaults to empty string', () {
      final json = {
        'id': 'x',
        'type': 'destination',
        'savedAt': DateTime.now().toIso8601String(),
      };

      final item = OfflineCacheItem.fromJson(json);
      expect(item.title, '');
    });

    test('missing savedAt defaults to approximately now', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final json = {
        'id': 'x',
        'type': 'destination',
        'title': 'T',
        'savedAt': null,
      };

      final item = OfflineCacheItem.fromJson(json);
      expect(item.savedAt.isAfter(before), isTrue);
    });

    test('routeData as Map (not string) is parsed correctly', () {
      final json = {
        'id': 'x',
        'type': 'routeTrip',
        'title': 'T',
        'routeData': {'key': 'val'},
        'savedAt': DateTime.now().toIso8601String(),
      };

      final item = OfflineCacheItem.fromJson(json);
      expect(item.routeData!['key'], 'val');
    });

    test('placeData as Map (not string) is parsed correctly', () {
      final json = {
        'id': 'x',
        'type': 'destination',
        'title': 'T',
        'placeData': {'name': 'Ella'},
        'savedAt': DateTime.now().toIso8601String(),
      };

      final item = OfflineCacheItem.fromJson(json);
      expect(item.placeData!['name'], 'Ella');
    });

    test('malformed routeData string is silently ignored', () {
      final json = {
        'id': 'x',
        'type': 'routeTrip',
        'title': 'T',
        'routeData': 'not valid json {{{',
        'savedAt': DateTime.now().toIso8601String(),
      };

      final item = OfflineCacheItem.fromJson(json);
      expect(item.routeData, isNull);
    });

    test('malformed placeData string is silently ignored', () {
      final json = {
        'id': 'x',
        'type': 'destination',
        'title': 'T',
        'placeData': '<<<invalid>>>',
        'savedAt': DateTime.now().toIso8601String(),
      };

      final item = OfflineCacheItem.fromJson(json);
      expect(item.placeData, isNull);
    });

    test('numeric fields parsed from int json values', () {
      final json = {
        'id': 'x',
        'type': 'routeTrip',
        'title': 'T',
        'days': 5,
        'stops': 8,
        'distanceKm': 300,
        'budgetLKR': 50000,
        'latitude': 7,
        'longitude': 80,
        'savedAt': DateTime.now().toIso8601String(),
      };

      final item = OfflineCacheItem.fromJson(json);
      expect(item.days, 5);
      expect(item.stops, 8);
      expect(item.distanceKm, 300.0);
      expect(item.budgetLKR, 50000.0);
      expect(item.latitude, 7.0);
      expect(item.longitude, 80.0);
    });
  });

  group('OfflineCacheItem — copyWith', () {
    test('copyWith id overrides id only', () {
      final now = DateTime(2025, 1, 1);
      final original = OfflineCacheItem(
        id: 'original-id',
        type: OfflineCacheType.destination,
        title: 'Ella',
        savedAt: now,
      );

      final copy = original.copyWith(id: 'new-id');
      expect(copy.id, 'new-id');
      expect(copy.type, original.type);
      expect(copy.title, original.title);
      expect(copy.savedAt, original.savedAt);
    });

    test('copyWith type overrides type only', () {
      final now = DateTime(2025, 1, 1);
      final original = OfflineCacheItem(
        id: 'abc',
        type: OfflineCacheType.destination,
        title: 'Ella',
        savedAt: now,
      );

      final copy = original.copyWith(type: OfflineCacheType.routeTrip);
      expect(copy.type, OfflineCacheType.routeTrip);
      expect(copy.id, original.id);
    });

    test('copyWith preserves optional fields', () {
      final now = DateTime(2025, 1, 1);
      final original = OfflineCacheItem(
        id: 'abc',
        type: OfflineCacheType.destination,
        title: 'Ella',
        imageUrl: 'https://img.com/ella.jpg',
        latitude: 6.87,
        longitude: 81.04,
        placeData: {'k': 'v'},
        savedAt: now,
      );

      final copy = original.copyWith(id: 'new');
      expect(copy.imageUrl, original.imageUrl);
      expect(copy.latitude, original.latitude);
      expect(copy.longitude, original.longitude);
      expect(copy.placeData, original.placeData);
    });
  });
}
