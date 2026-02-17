import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  double _routeDistanceKm = 0.0;

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
    _rebuildOptimizedRoute();
    _didLoadArguments = true;
  }

  void _rebuildOptimizedRoute() {
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
      });
      return;
    }

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
        points: points,
        color: Theme.of(context).colorScheme.primary,
        width: 5,
      ),
    };

    setState(() {
      _optimizedStops = optimized;
      _markers = markers;
      _polylines = polylines;
      _routeDistanceKm = _calculateRouteDistanceKm(points);
    });

    _fitMapToPoints(points);
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
    _rebuildOptimizedRoute();
  }

  void _optimizeRouteManually() {
    if (_cartDestinations.isEmpty) return;
    _rebuildOptimizedRoute();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Route optimized'),
        duration: Duration(seconds: 1),
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
        body: Column(
          children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_optimizedStops.length} place(s) | Approx ${_routeDistanceKm.toStringAsFixed(1)} km',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed:
                      _cartDestinations.isEmpty ? null : _optimizeRouteManually,
                  icon: const Icon(Icons.alt_route, size: 18),
                  label: const Text('Optimize Route'),
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
