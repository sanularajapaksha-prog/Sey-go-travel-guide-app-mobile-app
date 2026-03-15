// lib/presentation/trip_summary/route_summary_itinerary_screen.dart

import 'dart:math'; // for Random()

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

class RouteSummaryItineraryScreen extends StatelessWidget {
  // Pass these from RoutePlannerScreen
  final List<Map<String, dynamic>> optimizedStops;
  final double totalDistanceKm;
  final double totalDurationMin;
  final LatLng origin;
  final List<LatLng> routePoints;

  const RouteSummaryItineraryScreen({
    super.key,
    required this.optimizedStops,
    required this.totalDistanceKm,
    required this.totalDurationMin,
    required this.origin,
    required this.routePoints,
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
        title: const Text("Your Itinerary"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {}, // TODO: share itinerary
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${optimizedStops.length} Stops",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      "${totalDistanceKm.toStringAsFixed(1)} km • ${totalDurationMin.toStringAsFixed(0)} min",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    // ─── All logic moved here so context is available ───
                    final googleUrl = Uri.parse(
                      "https://www.google.com/maps/dir/?api=1"
                      "&origin=${origin.latitude},${origin.longitude}"
                      "&destination=${origin.latitude},${origin.longitude}"
                      "&waypoints=${optimizedStops.map((stop) => "${stop['latitude'] as num},${stop['longitude'] as num}").join('|')}"
                      "&travelmode=driving",
                    );

                    if (await canLaunchUrl(googleUrl)) {
                      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Could not open Google Maps")),
                      );
                    }
                  },
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text("View on Maps"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(4.w),
              itemCount: optimizedStops.length,
              separatorBuilder: (context, index) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
                final stop = optimizedStops[index];
                final isFirst = index == 0;
                final isLast = index == optimizedStops.length - 1;

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: theme.colorScheme.primary,
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stop['name'] as String,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    stop['category'] as String? ?? 'Place',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (!isFirst || !isLast)
                          Padding(
                            padding: EdgeInsets.only(top: 2.h, bottom: 1.h),
                            child: Row(
                              children: [
                                Icon(Icons.straighten, size: 16, color: theme.colorScheme.primary),
                                SizedBox(width: 2.w),
                                Text(
                                  "≈ ${_estimateLegDistance(index)} km from previous",
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),

                        if (stop['image'] != null)
                          Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                stop['image'] as String,
                                height: 18.h,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  height: 18.h,
                                  color: theme.colorScheme.surfaceVariant,
                                  child: const Center(child: Icon(Icons.image_not_supported)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder for leg distance
  String _estimateLegDistance(int index) {
    if (index == 0) return "Start";
    return (Random().nextDouble() * 10 + 2).toStringAsFixed(1);
  }
}