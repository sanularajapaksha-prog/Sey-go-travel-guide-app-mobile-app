import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
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
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String? _searchMatchedCategory;
  Map<String, dynamic>? _selectedDestination;
  final TextEditingController _searchController = TextEditingController();
  bool _showListView = false;
  final List<Map<String, dynamic>> _tripCart = [];

  // Mock destination data with geographic coordinates
  final List<Map<String, dynamic>> _destinations = [
    {
      "id": 1,
      "name": "Ella",
      "category": "Mountains",
      "latitude": 6.8667,
      "longitude": 81.0467,
      "image":
      "https://images.unsplash.com/photo-1620744577685-8fac0be42e44",
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
      "image":
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
      "image":
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
      "image":
      "https://images.unsplash.com/photo-1585723816185-2b158d4d5a34",
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
      "image":
      "https://images.unsplash.com/photo-1420639246026-982a997b3abf",
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
      "image":
      "https://images.unsplash.com/photo-1662319173895-a2c67d4f473c",
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
      "image":
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
      "image":
      "https://img.rocket.new/generatedImages/rocket_gen_img_1d28e9dd5-1767182645659.png",
      "semanticLabel":
      "Elephant herd walking through grasslands in Wilpattu National Park at golden hour",
      "description":
      "Largest national park known for natural lakes and diverse wildlife including leopards",
      "rating": 4.7,
      "reviews": 1745,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      await _loadDestinationsFromApi();
      await _getCurrentLocation();
      await _createMarkers();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() => _currentPosition = position);
    } catch (e) {
      // Silent fail - map will show default location
    }
  }

  Future<void> _createMarkers() async {
    final filteredDestinations = _selectedCategory == 'All'
        ? _destinations
        : _destinations
        .where((d) => d['category'] == _selectedCategory)
        .toList();

    _markers.clear();

    for (var destination in filteredDestinations) {
      final marker = Marker(
        markerId: MarkerId(destination['id'].toString()),
        position: LatLng(
          destination['latitude'] as double,
          destination['longitude'] as double,
        ),
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

  Future<void> _loadDestinationsFromApi() async {
    try {
      final rows = await ApiService.fetchPlaces();
      final mapped = rows
          .whereType<Map>()
          .toList()
          .asMap()
          .entries
          .map((entry) => _mapPlaceRow(Map<String, dynamic>.from(entry.value), entry.key))
          .whereType<Map<String, dynamic>>()
          .toList();

      if (mapped.isEmpty) {
        _showInfoSnack('No places returned from backend. Showing local sample data.');
        return;
      }

      _destinations
        ..clear()
        ..addAll(mapped);
      _showInfoSnack('Loaded ${mapped.length} places from backend.');
    } catch (error) {
      debugPrint('Failed to fetch backend places: $error');
      _showInfoSnack('Failed to load places from backend: $error');
    }
  }

  Map<String, dynamic>? _mapPlaceRow(Map<String, dynamic> row, int index) {
    final parsedCoords = _parseCoordinates(row['coordinates']);
    final latitude =
        _toDouble(row['latitude'] ?? row['lat']) ?? parsedCoords.$1;
    final longitude =
        _toDouble(row['longitude'] ?? row['lng']) ?? parsedCoords.$2;

    if (latitude == null || longitude == null) {
      return null;
    }

    final name = (row['name'] ?? row['address'] ?? 'Unknown Place').toString();
    final category = _mapCategory(
      row['primary_category'] ?? row['category'],
      row['categories'] ?? row['types'],
    );
    final imageUrl = _extractImageUrl(
      row,
      latitude: latitude,
      longitude: longitude,
    );
    final idValue = row['place_id'] ?? row['id'] ?? '${name}_$index';

    return {
      'id': idValue,
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'image': imageUrl ?? 'https://images.unsplash.com/photo-1501785888041-af3ef285b470',
      'semanticLabel': 'Photo of $name',
      'description': (row['description'] ?? row['address'] ?? row['location'] ?? 'No description available.').toString(),
      'rating': _toDouble(row['avg_rating'] ?? row['rating']) ?? 0.0,
      'reviews': (row['review_count'] is num) ? (row['review_count'] as num).toInt() : 0,
      'google_url': row['google_url'],
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

    // Preserve "historical" as a separate category instead of forcing to Temples.
    if (combined.contains('historical') ||
        combined.contains('heritage') ||
        combined.contains('museum') ||
        combined.contains('fort') ||
        combined.contains('ruins')) {
      return 'Historical Sites';
    }

    if (combined.contains('beach') || combined.contains('coast') || combined.contains('sea')) {
      return 'Beach Side';
    }
    if (combined.contains('mountain') || combined.contains('hill') || combined.contains('peak')) {
      return 'Mountains';
    }
    if (combined.contains('temple') || combined.contains('shrine') || combined.contains('church') || combined.contains('mosque')) {
      return 'Temples';
    }
    if (combined.contains('camp') || combined.contains('park') || combined.contains('wildlife')) {
      return 'Camping';
    }

    return rawCategoryText.isNotEmpty ? rawCategoryText : 'Other';
  }

  String? _extractImageUrl(
    Map<String, dynamic> row, {
    required double latitude,
    required double longitude,
  }) {
    final directGooglePhoto = _extractDirectGooglePhotoUrl(row);
    if (directGooglePhoto != null) {
      return directGooglePhoto;
    }

    final direct = row['image'] ?? row['photo_url'] ?? row['image_url'];
    if (direct is String &&
        direct.startsWith('http') &&
        !direct.contains('example.com') &&
        !_isGoogleMapPageUrl(direct)) {
      return direct;
    }

    final googleUrl = (row['google_url'] ?? '').toString().trim();
    if (googleUrl.isNotEmpty && _isGoogleMapPageUrl(googleUrl)) {
      return '${ApiService.baseUrl}/places/photo-from-google-url'
          '?url=${Uri.encodeComponent(googleUrl)}';
    }

    final placeId = (row['place_id'] ?? '').toString().trim();
    if (placeId.isNotEmpty) {
      return '${ApiService.baseUrl}/places/photo/$placeId';
    }

    final publicUrls = _asStringList(row['photo_public_urls']);
    if (publicUrls.isNotEmpty) {
      return publicUrls.first;
    }

    final paths = row['photo_storage_paths'];
    String? first;

    if (paths is List && paths.isNotEmpty && paths.first is String) {
      first = (paths.first as String).trim();
    } else if (paths is String && paths.trim().isNotEmpty) {
      first = paths.trim();
    }

    if (first == null || first.isEmpty || first.startsWith('ChI')) {
      return null;
    }

    if (first.startsWith('http')) {
      return first;
    }

    final supabaseUrl = (dotenv.env['SUPABASE_URL'] ?? '').trim();
    if (supabaseUrl.isEmpty || supabaseUrl.contains('your-project-ref')) {
      return null;
    }

    final normalizedPath = first.startsWith('/') ? first.substring(1) : first;
    return '$supabaseUrl/storage/v1/object/public/place-images/$normalizedPath';
  }

  String? _extractDirectGooglePhotoUrl(Map<String, dynamic> row) {
    final candidates = <String>[
      (row['google_url'] ?? '').toString().trim(),
      (row['image'] ?? '').toString().trim(),
      (row['photo_url'] ?? '').toString().trim(),
      (row['image_url'] ?? '').toString().trim(),
    ];

    final fromPublic = _asStringList(row['photo_public_urls']);
    candidates.addAll(fromPublic);

    for (final raw in candidates) {
      if (raw.isEmpty || !raw.startsWith('http')) continue;
      final uri = Uri.tryParse(raw);
      final host = uri?.host.toLowerCase() ?? '';
      if (host.endsWith('googleusercontent.com') ||
          host.contains('gstatic.com')) {
        return raw;
      }
    }
    return null;
  }

  bool _isGoogleMapPageUrl(String url) {
    final normalized = url.toLowerCase();
    return normalized.contains('maps.google.com') ||
        normalized.contains('google.com/maps');
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return const [];
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        final body = trimmed.substring(1, trimmed.length - 1).trim();
        if (body.isEmpty) return const [];
        return body
            .split(',')
            .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [trimmed];
    }
    return const [];
  }

  void _showInfoSnack(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    });
  }

  Future<BitmapDescriptor> _getMarkerIcon(String category) async {
    // Use default markers with different colors based on category
    switch (category) {
      case 'Beach Side':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      case 'Mountains':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'Temples':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case 'Camping':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        );
      default:
        return BitmapDescriptor.defaultMarker;
    }
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
            arguments: _selectedDestination,
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

    final alreadyAdded = _tripCart.any((item) => item['id'] == destination['id']);
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

    final result = await Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(
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
            result.whereType<Map>().map((item) => Map<String, dynamic>.from(item)),
          );
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _searchMatchedCategory = null;
      _selectedCategory = category;
    });
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
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      setState(() {
        _searchMatchedCategory = null;
        _selectedCategory = 'All';
      });
      _createMarkers();
      return;
    }

    final forcedCategory = _resolveCategoryFromQuery(normalized);
    if (forcedCategory != null) {
      final categoryPlaces = _destinations
          .where((d) => d['category'] == forcedCategory)
          .toList();
      setState(() {
        _searchMatchedCategory = forcedCategory;
        _selectedCategory = forcedCategory;
      });
      _createMarkers();
      if (categoryPlaces.isNotEmpty && _mapController != null) {
        final destination = categoryPlaces.first;
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              destination['latitude'] as double,
              destination['longitude'] as double,
            ),
            12.5,
          ),
        );
      }
      return;
    }

    final results = _destinations
        .where(
          (d) =>
      (d['name'] as String).toLowerCase().contains(
        normalized,
      ) ||
          (d['category'] as String).toLowerCase().contains(
            normalized,
          ),
    )
        .toList();

    if (results.isNotEmpty) {
      final destination = results.first;
      final matchedCategory = destination['category'] as String;
      setState(() {
        _searchMatchedCategory = matchedCategory;
        _selectedCategory = matchedCategory;
      });
      _createMarkers();
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              destination['latitude'] as double,
              destination['longitude'] as double,
            ),
            14.0,
          ),
        );
      }
      return;
    }

    setState(() {
      _searchMatchedCategory = null;
    });
  }

  String? _resolveCategoryFromQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;

    if (q == 'temple' || q == 'temples') return 'Temples';
    if (q == 'historical' ||
        q == 'history' ||
        q == 'heritage' ||
        q == 'historical sites') {
      return 'Historical Sites';
    }
    if (q == 'beach' || q == 'beaches' || q == 'beach side') {
      return 'Beach Side';
    }
    if (q == 'mountain' || q == 'mountains' || q == 'hiking') {
      return 'Mountains';
    }
    if (q == 'camping' || q == 'camp' || q == 'wildlife') return 'Camping';
    return null;
  }

  List<Map<String, dynamic>> get _filteredDestinations {
    final filtered = _selectedCategory == 'All'
        ? _destinations
        : _destinations
        .where((d) => d['category'] == _selectedCategory)
        .toList();

    // When search found a place/category, show all places in that category.
    if (_searchMatchedCategory != null) return filtered;

    if (_searchController.text.isEmpty) return filtered;

    return filtered
        .where(
          (d) =>
      (d['name'] as String).toLowerCase().contains(
        _searchController.text.toLowerCase(),
      ) ||
          (d['category'] as String).toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ),
    )
        .toList();
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
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: theme.dividerColor, width: 1.0),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
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
                              _searchMatchedCategory = null;
                              _selectedCategory = 'All';
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
          ),
        ),

        // Category filter
        MapFilterWidget(
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

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition != null
                ? LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            )
                : LatLng(7.8731, 80.7718), // Center of Sri Lanka
            zoom: 8.0,
          ),
          markers: _markers,
          onMapCreated: (controller) => _mapController = controller,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: true,
          zoomGesturesEnabled: true,
        ),

        // Current location button
        Positioned(
          right: 4.w,
          bottom: 4.h,
          child: Container(
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
        ),
      ],
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
