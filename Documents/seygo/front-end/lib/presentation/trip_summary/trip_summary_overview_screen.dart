import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/offline_cache_item.dart';
import '../../data/services/api_service.dart';
import '../../data/services/offline_trip_service.dart';
import '../../providers/offline_provider.dart';
import '../../providers/user_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/place_photo_widget.dart';

class TripSummaryOverviewScreen extends StatefulWidget {
  final String tripName;
  final String tripGoogleUrl;
  final String dateRange;
  final int days;
  final double totalBudgetLKR;
  final double totalDistanceKm;
  final String transportMode;
  final String travelTime;
  final int stops;
  final String emergencyContact;
  final LatLng origin;
  final List<LatLng> routePoints;
  final List<Map<String, dynamic>> optimizedStops;

  const TripSummaryOverviewScreen({
    super.key,
    required this.tripName,
    required this.tripGoogleUrl,
    required this.dateRange,
    required this.days,
    required this.totalBudgetLKR,
    required this.totalDistanceKm,
    required this.transportMode,
    required this.travelTime,
    required this.stops,
    required this.emergencyContact,
    required this.origin,
    required this.routePoints,
    required this.optimizedStops,
  });

  @override
  State<TripSummaryOverviewScreen> createState() =>
      _TripSummaryOverviewScreenState();
}

class _TripSummaryOverviewScreenState extends State<TripSummaryOverviewScreen> {
  bool _offlineMode = false;
  bool _offlineReady = false;
  bool _isSavingPlaylist = false;

  /// Stable id for this trip in the offline cache.
  String get _tripCacheId =>
      'trip_${widget.tripName.replaceAll(RegExp(r'\s+'), '_').toLowerCase()}';

  @override
  void initState() {
    super.initState();
    _loadOfflineState();
  }

  Future<void> _loadOfflineState() async {
    final provider = context.read<OfflineProvider>();
    // Ensure cache is loaded
    if (provider.items.isEmpty) await provider.load();
    if (!mounted) return;
    setState(() {
      _offlineMode = provider.isCached(_tripCacheId);
      _offlineReady = true;
    });
  }

  Future<void> _toggleOfflineMode(bool value) async {
    final provider = context.read<OfflineProvider>();
    if (value) {
      // Also keep legacy OfflineTripService in sync for backward compat
      await OfflineTripService.saveTrip(
        tripName: widget.tripName,
        tripGoogleUrl: widget.tripGoogleUrl,
        dateRange: widget.dateRange,
        days: widget.days,
        totalBudgetLKR: widget.totalBudgetLKR,
        totalDistanceKm: widget.totalDistanceKm,
        transportMode: widget.transportMode,
        travelTime: widget.travelTime,
        stops: widget.stops,
        emergencyContact: widget.emergencyContact,
        origin: widget.origin,
        routePoints: widget.routePoints,
        optimizedStops: widget.optimizedStops,
      );
      await provider.save(OfflineCacheItem(
        id: _tripCacheId,
        type: OfflineCacheType.routeTrip,
        title: widget.tripName,
        imageUrl: widget.tripGoogleUrl.isNotEmpty ? widget.tripGoogleUrl : null,
        dateRange: widget.dateRange,
        days: widget.days,
        stops: widget.stops,
        distanceKm: widget.totalDistanceKm,
        budgetLKR: widget.totalBudgetLKR,
        transportMode: widget.transportMode,
        travelTime: widget.travelTime,
        emergencyContact: widget.emergencyContact,
        routeData: {
          'origin': {
            'latitude': widget.origin.latitude,
            'longitude': widget.origin.longitude,
          },
          'routePoints': widget.routePoints
              .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
              .toList(),
          'optimizedStops': widget.optimizedStops,
        },
        savedAt: DateTime.now(),
      ));
    } else {
      await provider.deleteById(_tripCacheId);
      await OfflineTripService.clearTrip();
    }
    if (!mounted) return;
    setState(() => _offlineMode = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Trip saved for offline use' : 'Offline trip cache cleared',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.secondaryLight,
      ),
    );
  }

  bool get _hasValidImage =>
      widget.tripGoogleUrl.isNotEmpty &&
      (widget.tripGoogleUrl.startsWith('http://') ||
          widget.tripGoogleUrl.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.surfaceLight,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(theme),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsSection(theme),
                _buildChipsSection(theme),
                if (widget.optimizedStops.isNotEmpty)
                  _buildStopsTimeline(theme),
                _buildSafetyCard(theme),
                _buildActionButtons(theme),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sliver app bar with hero image ──────────────────────────────────────────

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 34.h,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.secondaryLight,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: _shareTrip,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image or gradient fallback
            _hasValidImage
                ? PlacePhotoWidget(
                    googleUrl: widget.tripGoogleUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    semanticLabel: widget.tripName,
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1565C0), AppTheme.secondaryLight],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.map_rounded,
                        size: 72,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            // Trip info at bottom
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryLight.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Trip Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    widget.tripName.isNotEmpty ? widget.tripName : 'My Trip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 0.6.h),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        widget.dateRange.isNotEmpty
                            ? '${widget.dateRange} · ${widget.days} ${widget.days == 1 ? 'day' : 'days'}'
                            : '${widget.days} ${widget.days == 1 ? 'day' : 'days'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats grid ──────────────────────────────────────────────────────────────

  Widget _buildStatsSection(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.attach_money_rounded,
              label: 'Total Budget',
              value:
                  'LKR ${widget.totalBudgetLKR.toStringAsFixed(0)}',
              iconColor: const Color(0xFF22C55E),
              bgColor: const Color(0xFFDCFCE7),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _StatCard(
              icon: Icons.straighten_rounded,
              label: 'Distance',
              value: '${widget.totalDistanceKm.toStringAsFixed(0)} km',
              iconColor: AppTheme.secondaryLight,
              bgColor: const Color(0xFFDBEAFE),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _StatCard(
              icon: Icons.wb_sunny_rounded,
              label: 'Duration',
              value:
                  '${widget.days} ${widget.days == 1 ? 'Day' : 'Days'}',
              iconColor: const Color(0xFFF59E0B),
              bgColor: const Color(0xFFFEF3C7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info chips ──────────────────────────────────────────────────────────────

  Widget _buildChipsSection(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Wrap(
        spacing: 2.w,
        runSpacing: 1.2.h,
        children: [
          _InfoChip(
            icon: _transportIcon(widget.transportMode),
            label: widget.transportMode.isNotEmpty
                ? widget.transportMode
                : 'Car',
            prefix: 'Transport',
          ),
          _InfoChip(
            icon: Icons.timer_outlined,
            label: widget.travelTime.isNotEmpty ? widget.travelTime : '—',
            prefix: 'Travel Time',
          ),
          _InfoChip(
            icon: Icons.place_outlined,
            label: '${widget.stops} ${widget.stops == 1 ? 'place' : 'places'}',
            prefix: 'Stops',
          ),
        ],
      ),
    );
  }

  IconData _transportIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'walk':
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'bike':
      case 'cycling':
        return Icons.directions_bike_rounded;
      case 'transit':
      case 'bus':
        return Icons.directions_bus_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }

  // ── Stops timeline ──────────────────────────────────────────────────────────

  Widget _buildStopsTimeline(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Stops',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 1.5.h),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.optimizedStops.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 16.w,
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final stop = widget.optimizedStops[index];
                final name =
                    (stop['name'] as String?) ?? 'Stop ${index + 1}';
                final district = (stop['district'] as String?) ?? '';
                final isFirst = index == 0;
                final isLast = index == widget.optimizedStops.length - 1;

                return Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 4.w, vertical: 1.4.h),
                  child: Row(
                    children: [
                      // Number badge
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isFirst || isLast
                              ? AppTheme.secondaryLight
                              : AppTheme.secondaryLight
                                  .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isFirst || isLast
                                  ? Colors.white
                                  : AppTheme.secondaryLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (district.isNotEmpty)
                              Text(
                                district,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isFirst)
                        _StopBadge('START', AppTheme.secondaryLight)
                      else if (isLast)
                        _StopBadge('END', const Color(0xFF22C55E)),
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

  // ── Safety card ─────────────────────────────────────────────────────────────

  Widget _buildSafetyCard(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(5.w, 2.5.h, 5.w, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: AppTheme.secondaryLight, size: 20),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Safety & Preparation',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            const Divider(height: 1),
            // Offline toggle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: SwitchListTile(
                title: const Text(
                  'Offline Mode',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _offlineMode
                      ? 'Trip details saved on this device'
                      : 'Save route & details for offline use',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _offlineReady && _offlineMode,
                onChanged: _offlineReady ? _toggleOfflineMode : null,
                activeColor: AppTheme.secondaryLight,
              ),
            ),
            if (_offlineMode)
              Padding(
                padding:
                    EdgeInsets.fromLTRB(5.w, 0, 5.w, 1.5.h),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppTheme.secondaryLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Google Maps can open offline only if the map area is already downloaded in the Google Maps app.',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppTheme.secondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 1),
            // Emergency contact
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phone_rounded,
                    color: Color(0xFFEF4444), size: 20),
              ),
              title: const Text(
                'Emergency Contact',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                widget.emergencyContact.isNotEmpty
                    ? widget.emergencyContact
                    : 'Not set',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: widget.emergencyContact.isNotEmpty
                      ? AppTheme.secondaryLight
                      : null,
                ),
              ),
              trailing: widget.emergencyContact.isNotEmpty
                  ? const Icon(Icons.chevron_right,
                      color: AppTheme.secondaryLight)
                  : null,
              onTap: widget.emergencyContact.isNotEmpty
                  ? _callEmergencyContact
                  : null,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action buttons ──────────────────────────────────────────────────────────

  Widget _buildActionButtons(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 0),
      child: Column(
        children: [
          // Save as Playlist
          SizedBox(
            width: double.infinity,
            height: 6.5.h,
            child: OutlinedButton.icon(
              onPressed: _isSavingPlaylist ? null : _saveAsPlaylist,
              icon: _isSavingPlaylist
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.secondaryLight),
                    )
                  : const Icon(Icons.playlist_add_rounded),
              label: Text(
                'Save as Playlist',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.secondaryLight,
                side: const BorderSide(color: AppTheme.secondaryLight, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          SizedBox(height: 1.5.h),
          // Start Journey
          SizedBox(
            width: double.infinity,
            height: 6.5.h,
            child: ElevatedButton.icon(
              onPressed: _startJourney,
              icon: const Icon(Icons.play_arrow_rounded, size: 26),
              label: Text(
                'Start Journey',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryLight,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _shareTrip() {
    final stopNames = widget.optimizedStops
        .map((s) => s['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    final text = stopNames.isEmpty
        ? 'Check out my SeyGo trip: ${widget.tripName}'
        : 'Check out my SeyGo trip: ${widget.tripName}\n${stopNames.map((n) => '• $n').join('\n')}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startJourney() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Start Journey',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          _offlineMode
              ? 'Open this route in external maps? If you are offline, Google Maps will only navigate if that region is already downloaded.'
              : 'Open this route in external maps?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryLight,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, 'google'),
            child: const Text('Google Maps'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    final originStr = '${widget.origin.latitude},${widget.origin.longitude}';
    final destinationStr = widget.optimizedStops.isNotEmpty
        ? '${widget.optimizedStops.last['latitude'] as num},${widget.optimizedStops.last['longitude'] as num}'
        : originStr;
    final waypoints = widget.optimizedStops.length > 1
        ? widget.optimizedStops
            .sublist(0, widget.optimizedStops.length - 1)
            .map((s) =>
                '${s['latitude'] as num},${s['longitude'] as num}')
            .join('|')
        : '';

    final googleUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$originStr'
      '&destination=$destinationStr'
      '${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  Future<void> _saveAsPlaylist() async {
    final nameController = TextEditingController(text: widget.tripName);
    final descController = TextEditingController(
      text:
          '${widget.stops} stops · ${widget.totalDistanceKm.toStringAsFixed(0)} km',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        bool isPublic = false;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Save as Playlist',
                style: TextStyle(fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isPublic ? 'Public' : 'Private'),
                    Switch(
                      value: isPublic,
                      activeColor: AppTheme.secondaryLight,
                      onChanged: (v) => setLocal(() => isPublic = v),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () =>
                    Navigator.pop(ctx, {'isPublic': isPublic}),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSavingPlaylist = true);

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final playlist = await ApiService.createPlaylist(
      name: name,
      description: descController.text.trim().isNotEmpty
          ? descController.text.trim()
          : null,
      icon: 'route',
      visibility: (result['isPublic'] as bool? ?? false) ? 'public' : 'private',
      accessToken: token,
    );

    if (playlist == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create playlist.')),
        );
        setState(() => _isSavingPlaylist = false);
      }
      return;
    }

    // Invalidate cache so Playlists tab fetches fresh data on next visit.
    if (mounted) {
      Provider.of<UserDataProvider>(context, listen: false).invalidate();
    }

    final playlistId = playlist['id']?.toString() ?? '';
    int saved = 0;
    for (final stop in widget.optimizedStops) {
      // Check every possible id key the stop map might carry
      final pid = (stop['place_id'] ??
              stop['id'] ??
              stop['placeId'] ??
              stop['destination_id'])
          ?.toString()
          .trim() ?? '';
      if (pid.isEmpty) continue;
      final ok = await ApiService.addDestinationToPlaylist(
        playlistId: playlistId,
        placeId: pid,
        accessToken: token,
      );
      if (ok) saved++;
    }

    if (mounted) {
      final msg = saved > 0
          ? 'Trip saved as playlist! ($saved/${widget.optimizedStops.length} stops added)'
          : 'Playlist created but stops could not be linked. Try adding them manually.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: saved > 0 ? AppTheme.secondaryLight : Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() => _isSavingPlaylist = false);
    }
  }

  Future<void> _callEmergencyContact() async {
    final telUri = Uri.parse('tel:${widget.emergencyContact}');
    if (await canLaunchUrl(telUri)) await launchUrl(telUri);
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          SizedBox(height: 1.2.h),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10.5.sp,
            ),
          ),
          SizedBox(height: 0.4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String prefix;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.prefix,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.secondaryLight),
          SizedBox(width: 1.5.w),
          Text(
            '$prefix  ',
            style: TextStyle(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StopBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
