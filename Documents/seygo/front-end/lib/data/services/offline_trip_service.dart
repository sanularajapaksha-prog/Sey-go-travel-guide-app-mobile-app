import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineTripService {
  // Legacy key – kept for backward compat (still written on save)
  static const String _offlineTripKey = 'offline_trip_summary';

  // v2 multi-trip list: stores every saved trip as full JSON
  static const String _tripsV2Key = 'offline_trips_v2';

  // ── save ────────────────────────────────────────────────────────────────────
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
    final id =
        DateTime.now().millisecondsSinceEpoch.toString(); // unique trip id
    final savedAt = DateTime.now().toIso8601String();

    final payload = <String, dynamic>{
      'id': id,
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
          .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
          .toList(),
      'optimizedStops': optimizedStops,
      'savedAt': savedAt,
    };

    // Legacy single-trip key (backward compat)
    await prefs.setString(_offlineTripKey, jsonEncode(payload));

    // v2 multi-trip list
    final existing = await _loadRawList(prefs);
    existing.removeWhere((t) => t['tripName'] == tripName); // dedup by name
    existing.insert(0, payload); // newest first
    await prefs.setString(_tripsV2Key, jsonEncode(existing));
  }

  // ── delete ──────────────────────────────────────────────────────────────────
  static Future<void> deleteTripById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _loadRawList(prefs);
    list.removeWhere((t) => t['id']?.toString() == id);
    await prefs.setString(_tripsV2Key, jsonEncode(list));

    // If this was also the legacy trip, clear it
    final legacy = await loadTrip();
    if (legacy != null && legacy['id']?.toString() == id) {
      await prefs.remove(_offlineTripKey);
    }
  }

  static Future<void> clearTrip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineTripKey);
  }

  static Future<void> clearAllTrips() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineTripKey);
    await prefs.remove(_tripsV2Key);
  }

  // ── load ────────────────────────────────────────────────────────────────────
  static Future<bool> hasOfflineTrip() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_tripsV2Key)) {
      final list = await _loadRawList(prefs);
      return list.isNotEmpty;
    }
    return prefs.containsKey(_offlineTripKey);
  }

  /// Returns the single most-recent trip (legacy behaviour).
  static Future<Map<String, dynamic>?> loadTrip() async {
    final prefs = await SharedPreferences.getInstance();
    // Prefer v2 list (newest first)
    final list = await _loadRawList(prefs);
    if (list.isNotEmpty) return list.first;
    // Fallback to legacy key
    final raw = prefs.getString(_offlineTripKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Returns ALL saved trips, newest first.
  static Future<List<Map<String, dynamic>>> loadAllTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final v2 = await _loadRawList(prefs);
    if (v2.isNotEmpty) return v2;

    // Migrate legacy single-trip to v2 list on first call
    final raw = prefs.getString(_offlineTripKey);
    if (raw == null) return [];
    try {
      final trip = jsonDecode(raw) as Map<String, dynamic>;
      if (!trip.containsKey('id')) {
        trip['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }
      final list = [trip];
      await prefs.setString(_tripsV2Key, jsonEncode(list));
      return list;
    } catch (e) {
      if (kDebugMode) debugPrint('OfflineTripService migration error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> loadTripById(String id) async {
    final all = await loadAllTrips();
    try {
      return all.firstWhere((t) => t['id']?.toString() == id);
    } catch (_) {
      return null;
    }
  }

  // ── private helpers ──────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> _loadRawList(
      SharedPreferences prefs) async {
    final raw = prefs.getString(_tripsV2Key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
