import 'package:flutter/material.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/place_photo_widget.dart';

/// Search results / explore screen.
/// [PlaceCard] now accepts [googleUrl] from `places.google_url`
/// to load real place photos via [PlacePhotoWidget].
class PlaylistSearchScreen extends StatelessWidget {
  const PlaylistSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // HEADER
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(
                      'https://picsum.photos/200',
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, Vennesa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Explore Sri Lanka',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.notifications_none, size: 28),
                ],
              ),

              const SizedBox(height: 25),

              // SEARCH BAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ella',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Icon(Icons.tune),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // CATEGORY CHIPS
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    CategoryChip('Adventure & Nature', true),
                    CategoryChip('Coastal', false),
                    CategoryChip('Viewpoints', false),
                    CategoryChip('Heritage', false),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Search Results for "Ella"',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // RESULT LIST
              // Replace googleUrl values with the real google_url from your DB
              Expanded(
                child: ListView(
                  children: const [
                    PlaceSearchCard(
                      title: 'Little Adams Peak',
                      type: 'Hiking',
                      location: 'Ella, Badulla District',
                      googleUrl: 'https://maps.google.com/?cid=77844228',
                    ),
                    PlaceSearchCard(
                      title: 'Nine Arches Bridge',
                      type: 'Viewpoint',
                      location: 'Ella, Badulla District',
                      googleUrl: 'https://maps.google.com/?cid=111613449',
                    ),
                    PlaceSearchCard(
                      title: 'Ella Rock Trailhead',
                      type: 'Hiking',
                      location: 'Ella, Badulla District',
                      googleUrl: 'https://maps.google.com/?cid=141432637',
                    ),
                    PlaceSearchCard(
                      title: 'Ravana Ella',
                      type: 'Nature',
                      location: 'Ella, Badulla District',
                      googleUrl: 'https://maps.google.com/?cid=16905583',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(35),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.home_outlined, color: Colors.white),
            Icon(Icons.map_outlined, color: Colors.white),
            Icon(Icons.favorite_border, color: Colors.white),
            Icon(Icons.person_outline, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String text;
  final bool selected;

  const CategoryChip(this.text, this.selected, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

/// A search result card for a place.
/// Pass [googleUrl] from the database `places.google_url` column
/// to load the real Google Places photo automatically.
class PlaceSearchCard extends StatelessWidget {
  final String title;
  final String type;
  final String location;

  /// The full google_url value from the database.
  /// e.g. "https://maps.google.com/?cid=77844228"
  final String? googleUrl;

  const PlaceSearchCard({
    super.key,
    required this.title,
    required this.type,
    required this.location,
    this.googleUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Place photo — loaded from Google Places via CID
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: PlacePhotoWidget(
              googleUrl: googleUrl,
              height: 75,
              width: 90,
              fit: BoxFit.cover,
              semanticLabel: title,
            ),
          ),
          const SizedBox(width: 15),

          // TEXT SECTION
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add to your Playlist',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          FavoriteButton(
            placeId: title,
            placeName: title,
            imageUrl: googleUrl ?? '',
            location: location,
            semanticLabel: title,
            size: 26,
          ),
        ],
      ),
    );
  }
}
