import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';

  static Future<List<dynamic>> fetchPlaces({String? accessToken}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(
      Uri.parse('$baseUrl/places/'),
      headers: headers,
    );

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

    final uri = Uri.parse('$baseUrl/places/search').replace(
      queryParameters: params,
    );

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
}
