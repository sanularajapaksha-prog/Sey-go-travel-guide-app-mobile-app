import 'package:google_maps_flutter/google_maps_flutter.dart';

class SavedLocation {
  final String name;
  final LatLng position;
  final String description;

  SavedLocation({
    required this.name,
    required this.position,
    required this.description
  });
}