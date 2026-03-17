class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.semanticLabel,
    required this.location,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviews,
    required this.googleUrl,
    required this.imageUrl,
    required this.imageSource,
    required this.photoPublicUrls,
  });

  final String id;
  final String name;
  final String category;
  final String semanticLabel;
  final String location;
  final String description;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int reviews;
  final String? googleUrl;
  final String? imageUrl;
  final String? imageSource;
  final List<String> photoPublicUrls;

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: (map['id'] ?? map['place_id'] ?? map['name'] ?? '').toString(),
      name: (map['name'] ?? 'Unknown Place').toString(),
      category: (map['category'] ?? 'Other').toString(),
      semanticLabel:
          (map['semanticLabel'] ?? map['semantic_label'] ?? map['name'] ?? 'Place photo')
              .toString(),
      location:
          (map['location'] ?? map['address'] ?? map['formatted_address'] ?? '')
              .toString(),
      description:
          (map['description'] ?? map['summary'] ?? 'No description available.')
              .toString(),
      latitude: _toDouble(map['latitude'] ?? map['lat']),
      longitude: _toDouble(map['longitude'] ?? map['lng'] ?? map['lon']),
      rating: _toDouble(map['rating'] ?? map['avg_rating']) ?? 0.0,
      reviews: _toInt(map['reviews'] ?? map['review_count']) ?? 0,
      googleUrl: _normalizeGoogleUrl(map['googleUrl'] ?? map['google_url']),
      imageUrl: _normalizeHttpUrl(map['imageUrl'] ?? map['image_url']),
      imageSource: map['imageSource']?.toString() ?? map['image_source']?.toString(),
      photoPublicUrls: _toStringList(map['photoPublicUrls'] ?? map['photo_public_urls']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'semanticLabel': semanticLabel,
      'location': location,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'reviews': reviews,
      'googleUrl': googleUrl,
      'google_url': googleUrl,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
      'imageSource': imageSource,
      'image_source': imageSource,
      'photoPublicUrls': photoPublicUrls,
      'photo_public_urls': photoPublicUrls,
      'image': resolveBestAvailableImageUrl(),
    };
  }

  String? get googlePhotoUrl => withGooglePhotoWidth(googleUrl);
  String? get cachedImageUrl => withGooglePhotoWidth(imageUrl);

  String? resolveBestAvailableImageUrl() {
    for (final url in photoPublicUrls) {
      final normalized = withGooglePhotoWidth(url);
      if (normalized != null) {
        return normalized;
      }
    }
    if (cachedImageUrl != null) {
      return cachedImageUrl;
    }
    return null;
  }

  static String? withGooglePhotoWidth(String? url, {int maxWidth = 800}) {
    final normalized = _normalizeGoogleUrl(url);
    if (normalized == null) {
      return null;
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme) {
      return normalized;
    }

    final query = Map<String, String>.from(uri.queryParameters);
    query.putIfAbsent('maxwidth', () => '$maxWidth');
    return uri.replace(queryParameters: query).toString();
  }

  static String? _normalizeGoogleUrl(dynamic value) {
    return _normalizeHttpUrl(value);
  }

  static String? _normalizeHttpUrl(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (text.startsWith('http://') || text.startsWith('https://')) {
      final lowered = text.toLowerCase();
      if (lowered.contains('example.com')) {
        return null;
      }
      return text;
    }
    return null;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => _normalizeHttpUrl(item))
          .whereType<String>()
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
            .map((item) => _normalizeHttpUrl(item.replaceAll('"', '').replaceAll("'", '').trim()))
            .whereType<String>()
            .toList();
      }
      final single = _normalizeHttpUrl(trimmed);
      return single == null ? const [] : [single];
    }
    return const [];
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
