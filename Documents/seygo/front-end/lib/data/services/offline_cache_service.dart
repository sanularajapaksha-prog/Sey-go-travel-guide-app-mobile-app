import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/offline_cache_item.dart';

/// Persists all offline cached items as a JSON list under a per-user key in
/// SharedPreferences. Each user's data is isolated under
/// `offline_cache_v1_<userId>` so switching accounts never leaks data.
class OfflineCacheService {
  static String _key(String userId) =>
      userId.isNotEmpty ? 'offline_cache_v1_$userId' : 'offline_cache_v1_guest';

  // ── load ────────────────────────────────────────────────────────────────────

  /// Returns all cached items for [userId], newest first.
  /// Item-tolerant: a single corrupt entry is skipped rather than wiping the
  /// entire list.
  static Future<List<OfflineCacheItem>> loadAll({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _key(userId);
    final raw = prefs.getString(cacheKey);
    if (kDebugMode) debugPrint('[OfflineCache] uid=$userId key=$cacheKey present=${raw != null}');
    if (raw == null || raw.isEmpty) return [];
    List decoded;
    try {
      decoded = jsonDecode(raw) as List;
    } catch (e) {
      if (kDebugMode) debugPrint('[OfflineCache] loadAll JSON parse error: $e');
      return [];
    }
    final items = <OfflineCacheItem>[];
    for (final e in decoded.whereType<Map>()) {
      try {
        items.add(OfflineCacheItem.fromJson(Map<String, dynamic>.from(e)));
      } catch (err) {
        if (kDebugMode) debugPrint('[OfflineCache] skipping corrupt item: $err');
      }
    }
    if (kDebugMode) debugPrint('[OfflineCache] loaded ${items.length} items for uid=$userId');
    return items;
  }

  /// Returns `true` if an item with [id] exists in the cache for [userId].
  static Future<bool> contains(String id, {required String userId}) async {
    final all = await loadAll(userId: userId);
    return all.any((item) => item.id == id);
  }

  // ── save ────────────────────────────────────────────────────────────────────

  /// Persists [items] directly to SharedPreferences under [userId]'s key.
  static Future<void> persistAll(List<OfflineCacheItem> items,
      {required String userId}) async {
    await _persist(items, userId: userId);
  }

  // ── delete ──────────────────────────────────────────────────────────────────

  static Future<void> clearAll({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }

  // ── private helpers ──────────────────────────────────────────────────────────

  static Future<void> _persist(List<OfflineCacheItem> items,
      {required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _key(userId);
    final jsonList = <Map<String, dynamic>>[];
    for (final item in items) {
      try {
        jsonList.add(item.toJson());
      } catch (e) {
        if (kDebugMode) debugPrint('[OfflineCache] skipping item ${item.id} (toJson error): $e');
      }
    }
    String encoded;
    try {
      encoded = jsonEncode(jsonList);
    } catch (e) {
      if (kDebugMode) debugPrint('[OfflineCache] jsonEncode failed — aborting persist: $e');
      return;
    }
    final ok = await prefs.setString(cacheKey, encoded);
    if (kDebugMode) {
      debugPrint(ok
          ? '[OfflineCache] persisted ${jsonList.length} items for uid=$userId'
          : '[OfflineCache] setString returned false for uid=$userId!');
    }
    if (!ok) throw Exception('[OfflineCache] SharedPreferences write failed for key $cacheKey');
  }
}
