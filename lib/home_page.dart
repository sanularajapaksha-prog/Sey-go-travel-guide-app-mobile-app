import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:lottie/lottie.dart';

// ✅ The Data Model for your Saved Locations
class SavedLocation {
  final String name;
  final gmaps.LatLng position;
  final String description;

  SavedLocation({required this.name, required this.position, required this.description});
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const gmaps.LatLng _initialPos = gmaps.LatLng(6.9639, 80.7718); // Nuwara Eliya
  gmaps.GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  List<SavedLocation> _playlist = [];
  Set<gmaps.Marker> _markers = {};
  bool _isLoading = true; // Shows Lottie initially

  // Selection states for "Add to Cart"
  gmaps.LatLng? _selectedPos;
  String? _selectedName;
  bool _showActiveCard = false;

  final String _apiKey = "AIzaSyB6dQ9lJq0CQBaGzkJet_-Ua33hX4i_6_s";

  @override
  void initState() {
    super.initState();
    // Fast branding animation delay upon entry
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _onPlaceSelected(double lat, double lng, String name) {
    gmaps.LatLng destination = gmaps.LatLng(lat, lng);
    setState(() {
      _selectedPos = destination;
      _selectedName = name;
      _showActiveCard = true;
    });

    // Cinematic "Fly-in" animation (3D Perspective)
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(target: destination, zoom: 15.5, tilt: 50, bearing: 30),
      ),
    );
  }

  void _addToPlaylist() {
    if (_selectedName != null && _selectedPos != null) {
      setState(() {
        _playlist.add(SavedLocation(
            name: _selectedName!,
            position: _selectedPos!,
            description: "Discover this hidden gem in Sri Lanka"
        ));
        // Persistent blue marker for saved items
        _markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId(_selectedName!),
            position: _selectedPos!,
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure),
          ),
        );
        _showActiveCard = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${_selectedName} added to your Seygo Playlist!"), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map Layer
          gmaps.GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: const gmaps.CameraPosition(target: _initialPos, zoom: 13),
            myLocationEnabled: true,
            markers: _markers,
            onTap: (_) => setState(() => _showActiveCard = false),
          ),

          // 2. Search Bar Header
          Positioned(top: 50, left: 15, right: 15, child: _buildSearchBox()),

          // 3. Persistent "Add to Cart" Card
          if (_showActiveCard)
            Positioned(
              bottom: 140, left: 20, right: 20,
              child: _buildActiveLocationCard(),
            ),

          // 4. ✅ DRAGGABLE SCROLLABLE SHEET (Playlist View)
          DraggableScrollableSheet(
            initialChildSize: _playlist.isEmpty ? 0.0 : 0.15, // Only shows if playlist has items
            minChildSize: _playlist.isEmpty ? 0.0 : 0.15,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
                ),
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _playlist.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildHandle();
                    return _buildPlaylistCard(index - 1);
                  },
                ),
              );
            },
          ),

          // 5. Loading Animation
          if (_isLoading)
            Container(color: Colors.white, child: Center(child: Lottie.asset('assets/animations/map_loading.json', width: 200))),
        ],
      ),
    );
  }

  // UI Helper Widgets below...
  Widget _buildActiveLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_selectedName ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _addToPlaylist,
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            label: const Text("ADD TO CART", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(int index) {
    final item = _playlist[index];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: ListTile(
        leading: ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.image_outlined))),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(item.description, style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => setState(() {
            _markers.removeWhere((m) => m.markerId.value == item.name);
            _playlist.removeAt(index);
          }),
        ),
        onTap: () => _mapController?.animateCamera(gmaps.CameraUpdate.newLatLng(item.position)),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))));
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: _searchController,
        googleAPIKey: _apiKey,
        inputDecoration: const InputDecoration(hintText: "Search gems in Sri Lanka...", border: InputBorder.none, prefixIcon: Icon(Icons.search, color: Colors.blueAccent)),
        countries: ["lk"],
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (p) => _onPlaceSelected(double.parse(p.lat!), double.parse(p.lng!), p.description!),
        itemClick: (p) => _searchController.text = p.description!,
      ),
    );
  }
}