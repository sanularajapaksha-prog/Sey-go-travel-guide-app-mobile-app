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
      home: HomeScreen(),
    );
  }
}

/// MAIN SCREEN (Background Blur Example)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Stack(
        children: [
          /// FAKE BACKGROUND CONTENT
          Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) => const PlaylistDialog(),
                );
              },
              child: const Text("Open Playlist"),
            ),
          ),
        ],
      ),
    );
  }
}

/// PLAYLIST DIALOG
class PlaylistDialog extends StatelessWidget {
  const PlaylistDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// CLOSE BUTTON
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close),
              ),
            ),

            const SizedBox(height: 10),

            /// PLAYLIST ITEMS
            const PlaylistItem(
              image: "https://picsum.photos/200/300?1",
              title: "Temple of tooth",
              location: "Kandy",
            ),
            const SizedBox(height: 15),
            const PlaylistItem(
              image: "https://picsum.photos/200/300?2",
              title: "Royal botanical garden",
              location: "Kandy",
            ),
            const SizedBox(height: 15),
            const PlaylistItem(
              image: "https://picsum.photos/200/300?3",
              title: "Kandy Lake",
              location: "Kandy",
            ),
            const SizedBox(height: 15),
            const PlaylistItem(
              image: "https://picsum.photos/200/300?4",
              title: "Bahirawakanda temple",
              location: "Kandy",
            ),

            const SizedBox(height: 30),

            /// START JOURNEY BUTTON
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1C1C1C), Color(0xFF2A2A2A)],
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                "Start Journey",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// PLAYLIST CARD ITEM
class PlaylistItem extends StatelessWidget {
  final String image;
  final String title;
  final String location;

  const PlaylistItem({
    super.key,
    required this.image,
    required this.title,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [

          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              image,
              height: 60,
              width: 60,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 15),

          /// TITLE + LOCATION
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// DISTANCE
          const Row(
            children: [
              Icon(Icons.route, size: 16, color: Colors.teal),
              SizedBox(width: 5),
              Text(
                "185 km",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),

          const SizedBox(width: 10),

          /// DELETE ICON
          const Icon(Icons.delete_outline, color: Colors.grey),
        ],
      ),
    );
  }
}