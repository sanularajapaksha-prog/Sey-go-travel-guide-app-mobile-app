import 'package:flutter/material.dart';
import '../../widgets/place_photo_widget.dart';

/// Overview / detail screen for a single place (e.g. Sigiriya).
/// Pass [googleUrl] from the database `places.google_url` column so the
/// real Google Places photo is loaded automatically.
class FlutterOverviewScreen extends StatelessWidget {
  final String placeName;
  final String description;
  final String distanceKm;
  final String duration;
  final double rating;
  final int reviewCount;

  /// The google_url column value from the `places` table.
  /// e.g. "https://maps.google.com/?cid=55190463"
  final String? googleUrl;

  const FlutterOverviewScreen({
    super.key,
    required this.placeName,
    this.googleUrl,
    this.description =
        'Sigiriya Lion Rock is an engineering and artistic marvel set within '
        'the lush landscapes of Sri Lanka\'s Cultural Triangle. It features preserved '
        'frescoes, landscaped gardens, and the imposing lion paws leading to the summit.',
    this.distanceKm = '185 km',
    this.duration = '1 Day',
    this.rating = 4.8,
    this.reviewCount = 2900,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Search Bar AppBar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 10),
              Text(
                placeName,
                style: const TextStyle(color: Colors.grey),
              ),
              const Spacer(),
              const Icon(Icons.tune, color: Colors.grey),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs
            Row(
              children: const [
                Text('All', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 20),
                Text('Latest'),
                SizedBox(width: 20),
                Text('Popular', style: TextStyle(color: Colors.blue)),
              ],
            ),

            const SizedBox(height: 20),

            // Image Carousel — loads real photo from Google Places via CID
            SizedBox(
              height: 220,
              child: PageView(
                children: [
                  _buildCarouselImage(),
                  _buildCarouselImage(),
                  _buildCarouselImage(),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Title + Distance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  placeName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(distanceKm),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Text(
              'Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // Duration + Rating
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue),
                const SizedBox(width: 5),
                Text(duration),
                const SizedBox(width: 20),
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 5),
                Text(
                  '$rating (${(reviewCount / 1000).toStringAsFixed(1)}k Reviews)',
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Description
            Text(
              description,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 25),

            // Add to Cart Button
            Center(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Add to cart'),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }

  Widget _buildCarouselImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: googleUrl != null && googleUrl!.isNotEmpty
          ? PlacePhotoWidget(
              googleUrl: googleUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              semanticLabel: placeName,
            )
          : Image.asset(
              'assets/images/no-image.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 220,
            ),
    );
  }
}
