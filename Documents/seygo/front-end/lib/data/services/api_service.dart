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
}
