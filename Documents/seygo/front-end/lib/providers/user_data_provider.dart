import 'package:flutter/foundation.dart';

import '../data/services/api_service.dart';

/// Pre-fetches all auth-dependent user data (profile, playlists, stats)
/// right after login so that Profile, Playlists, and Home screens display
/// instantly without a loading spinner.
class UserDataProvider extends ChangeNotifier {
  // ── cached data ──────────────────────────────────────────────────────────────
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _myPlaylists = [];
  List<Map<String, dynamic>> _featuredPlaylists = [];
  Map<String, dynamic> _stats = {
    'playlists': 0,
    'places': 0,
    'reviews': 0,
    'photos': 0,
  };

  // ── loaded flags ─────────────────────────────────────────────────────────────
  bool _profileLoaded = false;
  bool _myPlaylistsLoaded = false;
  bool _featuredPlaylistsLoaded = false;
  bool _statsLoaded = false;

  // ── getters ──────────────────────────────────────────────────────────────────
  Map<String, dynamic>? get profile => _profile;
  List<Map<String, dynamic>> get myPlaylists => _myPlaylists;
  List<Map<String, dynamic>> get featuredPlaylists => _featuredPlaylists;
  Map<String, dynamic> get stats => _stats;

  bool get profileLoaded => _profileLoaded;
  bool get myPlaylistsLoaded => _myPlaylistsLoaded;
  bool get featuredPlaylistsLoaded => _featuredPlaylistsLoaded;
  bool get statsLoaded => _statsLoaded;

  /// Runs all four fetches in parallel. Called from [main.dart] after login.
  /// Silent on errors — cached values remain from any previously successful fetch.
  Future<void> preload(String accessToken) async {
    await Future.wait([
      _fetchProfile(accessToken),
      _fetchMyPlaylists(accessToken),
      _fetchFeaturedPlaylists(accessToken),
      _fetchStats(accessToken),
    ]);
  }

  /// Re-fetches only playlists (call after create / edit / delete).
  Future<void> refreshPlaylists(String? accessToken) async {
    await Future.wait([
      _fetchMyPlaylists(accessToken ?? ''),
      _fetchFeaturedPlaylists(accessToken ?? ''),
    ]);
  }

  /// Clears all cached data. Call on sign-out so stale data isn't shown to the
  /// next user who might log into a different account on the same device.
  void invalidate() {
    _profile = null;
    _myPlaylists = [];
    _featuredPlaylists = [];
    _stats = {'playlists': 0, 'places': 0, 'reviews': 0, 'photos': 0};
    _profileLoaded = false;
    _myPlaylistsLoaded = false;
    _featuredPlaylistsLoaded = false;
    _statsLoaded = false;
    notifyListeners();
  }

  // ── private fetch helpers ────────────────────────────────────────────────────

  Future<void> _fetchProfile(String token) async {
    try {
      final data = await ApiService.fetchProfile(accessToken: token);
      _profile = data;
      _profileLoaded = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _fetchMyPlaylists(String token) async {
    try {
      final data = await ApiService.fetchMyPlaylists(
        accessToken: token.isNotEmpty ? token : null,
      );
      _myPlaylists = data;
      _myPlaylistsLoaded = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _fetchFeaturedPlaylists(String token) async {
    try {
      final data = await ApiService.fetchPlaylists(
        accessToken: token.isNotEmpty ? token : null,
      );
      _featuredPlaylists = data;
      _featuredPlaylistsLoaded = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _fetchStats(String token) async {
    try {
      final data = await ApiService.fetchUserStats(
        accessToken: token.isNotEmpty ? token : null,
      );
      _stats = data;
      _statsLoaded = true;
      notifyListeners();
    } catch (_) {}
  }
}
