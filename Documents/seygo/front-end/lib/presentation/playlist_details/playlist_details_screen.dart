import 'package:flutter/material.dart';
import '../../widgets/place_photo_widget.dart';

/// Place / playlist detail screen showing a large hero image, stats, and
/// a description about the place.
///
/// Pass [googleUrl] from `places.google_url` in the database so the hero photo
/// is loaded automatically via [PlacePhotoWidget].
class PlaylistDetailsScreen extends StatelessWidget {
  final String placeName;
  final String placeLocation;
  final String description;
  final double rating;
  final String ratingCount;
  final String distanceKm;
  final int restaurantCount;

  /// The full google_url from the database.
  /// e.g. "https://maps.google.com/?cid=111613449"
  final String? googleUrl;

  const PlaylistDetailsScreen({
    super.key,
    this.placeName = 'Nine Arch Bridge',
    this.placeLocation = 'Ella, Sri Lanka',
    this.description =
        'The Nine Arch Bridge in Ella, Sri Lanka, is a historic stone bridge '
        'with nine arches built in 1921 without steel. It\'s surrounded by '
        'beautiful green hills and tea plantations, making it a peaceful and '
        'scenic place to visit. The bridge shows impressive craftsmanship and '
        'is a popular spot for watching trains pass.',
    this.rating = 4.8,
    this.ratingCount = '3.2k',
    this.distanceKm = '2.1 km',
    this.restaurantCount = 108,
    this.googleUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),
      body: Stack(
        children: [
          // SCROLLABLE CONTENT
          SingleChildScrollView(
            child: Column(
              children: [
                // TOP HERO IMAGE — loaded from Google Places via CID
                Stack(
                  children: [
                    SizedBox(
                      height: 350,
                      width: double.infinity,
                      child: PlacePhotoWidget(
                        googleUrl: googleUrl,
                        width: double.infinity,
                        height: 350,
                        fit: BoxFit.cover,
                        semanticLabel: placeName,
                        useSadFaceFallback: true,
                      ),
                    ),

                    // CLOSE BUTTON
                    Positioned(
                      top: 50,
                      right: 20,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child:
                              const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                // WHITE SECTION
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 90, 20, 120),
                  decoration: const BoxDecoration(
                    color: Color(0xfff3f4f6),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // STATS ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatCard(
                            icon: Icons.star,
                            value: rating.toString(),
                            label: '($ratingCount)',
                            color: Colors.blue,
                          ),
                          StatCard(
                            icon: Icons.location_on,
                            value: distanceKm,
                            label: 'Distance',
                            color: Colors.red,
                          ),
                          StatCard(
                            icon: Icons.restaurant,
                            value: '$restaurantCount',
                            label: 'Restaurants',
                            color: Colors.grey,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // ABOUT TITLE
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // DESCRIPTION
                      Text(
                        description,
                        style: const TextStyle(
                          height: 1.6,
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // FLOATING TITLE CARD
          Positioned(
            top: 300,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // TEXT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          placeName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(placeLocation),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // FAVORITE BUTTON
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child:
                        const Icon(Icons.favorite, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),

          // ADD TO PLAYLIST BUTTON
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Add To Playlist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
