import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../data/models/offline_cache_item.dart';
import '../../providers/offline_provider.dart';
import '../../theme/app_theme.dart';
import '../playlist_details/playlist_details_screen.dart';
import '../trip_summary/trip_summary_overview_screen.dart';

/// Shows all locally cached offline content — route trips, saved destinations,
/// and downloaded playlists.
///
/// Uses [OfflineProvider] for reactive state; no direct SharedPreferences calls.
class OfflineTripsScreen extends StatefulWidget {
  const OfflineTripsScreen({super.key});

  @override
  State<OfflineTripsScreen> createState() => _OfflineTripsScreenState();
}

class _OfflineTripsScreenState extends State<OfflineTripsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    // 3 tabs: Trips · Places · Playlists
    _tab = TabController(length: 3, vsync: this);
    // Refresh cache every time this screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfflineProvider>().load();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── navigation handlers ────────────────────────────────────────────────────

  void _openTrip(OfflineCacheItem item) {
    final rd = item.routeData ?? {};
    final originMap = rd['origin'] as Map?;
    final origin = originMap != null
        ? LatLng(
            (originMap['latitude'] as num).toDouble(),
            (originMap['longitude'] as num).toDouble(),
          )
        : const LatLng(7.8731, 80.7718);
    final routePoints = ((rd['routePoints'] as List?) ?? [])
        .whereType<Map>()
        .map((p) => LatLng(
              (p['latitude'] as num).toDouble(),
              (p['longitude'] as num).toDouble(),
            ))
        .toList();
    final optimizedStops = ((rd['optimizedStops'] as List?) ?? [])
        .whereType<Map>()
        .map((s) => s.cast<String, dynamic>())
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripSummaryOverviewScreen(
          tripName: item.title,
          tripGoogleUrl: item.imageUrl ?? '',
          dateRange: item.dateRange ?? '',
          days: item.days ?? optimizedStops.length,
          totalBudgetLKR: item.budgetLKR ?? 0,
          totalDistanceKm: item.distanceKm ?? 0,
          transportMode: item.transportMode ?? 'Car',
          travelTime: item.travelTime ?? '',
          stops: item.stops ?? optimizedStops.length,
          emergencyContact: item.emergencyContact ?? '',
          origin: origin,
          routePoints: routePoints,
          optimizedStops: optimizedStops,
        ),
      ),
    );
  }

  void _openDestination(OfflineCacheItem item) {
    final data = item.placeData ?? {};
    Navigator.of(context).pushNamed(
      '/destination-detail-screen',
      arguments: {'destination': data.isNotEmpty ? data : _itemToDestMap(item)},
    );
  }

  /// Opens the playlist detail screen using the cached playlist snapshot.
  void _openPlaylist(OfflineCacheItem item) {
    final playlistData = item.playlistData ?? {};
    // Use the cached data; the detail screen will try to fetch fresh stops too
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistDetailsScreen(
          playlistId: item.id,
          initialPlaylist: playlistData.isNotEmpty
              ? playlistData
              : {
                  'id': item.id,
                  'name': item.title,
                  'icon': 'playlist_play',
                  'description': item.description ?? '',
                  'destination_count': 0,
                  'destinationCount': 0,
                },
        ),
      ),
    );
  }

  Map<String, dynamic> _itemToDestMap(OfflineCacheItem item) => {
        'id': item.id,
        'name': item.title,
        'location': item.location ?? 'Sri Lanka',
        'description': item.description ?? '',
        'latitude': item.latitude ?? 7.8731,
        'longitude': item.longitude ?? 80.7718,
        'googleUrl': item.imageUrl,
        'imageUrl': item.imageUrl,
        'category': item.category,
      };

  Future<void> _delete(OfflineCacheItem item) async {
    await context.read<OfflineProvider>().deleteById(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from offline storage'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmClearAll(List<OfflineCacheItem> items) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all offline data?'),
        content: const Text(
            'This will permanently delete all saved offline trips, places, and playlists.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete all',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<OfflineProvider>().clearAll();
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<OfflineProvider>(
      builder: (context, provider, _) {
        final allItems = provider.items;
        final trips = provider.trips;
        final destinations = provider.destinations;
        final playlists = provider.playlists; // ← NEW

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            title: Text(
              'Offline Content',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (allItems.isNotEmpty)
                TextButton(
                  onPressed: () => _confirmClearAll(allItems),
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
            ],
            bottom: TabBar(
              controller: _tab,
              indicatorColor: AppTheme.secondaryLight,
              labelColor: AppTheme.secondaryLight,
              unselectedLabelColor:
                  theme.colorScheme.onSurface.withOpacity(0.55),
              tabs: [
                Tab(text: 'Trips (${trips.length})'),
                Tab(text: 'Places (${destinations.length})'),
                Tab(text: 'Playlists (${playlists.length})'), // ← NEW TAB
              ],
            ),
          ),
          body: provider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 2))
              : TabBarView(
                  controller: _tab,
                  children: [
                    // ── Tab 0: Offline trips ──────────────────────────────
                    _ItemList(
                      items: trips,
                      emptyIcon: Icons.offline_bolt_outlined,
                      emptyTitle: 'No offline trips saved',
                      emptyBody:
                          'Create a route in Route Planner and save it for offline access.',
                      onTap: _openTrip,
                      onDelete: _delete,
                    ),

                    // ── Tab 1: Offline places ─────────────────────────────
                    _ItemList(
                      items: destinations,
                      emptyIcon: Icons.place_outlined,
                      emptyTitle: 'No offline places saved',
                      emptyBody:
                          'Open a destination and tap "Save Offline" to access it without internet.',
                      onTap: _openDestination,
                      onDelete: _delete,
                    ),

                    // ── Tab 2: Offline playlists ──────────────────────────
                    _PlaylistList(
                      playlists: playlists,
                      onTap: _openPlaylist,
                      onDelete: _delete,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ── Generic scrollable item list (trips + places) ─────────────────────────────

class _ItemList extends StatelessWidget {
  final List<OfflineCacheItem> items;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyBody;
  final void Function(OfflineCacheItem) onTap;
  final void Function(OfflineCacheItem) onDelete;

  const _ItemList({
    required this.items,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyBody,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(
          icon: emptyIcon, title: emptyTitle, body: emptyBody);
    }
    final theme = Theme.of(context);
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: 1.5.h),
      itemBuilder: (context, index) {
        final item = items[index];
        return _CacheItemCard(
          item: item,
          onTap: () => onTap(item),
          onDelete: () => onDelete(item),
          theme: theme,
        );
      },
    );
  }
}

// ── Offline playlist list ─────────────────────────────────────────────────────

class _PlaylistList extends StatelessWidget {
  final List<OfflineCacheItem> playlists;
  final void Function(OfflineCacheItem) onTap;
  final void Function(OfflineCacheItem) onDelete;

  const _PlaylistList({
    required this.playlists,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return const _EmptyState(
        icon: Icons.queue_music_outlined,
        title: 'No offline playlists saved',
        body:
            'Go to Playlists, tap the cloud icon on any playlist, and it will appear here for offline access.',
      );
    }

    final theme = Theme.of(context);
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: playlists.length,
      separatorBuilder: (_, _) => SizedBox(height: 1.5.h),
      itemBuilder: (context, index) {
        final item = playlists[index];
        return _PlaylistCard(
          item: item,
          onTap: () => onTap(item),
          onDelete: () => onDelete(item),
          theme: theme,
        );
      },
    );
  }
}

// ── Playlist card for offline tab ─────────────────────────────────────────────

class _PlaylistCard extends StatelessWidget {
  final OfflineCacheItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ThemeData theme;

  const _PlaylistCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final savedAt = item.savedAt;
    final savedLabel = 'Saved ${savedAt.day}/${savedAt.month}/${savedAt.year}';

    // Pull destination count from the cached playlistData snapshot
    final playlistData = item.playlistData ?? {};
    final destCount =
        (playlistData['destinationCount'] ?? playlistData['destination_count'] ?? 0)
            as int;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove playlist?'),
            content: Text('Remove "${item.title}" from offline storage?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Remove',
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 6.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail or fallback icon
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        width: 14.w,
                        height: 14.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _playlistIconBox(),
                      )
                    : _playlistIconBox(),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (destCount > 0) ...[
                      SizedBox(height: 0.4.h),
                      Text(
                        '$destCount ${destCount == 1 ? 'destination' : 'destinations'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                    if (item.description != null &&
                        item.description!.isNotEmpty) ...[
                      SizedBox(height: 0.3.h),
                      Text(
                        item.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.45),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 0.6.h),
                    Row(
                      children: [
                        Icon(
                          Icons.download_done_rounded,
                          size: 12,
                          color: AppTheme.secondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          savedLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.38),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.35)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playlistIconBox() {
    return Container(
      width: 14.w,
      height: 14.w,
      decoration: BoxDecoration(
        color: AppTheme.secondaryLight.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.queue_music_rounded,
        color: AppTheme.secondaryLight,
        size: 6.w,
      ),
    );
  }
}

// ── Generic item card (trips + places) ───────────────────────────────────────

class _CacheItemCard extends StatelessWidget {
  final OfflineCacheItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ThemeData theme;

  const _CacheItemCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isTrip = item.type == OfflineCacheType.routeTrip;
    final savedAt = item.savedAt;
    final savedLabel =
        'Saved ${savedAt.day}/${savedAt.month}/${savedAt.year}';

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isTrip ? 'Delete trip?' : 'Delete place?'),
            content: Text('Remove "${item.title}" from offline storage?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 6.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        width: 14.w,
                        height: 14.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _iconBox(isTrip, theme),
                      )
                    : _iconBox(isTrip, theme),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.location != null && item.location!.isNotEmpty)
                      Text(
                        item.location!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (isTrip) ...[
                      SizedBox(height: 0.8.h),
                      Row(
                        children: [
                          _chip(context,
                              icon: Icons.calendar_today_outlined,
                              label: '${item.days ?? 0}d'),
                          SizedBox(width: 1.5.w),
                          _chip(context,
                              icon: Icons.place_outlined,
                              label: '${item.stops ?? 0} stops'),
                          SizedBox(width: 1.5.w),
                          _chip(context,
                              icon: Icons.route_outlined,
                              label:
                                  '${(item.distanceKm ?? 0).toStringAsFixed(0)} km'),
                        ],
                      ),
                    ] else if (item.category != null &&
                        item.category!.isNotEmpty) ...[
                      SizedBox(height: 0.6.h),
                      _chip(context,
                          icon: Icons.category_outlined,
                          label: item.category!),
                    ],
                    SizedBox(height: 0.6.h),
                    Text(
                      savedLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.38),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.35)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBox(bool isTrip, ThemeData theme) {
    return Container(
      width: 14.w,
      height: 14.w,
      decoration: BoxDecoration(
        color: AppTheme.secondaryLight.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isTrip ? Icons.offline_bolt_rounded : Icons.place_rounded,
        color: AppTheme.secondaryLight,
        size: 6.w,
      ),
    );
  }

  Widget _chip(BuildContext context,
      {required IconData icon, required String label}) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 11,
              color: theme.colorScheme.onSurface.withOpacity(0.55)),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _EmptyState(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18.w,
                color: theme.colorScheme.onSurface.withOpacity(0.18)),
            SizedBox(height: 3.h),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
