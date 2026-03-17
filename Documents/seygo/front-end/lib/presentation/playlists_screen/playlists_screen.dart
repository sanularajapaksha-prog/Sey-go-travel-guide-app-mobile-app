import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../data/services/api_service.dart';
import '../../widgets/custom_icon_widget.dart';
import '../playlist_details/playlist_details_screen.dart';
import './widgets/create_playlist_dialog.dart';
import './widgets/empty_playlists_widget.dart';
import './widgets/playlist_card_widget.dart';

/// Playlists Screen - Manages user's saved destination collections
/// Displays playlists in vertical scrolling card layout with creation and management features
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

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final data = await ApiService.fetchPlaylists(accessToken: token);
    if (mounted) {
      setState(() {
        _playlists = data;
        _filteredPlaylists = List.from(_playlists);
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
          final descLower = (playlist['description'] as String? ?? '')
              .toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) ||
              descLower.contains(queryLower);
        }).toList();
      }
    });
  }

  Future<void> _refreshPlaylists() async {
    await _loadPlaylists();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlists synced'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

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
        await _loadPlaylists();
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
        await _loadPlaylists();
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
                  await _loadPlaylists();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          color: theme.appBarTheme.backgroundColor,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
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
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: CustomIconWidget(
                                iconName: 'clear',
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isSearching = false;
                                  _searchController.clear();
                                  _filteredPlaylists = List.from(
                                    _playlists,
                                  );
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
                          style: theme.textTheme.headlineSmall?.copyWith(
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
                          onPressed: () => setState(() => _isSearching = true),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _filteredPlaylists.isEmpty
              ? _playlists.isEmpty
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
          )
              : RefreshIndicator(
            onRefresh: _refreshPlaylists,
            child: ListView.builder(
              padding: EdgeInsets.only(top: 1.h, bottom: 2.h),
              itemCount: _filteredPlaylists.length,
              itemBuilder: (context, index) {
                final playlist = _filteredPlaylists[index];
                return PlaylistCardWidget(
                  playlist: playlist,
                  onTap: () => _openPlaylistDetail(playlist),
                  onEdit: () => _editPlaylist(playlist),
                  onDelete: () => _deletePlaylist(playlist),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
