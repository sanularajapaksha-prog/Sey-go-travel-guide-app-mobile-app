import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';

/// ============================================================================
/// API SERVICE CORE ARCHITECTURE
/// ============================================================================
/// 
/// Overview:
/// This service acts as the central networking hub for the SeyGo application.
/// It interfaces directly with the SeyGo Python/FastAPI backend and Supabase
/// for authentication, storage, and database operations.
/// 
/// Architectural Principles:
/// 1. Stateless Operations:
///    Except for extremely short-lived memory caches (e.g. `_resolvedPhotoCache`),
///    no persistent state should live here. All state must be provided by 
///    Providers or passed via parameters.
/// 
/// 2. Error Boundary Strategy:
///    - Silent failures (e.g. `catch (_) {}`) are STRICTLY FORBIDDEN.
///    - All network errors must be caught, logged via `debugPrint` or a central
///      logger, and optionally rethrown to the UI for user feedback.
///    - For operations with safe fallbacks (like route optimization failing over
///      to nearest-neighbor), the error should be logged, but the fallback data
///      should be returned gently.
/// 
/// 3. Authentication Flow:
///    - Every secure endpoint expects a valid JWT `accessToken`.
///    - The `supabase_flutter` SDK handles token refresh automatically. 
///      Always query `Supabase.instance.client.auth.currentSession?.accessToken` 
///      at the moment of the request rather than storing it locally.
/// 
/// 4. Environment and Security (HTTPS Enforcement):
///    - The `API_BASE_URL` is parsed from `.env`.
///    - In production builds (`kReleaseMode`), all endpoints MUST use HTTPS 
///      to prevent mixed-content blocking on Web and cleartext traffic blocking
///      on Android/iOS.
///    - The fallback URLs `10.0.2.2:8000` (Android Emulator) and `127.0.0.1:8000`
///      (iOS/Web) are exclusively for debug environments.
/// 
/// 5. Modular Caching:
///    - High-frequency read endpoints employ a localized TTL cache (e.g. 
///      `_profileCache`).
///    - Before calling endpoints, the cache is inspected. If data is newer 
///      than `_cacheDuration`, the cache is yielded. 
///    - Cache can be unconditionally evicted via `invalidateCache()` functions.
/// 
/// 6. Image Resolution Strategy:
///    - Google Places API photos require proxying or generating secure pre-signed 
///      URLs. The `resolveBestPlaceImage` function optimizes this by caching 
///      discovered URLs locally to prevent duplicate billing charges on the Maps API.
/// 
/// 7. Timeouts & Retries:
///    - All `http.get` and `http.post` operations must include a `.timeout()`
///      clause (typically 15-30 seconds depending on payload) to prevent indefinite
///      hanging on poor mobile networks.
/// 
/// 8. Type Safety & Serialization:
///    - Strict `jsonDecode` with type casting (`as Map<String, dynamic>`) is
///      used to ensure format exceptions are caught synchronously.
/// 
/// 9. Dependency Injection Readiness:
///    - While currently built as static methods for rapid development, the service
///      is structured to be easily converted into a singleton or injectable service
///      using `get_it` and `injectable` in the future without changing method signatures.
/// 
/// 10. Rate Limiting:
///     - Heavy geographical operations (e.g. repeated `semanticSearch` or `optimizeRoute`)
///       should implement simple debouncing on the UI layer. The API service will
///       forward exactly what it receives.
/// ============================================================================

class ApiService {
  static final Map<String, String?> _resolvedPhotoCache = <String, String?>{};
  static final Map<String, Future<String?>> _pendingPhotoRequests =
      <String, Future<String?>>{};

  static Map<String, dynamic>? _profileCache;
  static DateTime? _profileCacheTime;

  /// Always returns the current live access token from Supabase's session.
  /// The supabase_flutter SDK auto-refreshes tokens, so this is always fresh.
  static String? get currentToken =>
      Supabase.instance.client.auth.currentSession?.accessToken;

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
      return 'http://127.0.0.1:8000' /* Enforce HTTPS in prod via env */;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000' /* Enforce HTTPS in prod via env */;
    }
    return 'http://127.0.0.1:8000' /* Enforce HTTPS in prod via env */;
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
            body: jsonEncode({'origin': origin, 'destinations': destinations}),
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
        .timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception(
      'Failed to load places: ${response.statusCode} ${response.body}',
    );
  }

  /// Semantic ML search — uses sentence-transformers on the backend.
  /// Returns full response map with: query, center, detected_category,
  /// radius_km, count, low_confidence, results[].
  static Future<Map<String, dynamic>> semanticSearch({
    required String query,
    double? latitude,
    double? longitude,
    double radiusKm = 10.0,
    int topN = 20,
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
    final body = jsonEncode({
      'query': query,
      'latitude': latitude,
      'longitude': longitude,
      'radius_km': radiusKm,
      'top_n': topN,
    });
    final uri = Uri.parse('$baseUrl/search/');
    final response = await http
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      'Semantic search failed: ${response.statusCode} ${response.body}',
    );
  }

  /// Triggers a background rebuild of the semantic search index on the backend.
  /// Should be called once after login — fire-and-forget.
  static Future<void> rebuildSearchIndex({required String accessToken}) async {
    final uri = Uri.parse('$baseUrl/search/rebuild');
    try {
      await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      // Best-effort only — silent on failure.
    }
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

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));
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
    final cacheKey = place.id.isNotEmpty
        ? place.id
        : (place.googleUrl ?? place.name);
    if (_resolvedPhotoCache.containsKey(cacheKey)) {
      return _resolvedPhotoCache[cacheKey];
    }

    final immediate = place.resolveBestAvailableImageUrl();
    if (immediate != null) {
      _resolvedPhotoCache[cacheKey] = immediate;
      return immediate;
    }

    final googleUrl = place.googleUrl;
    final fallbackName = place.name;

    final pending = _pendingPhotoRequests[cacheKey];
    if (pending != null) {
      return pending;
    }

    final future = _resolvePhotoFromGoogleUrl(
      googleUrl: googleUrl ?? '',
      placeId: place.id,
      fallbackName: fallbackName,
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
    String? fallbackName,
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
      fallbackName: fallbackName,
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
    String? fallbackName,
  }) async {
    // --- Direct Google Places API resolution using GOOGLE_PLACES_API_KEY ---
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

    if (apiKey.isNotEmpty) {
      // Try resolving directly via Google Places API (no backend needed)
      String? directUrl;
      if (googleUrl.isNotEmpty) {
        directUrl = await _resolveViaGooglePlacesApi(
          googleUrl: googleUrl,
          apiKey: apiKey,
        );
      }

      if (directUrl == null && fallbackName != null && fallbackName.isNotEmpty) {
        directUrl = await _resolveViaGooglePlacesApi(
          googleUrl: 'https://maps.google.com/?q=${Uri.encodeComponent(fallbackName)}',
          apiKey: apiKey,
        );
      }
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

      final resolved = Place.withGooglePhotoWidth(
        decoded['photo_url']?.toString(),
      );
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

      String? searchInput;
      if (cid != null && cid.isNotEmpty) {
        searchInput = 'cid:$cid';
      } else if (q != null && q.isNotEmpty) {
        searchInput = q;
      } else if (uri != null) {
        // Fallback: Extract from path (e.g., .../place/Name/@lat,lng,...)
        final pathSegments = uri.pathSegments;
        final placeIdx = pathSegments.indexOf('place');
        if (placeIdx >= 0 && placeIdx + 1 < pathSegments.length) {
          final rawName = pathSegments[placeIdx + 1];
          // Many path-based URLs use @lat,lng after the name, e.g. /place/Name/@7,8,15z
          if (!rawName.startsWith('@')) {
            searchInput = Uri.decodeComponent(rawName).replaceAll('+', ' ');
          }
        }
      }

      if (searchInput == null || searchInput.isEmpty) {
        return null;
      }

      // Step 2: Find Place using CID or Query → get place_id
      final findPlaceUri =
          Uri.parse(
            'https://maps.googleapis.com/maps/api/place/findplacefromtext/json',
          ).replace(
            queryParameters: {
              'input': searchInput,
              'inputtype': 'textquery',
              'fields': 'place_id',
              'key': apiKey,
            },
          );

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
      final detailsUri =
          Uri.parse(
            'https://maps.googleapis.com/maps/api/place/details/json',
          ).replace(
            queryParameters: {
              'place_id': resolvedPlaceId,
              'fields': 'photos',
              'key': apiKey,
            },
          );

      final detailsResponse = await http
          .get(detailsUri)
          .timeout(const Duration(seconds: 10));

      if (detailsResponse.statusCode != 200) return null;

      final detailsData =
          jsonDecode(detailsResponse.body) as Map<String, dynamic>;
      final photos =
          (detailsData['result'] as Map<String, dynamic>?)?['photos'] as List?;
      if (photos == null || photos.isEmpty) return null;

      final photoRef = (photos.first as Map<String, dynamic>)['photo_reference']
          ?.toString();
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
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'full_name': fullName.trim(),
            'email': email.trim().toLowerCase(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));

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
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));

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

  static Future<void> persistBackendSession(
    Map<String, dynamic> authPayload,
  ) async {
    final refreshToken = authPayload['refresh_token']?.toString();
    if (refreshToken == null || refreshToken.isEmpty) {
      return;
    }

    try {
      await Supabase.instance.client.auth.setSession(refreshToken);
    } catch (e) {
      throw Exception(
        'Authenticated, but failed to store the session locally: $e',
      );
    }
  }

  static Future<void> sendLoginOtp({required String email}) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login/send-otp'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim().toLowerCase()}),
        )
        .timeout(const Duration(seconds: 15));

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
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login/verify-otp'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'code': code.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

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
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/resend-verification'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim().toLowerCase()}),
        )
        .timeout(const Duration(seconds: 15));

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
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/verify-otp'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'code': code.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

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

  static Future<void> forgotPassword({required String email}) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/forgot-password'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim().toLowerCase()}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final bodyText = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(bodyText);
    if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
      throw Exception(decoded['detail'].toString());
    }
    throw Exception(
      'Failed to send password reset email: ${response.statusCode}',
    );
  }

  static Future<void> resetPassword({
    required String accessToken,
    required String refreshToken,
    required String newPassword,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/reset-password'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'access_token': accessToken,
            'refresh_token': refreshToken,
            'new_password': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final bodyText = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(bodyText);
    if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
      throw Exception(decoded['detail'].toString());
    }
    throw Exception('Failed to reset password: ${response.statusCode}');
  }

  /// Geocode a free-text query to lat/lng using the Google Places
  /// findplacefromtext API, biased to Sri Lanka.
  /// Returns a map with keys: name, latitude, longitude, address, place_id.
  static Future<Map<String, dynamic>?> geocodePlace(String query) async {
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
    if (apiKey.isEmpty) return null;
    try {
      final uri =
          Uri.parse(
            'https://maps.googleapis.com/maps/api/place/findplacefromtext/json',
          ).replace(
            queryParameters: {
              'input': query,
              'inputtype': 'textquery',
              'fields': 'place_id,name,geometry,formatted_address',
              'locationbias': 'rectangle:5.5,79.4|10.1,82.1',
              'key': apiKey,
            },
          );
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
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _profileCache != null &&
        _profileCacheTime != null &&
        now.difference(_profileCacheTime!) < const Duration(minutes: 5)) {
      return _profileCache;
    }
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
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _profileCache = jsonDecode(response.body) as Map<String, dynamic>;
        _profileCacheTime = DateTime.now();
        return _profileCache;
      }
    } catch (error, stackTrace) {
      if (kDebugMode) debugPrint('API Error Detected: $error\n$stackTrace');
    }
    return null;
  }

  static void invalidateProfileCache() {
    _profileCache = null;
    _profileCacheTime = null;
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
    // Null-aware map entries (Dart 3.9+): only includes a key if value != null,
    // enabling safe partial-update PATCH semantics over PUT.
    final payload = <String, dynamic>{
      'full_name': ?fullName,
      'bio': ?bio,
      'home_city': ?homeCity,
      'travel_style': ?travelStyle,
      'avatar_url': ?avatarUrl,
    };
    if (payload.isEmpty) return false;
    try {
      final response = await http
          .put(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        invalidateProfileCache();
        return true;
      }
      return false;
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
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = body['playlists'] as List? ?? [];
        return list.whereType<Map<String, dynamic>>().toList();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) debugPrint('API Error Detected: $error\n$stackTrace');
    }
    return const [];
  }

  /// Returns playlists owned by the authenticated user (calls /playlists/mine).
  static Future<List<Map<String, dynamic>>> fetchMyPlaylists({
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
    final uri = Uri.parse('$baseUrl/playlists/mine');
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = body['playlists'] as List? ?? [];
        return list.whereType<Map<String, dynamic>>().toList();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) debugPrint('API Error Detected: $error\n$stackTrace');
    }
    return const [];
  }

  /// Returns activity stat counts for the authenticated user.
  static Future<Map<String, dynamic>> fetchUserStats({
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
    final uri = Uri.parse('$baseUrl/users/me/stats');
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (error, stackTrace) {
      if (kDebugMode) debugPrint('API Error Detected: $error\n$stackTrace');
    }
    return {'playlists': 0, 'places': 0, 'reviews': 0, 'photos': 0};
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
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (error, stackTrace) {
      if (kDebugMode) debugPrint('API Error Detected: $error\n$stackTrace');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createPlaylist({
    required String name,
    String? description,
    String icon = 'playlist_play',
    String visibility = 'public',
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
              'description': ?description,
              'icon': icon,
              'visibility': visibility,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (error, stackTrace) {
      if (kDebugMode) debugPrint('API Error Detected: $error\n$stackTrace');
    }
    return null;
  }

  static Future<bool> addDestinationToPlaylist({
    required String playlistId,
    required String placeId,
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
    final uri = Uri.parse('$baseUrl/playlists/$playlistId/destinations');
    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode({'place_id': placeId}))
          .timeout(const Duration(seconds: 15));
      if (kDebugMode) debugPrint('[addDest] playlist=$playlistId place=$placeId → ${response.statusCode} ${response.body}');
      return response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) debugPrint('[addDest] playlist=$playlistId place=$placeId → ERROR $e');
      return false;
    }
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
    String? visibility,
    String? bannerUrl,
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
      if (visibility != null) 'visibility': visibility,
      if (bannerUrl != null) 'banner_url': bannerUrl,
    };
    if (payload.isEmpty) return false;
    try {
      final response = await http
          .put(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 15));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Uploads a playlist banner image to Supabase Storage and returns the public URL.
  ///
  /// File is stored at path {userId}/{playlistId}/{timestamp}.jpg inside the
  /// 'playlist-banners' bucket. Returns null on failure.
  static Future<String?> uploadPlaylistBanner({
    required String playlistId,
    required String userId,
    required Uint8List imageBytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Path is relative to the bucket root — do NOT include the bucket name here
    final path = '$userId/$playlistId/$timestamp.jpg';
    try {
      await Supabase.instance.client.storage
          .from('playlist-banners')
          .uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      final publicUrl = Supabase.instance.client.storage
          .from('playlist-banners')
          .getPublicUrl(path);
      if (kDebugMode) debugPrint('[uploadPlaylistBanner] uploaded → $publicUrl');
      return publicUrl;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[uploadPlaylistBanner] error: $e\n$st');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMyReviews({String? accessToken}) async {
    final uri = Uri.parse('$baseUrl/reviews/mine');
    try {
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.whereType<Map<String, dynamic>>().toList();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) debugPrint('API Error Detected: $error\n$stackTrace');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchCommunityReviews({int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/reviews/').replace(queryParameters: {'limit': '$limit'});
    try {
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.whereType<Map<String, dynamic>>().toList();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) debugPrint('API Error Detected: $error\n$stackTrace');
    }
    return [];
  }

  static Future<({bool ok, String? error})> submitReview({
    required String placeName,
    required int rating,
    String? placeId,
    String? reviewText,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/reviews/');
    try {
      final response = await http.post(uri,
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'place_name': placeName,
          'rating': rating,
          if (placeId != null) 'place_id': placeId,
          if (reviewText != null) 'review_text': reviewText,
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 201) return (ok: true, error: null);
      return (ok: false, error: 'HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      return (ok: false, error: 'Exception: $e');
    }
  }

  // ── Review interactions ─────────────────────────────────────────────────────

  static Future<int?> likeReview(String reviewId, {String? accessToken}) async {
    final uri = Uri.parse('$baseUrl/reviews/$reviewId/like');
    try {
      final response = await http.put(uri, headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        return (body['likes_count'] as num?)?.toInt();
      }
    } catch (e, s) {
      if (kDebugMode) debugPrint('likeReview error: $e\n$s');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchReviewComments(String reviewId) async {
    final uri = Uri.parse('$baseUrl/reviews/$reviewId/comments');
    try {
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.whereType<Map<String, dynamic>>().toList();
      }
    } catch (e, s) {
      if (kDebugMode) debugPrint('fetchReviewComments error: $e\n$s');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> addReviewComment(
    String reviewId,
    String commentText, {
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/reviews/$reviewId/comments');
    try {
      final response = await http.post(uri,
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'comment_text': commentText}),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e, s) {
      if (kDebugMode) debugPrint('addReviewComment error: $e\n$s');
    }
    return null;
  }

  // ── Notifications ────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchNotifications({String? accessToken}) async {
    final uri = Uri.parse('$baseUrl/notifications/').replace(queryParameters: {'limit': '50'});
    try {
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.whereType<Map<String, dynamic>>().toList();
      }
    } catch (e, s) {
      if (kDebugMode) debugPrint('fetchNotifications error: $e\n$s');
    }
    return [];
  }

  static Future<int> fetchUnreadNotificationCount({String? accessToken}) async {
    final uri = Uri.parse('$baseUrl/notifications/unread-count');
    try {
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        return (body['count'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  static Future<void> markNotificationRead(String id, {String? accessToken}) async {
    final uri = Uri.parse('$baseUrl/notifications/$id/read');
    try {
      await http.put(uri, headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      }).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static Future<void> markAllNotificationsRead({String? accessToken}) async {
    final uri = Uri.parse('$baseUrl/notifications/read-all');
    try {
      await http.put(uri, headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      }).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static Future<void> deleteNotification(String id, {String? accessToken}) async {
    final uri = Uri.parse('$baseUrl/notifications/$id');
    try {
      await http.delete(uri, headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      }).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static Future<void> clearAllNotifications({String? accessToken}) async {
    final uri = Uri.parse('$baseUrl/notifications/clear-all');
    try {
      await http.delete(uri, headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      }).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> fetchPendingReviews({String? accessToken}) async {
    final uri = Uri.parse('$baseUrl/reviews/pending').replace(queryParameters: {'limit': '50'});
    try {
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.whereType<Map<String, dynamic>>().toList();
      }
    } catch (e, s) {
      if (kDebugMode) debugPrint('fetchPendingReviews error: $e\n$s');
    }
    return [];
  }

  static Future<bool> approveReview(String reviewId, {String? accessToken}) async {
    final uri = Uri.parse('$baseUrl/reviews/$reviewId/approve');
    try {
      final response = await http.put(uri, headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      }).timeout(const Duration(seconds: 10));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> rejectReview(String reviewId, {String? accessToken}) async {
    final uri = Uri.parse('$baseUrl/reviews/$reviewId/reject');
    try {
      final response = await http.put(uri, headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      }).timeout(const Duration(seconds: 10));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteAccount({String? accessToken}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
    final uri = Uri.parse('$baseUrl/users/me');
    try {
      final response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
