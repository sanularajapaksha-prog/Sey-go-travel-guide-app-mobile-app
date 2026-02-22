import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ExploreScreen(),
    );
  }
}

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

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

              /// HEADER
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(
                      "https://picsum.photos/200",
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hi, Vennesa",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Explore Sri Lanka",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.notifications_none, size: 28),
                ],
              ),

              const SizedBox(height: 25),

              /// SEARCH BAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Ella",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Icon(Icons.tune),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// CATEGORY CHIPS
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    CategoryChip("Adventure & Nature", true),
                    CategoryChip("Coastal", false),
                    CategoryChip("Viewpoints", false),
                    CategoryChip("Heritage", false),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Search Results for "Ella"',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              /// RESULT LIST
              Expanded(
                child: ListView(
                  children: const [
                    PlaceCard(
                      title: "Little Adams Peak",
                      type: "Hiking",
                    ),
                    PlaceCard(
                      title: "Nine Arches Bridge",
                      type: "Viewpoint",
                    ),
                    PlaceCard(
                      title: "Ella Rock Trailhead",
                      type: "Hiking",
                    ),
                    PlaceCard(
                      title: "Ravana Ella",
                      type: "Nature",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      /// BOTTOM NAVIGATION
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
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

class PlaceCard extends StatelessWidget {
  final String title;
  final String type;

  const PlaceCard({
    super.key,
    required this.title,
    required this.type,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              "https://picsum.photos/300",
              height: 75,
              width: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 75,
                  width: 90,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 15),

          /// TEXT SECTION
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
                const Text(
                  "Ella, Badulla District",
                  style: TextStyle(
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
                  "Add to your Playlist",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          const Icon(Icons.favorite_border, size: 26),
        ],
      ),
    );
  }
}