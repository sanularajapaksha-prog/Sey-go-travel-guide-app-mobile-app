import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../data/models/offline_cache_item.dart';
import '../../data/services/api_service.dart';
import '../../providers/offline_provider.dart';
import '../../providers/user_data_provider.dart';
import '../../widgets/custom_icon_widget.dart';
import '../playlist_details/playlist_details_screen.dart';
import './widgets/create_playlist_dialog.dart';
import './widgets/empty_playlists_widget.dart';
import './widgets/playlist_card_widget.dart';

/// Playlists Screen — shows the user's saved destination collections.
///
/// Layout:
///   1. Downloaded section  — playlists saved for offline access (OfflineProvider)
///   2. My Playlists section — playlists fetched from the API
class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _playlists = [];
  List<Map<String, dynamic>> _filteredPlaylists = [];
  bool _isSearching = false;
  bool _initialized = false;

  /// Tracks which playlist ID is currently uploading a banner (shows loading).
  String? _uploadingBannerForId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadPlaylists();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── playlist loading ────────────────────────────────────────────────────────

  Future<void> _loadPlaylists({bool forceRefresh = false}) async {
    final udp = Provider.of<UserDataProvider>(context, listen: false);
    if (!forceRefresh && udp.myPlaylistsLoaded) {
      if (mounted) {
        setState(() {
          _playlists = udp.myPlaylists;
          _filteredPlaylists = udp.myPlaylists;
        });
      }
      return;
    }
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final data = await ApiService.fetchMyPlaylists(accessToken: token);
    if (mounted) {
      setState(() {
        _playlists = data;
        final q = _searchController.text;
        _filteredPlaylists = q.isEmpty
            ? List.from(_playlists)
            : _playlists.where((p) {
                final name = (p['name'] as String).toLowerCase();
                final desc = (p['description'] as String? ?? '').toLowerCase();
                return name.contains(q.toLowerCase()) ||
                    desc.contains(q.toLowerCase());
              }).toList();
      });
    }
  }

  void _filterPlaylists(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPlaylists = List.from(_playlists);
      } else {
        _filteredPlaylists = _playlists.where((playlist) {
          final nameLower = (playlist['name'] as String).toLowerCase();
          final descLower =
              (playlist['description'] as String? ?? '').toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) ||
              descLower.contains(queryLower);
        }).toList();
      }
    });
  }

  Future<void> _refreshPlaylists() async {
    await _loadPlaylists(forceRefresh: true);
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  void _createPlaylist() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const CreatePlaylistDialog(),
    );

    if (result != null && mounted) {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final created = await ApiService.createPlaylist(
        name: result['name']!,
        description: result['description'],
        icon: result['icon'] ?? 'playlist_play',
        accessToken: token,
      );

      if (!mounted) return;

      if (created != null) {
        await _loadPlaylists(forceRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playlist "${result['name']}" created'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create playlist'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _editPlaylist(Map<String, dynamic> playlist) async {
    final isEditable = playlist['is_editable'] as bool? ?? true;
    if (!isEditable) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => CreatePlaylistDialog(
        initialName: playlist['name'] as String,
        initialDescription: playlist['description'] as String?,
        isEdit: true,
      ),
    );

    if (result != null && mounted) {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final ok = await ApiService.updatePlaylist(
        playlistId: playlist['id'] as String,
        name: result['name'],
        description: result['description'],
        icon: result['icon'],
        accessToken: token,
      );

      if (!mounted) return;

      if (ok) {
        await _loadPlaylists(forceRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playlist "${result['name']}" updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update playlist'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _deletePlaylist(Map<String, dynamic> playlist) {
    final isDeletable = playlist['is_deletable'] as bool? ?? true;
    if (!isDeletable) return;

    final isDefault = playlist['is_default'] as bool? ?? false;
    if (isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete default playlists'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Delete Playlist'),
          content: Text(
            'Are you sure you want to delete "${playlist['name']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final token = Supabase
                    .instance.client.auth.currentSession?.accessToken;
                final ok = await ApiService.deletePlaylist(
                  playlistId: playlist['id'] as String,
                  accessToken: token,
                );
                if (!mounted) return;
                if (ok) {
                  await _loadPlaylists(forceRefresh: true);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playlist "${playlist['name']}" deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete playlist'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(
                'Delete',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openPlaylistDetail(Map<String, dynamic> playlist) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaylistDetailsScreen(
          playlistId: (playlist['id'] ?? '').toString(),
          initialPlaylist: playlist,
        ),
      ),
    );
  }

  // ── offline playlist logic ──────────────────────────────────────────────────

  /// Saves [playlist] to the local offline cache using the playlist's own ID
  /// as the unique key. Calling this again with the same playlist just updates
  /// the entry — it never creates a duplicate.
  Future<void> _savePlaylistOffline(Map<String, dynamic> playlist) async {
    final offlineProvider =
        Provider.of<OfflineProvider>(context, listen: false);
    final playlistId = (playlist['id'] ?? '').toString();
    if (playlistId.isEmpty) return;

    // Pick the best available image for the cache item thumbnail.
    // Use whereType<String>() instead of cast<String>() — safe even if the
    // list contains non-String elements (avoids lazy CastError).
    // Use toString-coercion for banner_url in case the API returns a non-String.
    final bannerUrl = playlist['banner_url'] is String
        ? playlist['banner_url'] as String
        : null;
    final previewImages = (playlist['previewImages'] as List? ?? const [])
        .whereType<String>()
        .toList();
    final imageUrl =
        bannerUrl ?? (previewImages.isNotEmpty ? previewImages.first : null);

    // Build a safe, explicitly typed snapshot — avoids jsonEncode failures
    // that can occur with raw API maps containing List<dynamic> fields.
    // Use null-safe coercions (toString(), toInt()) instead of direct `as`
    // casts, which throw TypeError on unexpected runtime types.
    final rawCount = playlist['destination_count'] ?? playlist['destinationCount'] ?? 0;
    final destCount = (rawCount is num) ? rawCount.toInt() : int.tryParse(rawCount.toString()) ?? 0;
    final safeSnapshot = <String, dynamic>{
      'id': playlistId,
      'name': playlist['name']?.toString() ?? 'Playlist',
      'description': playlist['description']?.toString(),
      'icon': playlist['icon']?.toString() ?? 'playlist_play',
      'banner_url': bannerUrl,
      'previewImages': previewImages, // already List<String> via whereType
      'destination_count': destCount,
      'destinationCount': destCount,
      'creator_name': playlist['creator_name']?.toString(),
      'visibility': playlist['visibility']?.toString() ?? 'public',
      'is_editable': false,
      'is_deletable': false,
      'is_featured': (playlist['is_featured'] as bool?) ?? false,
      'semanticLabels': (playlist['semanticLabels'] as List? ?? [])
          .whereType<String>()
          .toList(),
    };

    final item = OfflineCacheItem(
      id: playlistId, // unique per playlist — prevents overwriting other entries
      type: OfflineCacheType.playlist,
      title: playlist['name']?.toString() ?? 'Playlist',
      imageUrl: imageUrl,
      description: playlist['description']?.toString(),
      savedAt: DateTime.now(),
      playlistData: safeSnapshot,
    );

    try {
      await offlineProvider.save(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${playlist['name']}" saved for offline'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[savePlaylistOffline] error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save playlist offline'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Removes the playlist with [playlistId] from the offline cache.
  Future<void> _removePlaylistOffline(String playlistId) async {
    final offlineProvider =
        Provider.of<OfflineProvider>(context, listen: false);
    try {
      await offlineProvider.deleteById(playlistId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from offline'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[removePlaylistOffline] error: $e\n$st');
    }
  }

  // ── banner upload logic ─────────────────────────────────────────────────────

  /// Opens the gallery picker, uploads the chosen image to Supabase Storage,
  /// saves the public URL to the playlist record via the API, then refreshes
  /// the playlist list so the card immediately reflects the new banner.
  Future<void> _uploadBannerForPlaylist(Map<String, dynamic> playlist) async {
    final playlistId = playlist['id'] as String? ?? '';
    if (playlistId.isEmpty) return;

    final picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // reduce file size before upload
        maxWidth: 1200,
        maxHeight: 800,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[banner] image picker error: $e');
    }
    if (file == null || !mounted) return;

    // Show loading indicator on the card
    setState(() => _uploadingBannerForId = playlistId);

    try {
      final Uint8List bytes = await file.readAsBytes();

      final userId =
          Supabase.instance.client.auth.currentUser?.id ?? 'unknown';
      final token =
          Supabase.instance.client.auth.currentSession?.accessToken;

      // Upload to Supabase Storage: playlist-banners/{userId}/{playlistId}/{ts}.jpg
      final publicUrl = await ApiService.uploadPlaylistBanner(
        playlistId: playlistId,
        userId: userId,
        imageBytes: bytes,
      );

      if (publicUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload banner image'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Persist the banner URL to the playlist DB row
      final ok = await ApiService.updatePlaylist(
        playlistId: playlistId,
        bannerUrl: publicUrl,
        accessToken: token,
      );

      if (!mounted) return;

      if (ok) {
        // Refresh list so the card shows the new banner immediately
        await _loadPlaylists(forceRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banner updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banner uploaded but failed to save to playlist'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[banner] upload error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong uploading the banner'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingBannerForId = null);
    }
  }

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // ── App bar ──────────────────────────────────────────────────────────
          Container(
            color: theme.appBarTheme.backgroundColor,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    child: Row(
                      children: [
                        _isSearching
                            ? Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: 'Search playlists...',
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.all(2.w),
                                      child: CustomIconWidget(
                                        iconName: 'search',
                                        size: 20,
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: CustomIconWidget(
                                        iconName: 'clear',
                                        size: 20,
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isSearching = false;
                                          _searchController.clear();
                                          _filteredPlaylists =
                                              List.from(_playlists);
                                        });
                                      },
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 4.w,
                                      vertical: 1.5.h,
                                    ),
                                  ),
                                  onChanged: _filterPlaylists,
                                ),
                              )
                            : Expanded(
                                child: Text(
                                  'Playlists',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                        if (!_isSearching) ...[
                          IconButton(
                            icon: CustomIconWidget(
                              iconName: 'search',
                              size: 24,
                              color: theme.colorScheme.onSurface,
                            ),
                            onPressed: () =>
                                setState(() => _isSearching = true),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────────
          Expanded(
            child: Consumer<OfflineProvider>(
              builder: (context, offlineProvider, _) {
                final offlinePlaylists = offlineProvider.playlists;

                // Nothing to show at all
                if (_filteredPlaylists.isEmpty && offlinePlaylists.isEmpty) {
                  return _playlists.isEmpty
                      ? EmptyPlaylistsWidget(onCreatePlaylist: _createPlaylist)
                      : Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomIconWidget(
                                  iconName: 'search_off',
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.3),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'No playlists found',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                }

                return RefreshIndicator(
                  onRefresh: _refreshPlaylists,
                  child: CustomScrollView(
                    slivers: [
                      // ── Downloaded / Offline section ────────────────────────
                      if (offlinePlaylists.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionHeader(
                            icon: Icons.download_done_rounded,
                            label: 'Downloaded',
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = offlinePlaylists[index];
                              // Reconstruct the playlist map from the saved snapshot
                              final playlistMap = Map<String, dynamic>.from(
                                item.playlistData ?? {},
                              );
                              // Mark as offline copy so the card adjusts its UI
                              playlistMap['is_editable'] = false;
                              playlistMap['is_deletable'] = false;
                              if (playlistMap['name'] == null) {
                                playlistMap['name'] = item.title;
                              }
                              if (playlistMap['icon'] == null) {
                                playlistMap['icon'] = 'playlist_play';
                              }

                              return PlaylistCardWidget(
                                key: ValueKey('offline_${item.id}'),
                                playlist: playlistMap,
                                isOfflineCopy: true,
                                onTap: () => _openPlaylistDetail(playlistMap),
                                onEdit: () {},
                                onDelete: () =>
                                    _removePlaylistOffline(item.id),
                                onRemoveOffline: () =>
                                    _removePlaylistOffline(item.id),
                              );
                            },
                            childCount: offlinePlaylists.length,
                          ),
                        ),
                      ],

                      // ── My Playlists section ────────────────────────────────
                      if (_filteredPlaylists.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionHeader(
                            icon: Icons.queue_music_rounded,
                            label: offlinePlaylists.isNotEmpty
                                ? 'My Playlists'
                                : null, // hide header when there's no offline section above
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final playlist = _filteredPlaylists[index];
                              final playlistId =
                                  (playlist['id'] ?? '').toString();
                              final isUploading =
                                  _uploadingBannerForId == playlistId;

                              return Stack(
                                children: [
                                  PlaylistCardWidget(
                                    key: ValueKey('online_$playlistId'),
                                    playlist: playlist,
                                    onTap: () => _openPlaylistDetail(playlist),
                                    onEdit: () => _editPlaylist(playlist),
                                    onDelete: () => _deletePlaylist(playlist),
                                    onSaveOffline: () =>
                                        _savePlaylistOffline(playlist),
                                    onRemoveOffline: () =>
                                        _removePlaylistOffline(playlistId),
                                    onBannerTap: (playlist['is_editable']
                                                as bool? ??
                                            true)
                                        ? () =>
                                            _uploadBannerForPlaylist(playlist)
                                        : null,
                                  ),
                                  // Uploading overlay shown while the banner is being uploaded
                                  if (isUploading)
                                    Positioned.fill(
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 4.w,
                                          vertical: 1.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.35),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                            childCount: _filteredPlaylists.length,
                          ),
                        ),
                      ],

                      // Bottom padding
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header widget
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String? label;

  const _SectionHeader({required this.icon, this.label});

  @override
  Widget build(BuildContext context) {
    // If no label is provided, render an invisible spacer so layout stays tidy
    if (label == null) return const SizedBox(height: 8);

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
