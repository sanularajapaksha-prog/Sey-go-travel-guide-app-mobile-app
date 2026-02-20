import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const LatLng _initialPos = LatLng(6.9639, 80.7718); // Nuwara Eliya
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  // Set to store the markers displayed on the map
  Set<Marker> _markers = {};

  final String _apiKey = "AIzaSyB6dQ9lJq0CQBaGzkJet_-Ua33hX4i_6_s";

  // Function to move camera and add a marker
  void _handleLocationSelection(double lat, double lng, String address) {
    LatLng target = LatLng(lat, lng);

    // 1. Update the Marker
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId("searched_place"),
          position: target,
          infoWindow: InfoWindow(title: address),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        )
      };
    });

    // 2. Move the Camera
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15),
      ),
    );

    // 3. Show Location Details Panel
    _showLocationDetails(address, lat, lng);
  }

  // UI for the location details at the bottom
  void _showLocationDetails(String name, double lat, double lng) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 5),
                  Text("Coordinates: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}",
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text("Set as Destination", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: const CameraPosition(target: _initialPos, zoom: 13),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers, // Link the markers to the map
          ),

          // Search Bar
          Positioned(
            top: 50, left: 15, right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: _searchController,
                googleAPIKey: _apiKey,
                inputDecoration: const InputDecoration(
                  hintText: "Search location...",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                debounceTime: 600,
                countries: ["lk"],
                isLatLngRequired: true,
                // ✅ FULL getPlaceDetailWithLatLng FUNCTION
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  if (prediction.lat != null && prediction.lng != null) {
                    double lat = double.parse(prediction.lat!);
                    double lng = double.parse(prediction.lng!);
                    _handleLocationSelection(lat, lng, prediction.description ?? "");
                  }
                },
                itemClick: (Prediction prediction) {
                  _searchController.text = prediction.description ?? "";
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _searchController.text.length),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}