import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
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
}
