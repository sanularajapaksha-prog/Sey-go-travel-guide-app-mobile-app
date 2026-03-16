import 'package:flutter/material.dart';

void main() {
  runApp(const TravelApp());
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PlaceDetailsPage(),
    );
  }
}

class PlaceDetailsPage extends StatelessWidget {
  const PlaceDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),

      body: Stack(
        children: [
          /// SCROLLABLE CONTENT
          SingleChildScrollView(
            child: Column(
              children: [
                /// TOP IMAGE
                Stack(
                  children: [
                    SizedBox(
                      height: 350,
                      width: double.infinity,
                      child: Image.network(
                        "https://images.unsplash.com/photo-1593693397690-362cb9666fc2",
                        fit: BoxFit.cover,
                      ),
                    ),

                    /// CLOSE BUTTON
                    Positioned(
                      top: 50,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ],
                ),

                /// WHITE SECTION
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
                      /// STATS ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          StatCard(
                            icon: Icons.star,
                            value: "4.8",
                            label: "(3.2k)",
                            color: Colors.blue,
                          ),
                          StatCard(
                            icon: Icons.location_on,
                            value: "2.1 km",
                            label: "Distance",
                            color: Colors.red,
                          ),
                          StatCard(
                            icon: Icons.restaurant,
                            value: "108",
                            label: "Restaurants",
                            color: Colors.grey,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      /// ABOUT TITLE
                      const Text(
                        "About",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// DESCRIPTION
                      const Text(
                        "The Nine Arch Bridge in Ella, Sri Lanka, is a historic stone bridge with nine arches built in 1921 without steel. It’s surrounded by beautiful green hills and tea plantations, making it a peaceful and scenic place to visit. The bridge shows impressive craftsmanship and is a popular spot for watching trains pass.",
                        style: TextStyle(
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

          /// FLOATING TITLE CARD
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
                  /// TEXT
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Nine Arch Bridge",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text("Ella, Sri Lanka"),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// FAVORITE BUTTON
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.favorite, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),

          /// ADD TO CART BUTTON
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
                "Add To Cart",
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
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
