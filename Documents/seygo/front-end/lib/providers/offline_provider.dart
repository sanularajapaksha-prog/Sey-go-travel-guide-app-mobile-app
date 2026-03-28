import 'package:flutter/foundation.dart';

import '../data/models/offline_cache_item.dart';
import '../data/services/offline_cache_service.dart';

/// Reactive state for the offline cache.
///
/// Wrap your widget tree with `ChangeNotifierProvider(create: (_) => OfflineProvider()..load())`
/// and call `Provider.of<OfflineProvider>(context)` to read state.
class OfflineProvider extends ChangeNotifier {
  List<OfflineCacheItem> _items = [];
  bool _loading = false;
  bool _initialized = false;

  List<OfflineCacheItem> get items => List.unmodifiable(_items);

  List<OfflineCacheItem> get trips =>
      _items.where((e) => e.type == OfflineCacheType.routeTrip).toList();

  List<OfflineCacheItem> get destinations =>
      _items.where((e) => e.type == OfflineCacheType.destination).toList();

  /// All playlists saved for offline access, newest first.
  List<OfflineCacheItem> get playlists =>
      _items.where((e) => e.type == OfflineCacheType.playlist).toList();

  bool get isLoading => _loading;

  /// True after the first [load] completes. An empty [items] list does NOT
  /// mean the provider is uninitialized — it may simply mean nothing is saved.
  /// Use this flag instead of `items.isEmpty` to guard lazy load() calls.
  bool get isInitialized => _initialized;

  bool isCached(String id) => _items.any((e) => e.id == id);

  // ── load ────────────────────────────────────────────────────────────────────

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await OfflineCacheService.loadAll();
    _loading = false;
    _initialized = true;
    notifyListeners();
  }

  // ── save ────────────────────────────────────────────────────────────────────

  Future<void> save(OfflineCacheItem item) async {
    // Snapshot current list so we can roll back if the persist fails.
    final snapshot = List<OfflineCacheItem>.from(_items);

    // Update in-memory state FIRST — this is the single source of truth.
    // Avoids the read-modify-write race where a second concurrent save reads
    // SharedPreferences before the first write commits, silently dropping it.
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      _items[idx] = item;
    } else {
      _items.insert(0, item);
    }
    notifyListeners();

    try {
      // Persist the full current list directly — no SharedPreferences read needed.
      await OfflineCacheService.persistAll(_items);
    } catch (e) {
      // Revert so the UI (cloud icon, Downloaded section) stays consistent
      // with what is actually persisted on disk.
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
      await OfflineCacheService.persistAll(_items);
    } catch (e) {
      _items
        ..clear()
        ..addAll(snapshot);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearAll() async {
    await OfflineCacheService.clearAll();
    _items.clear();
    notifyListeners();
  }
}
