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

  List<OfflineCacheItem> get items => List.unmodifiable(_items);

  List<OfflineCacheItem> get trips =>
      _items.where((e) => e.type == OfflineCacheType.routeTrip).toList();

  List<OfflineCacheItem> get destinations =>
      _items.where((e) => e.type == OfflineCacheType.destination).toList();

  /// All playlists saved for offline access, newest first.
  List<OfflineCacheItem> get playlists =>
      _items.where((e) => e.type == OfflineCacheType.playlist).toList();

  bool get isLoading => _loading;

  bool isCached(String id) => _items.any((e) => e.id == id);

  // ── load ────────────────────────────────────────────────────────────────────

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await OfflineCacheService.loadAll();
    _loading = false;
    notifyListeners();
  }

  // ── save ────────────────────────────────────────────────────────────────────

  Future<void> save(OfflineCacheItem item) async {
    await OfflineCacheService.save(item);
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      _items[idx] = item;
    } else {
      _items.insert(0, item);
    }
    notifyListeners();
  }

  // ── delete ──────────────────────────────────────────────────────────────────

  Future<void> deleteById(String id) async {
    await OfflineCacheService.deleteById(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await OfflineCacheService.clearAll();
    _items.clear();
    notifyListeners();
  }
}
