// lib/presentation/trip_summary/trip_summary_overview_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

class TripSummaryOverviewScreen extends StatelessWidget {
  // Pass these from RoutePlannerScreen
  final String tripName;
  final String tripImageUrl;
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
    required this.tripImageUrl,
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
            onPressed: () {}, // TODO: share trip
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image + Trip Name Overlay
            Stack(
              children: [
                Image.network(
                  tripImageUrl,
                  height: 35.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 35.h,
                    color: theme.colorScheme.surfaceVariant,
                    child: const Center(child: Icon(Icons.image_not_supported)),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
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
                        tripName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '$dateRange - $days days',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
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
                  // Budget & Distance Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard(
                        context,
                        'Total Budget',
                        'LKR ${totalBudgetLKR.toStringAsFixed(0)}',
                        Icons.attach_money,
                      ),
                      _buildStatCard(
                        context,
                        'Total Distance',
                        '${totalDistanceKm.toStringAsFixed(0)} km',
                        Icons.straighten,
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  // Transport / Time / Stops Chips
                  Wrap(
                    spacing: 3.w,
                    runSpacing: 2.h,
                    children: [
                      _buildStatChip(
                        context,
                        Icons.directions_car,
                        'Transport',
                        transportMode,
                      ),
                      _buildStatChip(
                        context,
                        Icons.timer_outlined,
                        'Travel Time',
                        travelTime,
                      ),
                      _buildStatChip(
                        context,
                        Icons.place_outlined,
                        'Stops',
                        '$stops places',
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  // Safety & Preparation Card
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
                            subtitle: const Text('Download maps & details'),
                            value: false, // TODO: connect to real state
                            onChanged: (val) {}, // TODO: toggle download
                            activeColor: theme.colorScheme.primary,
                          ),
                          ListTile(
                            leading: const Icon(Icons.phone_outlined),
                            title: const Text('Emergency Contact'),
                            subtitle: Text(emergencyContact),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: launch tel://
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  // Start Journey Button with Confirmation Dialog
                  SizedBox(
                    width: double.infinity,
                    height: 7.h,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final choice = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Start Journey'),
                            content:
                                const Text('Open this route in external maps?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'google'),
                                child: const Text('Google Maps'),
                              ),
                              if (Theme.of(context).platform ==
                                  TargetPlatform.iOS)
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, 'apple'),
                                  child: const Text('Apple Maps'),
                                ),
                            ],
                          ),
                        );

                        if (choice == null) return;

                        final originStr =
                            '${origin.latitude},${origin.longitude}';
                        final destinationStr = optimizedStops.isNotEmpty
                            ? '${optimizedStops.last['latitude'] as num},${optimizedStops.last['longitude'] as num}'
                            : originStr;
                        final waypoints = optimizedStops.length > 1
                            ? optimizedStops
                                .sublist(0, optimizedStops.length - 1)
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
                          } else {
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
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open Apple Maps'),
                              ),
                            );
                          }
                        }
                      },
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
    );
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
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
        color: theme.colorScheme.primary.withOpacity(0.1),
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
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
