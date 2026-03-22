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
  static Future<List<OfflineCacheItem>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .whereType<Map>()
          .map((e) =>
              OfflineCacheItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('OfflineCacheService.loadAll error: $e');
      return [];
    }
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
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_cacheKey, encoded);
  }
}
