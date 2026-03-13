import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:lottie/lottie.dart';

// ✅ Model class for storing saved locations in the playlist
class SavedLocation {
  final String name;           // Name of the location
  final gmaps.LatLng position; // Latitude & Longitude
  final String description;    // Short description

  SavedLocation({
    required this.name,
    required this.position,
    required this.description,
  });
}

// Main Map Page Stateful Widget
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Initial camera position for the map (Nuwara Eliya)
  static const gmaps.LatLng _initialPos = gmaps.LatLng(6.9639, 80.7718);

  gmaps.GoogleMapController? _mapController; // Controller to control map camera
  final TextEditingController _searchController = TextEditingController(); // Controller for search input

  List<SavedLocation> _playlist = []; // User's saved locations
  Set<gmaps.Marker> _markers = {};    // Map markers for saved locations

  bool _isLoading = true;             // Loading overlay flag
  bool _showCartButton = false;       // Show "Add to Cart" button when a location is selected
  gmaps.LatLng? _selectedPos;         // Currently selected position
  String? _selectedName;              // Currently selected location name

  // Google API key for Places API
  final String _apiKey = "AIzaSyB6dQ9lJq0CQBaGzkJet_-Ua33hX4i_6_s";

  @override
  void initState() {
    super.initState();
    // Show a loading overlay for 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  // Called when a place is selected from search results
  void _onPlaceSelected(double lat, double lng, String name) {
    gmaps.LatLng dest = gmaps.LatLng(lat, lng);
    setState(() {
      _selectedPos = dest;
      _selectedName = name;
      _showCartButton = true; // Show "Add to Cart" button
    });

    // Animate the camera to selected location
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(target: dest, zoom: 15.5, tilt: 50, bearing: 30),
      ),
    );
  }

  // Add the selected location to the playlist
  void _addToCart() {
    if (_selectedName != null && _selectedPos != null) {
      setState(() {
        final id = "${_selectedName}_${DateTime.now().millisecondsSinceEpoch}";
        // Add to playlist
        _playlist.add(
          SavedLocation(
            name: _selectedName!,
            position: _selectedPos!,
            description: "Hidden Gem in Sri Lanka",
          ),
        );
        // Add a marker on the map
        _markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId(id),
            position: _selectedPos!,
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure),
            infoWindow: gmaps.InfoWindow(title: _selectedName),
          ),
        );
        _showCartButton = false; // Hide button after adding
      });

      // Show a confirmation SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Added $_selectedName to playlist"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1️⃣ Map Layer
          gmaps.GoogleMap(
            onMapCreated: (c) => _mapController = c,
            initialCameraPosition: const gmaps.CameraPosition(target: _initialPos, zoom: 13),
            markers: _markers,
            myLocationEnabled: true,           // Show user's current location
            onTap: (_) => setState(() => _showCartButton = false), // Hide cart button if map is tapped
          ),

          // 2️⃣ Search Box Layer
          Positioned(top: 50, left: 15, right: 15, child: _buildSearchBox()),

          // 3️⃣ Floating "Add to Cart" Button
          if (_showCartButton)
            Positioned(
              bottom: 140, left: 50, right: 50,
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: const Text(
                    "ADD TO CART",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.all(15),
                  shape: const StadiumBorder(),
                ),
              ),
            ),

          // 4️⃣ Draggable Playlist Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.15,
            minChildSize: 0.15,
            maxChildSize: 0.8,
            snap: true,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: ListView.builder(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _playlist.isEmpty ? 2 : _playlist.length + 1, // Handle empty state
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildHandle();      // Small handle bar
                    if (_playlist.isEmpty) return _buildEmptyState(); // Show empty message
                    return _buildPlaylistTile(index - 1);       // Playlist item
                  },
                ),
              );
            },
          ),

          // 5️⃣ Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Lottie.asset('assets/animations/map_loading.json', width: 200),
              ),
            ),
        ],
      ),
    );
  }

  // Empty playlist widget
  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.playlist_add_check_circle_outlined, size: 50, color: Colors.grey[300]),
        const SizedBox(height: 10),
        const Text(
          "Your playlist is empty",
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const Text(
          "Swipe up to see your trip plan",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  // Playlist tile for a saved location
  Widget _buildPlaylistTile(int i) {
    final item = _playlist[i];
    return ListTile(
      leading: const Icon(Icons.location_on, color: Colors.blueAccent),
      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        onPressed: () => setState(() {
          _markers.removeWhere((m) => m.position == item.position); // Remove marker
          _playlist.removeAt(i);                                     // Remove from playlist
        }),
      ),
      onTap: () => _mapController?.animateCamera(gmaps.CameraUpdate.newLatLng(item.position)), // Center map
    );
  }

  // Handle for draggable sheet
  Widget _buildHandle() => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );

  // ✅ Search box widget with Google Places Autocomplete
  Widget _buildSearchBox() {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: GooglePlaceAutoCompleteTextField(
          textEditingController: _searchController,
          googleAPIKey: _apiKey,
          inputDecoration: const InputDecoration(
            hintText: "Search gems in Sri Lanka...",
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
          ),
          countries: ["lk"],           // Limit results to Sri Lanka
          isLatLngRequired: true,      // Return lat/lng along with place
          debounceTime: 300,           // Wait 300ms between typing
          itemClick: (prediction) {
            FocusScope.of(context).unfocus(); // Close keyboard
            _searchController.text = prediction.description!;
            _onPlaceSelected(
              double.parse(prediction.lat!),
              double.parse(prediction.lng!),
              prediction.description!,
            );
          },
        ),
      ),
    );
  }
}