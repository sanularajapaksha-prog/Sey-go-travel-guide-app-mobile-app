import 'package:flutter_test/flutter_test.dart';
import 'package:seygo_travel_app/providers/favorites_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

FavoritePlace _place({
  String id = 'place-1',
  String name = 'Sigiriya',
  String? imageUrl = 'https://cdn.net/sigiriya.jpg',
  String? googleUrl = 'https://maps.google.com/?cid=1',
  String location = 'Matale District',
  String semanticLabel = 'Ancient rock fortress',
}) =>
    FavoritePlace(
      id: id,
      name: name,
      imageUrl: imageUrl,
      googleUrl: googleUrl,
      location: location,
      semanticLabel: semanticLabel,
    );

void main() {
  // ── FavoritePlace model ───────────────────────────────────────────────────
  group('FavoritePlace — construction', () {
    test('stores all required fields', () {
      final p = _place();
      expect(p.id, 'place-1');
      expect(p.name, 'Sigiriya');
      expect(p.imageUrl, 'https://cdn.net/sigiriya.jpg');
      expect(p.googleUrl, 'https://maps.google.com/?cid=1');
      expect(p.location, 'Matale District');
      expect(p.semanticLabel, 'Ancient rock fortress');
    });

    test('null imageUrl is accepted', () {
      final p = _place(imageUrl: null);
      expect(p.imageUrl, isNull);
    });

    test('null googleUrl is accepted', () {
      final p = _place(googleUrl: null);
      expect(p.googleUrl, isNull);
    });

    test('both optional fields null simultaneously', () {
      final p = _place(imageUrl: null, googleUrl: null);
      expect(p.imageUrl, isNull);
      expect(p.googleUrl, isNull);
    });
  });

  // ── FavoritePlace.toJson ───────────────────────────────────────────────────
  group('FavoritePlace.toJson', () {
    test('contains all expected keys', () {
      final json = _place().toJson();
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('imageUrl'), isTrue);
      expect(json.containsKey('googleUrl'), isTrue);
      expect(json.containsKey('location'), isTrue);
      expect(json.containsKey('semanticLabel'), isTrue);
    });

    test('values match constructor arguments', () {
      final json = _place().toJson();
      expect(json['id'], 'place-1');
      expect(json['name'], 'Sigiriya');
      expect(json['imageUrl'], 'https://cdn.net/sigiriya.jpg');
      expect(json['googleUrl'], 'https://maps.google.com/?cid=1');
      expect(json['location'], 'Matale District');
      expect(json['semanticLabel'], 'Ancient rock fortress');
    });

    test('null imageUrl serialises as null', () {
      final json = _place(imageUrl: null).toJson();
      expect(json['imageUrl'], isNull);
    });

    test('null googleUrl serialises as null', () {
      final json = _place(googleUrl: null).toJson();
      expect(json['googleUrl'], isNull);
    });
  });

  // ── FavoritePlace.fromJson ─────────────────────────────────────────────────
  group('FavoritePlace.fromJson', () {
    test('restores all fields', () {
      final json = {
        'id': 'abc',
        'name': 'Kandy',
        'imageUrl': 'https://cdn.net/kandy.jpg',
        'googleUrl': 'https://maps.google.com/?cid=9',
        'location': 'Kandy District',
        'semanticLabel': 'Cultural city',
      };
      final p = FavoritePlace.fromJson(json);
      expect(p.id, 'abc');
      expect(p.name, 'Kandy');
      expect(p.imageUrl, 'https://cdn.net/kandy.jpg');
      expect(p.googleUrl, 'https://maps.google.com/?cid=9');
      expect(p.location, 'Kandy District');
      expect(p.semanticLabel, 'Cultural city');
    });

    test('null imageUrl is restored as null', () {
      final json = {
        'id': 'x',
        'name': 'Ella',
        'imageUrl': null,
        'googleUrl': null,
        'location': 'Badulla',
        'semanticLabel': 'Mountain town',
      };
      final p = FavoritePlace.fromJson(json);
      expect(p.imageUrl, isNull);
      expect(p.googleUrl, isNull);
    });
  });

  // ── FavoritePlace round-trip ───────────────────────────────────────────────
  group('FavoritePlace — toJson / fromJson round-trip', () {
    test('full data survives round-trip', () {
      final original = _place();
      final restored = FavoritePlace.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.googleUrl, original.googleUrl);
      expect(restored.location, original.location);
      expect(restored.semanticLabel, original.semanticLabel);
    });

    test('null optional fields survive round-trip', () {
      final original = _place(imageUrl: null, googleUrl: null);
      final restored = FavoritePlace.fromJson(original.toJson());
      expect(restored.imageUrl, isNull);
      expect(restored.googleUrl, isNull);
    });

    test('special characters in name survive round-trip', () {
      final original = _place(name: "Temple O'Brien & Sons — \"Grand\"");
      final restored = FavoritePlace.fromJson(original.toJson());
      expect(restored.name, original.name);
    });

    test('unicode characters survive round-trip', () {
      final original = _place(name: 'දිගාමඩුල්ල', location: 'ශ්‍රී ලංකාව');
      final restored = FavoritePlace.fromJson(original.toJson());
      expect(restored.name, original.name);
      expect(restored.location, original.location);
    });
  });
}
