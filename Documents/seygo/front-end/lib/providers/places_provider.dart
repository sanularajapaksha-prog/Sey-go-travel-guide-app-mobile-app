import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/services/api_service.dart';

/// Pre-fetches places and GPS position as soon as the app starts so that
/// the Map screen can display data immediately without waiting for the user
/// to navigate there first.
class PlacesProvider extends ChangeNotifier {
  List<dynamic> _rawRows = [];
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _error;

  Position? _cachedPosition;
  bool _locationLoading = false;

  List<dynamic> get rawRows => _rawRows;
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get cachedPosition => _cachedPosition;

  PlacesProvider() {
    preload();
    _prefetchLocationSilently();
  }

  /// Fetches all place rows from the backend in batches.
  /// Safe to call multiple times — no-ops if already loading or loaded.
  Future<void> preload() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      const batchSize = 500;
      final allRows = <dynamic>[];
      int offset = 0;
      while (true) {
        final batch = await ApiService.fetchPlaces(
          limit: batchSize,
          offset: offset,
        );
        allRows.addAll(batch);
        if (batch.length < batchSize) break;
        offset += batchSize;
      }
      _rawRows = allRows;
      _isLoaded = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets GPS position without showing a permission dialog.
  /// Only runs if the user already granted location permission previously.
  Future<void> _prefetchLocationSilently() async {
    if (_locationLoading || _cachedPosition != null) return;
    _locationLoading = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
      _cachedPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      notifyListeners();
    } catch (_) {
      // Silent — best-effort prefetch only.
    } finally {
      _locationLoading = false;
    }
  }
}
