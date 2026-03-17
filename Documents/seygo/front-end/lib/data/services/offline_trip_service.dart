import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineTripService {
  static const String _offlineTripKey = 'offline_trip_summary';

  static Future<void> saveTrip({
    required String tripName,
    required String tripGoogleUrl,
    required String dateRange,
    required int days,
    required double totalBudgetLKR,
    required double totalDistanceKm,
    required String transportMode,
    required String travelTime,
    required int stops,
    required String emergencyContact,
    required LatLng origin,
    required List<LatLng> routePoints,
    required List<Map<String, dynamic>> optimizedStops,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'tripName': tripName,
      'tripGoogleUrl': tripGoogleUrl,
      'dateRange': dateRange,
      'days': days,
      'totalBudgetLKR': totalBudgetLKR,
      'totalDistanceKm': totalDistanceKm,
      'transportMode': transportMode,
      'travelTime': travelTime,
      'stops': stops,
      'emergencyContact': emergencyContact,
      'origin': {
        'latitude': origin.latitude,
        'longitude': origin.longitude,
      },
      'routePoints': routePoints
          .map(
            (point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          )
          .toList(),
      'optimizedStops': optimizedStops,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_offlineTripKey, jsonEncode(payload));
  }

  static Future<void> clearTrip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineTripKey);
  }

  static Future<bool> hasOfflineTrip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_offlineTripKey);
  }
}
