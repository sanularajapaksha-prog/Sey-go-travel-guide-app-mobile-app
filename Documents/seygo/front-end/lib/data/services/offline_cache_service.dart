import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/offline_cache_item.dart';

/// Persists all offline cached items (both route trips and destinations)
/// as a JSON list under [_cacheKey] in SharedPreferences.
class OfflineCacheService {
  static const String _cacheKey = 'offline_cache_v1';

  // ── load ────────────────────────────────────────────────────────────────────

  /// Returns all cached items, newest first.
  /// Item-tolerant: a single corrupt entry is skipped rather than wiping the
  /// entire list (previous behaviour: one bad item → catch → return []).
  static Future<List<OfflineCacheItem>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (kDebugMode) debugPrint('[OfflineCache] raw key present: ${raw != null}, length: ${raw?.length}');
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
    if (kDebugMode) debugPrint('[OfflineCache] loaded ${items.length} items (types: ${items.map((i) => i.type.name).join(', ')})');
    return items;
  }

  /// Returns `true` if an item with [id] exists in the cache.
  static Future<bool> contains(String id) async {
    final all = await loadAll();
    return all.any((item) => item.id == id);
  }

  // ── save ────────────────────────────────────────────────────────────────────

  /// Adds or replaces an item (matched by [OfflineCacheItem.id]).
  static Future<void> save(OfflineCacheItem item) async {
    final all = await loadAll();
    final idx = all.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      all[idx] = item;
    } else {
      all.insert(0, item); // newest first
    }
    await _persist(all);
  }

  // ── delete ──────────────────────────────────────────────────────────────────

  static Future<void> deleteById(String id) async {
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);
    await _persist(all);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  // ── private helpers ──────────────────────────────────────────────────────────

  static Future<void> _persist(List<OfflineCacheItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    // Serialize each item individually so one bad item doesn't block the rest.
    final jsonList = <Map<String, dynamic>>[];
    for (final item in items) {
      try {
        jsonList.add(item.toJson());
      } catch (e) {
        if (kDebugMode) debugPrint('[OfflineCache] skipping item ${item.id} (toJson error): $e');
      }
    }
    final encoded = jsonEncode(jsonList);
    await prefs.setString(_cacheKey, encoded);
    if (kDebugMode) debugPrint('[OfflineCache] persisted ${jsonList.length} items');
  }
}
