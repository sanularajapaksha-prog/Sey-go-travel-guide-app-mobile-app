import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Interactive map preview that shows the destination pin, the user's current
/// location (blue dot), and a direct line between them.
class MapPreviewWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;
  final VoidCallback onNavigate;

  const MapPreviewWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.onNavigate,
  });

  @override
  State<MapPreviewWidget> createState() => _MapPreviewWidgetState();
}

class _MapPreviewWidgetState extends State<MapPreviewWidget> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  bool _locationLoading = true;
  bool _hasPermission = false;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  LatLng get _destination => LatLng(widget.latitude, widget.longitude);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Always show the destination marker immediately.
    if (mounted) {
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('destination'),
            position: _destination,
            infoWindow: InfoWindow(title: widget.locationName),
          ),
        };
      });
    }

    await _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _locationLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      final userLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _hasPermission = true;
        _userLocation = userLatLng;
        _locationLoading = false;

        // User location marker (azure/blue)
        _markers = {
          Marker(
            markerId: const MarkerId('destination'),
            position: _destination,
            infoWindow: InfoWindow(title: widget.locationName),
          ),
          Marker(
            markerId: const MarkerId('user'),
            position: userLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        };

        // Straight line from user → destination
        _polylines = {
          Polyline(
            polylineId: const PolylineId('preview_route'),
            points: [userLatLng, _destination],
            color: Theme.of(context).colorScheme.primary,
            width: 3,
            patterns: [PatternItem.dash(12), PatternItem.gap(6)],
          ),
        };
      });

      // Fit camera once the controller is ready
      _fitCamera();
    } catch (_) {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  void _fitCamera() {
    final controller = _mapController;
    if (controller == null) return;

    final dest = _destination;
    final user = _userLocation;

    if (user == null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(dest, 14));
      return;
    }

    final minLat = math.min(user.latitude, dest.latitude);
    final maxLat = math.max(user.latitude, dest.latitude);
    final minLon = math.min(user.longitude, dest.longitude);
    final maxLon = math.max(user.longitude, dest.longitude);

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.02, minLon - 0.02),
      northeast: LatLng(maxLat + 0.02, maxLon + 0.02),
    );
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location', style: theme.textTheme.titleLarge),
          SizedBox(height: 2.h),

          Container(
            height: 25.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(3.w),
              border: Border.all(color: theme.dividerColor, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3.w),
              child: Stack(
                children: [
                  // Interactive Google Map
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _destination,
                      zoom: 14,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: _hasPermission,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      // Fit after controller is ready (location may already
                      // be fetched at this point)
                      _fitCamera();
                    },
                  ),

                  // Loading indicator while fetching location
                  if (_locationLoading)
                    Positioned(
                      top: 1.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.9,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Getting your location…',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Distance badge (shown once user location is known)
                  if (_userLocation != null)
                    Positioned(
                      top: 1.h,
                      left: 3.w,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.92,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.near_me,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _distanceLabel(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Navigate button
                  Positioned(
                    bottom: 2.h,
                    right: 3.w,
                    child: ElevatedButton.icon(
                      onPressed: onNavigate,
                      icon: CustomIconWidget(
                        iconName: 'directions',
                        color: theme.colorScheme.onPrimary,
                        size: 5.w,
                      ),
                      label: const Text('Navigate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.5.h,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback get onNavigate => widget.onNavigate;

  String _distanceLabel() {
    final user = _userLocation;
    if (user == null) return '';
    final km = _haversineKm(
      user.latitude,
      user.longitude,
      widget.latitude,
      widget.longitude,
    );
    return km < 1
        ? '${(km * 1000).toStringAsFixed(0)} m away'
        : '${km.toStringAsFixed(1)} km away';
  }

  double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _rad(double deg) => deg * (math.pi / 180);
}
