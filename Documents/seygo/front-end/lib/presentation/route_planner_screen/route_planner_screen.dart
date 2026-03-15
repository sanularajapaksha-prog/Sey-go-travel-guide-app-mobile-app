import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/services/api_service.dart';
import '../trip_summary/route_summary_itinerary_screen.dart';
import '../trip_summary/trip_summary_overview_screen.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  static const LatLng _defaultOrigin = LatLng(7.8731, 80.7718);
  GoogleMapController? _mapController;
  bool _didLoadArguments = false;

  LatLng _origin = _defaultOrigin;
  List<Map<String, dynamic>> _cartDestinations = [];
  List<Map<String, dynamic>> _optimizedStops = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  double _routeDistanceKm = 0.0;
  double _routeDurationMin = 0.0;
  bool _isOptimizingRoute = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadArguments) return;

    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final rawDestinations = (arguments?['destinations'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];
    final originMap = arguments?['origin'] as Map?;

    if (originMap != null &&
        originMap['latitude'] is num &&
        originMap['longitude'] is num) {
      _origin = LatLng(
        (originMap['latitude'] as num).toDouble(),
        (originMap['longitude'] as num).toDouble(),
      );
    }

    _cartDestinations = rawDestinations;
    unawaited(_rebuildOptimizedRoute());
    _didLoadArguments = true;
  }

  Future<void> _rebuildOptimizedRoute() async {
    if (_cartDestinations.isEmpty) {
      setState(() {
        _optimizedStops = [];
        _markers = {
          Marker(
            markerId: const MarkerId('origin'),
            position: _origin,
            infoWindow: const InfoWindow(title: 'Start'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        };
        _polylines = {};
        _routeDistanceKm = 0.0;
        _routeDurationMin = 0.0;
        _isOptimizingRoute = false;
      });
      return;
    }

    setState(() {
      _isOptimizingRoute = true;
    });

    try {
      final response = await ApiService.optimizeRoute(
        origin: {
          'latitude': _origin.latitude,
          'longitude': _origin.longitude,
        },
        destinations: _cartDestinations
            .where(
              (d) => d['latitude'] is num && d['longitude'] is num,
            )
            .map((d) => {
                  ...d,
                  'latitude': (d['latitude'] as num).toDouble(),
                  'longitude': (d['longitude'] as num).toDouble(),
                })
            .toList(),
      );

      final optimized = (response['optimized_stops'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          <Map<String, dynamic>>[];

      final polylineRaw = (response['polyline_points'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          <Map<String, dynamic>>[];

      final points = <LatLng>[];
      for (final p in polylineRaw) {
        final lat = p['latitude'];
        final lng = p['longitude'];
        if (lat is num && lng is num) {
          points.add(LatLng(lat.toDouble(), lng.toDouble()));
        }
      }

      if (points.isEmpty) {
        points.add(_origin);
        for (final stop in optimized) {
          points.add(
            LatLng(
              (stop['latitude'] as num).toDouble(),
              (stop['longitude'] as num).toDouble(),
            ),
          );
        }
      }
      if (!mounted) return;

      _applyOptimizedRoute(
        optimized: optimized,
        routePoints: points,
        totalDistanceKm: (response['total_distance_km'] as num?)?.toDouble(),
        totalDurationMin:
            (response['total_duration_min'] as num?)?.toDouble() ?? 0.0,
      );
      return;
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      final shortMessage = message.length > 220
          ? '${message.substring(0, 220)}...'
          : message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Road routing unavailable: $shortMessage'),
          duration: const Duration(seconds: 4),
        ),
      );
      // Fallback to straight-line local optimization if backend routing fails.
      final optimized = _nearestNeighborOrder(_origin, _cartDestinations);
      final points = <LatLng>[_origin];
      for (final stop in optimized) {
        points.add(
          LatLng(
            (stop['latitude'] as num).toDouble(),
            (stop['longitude'] as num).toDouble(),
          ),
        );
      }
      _applyOptimizedRoute(
        optimized: optimized,
        routePoints: points,
        totalDistanceKm: _calculateRouteDistanceKm(points),
        totalDurationMin: 0.0,
      );
    }
  }

  void _applyOptimizedRoute({
    required List<Map<String, dynamic>> optimized,
    required List<LatLng> routePoints,
    double? totalDistanceKm,
    double totalDurationMin = 0.0,
  }) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('origin'),
        position: _origin,
        infoWindow: const InfoWindow(title: 'Start'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
    for (var i = 0; i < optimized.length; i++) {
      final stop = optimized[i];
      markers.add(
        Marker(
          markerId: MarkerId('stop_${stop['id']}'),
          position: LatLng(
            (stop['latitude'] as num).toDouble(),
            (stop['longitude'] as num).toDouble(),
          ),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${stop['name']}',
            snippet: stop['category'] as String?,
          ),
        ),
      );
    }

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('optimized_route'),
        points: routePoints,
        color: Theme.of(context).colorScheme.primary,
        width: 5,
      ),
    };

    setState(() {
      _optimizedStops = optimized;
      _markers = markers;
      _polylines = polylines;
      _routePoints = routePoints;
      _routeDistanceKm =
          totalDistanceKm ?? _calculateRouteDistanceKm(routePoints);
      _routeDurationMin = totalDurationMin;
      _isOptimizingRoute = false;
    });

    _fitMapToPoints(routePoints);
  }

  List<Map<String, dynamic>> _nearestNeighborOrder(
    LatLng origin,
    List<Map<String, dynamic>> destinations,
  ) {
    final pending = destinations.map((d) => Map<String, dynamic>.from(d)).toList();
    final ordered = <Map<String, dynamic>>[];
    var current = origin;

    while (pending.isNotEmpty) {
      pending.sort((a, b) {
        final aLatLng = LatLng(
          (a['latitude'] as num).toDouble(),
          (a['longitude'] as num).toDouble(),
        );
        final bLatLng = LatLng(
          (b['latitude'] as num).toDouble(),
          (b['longitude'] as num).toDouble(),
        );
        return _distanceKm(current, aLatLng).compareTo(
          _distanceKm(current, bLatLng),
        );
      });

      final next = pending.removeAt(0);
      ordered.add(next);
      current = LatLng(
        (next['latitude'] as num).toDouble(),
        (next['longitude'] as num).toDouble(),
      );
    }

    return ordered;
  }

  double _distanceKm(LatLng from, LatLng to) {
    final meters = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    return meters / 1000;
  }

  double _calculateRouteDistanceKm(List<LatLng> points) {
    if (points.length < 2) return 0;
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += _distanceKm(points[i], points[i + 1]);
    }
    return total;
  }

  Future<void> _fitMapToPoints(List<LatLng> points) async {
    if (_mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    if ((maxLat - minLat).abs() < 0.0001 && (maxLng - minLng).abs() < 0.0001) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 12),
      );
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 64),
    );
  }

  void _removeFromCart(Map<String, dynamic> destination) {
    _cartDestinations.removeWhere((d) => d['id'] == destination['id']);
    unawaited(_rebuildOptimizedRoute());
  }

  void _optimizeRouteManually() {
    if (_cartDestinations.isEmpty) return;
    unawaited(_rebuildOptimizedRoute());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Route optimized'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _openTripOverview() {
    if (_optimizedStops.isEmpty) return;

    final firstStop = _optimizedStops.first;
    final imageUrl =
        (firstStop['image'] ?? firstStop['photo_url'] ?? '').toString();
    final resolvedImageUrl = imageUrl.isNotEmpty
        ? imageUrl
        : 'https://images.unsplash.com/photo-1501785888041-af3ef285b470';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripSummaryOverviewScreen(
          tripName: 'Your Trip',
          tripImageUrl: resolvedImageUrl,
          dateRange: 'Flexible dates',
          days: _optimizedStops.length,
          totalBudgetLKR: 0.0,
          totalDistanceKm: _routeDistanceKm,
          transportMode: 'Car',
          travelTime: _routeDurationMin > 0
              ? '${_routeDurationMin.toStringAsFixed(0)} min'
              : 'Not available',
          stops: _optimizedStops.length,
          emergencyContact: '+94 112 345 678',
          origin: _origin,
          routePoints: _routePoints.isNotEmpty ? _routePoints : [_origin],
          optimizedStops: _optimizedStops,
        ),
      ),
    );
  }

  void _openItinerary() {
    if (_optimizedStops.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteSummaryItineraryScreen(
          optimizedStops: _optimizedStops,
          totalDistanceKm: _routeDistanceKm,
          totalDurationMin: _routeDurationMin,
          origin: _origin,
          routePoints: _routePoints.isNotEmpty ? _routePoints : [_origin],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_cartDestinations);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_cartDestinations),
          ),
          title: const Text('Trip Cart & Route'),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cartDestinations.isEmpty || _isOptimizingRoute
                        ? null
                        : _optimizeRouteManually,
                    icon: const Icon(Icons.alt_route, size: 18),
                    label: Text(
                      _isOptimizingRoute ? 'Optimizing...' : 'Optimize Route',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _optimizedStops.isEmpty || _isOptimizingRoute
                        ? null
                        : _openItinerary,
                    icon: const Icon(Icons.route_outlined, size: 18),
                    label: const Text('View Itinerary'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _optimizedStops.isEmpty || _isOptimizingRoute
                        ? null
                        : _openTripOverview,
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Trip Overview'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_optimizedStops.length} place(s) | ${_routeDistanceKm.toStringAsFixed(1)} km${_routeDurationMin > 0 ? ' | ${_routeDurationMin.toStringAsFixed(0)} min' : ''}',
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.34,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _origin, zoom: 8),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {
                _mapController = controller;
                final points = <LatLng>[
                  _origin,
                  ..._optimizedStops.map(
                    (stop) => LatLng(
                      (stop['latitude'] as num).toDouble(),
                      (stop['longitude'] as num).toDouble(),
                    ),
                  ),
                ];
                _fitMapToPoints(points);
              },
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
          Expanded(
            child: _optimizedStops.isEmpty
                ? Center(
                    child: Text(
                      'No places in cart yet.\nAdd places from map screen.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _optimizedStops.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final stop = _optimizedStops[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: theme.colorScheme.primary,
                              child: Text(
                                '${index + 1}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stop['name'] as String,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    stop['category'] as String,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeFromCart(stop),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Remove',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          ],
        ),
      ),
    );
  }
}
