import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../data/services/api_service.dart';
import './widgets/destination_bottom_sheet_widget.dart';
import './widgets/destination_marker_widget.dart';
import './widgets/map_filter_widget.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  static const LatLng _defaultSriLankaCenter = LatLng(7.8731, 80.7718);
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _hasLocationPermission = false;
  bool _isLoading = true;
  String _selectedCategory = 'All';
  double _selectedRadiusKm = 20.0;
  Map<String, dynamic>? _selectedDestination;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isSearchingPlaces = false;
  List<Map<String, dynamic>> _searchSuggestions = [];
  List<Map<String, dynamic>> _apiSearchPlaces = [];
  LatLng? _searchCenter;
  bool _showListView = false;
  final List<Map<String, dynamic>> _tripCart = [];
  final List<double> _radiusOptionsKm = [1, 3, 5, 10, 15, 20, 30, 40, 50, 60];

  // Prevents the initial "pan to my location" from firing more than once
  bool _didInitialLocationPan = false;

  // Radius circle overlay
  Set<Circle> _circles = {};
  bool _showRadiusCircle = false;

  // Geocoded pin for locations not in DB
  Map<String, dynamic>? _geocodedPin;

  // Place cards strip at bottom of map
  late final PageController _placeCardPageController;

  // Mock destination data with geographic coordinates
  final List<Map<String, dynamic>> _destinations = [
    {
      "id": 1,
      "name": "Ella",
      "category": "Mountains",
      "latitude": 6.8667,
      "longitude": 81.0467,
      "googleUrl": "https://images.unsplash.com/photo-1620744577685-8fac0be42e44",
      "semanticLabel":
          "Scenic mountain view of Ella with lush green tea plantations and misty peaks",
      "description":
          "Picturesque hill country town famous for Nine Arch Bridge and stunning mountain views",
      "rating": 4.8,
      "reviews": 2847,
    },
    {
      "id": 2,
      "name": "Kandy",
      "category": "Temples",
      "latitude": 7.2906,
      "longitude": 80.6337,
      "googleUrl":
          "https://img.rocket.new/generatedImages/rocket_gen_img_193f33a5e-1766335454247.png",
      "semanticLabel":
          "Sacred Temple of the Tooth Relic in Kandy with traditional Sri Lankan architecture",
      "description":
          "Cultural capital home to the sacred Temple of the Tooth Relic and beautiful lake",
      "rating": 4.7,
      "reviews": 3521,
    },
    {
      "id": 3,
      "name": "Jaffna",
      "category": "Temples",
      "latitude": 9.6615,
      "longitude": 80.0255,
      "googleUrl":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1b20076d0-1768674030531.png",
      "semanticLabel":
          "Historic Jaffna Fort with ancient stone walls overlooking the northern coastline",
      "description":
          "Northern peninsula known for unique Tamil culture, historic fort and pristine beaches",
      "rating": 4.6,
      "reviews": 1893,
    },
    {
      "id": 4,
      "name": "Mirissa Beach",
      "category": "Beach Side",
      "latitude": 5.9467,
      "longitude": 80.4589,
      "googleUrl": "https://images.unsplash.com/photo-1585723816185-2b158d4d5a34",
      "semanticLabel":
          "Golden sandy beach at Mirissa with turquoise waters and palm trees swaying in breeze",
      "description":
          "Stunning southern beach perfect for whale watching, surfing and tropical sunsets",
      "rating": 4.9,
      "reviews": 4156,
    },
    {
      "id": 5,
      "name": "Yala National Park",
      "category": "Camping",
      "latitude": 6.3725,
      "longitude": 81.5185,
      "googleUrl": "https://images.unsplash.com/photo-1420639246026-982a997b3abf",
      "semanticLabel":
          "Wild leopard resting on rocky outcrop in Yala National Park surrounded by dry forest",
      "description":
          "Premier wildlife sanctuary with highest leopard density and diverse ecosystems",
      "rating": 4.8,
      "reviews": 2934,
    },
    {
      "id": 6,
      "name": "Unawatuna",
      "category": "Beach Side",
      "latitude": 6.0094,
      "longitude": 80.2506,
      "googleUrl": "https://images.unsplash.com/photo-1662319173895-a2c67d4d5a34",
      "semanticLabel":
          "Crescent-shaped Unawatuna beach with clear blue waters and coral reef visible underwater",
      "description":
          "Crescent-shaped bay with coral reef, perfect for snorkeling and beach relaxation",
      "rating": 4.7,
      "reviews": 3687,
    },
    {
      "id": 7,
      "name": "Horton Plains",
      "category": "Mountains",
      "latitude": 6.8103,
      "longitude": 80.7981,
      "googleUrl":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1e356b9db-1766848581776.png",
      "semanticLabel":
          "Dramatic cliff edge at World's End viewpoint in Horton Plains with clouds below",
      "description":
          "High-altitude plateau featuring World's End cliff and unique cloud forest ecosystem",
      "rating": 4.9,
      "reviews": 2156,
    },
    {
      "id": 8,
      "name": "Wilpattu National Park",
      "category": "Camping",
      "latitude": 8.4381,
      "longitude": 80.0255,
      "googleUrl":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1d28e9dd5-1767182645659.png",
      "semanticLabel":
          "Elephant herd walking through grasslands in Wilpattu National Park at golden hour",
      "description":
          "Largest national park known for natural lakes and diverse wildlife including leopards",
      "rating": 4.7,
      "reviews": 1745,
    },
    {
      "id": 9,
      "name": "Sinharaja Forest Reserve",
      "category": "Camping",
      "latitude": 6.4040,
      "longitude": 80.4581,
      "googleUrl": "https://images.unsplash.com/photo-1448375240586-882707db888b",
      "semanticLabel":
          "Dense tropical rainforest canopy in Sinharaja Forest Reserve with rich biodiversity",
      "description":
          "UNESCO rainforest reserve with rare endemic birds, reptiles and guided jungle trails",
      "rating": 4.8,
      "reviews": 2260,
    },
    {
      "id": 10,
      "name": "Kumana National Park",
      "category": "Camping",
      "latitude": 6.5314,
      "longitude": 81.6666,
      "googleUrl": "https://images.unsplash.com/photo-1474511320723-9a56873867b5",
      "semanticLabel":
          "Wetlands and wild birds in Kumana National Park during golden hour",
      "description":
          "Eastern wildlife sanctuary known for bird migration, wetlands and safari routes",
      "rating": 4.7,
      "reviews": 1480,
    },
  ];

  @override
  void initState() {
    super.initState();
    _placeCardPageController = PageController(viewportFraction: 0.88);
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    _placeCardPageController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      await _loadPlacesFromBackend();
      await _getCurrentLocation();
      await _createMarkers();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPlacesFromBackend() async {
    try {
      var rows = await ApiService.fetchPlaces();
      if (rows.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        rows = await ApiService.fetchPlaces();
      }
      final mapped = rows
          .whereType<Map>()
          .toList()
          .asMap()
          .entries
          .map(
            (entry) => _mapPlaceRow(
              Map<String, dynamic>.from(entry.value),
              entry.key,
            ),
          )
          .whereType<Map<String, dynamic>>()
          .toList();
      if (mapped.isNotEmpty && mounted) {
        setState(() {
          _destinations
            ..clear()
            ..addAll(mapped);
          if (_selectedCategory != 'All' && !_availableCategories.contains(_selectedCategory)) {
            _selectedCategory = 'All';
          }
        });
      }
    } catch (_) {
      // Keep bundled fallback places if backend is unavailable.
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _hasLocationPermission = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _hasLocationPermission = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _hasLocationPermission = false);
        return;
      }

      setState(() => _hasLocationPermission = true);

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() => _currentPosition = position);
      _panToCurrentLocationOnce();
    } catch (e) {
      if (mounted) {
        setState(() => _hasLocationPermission = false);
      }
    }
  }

  void _panToCurrentLocationOnce() {
    if (_didInitialLocationPan) return;
    if (_currentPosition == null || _mapController == null) return;
    _didInitialLocationPan = true;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        13.0,
      ),
    );
  }

  Future<void> _createMarkers() async {
    final filteredDestinations = _filteredDestinations;
    final displayPositions = _buildDisplayPositions(filteredDestinations);

    _markers.clear();

    for (var destination in filteredDestinations) {
      final displayPosition = displayPositions[destination['id'].toString()] ??
          LatLng(
            destination['latitude'] as double,
            destination['longitude'] as double,
          );
      final marker = Marker(
        markerId: MarkerId(destination['id'].toString()),
        position: displayPosition,
        icon: await _getMarkerIcon(destination['category'] as String),
        onTap: () => _onMarkerTapped(destination),
        infoWindow: InfoWindow(
          title: destination['name'] as String,
          snippet: destination['category'] as String,
        ),
      );
      _markers.add(marker);
    }

    setState(() {});
  }

  Map<String, LatLng> _buildDisplayPositions(
    List<Map<String, dynamic>> places,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final place in places) {
      final latitude = place['latitude'] as double;
      final longitude = place['longitude'] as double;
      final bucket =
          '${latitude.toStringAsFixed(2)}:${longitude.toStringAsFixed(2)}';
      grouped.putIfAbsent(bucket, () => []).add(place);
    }

    final positions = <String, LatLng>{};
    for (final group in grouped.values) {
      if (group.length == 1) {
        final place = group.first;
        positions[place['id'].toString()] = LatLng(
          place['latitude'] as double,
          place['longitude'] as double,
        );
        continue;
      }

      for (var i = 0; i < group.length; i++) {
        final place = group[i];
        positions[place['id'].toString()] = _spreadMarkerPosition(
          latitude: place['latitude'] as double,
          longitude: place['longitude'] as double,
          index: i,
        );
      }
    }

    return positions;
  }

  LatLng _spreadMarkerPosition({
    required double latitude,
    required double longitude,
    required int index,
  }) {
    if (index == 0) {
      return LatLng(latitude, longitude);
    }

    const slotsPerRing = 8;
    const baseRadiusKm = 1.4;
    const ringStepKm = 0.9;
    final ring = ((index - 1) ~/ slotsPerRing) + 1;
    final positionInRing = (index - 1) % slotsPerRing;
    final angle = (2 * math.pi * positionInRing) / slotsPerRing;
    final radiusKm = baseRadiusKm + ((ring - 1) * ringStepKm);
    final latOffset = (radiusKm / 111.32) * math.sin(angle);
    final lonScale = math.cos(_toRadians(latitude)).abs().clamp(0.2, 1.0);
    final lonOffset = (radiusKm / (111.32 * lonScale)) * math.cos(angle);

    return LatLng(latitude + latOffset, longitude + lonOffset);
  }

  Map<String, dynamic>? _mapPlaceRow(Map<String, dynamic> row, int index) {
    final parsedCoords = _parseCoordinates(row['coordinates']);
    final latitude =
        _toDouble(row['latitude'] ?? row['lat']) ?? parsedCoords.$1;
    final longitude =
        _toDouble(row['longitude'] ?? row['lng'] ?? row['lon']) ??
        parsedCoords.$2;

    if (latitude == null || longitude == null) {
      return null;
    }

    final name = (row['name'] ?? row['address'] ?? 'Unknown Place').toString();
    final category = _mapCategory(
      row['primary_category'] ?? row['category'],
      row['categories'] ?? row['types'],
    );
    final googleUrl = _extractGoogleUrl(row);
    final imageUrl = _extractImageUrl(row);
    final idValue = row['place_id'] ?? row['id'] ?? '${name}_$index';

    return {
      'id': idValue,
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'googleUrl': googleUrl,
      'imageUrl': imageUrl,
      'imageSource': row['image_source'],
      'photoPublicUrls': _asStringList(row['photo_public_urls']),
      'image': imageUrl,
      'semanticLabel': 'Photo of $name',
      'description': (row['description'] ??
              row['address'] ??
              row['location'] ??
              'No description available.')
          .toString(),
      'rating': _toDouble(row['avg_rating'] ?? row['rating']) ?? 0.0,
      'reviews':
          row['review_count'] is num ? (row['review_count'] as num).toInt() : 0,
      'location': (row['location'] ?? row['address'] ?? '').toString(),
      'seedArea': (row['seed_area'] ?? '').toString(),
      'seed_area': row['seed_area'],
      'google_url': row['google_url'],
      'image_url': row['image_url'],
    };
  }

  (double?, double?) _parseCoordinates(dynamic value) {
    if (value is String && value.contains(',')) {
      final parts = value.split(',');
      if (parts.length >= 2) {
        return (_toDouble(parts[0]), _toDouble(parts[1]));
      }
    }
    if (value is Map) {
      return (_toDouble(value['lat']), _toDouble(value['lng']));
    }
    return (null, null);
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  String _mapCategory(dynamic rawCategory, dynamic rawTypes) {
    final rawAsString = (rawCategory ?? '').toString().trim();
    final rawAsCode = rawCategory is num
        ? rawCategory.toInt()
        : int.tryParse(rawAsString);

    if (rawAsCode != null) {
      switch (rawAsCode) {
        case 1:
          return 'Beach Side';
        case 2:
          return 'Mountains';
        case 3:
          return 'Temples';
        case 4:
          return 'Camping';
        default:
          return 'Other';
      }
    }

    final rawCategoryText = (rawCategory ?? '').toString().trim();
    final categoryText = rawCategoryText.toLowerCase();
    final typesText = (rawTypes ?? '').toString().toLowerCase();
    final combined = '$categoryText $typesText';

    if (combined.contains('historical') ||
        combined.contains('heritage') ||
        combined.contains('museum') ||
        combined.contains('fort') ||
        combined.contains('ruins')) {
      return 'Historical Sites';
    }

    if (combined.contains('beach') ||
        combined.contains('coast') ||
        combined.contains('sea')) {
      return 'Beach Side';
    }
    if (combined.contains('mountain') ||
        combined.contains('hill') ||
        combined.contains('peak')) {
      return 'Mountains';
    }
    if (combined.contains('temple') ||
        combined.contains('shrine') ||
        combined.contains('church') ||
        combined.contains('mosque')) {
      return 'Temples';
    }
    if (combined.contains('camp') ||
        combined.contains('park') ||
        combined.contains('wildlife')) {
      return 'Camping';
    }

    return rawCategoryText.isNotEmpty ? rawCategoryText : 'Other';
  }

  List<Map<String, dynamic>> _localSuggestions(String query, {int limit = 8}) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    final scored = _destinations.map((d) {
      final name = (d['name'] as String).toLowerCase();
      final category = (d['category'] as String).toLowerCase();
      final desc = (d['description'] as String).toLowerCase();
      double score = 0;
      if (name == q) score += 5;
      if (name.startsWith(q)) score += 3;
      if (name.contains(q)) score += 2;
      if (category.contains(q)) score += 1.2;
      if (desc.contains(q)) score += 0.8;
      return {'score': score, 'item': d};
    }).toList();

    scored.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );
    return scored
        .where((row) => (row['score'] as double) > 0)
        .take(limit)
        .map(
          (row) =>
              Map<String, dynamic>.from(row['item'] as Map<String, dynamic>),
        )
        .toList();
  }

  bool _isLikelySriLanka(double lat, double lon) {
    return lat >= 5.5 && lat <= 10.1 && lon >= 79.4 && lon <= 82.1;
  }

  List<Map<String, dynamic>> _rankSearchResults(
    List<Map<String, dynamic>> items,
    String query,
  ) {
    final q = query.toLowerCase().trim();
    final ranked = items.map((item) {
      final name = (item['name'] as String? ?? '').toLowerCase();
      final location = (item['location'] as String? ?? '').toLowerCase();
      final lat = (item['latitude'] as num?)?.toDouble();
      final lon = (item['longitude'] as num?)?.toDouble();
      double score = 0;

      if (name == q) {
        score += 6;
      }
      if (name.startsWith(q)) {
        score += 4;
      }
      if (name.contains(q)) {
        score += 2.5;
      }
      if (location.contains('sri lanka')) {
        score += 3.5;
      }
      if (lat != null && lon != null && _isLikelySriLanka(lat, lon)) {
        score += 3.5;
      }

      final centerLat = _activeCenterLat;
      final centerLon = _activeCenterLon;
      if (centerLat != null &&
          centerLon != null &&
          lat != null &&
          lon != null) {
        final d = _haversineKm(centerLat, centerLon, lat, lon);
        if (d <= 30) {
          score += 2.5;
        } else if (d <= 100) {
          score += 1.5;
        } else if (d <= 200) {
          score += 0.8;
        }
      }
      return {'score': score, 'item': item};
    }).toList();

    ranked.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );
    return ranked.map((row) => row['item'] as Map<String, dynamic>).toList();
  }

  Future<BitmapDescriptor> _getMarkerIcon(String category) async {
    final value = category.toLowerCase().trim();

    if (value.contains('beach') || value.contains('coast')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
    if (value.contains('mount') ||
        value.contains('hill') ||
        value.contains('hiking')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    if (value.contains('temple') ||
        value.contains('church') ||
        value.contains('mosque') ||
        value.contains('sacred')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
    if (value.contains('camp') ||
        value.contains('wildlife') ||
        value.contains('park') ||
        value.contains('forest')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    }
    if (value.contains('histor') ||
        value.contains('ancient') ||
        value.contains('heritage') ||
        value.contains('museum') ||
        value.contains('fort') ||
        value.contains('ruin')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
    if (value.contains('restaurant') ||
        value.contains('cafe') ||
        value.contains('food')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
    }

    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  String? _extractGoogleUrl(Map<String, dynamic> row) {
    final rawValue = (row['googleUrl'] ?? row['google_url']).toString().trim();
    if (rawValue.isEmpty) {
      return null;
    }
    if (rawValue.startsWith('http://') || rawValue.startsWith('https://')) {
      return rawValue;
    }
    return null;
  }

  String? _extractImageUrl(Map<String, dynamic> row) {
    final rawValue = (row['imageUrl'] ?? row['image_url']).toString().trim();
    if (rawValue.isEmpty) {
      return null;
    }
    if (rawValue.startsWith('http://') || rawValue.startsWith('https://')) {
      return rawValue;
    }
    return null;
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return const [];
      }
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        final body = trimmed.substring(1, trimmed.length - 1);
        return body
            .split(',')
            .map((item) => item.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((item) => item.isNotEmpty)
            .toList();
      }
      return [trimmed];
    }

    return const [];
  }

  void _onMarkerTapped(Map<String, dynamic> destination) {
    setState(() => _selectedDestination = destination);
    _showDestinationBottomSheet();
  }

  void _showDestinationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DestinationBottomSheetWidget(
        destination: _selectedDestination!,
        onViewDetails: () {
          Navigator.pop(context);
          Navigator.of(context, rootNavigator: true).pushNamed(
            '/destination-detail-screen',
            arguments: {
              'destination': _selectedDestination,
              'allDestinations': _destinations,
            },
          );
        },
        onAddToPlaylist: () {
          Navigator.pop(context);
          _showAddToPlaylistDialog();
        },
      ),
    );
  }

  void _showAddToPlaylistDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add to Trip Cart', style: theme.textTheme.titleLarge),
        content: Text(
          'Add ${_selectedDestination!['name']} to your trip cart?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addSelectedDestinationToTripCart();
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addSelectedDestinationToTripCart() {
    final destination = _selectedDestination;
    if (destination == null) return;

    final alreadyAdded = _tripCart.any(
      (item) => item['id'] == destination['id'],
    );
    if (!alreadyAdded) {
      setState(() {
        _tripCart.add(Map<String, dynamic>.from(destination));
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alreadyAdded
              ? '${destination['name']} is already in your trip cart'
              : '${destination['name']} added to trip cart',
        ),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Route',
          onPressed: _openRoutePlannerScreen,
        ),
      ),
    );
  }

  Future<void> _openRoutePlannerScreen() async {
    if (_tripCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add places first to view optimized route'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final result = await Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.routePlanner,
      arguments: {
        'destinations': _tripCart,
        'origin': _currentPosition != null
            ? {
                'latitude': _currentPosition!.latitude,
                'longitude': _currentPosition!.longitude,
              }
            : null,
      },
    );

    if (result is List) {
      setState(() {
        _tripCart
          ..clear()
          ..addAll(
            result.whereType<Map>().map(
              (item) => Map<String, dynamic>.from(item),
            ),
          );
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    _createMarkers();
  }

  void _centerOnCurrentLocation() async {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          12.0,
        ),
      );
    } else {
      await _getCurrentLocation();
      if (_currentPosition != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            12.0,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        if (!mounted) return;
        setState(() {
          _searchSuggestions = [];
          _apiSearchPlaces = [];
          _searchCenter = null;
        });
        await _createMarkers();
        return;
      }

      await _fetchSearchSuggestions(trimmed);
      await _createMarkers();
    });
  }

  Future<void> _fetchSearchSuggestions(String query) async {
    try {
      if (!mounted) return;
      setState(() => _isSearchingPlaces = true);

      final local = _localSuggestions(query, limit: 8);

      final results = await ApiService.searchPlacesFromDb(
        query: query,
        latitude: null,
        longitude: null,
        radiusKm: 500,
        limit: 12,
      );

      final mapped = results
          .whereType<Map>()
          .map((item) => _mapPlaceRow(Map<String, dynamic>.from(item), 0))
          .whereType<Map<String, dynamic>>()
          .where(
            (item) =>
                (item['latitude'] as double) != 0.0 ||
                (item['longitude'] as double) != 0.0,
          )
          .toList();
      final merged = <Map<String, dynamic>>[...local, ...mapped];
      final dedup = <String, Map<String, dynamic>>{};
      for (final item in merged) {
        final key =
            ((item['name'] as String? ?? '') +
                    (item['location'] as String? ?? ''))
                .toLowerCase()
                .trim();
        if (key.isEmpty) continue;
        dedup[key] = item;
      }
      final ranked = _rankSearchResults(
        dedup.values.toList(),
        query,
      ).take(8).toList();

      if (!mounted) return;
      setState(() {
        _searchSuggestions = ranked;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchSuggestions = _localSuggestions(query, limit: 8);
      });
    } finally {
      if (mounted) {
        setState(() => _isSearchingPlaces = false);
      }
    }
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _apiSearchPlaces = [];
        _searchCenter = null;
        _searchSuggestions = [];
        _geocodedPin = null;
        _circles = {};
        _showRadiusCircle = false;
      });
      await _createMarkers();
      return;
    }
    try {
      if (!mounted) return;
      setState(() => _isSearchingPlaces = true);

      final local = _localSuggestions(query, limit: 20);

      final places = await ApiService.searchPlacesFromDb(
        query: query,
        latitude: null,
        longitude: null,
        radiusKm: 500,
        limit: 100,
      );
      final mapped = places
          .whereType<Map>()
          .map((item) => _mapPlaceRow(Map<String, dynamic>.from(item), 0))
          .whereType<Map<String, dynamic>>()
          .toList();
      final merged = <Map<String, dynamic>>[...local, ...mapped];
      final dedup = <String, Map<String, dynamic>>{};
      for (final item in merged) {
        final key =
            ((item['name'] as String? ?? '') +
                    (item['location'] as String? ?? ''))
                .toLowerCase()
                .trim();
        if (key.isEmpty) continue;
        dedup[key] = item;
      }
      final ranked = _rankSearchResults(dedup.values.toList(), query);

      if (!mounted) return;
      setState(() {
        _apiSearchPlaces = ranked;
        _searchSuggestions = [];
        _geocodedPin = null;
      });
      await _createMarkers();

      if (ranked.isNotEmpty && _mapController != null) {
        final first = ranked.first;
        final lat = first['latitude'] as double;
        final lon = first['longitude'] as double;
        setState(() => _searchCenter = LatLng(lat, lon));
        if (_showRadiusCircle) _updateRadiusCircle();
        // Fit camera to show ALL result markers, not just the first one
        final visiblePoints = _filteredDestinations
            .map((p) => LatLng(
                  (p['latitude'] as num).toDouble(),
                  (p['longitude'] as num).toDouble(),
                ))
            .toList();
        await _fitMapToMarkers(
          visiblePoints.isNotEmpty ? visiblePoints : [LatLng(lat, lon)],
        );
      } else {
        // No DB results — geocode and drop a pin on the map
        final geo = await ApiService.geocodePlace(query);
        if (geo != null && mounted) {
          final lat = geo['latitude'] as double;
          final lon = geo['longitude'] as double;
          final pinCenter = LatLng(lat, lon);
          final pinMarker = Marker(
            markerId: const MarkerId('__geocoded__'),
            position: pinCenter,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueCyan,
            ),
            infoWindow: InfoWindow(
              title: geo['name'] as String,
              snippet: (geo['address'] as String?)?.isNotEmpty == true
                  ? geo['address'] as String
                  : null,
            ),
          );
          setState(() {
            _geocodedPin = geo;
            _searchCenter = pinCenter;
            _markers.add(pinMarker);
          });
          if (_showRadiusCircle) _updateRadiusCircle();
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              pinCenter,
              _zoomForRadius(_selectedRadiusKm),
            ),
          );
        }
      }
    } catch (_) {
      final local = _localSuggestions(query, limit: 20);
      if (mounted && local.isNotEmpty) {
        setState(() {
          _apiSearchPlaces = local;
          _searchSuggestions = [];
        });
        await _createMarkers();
        if (_mapController != null) {
          final first = local.first;
          final lat = first['latitude'] as double;
          final lon = first['longitude'] as double;
          setState(() => _searchCenter = LatLng(lat, lon));
          if (_showRadiusCircle) _updateRadiusCircle();
          final pts = local
              .map((p) => LatLng(
                    (p['latitude'] as num).toDouble(),
                    (p['longitude'] as num).toDouble(),
                  ))
              .toList();
          await _fitMapToMarkers(pts);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingPlaces = false);
      }
    }
  }

  void _onSuggestionTap(Map<String, dynamic> destination) {
    _searchController.text = destination['name'] as String;
    setState(() {
      _searchSuggestions = [];
      _apiSearchPlaces = [destination];
      _searchCenter = LatLng(
        destination['latitude'] as double,
        destination['longitude'] as double,
      );
    });
    _runSearch();
  }

  void _onRadiusSelected(double radiusKm) {
    setState(() {
      _selectedRadiusKm = radiusKm;
      _showRadiusCircle = true;
    });
    _updateRadiusCircle();
    _createMarkers().then((_) {
      // Fit camera to show all places that are now visible within the radius
      final pts = _filteredDestinations
          .map((p) => LatLng(
                (p['latitude'] as num).toDouble(),
                (p['longitude'] as num).toDouble(),
              ))
          .toList();
      if (pts.isNotEmpty) {
        _fitMapToMarkers(pts);
      } else {
        final center =
            _searchCenter ??
            (_currentPosition != null
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : null);
        if (center != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(center, _zoomForRadius(radiusKm)),
          );
        }
      }
    });
  }

  double _zoomForRadius(double radiusKm) {
    if (radiusKm <= 1) return 14.5;
    if (radiusKm <= 3) return 13.5;
    if (radiusKm <= 5) return 12.8;
    if (radiusKm <= 10) return 12.0;
    if (radiusKm <= 20) return 11.0;
    if (radiusKm <= 30) return 10.4;
    if (radiusKm <= 40) return 10.0;
    if (radiusKm <= 50) return 9.6;
    return 9.2;
  }

  /// Animate the camera to show all given [points] with padding.
  /// Falls back to a single zoom if only one point is given.
  Future<void> _fitMapToMarkers(List<LatLng> points) async {
    if (points.isEmpty || _mapController == null) return;
    if (points.length == 1) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, _zoomForRadius(_selectedRadiusKm)),
      );
      return;
    }
    final lats = points.map((p) => p.latitude).toList();
    final lons = points.map((p) => p.longitude).toList();
    final minLat = lats.reduce(math.min);
    final maxLat = lats.reduce(math.max);
    final minLon = lons.reduce(math.min);
    final maxLon = lons.reduce(math.max);
    // Add a small padding around bounds so pins aren't right on the edge
    const pad = 0.05;
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - pad, minLon - pad),
      northeast: LatLng(maxLat + pad, maxLon + pad),
    );
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 72.0),
    );
  }

  void _updateRadiusCircle() {
    final center =
        _searchCenter ??
        (_currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : null);
    if (center == null) return;
    final theme = Theme.of(context);
    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId('radius'),
          center: center,
          radius: _selectedRadiusKm * 1000,
          strokeColor: theme.colorScheme.primary,
          strokeWidth: 2,
          fillColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
      };
    });
  }

  List<Map<String, dynamic>> _applyRadiusFilter(
    List<Map<String, dynamic>> places,
  ) {
    if (_searchCenter == null) {
      return places;
    }
    final centerLat = _activeCenterLat;
    final centerLon = _activeCenterLon;
    if (centerLat == null || centerLon == null) {
      return places;
    }
    return places.where((place) {
      final lat = place['latitude'] as double;
      final lon = place['longitude'] as double;
      final distance = _haversineKm(centerLat, centerLon, lat, lon);
      return distance <= _selectedRadiusKm;
    }).toList();
  }

  double? get _activeCenterLat =>
      _searchCenter?.latitude ?? _currentPosition?.latitude;

  double? get _activeCenterLon =>
      _searchCenter?.longitude ?? _currentPosition?.longitude;

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRadians(double value) => value * (math.pi / 180.0);

  List<Map<String, dynamic>> get _filteredDestinations {
    final source =
        _apiSearchPlaces.isNotEmpty && _searchController.text.trim().isNotEmpty
        ? _apiSearchPlaces
        : _destinations;
    final categoryFiltered = _selectedCategory == 'All'
        ? source
        : source.where((d) => d['category'] == _selectedCategory).toList();
    final radiusFiltered = _applyRadiusFilter(categoryFiltered);

    if (_searchController.text.isEmpty) return radiusFiltered;

    return radiusFiltered
        .where(
          (d) =>
              (d['name'] as String).toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
              (d['category'] as String).toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
              ((d['description'] as String?) ?? '').toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ),
        )
        .toList();
  }

  List<String> get _availableCategories {
    final set = <String>{'All'};
    for (final item in _destinations) {
      final value = (item['category'] as String?)?.trim() ?? '';
      if (value.isNotEmpty) {
        set.add(value);
      }
    }
    final categories = set.toList();
    categories.sort((a, b) {
      if (a == 'All') return -1;
      if (b == 'All') return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search bar overlay
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow,
                blurRadius: 4.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onSubmitted: (_) => _runSearch(),
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Search destinations...',
                            hintStyle: theme.inputDecorationTheme.hintStyle,
                            prefixIcon: CustomIconWidget(
                              iconName: 'search',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: CustomIconWidget(
                                      iconName: 'clear',
                                      color: theme.colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchSuggestions = [];
                                        _apiSearchPlaces = [];
                                        _searchCenter = null;
                                      });
                                      _createMarkers();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 1.5.h,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Container(
                      height: 6.h,
                      width: 6.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: IconButton(
                        tooltip: 'Search',
                        icon: CustomIconWidget(
                          iconName: 'search',
                          color: theme.colorScheme.onPrimary,
                          size: 22,
                        ),
                        onPressed: () => _runSearch(),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Container(
                      height: 6.h,
                      width: 6.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: IconButton(
                        tooltip: 'Trip cart',
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CustomIconWidget(
                              iconName: 'shopping_cart',
                              color: theme.colorScheme.onPrimary,
                              size: 22,
                            ),
                            if (_tripCart.isNotEmpty)
                              Positioned(
                                right: -6,
                                top: -6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    '${_tripCart.length}',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onPressed: _openRoutePlannerScreen,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Container(
                      height: 6.h,
                      width: 6.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: IconButton(
                        tooltip: _showListView ? 'Show map' : 'Show list',
                        icon: CustomIconWidget(
                          iconName: _showListView ? 'map' : 'list',
                          color: theme.colorScheme.onPrimary,
                          size: 24,
                        ),
                        onPressed: () =>
                            setState(() => _showListView = !_showListView),
                      ),
                    ),
                  ],
                ),
                if (_isSearchingPlaces)
                  Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: theme.colorScheme.primary,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                if (_searchSuggestions.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 1.h),
                    constraints: BoxConstraints(maxHeight: 26.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchSuggestions.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: theme.dividerColor),
                      itemBuilder: (context, index) {
                        final item = _searchSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: CustomIconWidget(
                            iconName: 'place',
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                          title: Text(
                            item['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            item['location'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          onTap: () => _onSuggestionTap(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_searchSuggestions.isNotEmpty) SizedBox(height: 0.8.h),

        // Category filter
        MapFilterWidget(
          categories: _availableCategories,
          selectedCategory: _selectedCategory,
          onCategorySelected: _onCategorySelected,
        ),

        // Map or List view
        Expanded(child: _showListView ? _buildListView() : _buildMapView()),
      ],
    );
  }

  Widget _buildMapView() {
    final theme = Theme.of(context);
    final cards = _filteredDestinations;
    final hasCards = cards.isNotEmpty;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _defaultSriLankaCenter,
            zoom: 8.0,
          ),
          markers: _markers,
          circles: Set<Circle>.from(_circles),
          onMapCreated: (controller) {
            _mapController = controller;
            // If location was already fetched before the map finished
            // initialising, pan there now.
            _panToCurrentLocationOnce();
          },
          myLocationEnabled: _hasLocationPermission,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: true,
          zoomGesturesEnabled: true,
        ),

        // Place cards strip at bottom
        if (hasCards)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildPlaceCardsStrip(cards, theme),
          ),

        // Location + radius buttons (moved up when cards visible)
        Positioned(
          right: 4.w,
          bottom: hasCards ? 19.h : 4.h,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow,
                      blurRadius: 8.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _centerOnCurrentLocation,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      width: 12.w,
                      height: 12.w,
                      alignment: Alignment.center,
                      child: CustomIconWidget(
                        iconName: 'my_location',
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.2.h),
              PopupMenuButton<String>(
                tooltip: 'Radius',
                onSelected: (value) {
                  if (value == '__clear__') {
                    setState(() {
                      _showRadiusCircle = false;
                      _circles = {};
                    });
                  } else {
                    _onRadiusSelected(double.parse(value));
                  }
                },
                itemBuilder: (context) => [
                  ..._radiusOptionsKm.map(
                    (radius) => PopupMenuItem<String>(
                      value: radius.toString(),
                      child: Row(
                        children: [
                          if (_showRadiusCircle &&
                              _selectedRadiusKm == radius)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          if (!(_showRadiusCircle &&
                              _selectedRadiusKm == radius))
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text('${radius.toInt()} km'),
                        ],
                      ),
                    ),
                  ),
                  if (_showRadiusCircle)
                    const PopupMenuItem<String>(
                      value: '__clear__',
                      child: Row(
                        children: [
                          Icon(Icons.clear, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Clear radius',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                ],
                child: Container(
                  height: 5.4.h,
                  width: 12.w,
                  decoration: BoxDecoration(
                    color: _showRadiusCircle
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow,
                        blurRadius: 8.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _showRadiusCircle
                      ? Text(
                          '${_selectedRadiusKm.toInt()}km',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        )
                      : CustomIconWidget(
                          iconName: 'radar',
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceCardsStrip(
    List<Map<String, dynamic>> cards,
    ThemeData theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Count badge row
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 0.6.h),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${cards.length} place${cards.length == 1 ? '' : 's'} found',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 14.h,
          child: PageView.builder(
            controller: _placeCardPageController,
            itemCount: cards.length,
            onPageChanged: (index) {
              final place = cards[index];
              final lat = (place['latitude'] as num).toDouble();
              final lon = (place['longitude'] as num).toDouble();
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(LatLng(lat, lon)),
              );
            },
            itemBuilder: (context, index) =>
                _buildSinglePlaceCard(cards[index], theme),
          ),
        ),
      ],
    );
  }

  Widget _buildSinglePlaceCard(
    Map<String, dynamic> place,
    ThemeData theme,
  ) {
    final name = (place['name'] as String?) ?? '';
    final category = (place['category'] as String?) ?? '';
    final rating = (place['rating'] as num?)?.toDouble() ?? 0.0;
    final googleUrl = place['googleUrl'] as String?;

    String distanceLabel = '';
    final centerLat = _activeCenterLat;
    final centerLon = _activeCenterLon;
    final placeLat = (place['latitude'] as num?)?.toDouble();
    final placeLon = (place['longitude'] as num?)?.toDouble();
    if (centerLat != null &&
        centerLon != null &&
        placeLat != null &&
        placeLon != null) {
      final d = _haversineKm(centerLat, centerLon, placeLat, placeLon);
      distanceLabel = d < 1
          ? '${(d * 1000).toInt()} m'
          : '${d.toStringAsFixed(1)} km';
    }

    return Container(
      margin: EdgeInsets.fromLTRB(2.w, 1.h, 2.w, 1.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onMarkerTapped(place),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                child: PlacePhotoWidget(
                  googleUrl: googleUrl,
                  width: 22.w,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  semanticLabel: name,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.2.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 0.3.h),
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 0.3.h),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 2),
                          Text(
                            rating > 0
                                ? rating.toStringAsFixed(1)
                                : 'N/A',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (distanceLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              distanceLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 3.w),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.8.h,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _selectedDestination = place);
                    _addSelectedDestinationToTripCart();
                  },
                  child: Text(
                    '+ Cart',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    final theme = Theme.of(context);
    final destinations = _filteredDestinations;

    if (destinations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: theme.colorScheme.onSurfaceVariant,
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              'No destinations found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: destinations.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final destination = destinations[index];
        return DestinationMarkerWidget(
          destination: destination,
          onTap: () {
            setState(() => _selectedDestination = destination);
            _showDestinationBottomSheet();
          },
        );
      },
    );
  }
}
