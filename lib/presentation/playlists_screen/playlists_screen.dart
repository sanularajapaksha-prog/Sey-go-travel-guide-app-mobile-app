import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
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

  void _loadPlaylists() {
    _playlists = [
      {
        'id': '1',
        'name': 'Favorites',
        'description': 'My favorite destinations to visit',
        'icon': 'favorite',
        'destinationCount': 8,
        'previewImages': [
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
          'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=800',
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
        ],
        'semanticLabels': [
          'Scenic mountain landscape with snow-capped peaks under blue sky',
          'Tropical beach with turquoise water and palm trees at sunset',
          'Crystal clear ocean water meeting sandy beach with gentle waves',
        ],
        'isDefault': true,
      },
      {
        'id': '2',
        'name': 'Want to Visit',
        'description': 'Places on my bucket list',
        'icon': 'explore',
        'destinationCount': 12,
        'previewImages': [
          'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800',
          'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800',
        ],
        'semanticLabels': [
          'Winding mountain road through lush green hills at golden hour',
          'Ancient temple architecture with ornate stone carvings and pillars',
        ],
        'isDefault': true,
      },
      {
        'id': '3',
        'name': 'Beach Escapes',
        'description': 'Tropical paradise destinations',
        'icon': 'beach_access',
        'destinationCount': 6,
        'previewImages': [
          'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800',
          'https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?w=800',
          'https://images.unsplash.com/photo-1510414842594-a61c69b5ae57?w=800',
        ],
        'semanticLabels': [
          'White sand beach with crystal clear turquoise water and palm trees',
          'Tropical island beach with overwater bungalows at sunset',
          'Pristine beach cove surrounded by rocky cliffs and lush vegetation',
        ],
        'isDefault': false,
      },
      {
        'id': '4',
        'name': 'Mountain Adventures',
        'description': 'High altitude destinations',
        'icon': 'terrain',
        'destinationCount': 5,
        'previewImages': [
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800',
        ],
        'semanticLabels': [
          'Majestic mountain range with snow-covered peaks against dramatic sky',
        ],
        'isDefault': false,
      },
      {
        'id': '5',
        'name': 'Cultural Heritage',
        'description': 'Historical sites and temples',
        'icon': 'account_balance',
        'destinationCount': 9,
        'previewImages': [
          'https://images.unsplash.com/photo-1548013146-72479768bada?w=800',
          'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=800',
        ],
        'semanticLabels': [
          'Ancient Buddhist temple with golden spires and intricate architecture',
          'Historic stone temple ruins surrounded by tropical jungle vegetation',
        ],
        'isDefault': false,
      },
    ];
    _filteredPlaylists = List.from(_playlists);
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
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loadPlaylists();
    });
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
      setState(() {
        _playlists.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': result['name']!,
          'description': result['description'],
          'icon': result['icon']!,
          'destinationCount': 0,
          'previewImages': [],
          'semanticLabels': [],
          'isDefault': false,
        });
        _filteredPlaylists = List.from(_playlists);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playlist "${result['name']}" created'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _editPlaylist(Map<String, dynamic> playlist) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => CreatePlaylistDialog(
        initialName: playlist['name'] as String,
        initialDescription: playlist['description'] as String?,
        isEdit: true,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        final index = _playlists.indexWhere((p) => p['id'] == playlist['id']);
        if (index != -1) {
          _playlists[index]['name'] = result['name'];
          _playlists[index]['description'] = result['description'];
          _playlists[index]['icon'] = result['icon'];
          _filteredPlaylists = List.from(_playlists);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playlist "${result['name']}" updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deletePlaylist(Map<String, dynamic> playlist) {
    final isDefault = playlist['isDefault'] as bool;

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
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _playlists.removeWhere((p) => p['id'] == playlist['id']);
                  _filteredPlaylists = List.from(_playlists);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playlist "${playlist['name']}" deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/destination-detail-screen');
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
                          'My Playlists',
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
                        IconButton(
                          icon: CustomIconWidget(
                            iconName: 'add',
                            size: 24,
                            color: theme.colorScheme.onSurface,
                          ),
                          onPressed: _createPlaylist,
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
