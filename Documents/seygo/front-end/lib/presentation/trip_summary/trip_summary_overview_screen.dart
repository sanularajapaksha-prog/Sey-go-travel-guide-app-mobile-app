import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/api_service.dart';
import '../../data/services/offline_trip_service.dart';
import '../../widgets/custom_image_widget.dart';

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
  static const String _offlineEnabledKey = 'offline_trip_mode_enabled';

  bool _offlineMode = false;
  bool _offlineReady = false;
  bool _isSavingPlaylist = false;

  @override
  void initState() {
    super.initState();
    _loadOfflineState();
  }

  Future<void> _loadOfflineState() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_offlineEnabledKey) ?? false;
    final hasCachedTrip = await OfflineTripService.hasOfflineTrip();
    if (!mounted) return;
    setState(() {
      _offlineMode = enabled && hasCachedTrip;
      _offlineReady = true;
    });
  }

  Future<void> _toggleOfflineMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
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
      await prefs.setBool(_offlineEnabledKey, true);
    } else {
      await OfflineTripService.clearTrip();
      await prefs.setBool(_offlineEnabledKey, false);
    }

    if (!mounted) return;
    setState(() => _offlineMode = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Trip saved for offline use'
              : 'Offline trip cache cleared',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Trip Summary'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CustomImageWidget(
                  imageUrl: widget.tripGoogleUrl,
                  height: 35.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tripName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '${widget.dateRange} - ${widget.days} days',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(5.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard(
                        context,
                        'Total Budget',
                        'LKR ${widget.totalBudgetLKR.toStringAsFixed(0)}',
                        Icons.attach_money,
                      ),
                      _buildStatCard(
                        context,
                        'Total Distance',
                        '${widget.totalDistanceKm.toStringAsFixed(0)} km',
                        Icons.straighten,
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Wrap(
                    spacing: 3.w,
                    runSpacing: 2.h,
                    children: [
                      _buildStatChip(
                        context,
                        Icons.directions_car,
                        'Transport',
                        widget.transportMode,
                      ),
                      _buildStatChip(
                        context,
                        Icons.timer_outlined,
                        'Travel Time',
                        widget.travelTime,
                      ),
                      _buildStatChip(
                        context,
                        Icons.place_outlined,
                        'Stops',
                        '${widget.stops} places',
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(5.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safety & Preparation',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          SwitchListTile(
                            title: const Text('Offline Mode'),
                            subtitle: Text(
                              _offlineMode
                                  ? 'Trip details saved on this device'
                                  : 'Save route and trip details for offline use',
                            ),
                            value: _offlineReady && _offlineMode,
                            onChanged: _offlineReady ? _toggleOfflineMode : null,
                            activeColor: theme.colorScheme.primary,
                          ),
                          if (_offlineMode)
                            Padding(
                              padding: EdgeInsets.only(
                                left: 4.w,
                                right: 4.w,
                                bottom: 1.h,
                              ),
                              child: Text(
                                'Google Maps can open offline only if the map area is already downloaded in the Google Maps app.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ListTile(
                            leading: const Icon(Icons.phone_outlined),
                            title: const Text('Emergency Contact'),
                            subtitle: Text(widget.emergencyContact),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _callEmergencyContact,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  SizedBox(
                    width: double.infinity,
                    height: 7.h,
                    child: OutlinedButton.icon(
                      onPressed: _isSavingPlaylist ? null : _saveAsPlaylist,
                      icon: _isSavingPlaylist
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.playlist_add),
                      label: Text(
                        'Save as Playlist',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    width: double.infinity,
                    height: 7.h,
                    child: ElevatedButton.icon(
                      onPressed: _startJourney,
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: Text(
                        'Start Journey',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _startJourney() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Journey'),
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
          TextButton(
            onPressed: () => Navigator.pop(context, 'google'),
            child: const Text('Google Maps'),
          ),
          if (Theme.of(context).platform == TargetPlatform.iOS)
            TextButton(
              onPressed: () => Navigator.pop(context, 'apple'),
              child: const Text('Apple Maps'),
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
            .map(
              (stop) =>
                  '${stop['latitude'] as num},${stop['longitude'] as num}',
            )
            .join('|')
        : '';

    if (choice == 'google') {
      final googleUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$originStr'
        '&destination=$destinationStr'
        '${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}'
        '&travelmode=driving',
      );
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(
          googleUrl,
          mode: LaunchMode.externalApplication,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps'),
          ),
        );
      }
    } else if (choice == 'apple') {
      final appleUrl = Uri.parse(
        'maps://?saddr=$originStr&daddr=$destinationStr&dirflg=d',
      );
      if (await canLaunchUrl(appleUrl)) {
        await launchUrl(
          appleUrl,
          mode: LaunchMode.externalApplication,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Apple Maps'),
          ),
        );
      }
    }
  }

  Future<void> _saveAsPlaylist() async {
    final nameController = TextEditingController(text: widget.tripName);
    final descController = TextEditingController(
      text: '${widget.stops} stops · ${widget.totalDistanceKm.toStringAsFixed(0)} km',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        bool isPublic = false;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Save as Playlist'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isPublic ? 'Public' : 'Private'),
                    Switch(
                      value: isPublic,
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
              TextButton(
                onPressed: () => Navigator.pop(ctx, {'isPublic': isPublic}),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;
    final isPublic = result['isPublic'] as bool? ?? false;

    final name = nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSavingPlaylist = true);

    final token = Supabase.instance.client.auth.currentSession?.accessToken;

    final playlist = await ApiService.createPlaylist(
      name: name,
      description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
      icon: 'route',
      visibility: isPublic ? 'public' : 'private',
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

    final playlistId = playlist['id']?.toString() ?? '';
    int saved = 0;
    for (final stop in widget.optimizedStops) {
      final rawId = stop['place_id'] ?? stop['id'];
      final pid = rawId?.toString() ?? '';
      if (pid.isNotEmpty) {
        final ok = await ApiService.addDestinationToPlaylist(
          playlistId: playlistId,
          placeId: pid,
          accessToken: token,
        );
        if (ok) saved++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip saved as playlist! ($saved stops added)')),
      );
      setState(() => _isSavingPlaylist = false);
    }
  }

  Future<void> _callEmergencyContact() async {
    final telUri = Uri.parse('tel:${widget.emergencyContact}');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            SizedBox(height: 1.h),
            Text(title, style: theme.textTheme.bodySmall),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          SizedBox(width: 2.w),
          Text(label, style: theme.textTheme.bodySmall),
          SizedBox(width: 2.w),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
