import 'dart:convert';

enum OfflineCacheType { routeTrip, destination }

/// Unified model for everything saved to local offline storage.
///
/// [type] == [OfflineCacheType.routeTrip]  → full planned route from Route Planner.
/// [type] == [OfflineCacheType.destination] → single destination saved from Detail screen.
class OfflineCacheItem {
  final String id;
  final OfflineCacheType type;
  final String title;
  final String? imageUrl;
  final String? description;
  final String? category;
  final String? location;
  final double? latitude;
  final double? longitude;

  // Route trip specific
  final String? dateRange;
  final int? days;
  final int? stops;
  final double? distanceKm;
  final double? budgetLKR;
  final String? transportMode;
  final String? travelTime;
  final String? emergencyContact;

  /// Full route data for offline trip playback (origin, routePoints, optimizedStops).
  final Map<String, dynamic>? routeData;

  /// Full destination data map for offline destination viewing.
  final Map<String, dynamic>? placeData;

  final DateTime savedAt;

  const OfflineCacheItem({
    required this.id,
    required this.type,
    required this.title,
    required this.savedAt,
    this.imageUrl,
    this.description,
    this.category,
    this.location,
    this.latitude,
    this.longitude,
    this.dateRange,
    this.days,
    this.stops,
    this.distanceKm,
    this.budgetLKR,
    this.transportMode,
    this.travelTime,
    this.emergencyContact,
    this.routeData,
    this.placeData,
  });

  // ── serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'imageUrl': imageUrl,
        'description': description,
        'category': category,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'dateRange': dateRange,
        'days': days,
        'stops': stops,
        'distanceKm': distanceKm,
        'budgetLKR': budgetLKR,
        'transportMode': transportMode,
        'travelTime': travelTime,
        'emergencyContact': emergencyContact,
        'routeData': routeData != null ? jsonEncode(routeData) : null,
        'placeData': placeData != null ? jsonEncode(placeData) : null,
        'savedAt': savedAt.toIso8601String(),
      };

  factory OfflineCacheItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? routeData;
    Map<String, dynamic>? placeData;
    try {
      final rd = json['routeData'];
      if (rd is String && rd.isNotEmpty) {
        routeData = Map<String, dynamic>.from(jsonDecode(rd) as Map);
      } else if (rd is Map) {
        routeData = Map<String, dynamic>.from(rd);
      }
    } catch (_) {}
    try {
      final pd = json['placeData'];
      if (pd is String && pd.isNotEmpty) {
        placeData = Map<String, dynamic>.from(jsonDecode(pd) as Map);
      } else if (pd is Map) {
        placeData = Map<String, dynamic>.from(pd);
      }
    } catch (_) {}

    return OfflineCacheItem(
      id: json['id'] as String,
      type: OfflineCacheType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OfflineCacheType.destination,
      ),
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      dateRange: json['dateRange'] as String?,
      days: (json['days'] as num?)?.toInt(),
      stops: (json['stops'] as num?)?.toInt(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      budgetLKR: (json['budgetLKR'] as num?)?.toDouble(),
      transportMode: json['transportMode'] as String?,
      travelTime: json['travelTime'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      routeData: routeData,
      placeData: placeData,
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  OfflineCacheItem copyWith({String? id, OfflineCacheType? type}) =>
      OfflineCacheItem(
        id: id ?? this.id,
        type: type ?? this.type,
        title: title,
        imageUrl: imageUrl,
        description: description,
        category: category,
        location: location,
        latitude: latitude,
        longitude: longitude,
        dateRange: dateRange,
        days: days,
        stops: stops,
        distanceKm: distanceKm,
        budgetLKR: budgetLKR,
        transportMode: transportMode,
        travelTime: travelTime,
        emergencyContact: emergencyContact,
        routeData: routeData,
        placeData: placeData,
        savedAt: savedAt,
      );
}
