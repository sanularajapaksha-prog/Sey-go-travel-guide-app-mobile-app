import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:lottie/lottie.dart';

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
  static const gmaps.LatLng _initialPos = gmaps.LatLng(6.9639, 80.7718);
  gmaps.GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  List<SavedLocation> _playlist = [];
  Set<gmaps.Marker> _markers = {};
  bool _isLoading = true;
  bool _showCartButton = false;
  gmaps.LatLng? _selectedPos;
  String? _selectedName;

  final String _apiKey = "AIzaSyB6dQ9lJq0CQBaGzkJet_-Ua33hX4i_6_s";

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _onPlaceSelected(double lat, double lng, String name) {
    gmaps.LatLng dest = gmaps.LatLng(lat, lng);
    setState(() {
      _selectedPos = dest;
      _selectedName = name;
      _showCartButton = true;
    });
    _mapController?.animateCamera(gmaps.CameraUpdate.newCameraPosition(
      gmaps.CameraPosition(target: dest, zoom: 15.5, tilt: 50, bearing: 30),
    ));
  }

  void _addToCart() {
    if (_selectedName != null && _selectedPos != null) {
      setState(() {
        final id = "${_selectedName}_${DateTime.now().millisecondsSinceEpoch}";
        _playlist.add(SavedLocation(
            name: _selectedName!,
            position: _selectedPos!,
            description: "Explore Sri Lanka"
        ));
        _markers.add(gmaps.Marker(
          markerId: gmaps.MarkerId(id),
          position: _selectedPos!,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure),
          infoWindow: gmaps.InfoWindow(title: _selectedName),
        ));
        _showCartButton = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Added $_selectedName to playlist"), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          gmaps.GoogleMap(
            onMapCreated: (c) => _mapController = c,
            initialCameraPosition: const gmaps.CameraPosition(target: _initialPos, zoom: 13),
            markers: _markers,
            myLocationEnabled: true,
            onTap: (_) => setState(() => _showCartButton = false),
          ),

          Positioned(top: 50, left: 15, right: 15, child: _buildSearchBox()),

          if (_showCartButton)
            Positioned(
              bottom: 140, left: 50, right: 50,
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: const Text("ADD TO CART", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.all(15),
                    shape: const StadiumBorder()
                ),
              ),
            ),

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
                  itemCount: _playlist.isEmpty ? 2 : _playlist.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildHandle();
                    if (_playlist.isEmpty) return _buildEmptyState();
                    return _buildPlaylistTile(index - 1);
                  },
                ),
              );
            },
          ),

          if (_isLoading)
            Container(color: Colors.white, child: Center(child: Lottie.asset('assets/animations/map_loading.json', width: 200))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.playlist_add_check_circle_outlined, size: 50, color: Colors.grey[300]),
        const SizedBox(height: 10),
        const Text("Your playlist is empty", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        const Text("Swipe up to see your trip plan", style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildPlaylistTile(int i) {
    final item = _playlist[i];
    return ListTile(
      leading: const Icon(Icons.location_on, color: Colors.blueAccent),
      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text("Tap to view on map"),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        onPressed: () => setState(() {
          _markers.removeWhere((m) => m.infoWindow.title == item.name);
          _playlist.removeAt(i);
        }),
      ),
      onTap: () => _mapController?.animateCamera(gmaps.CameraUpdate.newLatLng(item.position)),
    );
  }

  Widget _buildHandle() => Center(child: Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))));

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: _searchController,
        googleAPIKey: _apiKey,
        inputDecoration: const InputDecoration(hintText: "Search gems...", border: InputBorder.none, prefixIcon: Icon(Icons.search)),
        countries: ["lk"],
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (p) => _onPlaceSelected(double.parse(p.lat!), double.parse(p.lng!), p.description!),
      ),
    );
  }
}