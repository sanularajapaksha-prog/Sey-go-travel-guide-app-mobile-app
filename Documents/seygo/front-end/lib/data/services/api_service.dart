import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/place.dart';

class ApiService {
  static final Map<String, String?> _resolvedPhotoCache = <String, String?>{};
  static final Map<String, Future<String?>> _pendingPhotoRequests =
      <String, Future<String?>>{};

  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      if (envUrl.contains('10.0.2.2') &&
          defaultTargetPlatform != TargetPlatform.android) {
        return envUrl.replaceAll('10.0.2.2', '127.0.0.1');
      }
      return envUrl;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Client-side fallback when backend route optimization is unavailable.
  /// Returns the destinations in their given order with empty polyline data.
  static Future<Map<String, dynamic>> optimizeRoute({
    required Map<String, dynamic> origin,
    required List<Map<String, dynamic>> destinations,
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    // Try backend if available; otherwise gracefully fall back.
    final uri = Uri.parse('$baseUrl/route/optimize');
    try {
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'origin': origin,
              'destinations': destinations,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
      // If backend fails, drop to client fallback below.
    } catch (_) {
      // Intentionally swallow; we return a safe fallback.
    }

    return {
      'optimized_stops': destinations,
      'polyline_points': <Map<String, dynamic>>[],
      'total_distance_km': null,
      'total_duration_min': null,
    };
  }

  static Future<List<dynamic>> fetchPlaces({
    String? accessToken,
    int limit = 100,
    int offset = 0,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final uri = Uri.parse(
      '$baseUrl/places/',
    ).replace(queryParameters: {'limit': '$limit', 'offset': '$offset'});

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception(
      'Failed to load places: ${response.statusCode} ${response.body}',
    );
  }

  static Future<List<dynamic>> searchPlacesFromDb({
    required String query,
    double? latitude,
    double? longitude,
    double radiusKm = 60,
    int limit = 30,
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final params = <String, String>{
      'q': query,
      'radius_km': radiusKm.toString(),
      'limit': limit.toString(),
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/places/search',
    ).replace(queryParameters: params);

    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to search places: ${response.statusCode} ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      final places = body['places'];
      if (places is List) {
        return places;
      }
    }
    return const <dynamic>[];
  }

  static Future<String?> resolveBestPlaceImage(Place place) async {
    final cacheKey = place.id.isNotEmpty ? place.id : (place.googleUrl ?? place.name);
    if (_resolvedPhotoCache.containsKey(cacheKey)) {
      return _resolvedPhotoCache[cacheKey];
    }

    final immediate = place.resolveBestAvailableImageUrl();
    if (immediate != null) {
      _resolvedPhotoCache[cacheKey] = immediate;
      return immediate;
    }

    final googleUrl = place.googleUrl;
    if (googleUrl == null || googleUrl.isEmpty) {
      _resolvedPhotoCache[cacheKey] = null;
      return null;
    }

    final pending = _pendingPhotoRequests[cacheKey];
    if (pending != null) {
      return pending;
    }

    final future = _resolvePhotoFromGoogleUrl(
      googleUrl: googleUrl,
      placeId: place.id,
    );
    _pendingPhotoRequests[cacheKey] = future;

    try {
      final resolved = await future;
      _resolvedPhotoCache[cacheKey] = resolved;
      return resolved;
    } finally {
      _pendingPhotoRequests.remove(cacheKey);
    }
  }

  static Future<String?> resolvePhotoFromRawGoogleUrl(
    String googleUrl, {
    String? cacheKey,
    String? placeId,
  }) async {
    final key = cacheKey ?? placeId ?? googleUrl;
    if (_resolvedPhotoCache.containsKey(key)) {
      return _resolvedPhotoCache[key];
    }
    final pending = _pendingPhotoRequests[key];
    if (pending != null) {
      return pending;
    }
    final future = _resolvePhotoFromGoogleUrl(
      googleUrl: googleUrl,
      placeId: placeId,
    );
    _pendingPhotoRequests[key] = future;
    try {
      final resolved = await future;
      _resolvedPhotoCache[key] = resolved;
      return resolved;
    } finally {
      _pendingPhotoRequests.remove(key);
    }
  }

  static Future<String?> _resolvePhotoFromGoogleUrl({
    required String googleUrl,
    String? placeId,
  }) async {
    // --- Direct Google Places API resolution using GOOGLE_PLACES_API_KEY ---
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

    if (apiKey.isNotEmpty) {
      // Try resolving directly via Google Places API (no backend needed)
      final directUrl = await _resolveViaGooglePlacesApi(
        googleUrl: googleUrl,
        apiKey: apiKey,
      );
      if (directUrl != null) return directUrl;
    }

    // --- Fallback: use backend endpoint ---
    final uri = Uri.parse('$baseUrl/places/photo-from-google-url').replace(
      queryParameters: <String, String>{
        'url': googleUrl,
        if (placeId != null && placeId.isNotEmpty) 'place_id': placeId,
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final bodyText = response.body.isEmpty ? '{}' : response.body;
      final decoded = jsonDecode(bodyText);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      if (decoded['success'] != true) {
        return null;
      }

      final resolved = Place.withGooglePhotoWidth(decoded['photo_url']?.toString());
      return resolved;
    } catch (_) {
      return null;
    }
  }

  /// Resolves a Google Maps URL directly to a photo URL using
  /// the Google Places API.
  ///
  /// Flow:
  ///   1. Extract `cid` (e.g. ?cid=123) OR `q` (e.g. ?q=Kandy) from URL
  ///   2. Use Find Place API to get the place_id
  ///   3. Use Place Details API to get a photo_reference
  ///   4. Build the photo URL from the photo_reference
  static Future<String?> _resolveViaGooglePlacesApi({
    required String googleUrl,
    required String apiKey,
  }) async {
    try {
      // Step 1: Extract CID or Query from URL
      final uri = Uri.tryParse(googleUrl);
      final cid = uri?.queryParameters['cid'];
      final q = uri?.queryParameters['q'];
      
      String searchInput;
      if (cid != null && cid.isNotEmpty) {
        searchInput = 'cid:$cid';
      } else if (q != null && q.isNotEmpty) {
        searchInput = q;
      } else {
        return null;
      }

      // Step 2: Find Place using CID or Query → get place_id
      final findPlaceUri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json',
      ).replace(queryParameters: {
        'input': searchInput,
        'inputtype': 'textquery',
        'fields': 'place_id',
        'key': apiKey,
      });

      final findResponse = await http
          .get(findPlaceUri)
          .timeout(const Duration(seconds: 10));

      if (findResponse.statusCode != 200) return null;

      final findData = jsonDecode(findResponse.body) as Map<String, dynamic>;
      final candidates = findData['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final resolvedPlaceId =
          (candidates.first as Map<String, dynamic>)['place_id']?.toString();
      if (resolvedPlaceId == null || resolvedPlaceId.isEmpty) return null;

      // Step 3: Get photo_reference from Place Details
      final detailsUri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json',
      ).replace(queryParameters: {
        'place_id': resolvedPlaceId,
        'fields': 'photos',
        'key': apiKey,
      });

      final detailsResponse = await http
          .get(detailsUri)
          .timeout(const Duration(seconds: 10));

      if (detailsResponse.statusCode != 200) return null;

      final detailsData =
          jsonDecode(detailsResponse.body) as Map<String, dynamic>;
      final photos =
          (detailsData['result'] as Map<String, dynamic>?)?['photos'] as List?;
      if (photos == null || photos.isEmpty) return null;

      final photoRef =
          (photos.first as Map<String, dynamic>)['photo_reference']?.toString();
      if (photoRef == null || photoRef.isEmpty) return null;

      // Step 4: Build final photo URL
      final photoUrl =
          'https://maps.googleapis.com/maps/api/place/photo'
          '?maxwidth=800'
          '&photoreference=$photoRef'
          '&key=$apiKey';

      return photoUrl;
    } catch (_) {
      return null;
    }
  }


  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    final bodyText = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(bodyText);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    }

    if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
      throw Exception(decoded['detail'].toString());
    }
    throw Exception('Registration failed: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    final bodyText = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(bodyText);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    }

    if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
      throw Exception(decoded['detail'].toString());
    }
    throw Exception('Login failed: ${response.statusCode}');
  }

  static Future<void> sendLoginOtp({required String email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/send-otp'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final bodyText = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(bodyText);
    if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
      throw Exception(decoded['detail'].toString());
    }
    throw Exception('Failed to send login code: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> verifyLoginOtp({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/verify-otp'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      }),
    );

    final bodyText = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(bodyText);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    }

    if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
      throw Exception(decoded['detail'].toString());
    }
    throw Exception('Failed to verify login code: ${response.statusCode}');
  }

  static Future<void> resendVerificationCode({required String email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-verification'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final bodyText = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(bodyText);
    if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
      throw Exception(decoded['detail'].toString());
    }
    throw Exception('Failed to resend code: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      }),
    );

    final bodyText = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(bodyText);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    }

    if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
      throw Exception(decoded['detail'].toString());
    }
    throw Exception('Failed to verify code: ${response.statusCode}');
  }

  /// Geocode a free-text query to lat/lng using the Google Places
  /// findplacefromtext API, biased to Sri Lanka.
  /// Returns a map with keys: name, latitude, longitude, address, place_id.
  static Future<Map<String, dynamic>?> geocodePlace(String query) async {
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
    if (apiKey.isEmpty) return null;
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json',
      ).replace(queryParameters: {
        'input': query,
        'inputtype': 'textquery',
        'fields': 'place_id,name,geometry,formatted_address',
        'locationbias': 'rectangle:5.5,79.4|10.1,82.1',
        'key': apiKey,
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;
      final candidate = candidates.first as Map<String, dynamic>;
      final geometry = candidate['geometry'] as Map?;
      final location = geometry?['location'] as Map?;
      if (location == null) return null;
      return {
        'name': candidate['name']?.toString() ?? query,
        'latitude': (location['lat'] as num).toDouble(),
        'longitude': (location['lng'] as num).toDouble(),
        'address': candidate['formatted_address']?.toString() ?? '',
        'place_id': candidate['place_id']?.toString() ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // User Profile
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>?> fetchProfile({
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
    final uri = Uri.parse('$baseUrl/users/me');
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> updateProfile({
    String? fullName,
    String? bio,
    String? homeCity,
    String? travelStyle,
    String? avatarUrl,
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
    final uri = Uri.parse('$baseUrl/users/me');
    final payload = <String, dynamic>{
      if (fullName != null) 'full_name': fullName,
      if (bio != null) 'bio': bio,
      if (homeCity != null) 'home_city': homeCity,
      if (travelStyle != null) 'travel_style': travelStyle,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
    try {
      final response = await http
          .put(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Playlists
  // ---------------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> fetchPlaylists({
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
    final uri = Uri.parse('$baseUrl/playlists/');
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = body['playlists'] as List? ?? [];
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return const [];
  }

  static Future<Map<String, dynamic>?> fetchPlaylistDetails({
    required String playlistId,
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
    final uri = Uri.parse('$baseUrl/playlists/$playlistId/details');
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> createPlaylist({
    required String name,
    String? description,
    String icon = 'playlist_play',
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
    final uri = Uri.parse('$baseUrl/playlists/');
    try {
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'name': name,
              if (description != null) 'description': description,
              'icon': icon,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deletePlaylist({
    required String playlistId,
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
    final uri = Uri.parse('$baseUrl/playlists/$playlistId');
    try {
      final response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updatePlaylist({
    required String playlistId,
    String? name,
    String? description,
    String? icon,
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
    final uri = Uri.parse('$baseUrl/playlists/$playlistId');
    final payload = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
    };
    if (payload.isEmpty) return false;
    try {
      final response = await http
          .put(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
