import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    final configured = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (configured.isNotEmpty) return configured;

    // Android emulator accesses host machine via 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    // Desktop/web/iOS simulator local fallback.
    return 'http://127.0.0.1:8000';
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

    final queryParameters = <String, String>{
      'q': query,
      'radius_km': '$radiusKm',
      'limit': '$limit',
      if (latitude != null) 'latitude': '$latitude',
      if (longitude != null) 'longitude': '$longitude',
    };

    final uri = Uri.parse(
      '$baseUrl/places/search',
    ).replace(queryParameters: queryParameters);

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final places = decoded['places'];
        if (places is List) {
          return places;
        }
      }
      throw Exception('Unexpected search response format');
    }

    throw Exception(
      'Failed to search places: ${response.statusCode} ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> optimizeRoute({
    required Map<String, dynamic> origin,
    required List<Map<String, dynamic>> destinations,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/routing/optimize'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'origin': origin, 'destinations': destinations}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(
      'Failed to optimize route: ${response.statusCode} ${response.body}',
    );
  }
}
