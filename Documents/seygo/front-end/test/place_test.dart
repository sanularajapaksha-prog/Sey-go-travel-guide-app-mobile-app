import 'package:flutter_test/flutter_test.dart';
import 'package:seygo_travel_app/data/models/place.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal valid map that produces a Place with no nulls.
Map<String, dynamic> _fullMap() => {
      'id': 'place-001',
      'name': 'Sigiriya Rock Fortress',
      'category': 'Heritage',
      'semanticLabel': 'Ancient rock fortress',
      'location': 'Matale District',
      'description': 'UNESCO World Heritage Site',
      'latitude': 7.9572,
      'longitude': 80.7603,
      'rating': 4.8,
      'review_count': 1200,
      'google_url': 'https://maps.google.com/?cid=12345',
      'image_url': 'https://img.example.net/sigiriya.jpg',
      'image_source': 'google',
      'photo_public_urls': [
        'https://cdn.example.net/photo1.jpg',
        'https://cdn.example.net/photo2.jpg',
      ],
    };

void main() {
  // ── Place.fromMap — happy path ─────────────────────────────────────────────
  group('Place.fromMap — full snake_case map', () {
    late Place place;

    setUp(() => place = Place.fromMap(_fullMap()));

    test('id parsed correctly', () => expect(place.id, 'place-001'));
    test('name parsed correctly',
        () => expect(place.name, 'Sigiriya Rock Fortress'));
    test('category parsed correctly', () => expect(place.category, 'Heritage'));
    test('semanticLabel parsed correctly',
        () => expect(place.semanticLabel, 'Ancient rock fortress'));
    test('location parsed correctly',
        () => expect(place.location, 'Matale District'));
    test('description parsed correctly',
        () => expect(place.description, 'UNESCO World Heritage Site'));
    test('latitude parsed correctly',
        () => expect(place.latitude, closeTo(7.9572, 0.0001)));
    test('longitude parsed correctly',
        () => expect(place.longitude, closeTo(80.7603, 0.0001)));
    test('rating parsed correctly', () => expect(place.rating, 4.8));
    test('reviews parsed correctly', () => expect(place.reviews, 1200));
    test('googleUrl parsed correctly',
        () => expect(place.googleUrl, 'https://maps.google.com/?cid=12345'));
    test('imageUrl parsed correctly',
        () => expect(place.imageUrl, 'https://img.example.net/sigiriya.jpg'));
    test('imageSource parsed correctly',
        () => expect(place.imageSource, 'google'));
    test('photoPublicUrls parsed correctly',
        () => expect(place.photoPublicUrls.length, 2));
  });

  // ── Place.fromMap — field aliases ──────────────────────────────────────────
  group('Place.fromMap — camelCase / alias fields', () {
    test('place_id alias used when id is absent', () {
      final p = Place.fromMap({'place_id': 'pid-1', 'name': 'X'});
      expect(p.id, 'pid-1');
    });

    test('id falls back to name when both id and place_id absent', () {
      final p = Place.fromMap({'name': 'Ella'});
      expect(p.id, 'Ella');
    });

    test('lat alias for latitude', () {
      final p = Place.fromMap({'name': 'A', 'lat': 6.5, 'lng': 80.0});
      expect(p.latitude, closeTo(6.5, 0.0001));
    });

    test('lng alias for longitude', () {
      final p = Place.fromMap({'name': 'A', 'lat': 6.5, 'lng': 80.0});
      expect(p.longitude, closeTo(80.0, 0.0001));
    });

    test('lon alias for longitude', () {
      final p = Place.fromMap({'name': 'A', 'longitude': null, 'lon': 79.5});
      expect(p.longitude, closeTo(79.5, 0.0001));
    });

    test('avg_rating alias for rating', () {
      final p = Place.fromMap({'name': 'A', 'avg_rating': 3.7});
      expect(p.rating, closeTo(3.7, 0.01));
    });

    test('reviews alias for review_count', () {
      final p = Place.fromMap({'name': 'A', 'reviews': 55});
      expect(p.reviews, 55);
    });

    test('googleUrl camelCase alias', () {
      final p = Place.fromMap(
          {'name': 'A', 'googleUrl': 'https://maps.google.com/?cid=99'});
      expect(p.googleUrl, 'https://maps.google.com/?cid=99');
    });

    test('imageUrl camelCase alias', () {
      final p = Place.fromMap(
          {'name': 'A', 'imageUrl': 'https://cdn.net/img.jpg'});
      expect(p.imageUrl, 'https://cdn.net/img.jpg');
    });

    test('photo_url alias for imageUrl', () {
      final p = Place.fromMap(
          {'name': 'A', 'photo_url': 'https://cdn.net/photo.jpg'});
      expect(p.imageUrl, 'https://cdn.net/photo.jpg');
    });

    test('photoPublicUrls camelCase alias', () {
      final p = Place.fromMap({
        'name': 'A',
        'photoPublicUrls': ['https://cdn.net/a.jpg']
      });
      expect(p.photoPublicUrls.length, 1);
    });

    test('address alias for location', () {
      final p = Place.fromMap({'name': 'A', 'address': 'Colombo'});
      expect(p.location, 'Colombo');
    });

    test('formatted_address alias for location', () {
      final p =
          Place.fromMap({'name': 'A', 'formatted_address': 'Galle Fort'});
      expect(p.location, 'Galle Fort');
    });

    test('summary alias for description', () {
      final p = Place.fromMap({'name': 'A', 'summary': 'Nice place'});
      expect(p.description, 'Nice place');
    });

    test('image_source alias for imageSource', () {
      final p =
          Place.fromMap({'name': 'A', 'image_source': 'supabase'});
      expect(p.imageSource, 'supabase');
    });
  });

  // ── Place.fromMap — defaults when fields missing ───────────────────────────
  group('Place.fromMap — missing / null fields use defaults', () {
    late Place p;
    setUp(() => p = Place.fromMap({}));

    test('name defaults to Unknown Place', () => expect(p.name, 'Unknown Place'));
    test('category defaults to Other', () => expect(p.category, 'Other'));
    test('semanticLabel defaults to Place photo',
        () => expect(p.semanticLabel, 'Place photo'));
    test('location defaults to empty string', () => expect(p.location, ''));
    test('description defaults to No description available.',
        () => expect(p.description, 'No description available.'));
    test('latitude is null', () => expect(p.latitude, isNull));
    test('longitude is null', () => expect(p.longitude, isNull));
    test('rating defaults to 0.0', () => expect(p.rating, 0.0));
    test('reviews defaults to 0', () => expect(p.reviews, 0));
    test('googleUrl is null', () => expect(p.googleUrl, isNull));
    test('imageUrl is null', () => expect(p.imageUrl, isNull));
    test('imageSource is null', () => expect(p.imageSource, isNull));
    test('photoPublicUrls is empty', () => expect(p.photoPublicUrls, isEmpty));
  });

  // ── Place.fromMap — type coercion (_toDouble, _toInt) ─────────────────────
  group('Place.fromMap — numeric type coercion', () {
    test('latitude from int', () {
      final p = Place.fromMap({'name': 'A', 'latitude': 7, 'longitude': 80});
      expect(p.latitude, 7.0);
      expect(p.latitude, isA<double>());
    });

    test('latitude from string number', () {
      final p = Place.fromMap({'name': 'A', 'latitude': '6.927'});
      expect(p.latitude, closeTo(6.927, 0.0001));
    });

    test('latitude null for invalid string', () {
      final p = Place.fromMap({'name': 'A', 'latitude': 'not-a-number'});
      expect(p.latitude, isNull);
    });

    test('rating from int', () {
      final p = Place.fromMap({'name': 'A', 'rating': 5});
      expect(p.rating, 5.0);
    });

    test('rating from string', () {
      final p = Place.fromMap({'name': 'A', 'rating': '3.5'});
      expect(p.rating, closeTo(3.5, 0.01));
    });

    test('review_count from double is truncated to int', () {
      final p = Place.fromMap({'name': 'A', 'review_count': 42.9});
      expect(p.reviews, 42);
    });

    test('review_count from string', () {
      final p = Place.fromMap({'name': 'A', 'reviews': '100'});
      expect(p.reviews, 100);
    });
  });

  // ── Place._normalizeHttpUrl — URL validation ───────────────────────────────
  group('Place.fromMap — URL normalisation', () {
    test('valid https URL is accepted for imageUrl', () {
      final p = Place.fromMap(
          {'name': 'A', 'image_url': 'https://cdn.example.net/img.jpg'});
      expect(p.imageUrl, isNotNull);
    });

    test('valid http URL is accepted', () {
      final p = Place.fromMap(
          {'name': 'A', 'image_url': 'http://cdn.example.net/img.jpg'});
      expect(p.imageUrl, isNotNull);
    });

    test('example.com URL is blocked', () {
      final p =
          Place.fromMap({'name': 'A', 'image_url': 'https://example.com/img.jpg'});
      expect(p.imageUrl, isNull);
    });

    test('source.unsplash.com URL is blocked', () {
      final p = Place.fromMap(
          {'name': 'A', 'image_url': 'https://source.unsplash.com/random'});
      expect(p.imageUrl, isNull);
    });

    test('relative URL is rejected', () {
      final p = Place.fromMap({'name': 'A', 'image_url': '/images/photo.jpg'});
      expect(p.imageUrl, isNull);
    });

    test('empty string URL is rejected', () {
      final p = Place.fromMap({'name': 'A', 'image_url': ''});
      expect(p.imageUrl, isNull);
    });

    test('null URL is rejected', () {
      final p = Place.fromMap({'name': 'A', 'image_url': null});
      expect(p.imageUrl, isNull);
    });

    test('google_url with example.com is blocked', () {
      final p = Place.fromMap(
          {'name': 'A', 'google_url': 'https://example.com/?cid=1'});
      expect(p.googleUrl, isNull);
    });
  });

  // ── Place._toStringList ────────────────────────────────────────────────────
  group('Place.fromMap — photoPublicUrls parsing (_toStringList)', () {
    test('list of valid URLs returns all valid ones', () {
      final p = Place.fromMap({
        'name': 'A',
        'photo_public_urls': [
          'https://cdn.net/a.jpg',
          'https://cdn.net/b.jpg',
        ],
      });
      expect(p.photoPublicUrls.length, 2);
    });

    test('list filters out invalid URLs', () {
      final p = Place.fromMap({
        'name': 'A',
        'photo_public_urls': [
          'https://cdn.net/a.jpg',
          'not-a-url',
          '',
          null,
          'https://example.com/x.jpg',
        ],
      });
      // only the first URL is valid
      expect(p.photoPublicUrls.length, 1);
      expect(p.photoPublicUrls.first, 'https://cdn.net/a.jpg');
    });

    test('JSON-encoded string array is parsed', () {
      final p = Place.fromMap({
        'name': 'A',
        'photo_public_urls':
            '["https://cdn.net/a.jpg","https://cdn.net/b.jpg"]',
      });
      expect(p.photoPublicUrls.length, 2);
    });

    test('single URL string is wrapped in a list', () {
      final p = Place.fromMap({
        'name': 'A',
        'photo_public_urls': 'https://cdn.net/single.jpg',
      });
      expect(p.photoPublicUrls.length, 1);
      expect(p.photoPublicUrls.first, 'https://cdn.net/single.jpg');
    });

    test('empty string returns empty list', () {
      final p = Place.fromMap({'name': 'A', 'photo_public_urls': ''});
      expect(p.photoPublicUrls, isEmpty);
    });

    test('null returns empty list', () {
      final p = Place.fromMap({'name': 'A', 'photo_public_urls': null});
      expect(p.photoPublicUrls, isEmpty);
    });

    test('integer value returns empty list', () {
      final p = Place.fromMap({'name': 'A', 'photo_public_urls': 42});
      expect(p.photoPublicUrls, isEmpty);
    });
  });

  // ── Place.withGooglePhotoWidth ─────────────────────────────────────────────
  group('Place.withGooglePhotoWidth', () {
    test('adds maxwidth param to a plain Google URL', () {
      final result = Place.withGooglePhotoWidth(
          'https://maps.google.com/?cid=12345');
      expect(result, contains('maxwidth=800'));
    });

    test('respects custom maxWidth param', () {
      final result = Place.withGooglePhotoWidth(
          'https://maps.google.com/?cid=12345',
          maxWidth: 400);
      expect(result, contains('maxwidth=400'));
    });

    test('does not override existing maxwidth', () {
      final result = Place.withGooglePhotoWidth(
          'https://maps.google.com/?cid=12345&maxwidth=1200');
      expect(result, contains('maxwidth=1200'));
      expect(result, isNot(contains('maxwidth=800')));
    });

    test('returns null for null input', () {
      expect(Place.withGooglePhotoWidth(null), isNull);
    });

    test('returns null for empty string', () {
      expect(Place.withGooglePhotoWidth(''), isNull);
    });

    test('returns null for relative URL', () {
      expect(Place.withGooglePhotoWidth('/photo.jpg'), isNull);
    });

    test('returns null for example.com URL', () {
      expect(
          Place.withGooglePhotoWidth('https://example.com/img.jpg'), isNull);
    });

    test('preserves other query params', () {
      final result = Place.withGooglePhotoWidth(
          'https://maps.google.com/?cid=12345&hl=en');
      expect(result, contains('cid=12345'));
      expect(result, contains('hl=en'));
    });
  });

  // ── Place.resolveBestAvailableImageUrl ─────────────────────────────────────
  group('Place.resolveBestAvailableImageUrl', () {
    test('returns first valid photoPublicUrl when available', () {
      final p = Place.fromMap({
        'name': 'A',
        'photo_public_urls': [
          'https://cdn.net/photo1.jpg',
          'https://cdn.net/photo2.jpg',
        ],
        'image_url': 'https://cdn.net/fallback.jpg',
      });
      expect(p.resolveBestAvailableImageUrl(),
          contains('cdn.net/photo1.jpg'));
    });

    test('falls back to imageUrl when photoPublicUrls is empty', () {
      final p = Place.fromMap({
        'name': 'A',
        'photo_public_urls': [],
        'image_url': 'https://cdn.net/fallback.jpg',
      });
      expect(p.resolveBestAvailableImageUrl(),
          contains('cdn.net/fallback.jpg'));
    });

    test('returns null when all sources are null/empty', () {
      final p = Place.fromMap({'name': 'A'});
      expect(p.resolveBestAvailableImageUrl(), isNull);
    });

    test('skips invalid photoPublicUrls and uses next valid one', () {
      final p = Place.fromMap({
        'name': 'A',
        'photo_public_urls': [
          'not-a-url',
          'https://example.com/x.jpg', // blocked
          'https://cdn.net/valid.jpg',
        ],
      });
      expect(p.resolveBestAvailableImageUrl(),
          contains('cdn.net/valid.jpg'));
    });
  });

  // ── Place getters ──────────────────────────────────────────────────────────
  group('Place computed getters', () {
    test('googlePhotoUrl adds maxwidth to googleUrl', () {
      final p = Place.fromMap({
        'name': 'A',
        'google_url': 'https://maps.google.com/?cid=999',
      });
      expect(p.googlePhotoUrl, contains('maxwidth='));
    });

    test('googlePhotoUrl is null when googleUrl is null', () {
      final p = Place.fromMap({'name': 'A'});
      expect(p.googlePhotoUrl, isNull);
    });

    test('cachedImageUrl adds maxwidth to imageUrl', () {
      final p = Place.fromMap({
        'name': 'A',
        'image_url': 'https://cdn.net/img.jpg',
      });
      expect(p.cachedImageUrl, contains('maxwidth='));
    });

    test('cachedImageUrl is null when imageUrl is null', () {
      final p = Place.fromMap({'name': 'A'});
      expect(p.cachedImageUrl, isNull);
    });
  });

  // ── Place.toMap ────────────────────────────────────────────────────────────
  group('Place.toMap', () {
    test('contains all expected keys', () {
      final p = Place.fromMap(_fullMap());
      final m = p.toMap();

      for (final key in [
        'id', 'name', 'category', 'semanticLabel', 'location', 'description',
        'latitude', 'longitude', 'rating', 'reviews',
        'googleUrl', 'google_url', 'imageUrl', 'image_url',
        'imageSource', 'image_source',
        'photoPublicUrls', 'photo_public_urls', 'image',
      ]) {
        expect(m.containsKey(key), isTrue, reason: 'Missing key: $key');
      }
    });

    test('toMap preserves numeric values', () {
      final p = Place.fromMap(_fullMap());
      final m = p.toMap();
      expect(m['latitude'], closeTo(7.9572, 0.0001));
      expect(m['longitude'], closeTo(80.7603, 0.0001));
      expect(m['rating'], 4.8);
      expect(m['reviews'], 1200);
    });

    test('toMap includes both camelCase and snake_case for URL fields', () {
      final p = Place.fromMap({
        'name': 'A',
        'google_url': 'https://maps.google.com/?cid=1',
        'image_url': 'https://cdn.net/img.jpg',
        'image_source': 'google',
      });
      final m = p.toMap();
      expect(m['googleUrl'], m['google_url']);
      expect(m['imageUrl'], m['image_url']);
      expect(m['imageSource'], m['image_source']);
    });

    test('toMap round-trip preserves core fields', () {
      final original = Place.fromMap(_fullMap());
      final restored = Place.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.category, original.category);
      expect(restored.location, original.location);
      expect(restored.rating, original.rating);
      expect(restored.reviews, original.reviews);
    });
  });

  // ── Edge cases ────────────────────────────────────────────────────────────
  group('Place.fromMap — edge cases', () {
    test('non-string id value is stringified', () {
      final p = Place.fromMap({'id': 42, 'name': 'A'});
      expect(p.id, '42');
    });

    test('non-string name value is stringified', () {
      final p = Place.fromMap({'name': 123});
      expect(p.name, '123');
    });

    test('zero rating is valid', () {
      final p = Place.fromMap({'name': 'A', 'rating': 0});
      expect(p.rating, 0.0);
    });

    test('zero reviews is valid', () {
      final p = Place.fromMap({'name': 'A', 'review_count': 0});
      expect(p.reviews, 0);
    });

    test('negative coordinates are accepted', () {
      final p = Place.fromMap(
          {'name': 'A', 'latitude': -33.8688, 'longitude': 151.2093});
      expect(p.latitude, closeTo(-33.8688, 0.0001));
    });

    test('extremely large review count is preserved', () {
      final p = Place.fromMap({'name': 'A', 'reviews': 999999});
      expect(p.reviews, 999999);
    });
  });
}
