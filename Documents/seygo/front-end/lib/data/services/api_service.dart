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

  static Future<List<dynamic>> fetchPlaces({String? accessToken}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final response = await http
        .get(
          Uri.parse('$baseUrl/places/'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception(
      'Failed to load places: ${response.statusCode} ${response.body}',
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
          body: jsonEncode({
            'origin': origin,
            'destinations': destinations,
          }),
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
