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
  // Initial center: Nuwara Eliya
  static const LatLng _nuwaraEliya = LatLng(6.9639, 80.7718);
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  // ✅ YOUR WORKING API KEY
  final String _apiKey = "AIzaSyB6dQ9lJq0CQBaGzkJet_-Ua33hX4i_6_s";

  // Moves camera to a specific lat/lng
  void _animateCamera(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 15),
      ),
    );
  }

  // Gets user's current GPS position
  Future<void> _goToCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _animateCamera(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Important to keep the map full screen when keyboard opens
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. THE MAP
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: const CameraPosition(target: _nuwaraEliya, zoom: 13),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // 2. THE SEARCH BAR
          Positioned(
            top: 50,
            left: 15,
            right: 15,
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
                  hintText: "Search location in Sri Lanka",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                debounceTime: 800,
                countries: ["lk"], // Restricts results to Sri Lanka
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  // ✅ When user selects a result, fly to those coordinates
                  if (prediction.lat != null && prediction.lng != null) {
                    double lat = double.parse(prediction.lat!);
                    double lng = double.parse(prediction.lng!);
                    _animateCamera(lat, lng);
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

          // 3. ACTION BUTTON (Current Location)
          Positioned(
            right: 15,
            top: 130,
            child: FloatingActionButton(
              onPressed: _goToCurrentLocation,
              mini: true,
              backgroundColor: Colors.black,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
