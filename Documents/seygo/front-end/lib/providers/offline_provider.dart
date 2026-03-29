import 'package:flutter/foundation.dart';

import '../data/models/offline_cache_item.dart';
import '../data/services/offline_cache_service.dart';

/// Reactive state for the offline cache.
///
/// Each user's data is stored under a separate SharedPreferences key.
/// Call [switchUser] after login and [clearMemory] after logout.
class OfflineProvider extends ChangeNotifier {
  List<OfflineCacheItem> _items = [];
  bool _loading = false;
  bool _initialized = false;
  String _userId = '';

  List<OfflineCacheItem> get items => List.unmodifiable(_items);

  List<OfflineCacheItem> get trips =>
      _items.where((e) => e.type == OfflineCacheType.routeTrip).toList();

  List<OfflineCacheItem> get destinations =>
      _items.where((e) => e.type == OfflineCacheType.destination).toList();

  List<OfflineCacheItem> get playlists =>
      _items.where((e) => e.type == OfflineCacheType.playlist).toList();

  bool get isLoading => _loading;

  /// True after the first [load] / [switchUser] completes.
  bool get isInitialized => _initialized;

  bool isCached(String id) => _items.any((e) => e.id == id);

  // ── load ────────────────────────────────────────────────────────────────────

  /// Load cache for [userId]. Called at app startup for anonymous/guest state.
  Future<void> load({String userId = ''}) async {
    _userId = userId;
    _loading = true;
    notifyListeners();
    _items = await OfflineCacheService.loadAll(userId: _userId);
    _loading = false;
    _initialized = true;
    notifyListeners();
  }

  /// Switch to a different user's offline data. Clears memory first so the
  /// previous user's data is never shown, then loads the new user's cache.
  Future<void> switchUser(String userId) async {
    if (_userId == userId && _initialized) return; // already loaded for this user
    _userId = userId;
    _items = [];
    _initialized = false;
    notifyListeners();
    await load(userId: _userId);
  }

  /// Clears in-memory data only (does NOT touch disk). Call on logout so the
  /// next user does not see stale items before their own data is loaded.
  void clearMemory() {
    _userId = '';
    _items = [];
    _initialized = false;
    notifyListeners();
  }

  // ── save ────────────────────────────────────────────────────────────────────

  Future<void> save(OfflineCacheItem item) async {
    final snapshot = List<OfflineCacheItem>.from(_items);
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      _items[idx] = item;
    } else {
      _items.insert(0, item);
    }
    notifyListeners();

    try {
      await OfflineCacheService.persistAll(_items, userId: _userId);
    } catch (e) {
      _items
        ..clear()
        ..addAll(snapshot);
      notifyListeners();
      rethrow;
    }
  }

  // ── delete ──────────────────────────────────────────────────────────────────

  Future<void> deleteById(String id) async {
    final snapshot = List<OfflineCacheItem>.from(_items);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    try {
      await OfflineCacheService.persistAll(_items, userId: _userId);
    } catch (e) {
      _items
        ..clear()
        ..addAll(snapshot);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearAll() async {
    await OfflineCacheService.clearAll(userId: _userId);
    _items.clear();
    notifyListeners();
  }
}
