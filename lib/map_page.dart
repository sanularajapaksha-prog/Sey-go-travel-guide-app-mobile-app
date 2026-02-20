import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:lottie/lottie.dart';

// Ensure this model is defined as before
class SavedLocation {
  final String name;
  final gmaps.LatLng position;
  final String? imagePath; // Optional: for the list thumbnails

  SavedLocation({required this.name, required this.position, this.imagePath});
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const gmaps.LatLng _initialPos = gmaps.LatLng(6.9639, 80.7718);
  gmaps.GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  List<SavedLocation> _playlist = [];
  Set<gmaps.Marker> _markers = {};
  bool _isLoading = true;

  // Tracking active search for the FAB
  gmaps.LatLng? _currentSelectedPos;
  String? _currentSelectedName;
  bool _isPlaceSelected = false;

  final String _apiKey = "AIzaSyB6dQ9lJq0CQBaGzkJet_-Ua33hX4i_6_s";

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _onPlaceSelected(double lat, double lng, String name) {
    gmaps.LatLng destination = gmaps.LatLng(lat, lng);
    setState(() {
      _currentSelectedPos = destination;
      _currentSelectedName = name;
      _isPlaceSelected = true;
    });
    _mapController?.animateCamera(gmaps.CameraUpdate.newLatLngZoom(destination, 15));
  }

  void _addToPlaylist() {
    if (_currentSelectedName != null && _currentSelectedPos != null) {
      setState(() {
        _playlist.add(SavedLocation(name: _currentSelectedName!, position: _currentSelectedPos!));
        _markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId(_currentSelectedName!),
            position: _currentSelectedPos!,
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure),
          ),
        );
        _isPlaceSelected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Map
          gmaps.GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: const gmaps.CameraPosition(target: _initialPos, zoom: 13),
            myLocationEnabled: true,
            markers: _markers,
            onTap: (_) => setState(() => _isPlaceSelected = false),
          ),

          // 2. Search Bar at Top
          Positioned(top: 50, left: 15, right: 15, child: _buildSearchBox()),

          // 3. Floating "Add to Playlist" Button
          if (_isPlaceSelected)
            Positioned(
              bottom: 140, // Height adjusted for the collapsed sheet
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: _addToPlaylist,
                backgroundColor: const Color(0xFF0077B6),
                icon: const Icon(Icons.playlist_add, color: Colors.white),
                label: const Text("ADD TO PLAYLIST", style: TextStyle(color: Colors.white)),
              ),
            ),

          // 4. ✅ DRAGGABLE SCROLLABLE PLAYLIST (Like your screenshot)
          if (_playlist.isNotEmpty)
            DraggableScrollableSheet(
              initialChildSize: 0.15, // Partially visible
              minChildSize: 0.15,
              maxChildSize: 0.8,    // Full screen when pulled up
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _playlist.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildSheetHeader(); // The handle at the top
                      }
                      return _buildPlaylistTile(index - 1);
                    },
                  ),
                );
              },
            ),

          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
        const Padding(
          padding: EdgeInsets.all(15.0),
          child: Text("Your Seygo Playlist", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPlaylistTile(int index) {
    final item = _playlist[index];
    return ListTile(
      leading: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.image, color: Colors.grey), // Placeholder for image
      ),
      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text("Tap to view on map"),
      trailing: IconButton(
        icon: const Icon(Icons.close, color: Colors.redAccent),
        onPressed: () => setState(() {
          _markers.removeWhere((m) => m.markerId.value == item.name);
          _playlist.removeAt(index);
        }),
      ),
      onTap: () {
        _mapController?.animateCamera(gmaps.CameraUpdate.newLatLng(item.position));
      },
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: _searchController,
        googleAPIKey: _apiKey,
        inputDecoration: const InputDecoration(hintText: "Search gems...", border: InputBorder.none, prefixIcon: Icon(Icons.search)),
        countries: ["lk"],
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (p) => _onPlaceSelected(double.parse(p.lat!), double.parse(p.lng!), p.description!),
        itemClick: (p) => _searchController.text = p.description!,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(color: Colors.white, child: Center(child: Lottie.asset('assets/animations/map_loading.json', width: 200)));
  }
}