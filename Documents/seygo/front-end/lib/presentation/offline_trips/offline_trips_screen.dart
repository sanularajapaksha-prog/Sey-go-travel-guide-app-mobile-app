import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../data/services/offline_trip_service.dart';
import '../../theme/app_theme.dart';
import '../trip_summary/trip_summary_overview_screen.dart';

/// Shows all locally saved offline trips as a scrollable list.
/// Tapping a trip opens the full itinerary (no network calls).
class OfflineTripsScreen extends StatefulWidget {
  const OfflineTripsScreen({super.key});

  @override
  State<OfflineTripsScreen> createState() => _OfflineTripsScreenState();
}

class _OfflineTripsScreenState extends State<OfflineTripsScreen> {
  List<Map<String, dynamic>> _trips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final trips = await OfflineTripService.loadAllTrips();
    if (!mounted) return;
    setState(() {
      _trips = trips;
      _loading = false;
    });
  }

  Future<void> _deleteTrip(String id) async {
    await OfflineTripService.deleteTripById(id);
    await _loadTrips();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip deleted'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openTrip(Map<String, dynamic> trip) {
    final originMap = trip['origin'] as Map?;
    final origin = originMap != null
        ? LatLng(
            (originMap['latitude'] as num).toDouble(),
            (originMap['longitude'] as num).toDouble(),
          )
        : const LatLng(7.8731, 80.7718);
    final routePoints = ((trip['routePoints'] as List?) ?? [])
        .whereType<Map>()
        .map((p) => LatLng(
              (p['latitude'] as num).toDouble(),
              (p['longitude'] as num).toDouble(),
            ))
        .toList();
    final optimizedStops = ((trip['optimizedStops'] as List?) ?? [])
        .whereType<Map>()
        .map((s) => s.cast<String, dynamic>())
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripSummaryOverviewScreen(
          tripName: trip['tripName'] as String? ?? 'Saved Trip',
          tripGoogleUrl: trip['tripGoogleUrl'] as String? ?? '',
          dateRange: trip['dateRange'] as String? ?? '',
          days: (trip['days'] as num?)?.toInt() ?? optimizedStops.length,
          totalBudgetLKR:
              (trip['totalBudgetLKR'] as num?)?.toDouble() ?? 0,
          totalDistanceKm:
              (trip['totalDistanceKm'] as num?)?.toDouble() ?? 0,
          transportMode: trip['transportMode'] as String? ?? 'Car',
          travelTime: trip['travelTime'] as String? ?? '',
          stops:
              (trip['stops'] as num?)?.toInt() ?? optimizedStops.length,
          emergencyContact: trip['emergencyContact'] as String? ?? '',
          origin: origin,
          routePoints: routePoints,
          optimizedStops: optimizedStops,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Offline Trips',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_trips.length > 1)
            TextButton(
              onPressed: _confirmClearAll,
              child: Text(
                'Clear all',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 13.sp,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _trips.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadTrips,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.w, vertical: 2.h),
                    itemCount: _trips.length,
                    separatorBuilder: (_, _) => SizedBox(height: 1.5.h),
                    itemBuilder: (context, index) {
                      final trip = _trips[index];
                      return _TripCard(
                        trip: trip,
                        onTap: () => _openTrip(trip),
                        onDelete: () {
                          final id = trip['id']?.toString() ?? '';
                          if (id.isNotEmpty) _deleteTrip(id);
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.offline_bolt_outlined,
              size: 18.w,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            SizedBox(height: 3.h),
            Text(
              'No offline trips saved',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Create a route in the Route Planner and save it\nfor offline access.',
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

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all trips?'),
        content: const Text(
            'This will permanently delete all saved offline trips.'),
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
    if (confirmed == true) {
      await OfflineTripService.clearAllTrips();
      await _loadTrips();
    }
  }
}

// ── Trip Card ────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TripCard({
    required this.trip,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = trip['tripName'] as String? ?? 'Trip';
    final dateRange = trip['dateRange'] as String? ?? '';
    final days = (trip['days'] as num?)?.toInt() ?? 0;
    final stops = (trip['stops'] as num?)?.toInt() ?? 0;
    final distanceKm = (trip['totalDistanceKm'] as num?)?.toDouble() ?? 0;
    final transportMode = trip['transportMode'] as String? ?? 'Car';
    final savedAt = trip['savedAt'] as String?;

    String savedLabel = '';
    if (savedAt != null) {
      try {
        final dt = DateTime.parse(savedAt).toLocal();
        savedLabel =
            'Saved ${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Dismissible(
      key: ValueKey(trip['id']),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete trip?'),
            content: Text('Remove "$name" from offline storage?'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.5.w),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryLight.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.offline_bolt_rounded,
                      color: AppTheme.secondaryLight,
                      size: 5.5.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (dateRange.isNotEmpty)
                          Text(
                            dateRange,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.55),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.35)),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  _statChip(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: '$days day${days == 1 ? '' : 's'}',
                  ),
                  SizedBox(width: 2.w),
                  _statChip(
                    context,
                    icon: Icons.place_outlined,
                    label: '$stops stop${stops == 1 ? '' : 's'}',
                  ),
                  SizedBox(width: 2.w),
                  _statChip(
                    context,
                    icon: Icons.route_outlined,
                    label: '${distanceKm.toStringAsFixed(0)} km',
                  ),
                  SizedBox(width: 2.w),
                  _statChip(
                    context,
                    icon: _transportIcon(transportMode),
                    label: transportMode,
                  ),
                ],
              ),
              if (savedLabel.isNotEmpty) ...[
                SizedBox(height: 1.2.h),
                Text(
                  savedLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withOpacity(0.38),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(BuildContext context,
      {required IconData icon, required String label}) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12,
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

  IconData _transportIcon(String mode) {
    final m = mode.toLowerCase();
    if (m.contains('bus')) return Icons.directions_bus_outlined;
    if (m.contains('bike') || m.contains('cycle')) {
      return Icons.directions_bike_outlined;
    }
    if (m.contains('walk')) return Icons.directions_walk_outlined;
    return Icons.directions_car_outlined;
  }
}
