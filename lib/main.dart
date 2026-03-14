import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: "Poppins"),
      home: const TravelPage(),
    );
  }
}

class TravelPage extends StatelessWidget {
  const TravelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 🔍 Search Bar
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
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.grey),
              SizedBox(width: 10),
              Text("Sigiriya", style: TextStyle(color: Colors.grey)),
              Spacer(),
              Icon(Icons.tune, color: Colors.grey),
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
                Text("All", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 20),
                Text("Latest"),
                SizedBox(width: 20),
                Text("Popular", style: TextStyle(color: Colors.blue)),
              ],
            ),

            const SizedBox(height: 20),

            // Image Carousel
            SizedBox(
              height: 220,
              child: PageView(
                children: [
                  travelAssetImage("Imagesnew/sigiriya.jpeg"),
                  travelAssetImage("Imagesnew/sigiriya.jpeg"),
                  travelAssetImage("Imagesnew/sigiriya.jpeg"),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Title + Distance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Sigiriya Lion Rock",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue),
                    SizedBox(width: 4),
                    Text("185 km"),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Text(
              "Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // Duration + Rating
            Row(
              children: const [
                Icon(Icons.access_time, color: Colors.blue),
                SizedBox(width: 5),
                Text("1 Day"),
                SizedBox(width: 20),
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 5),
                Text("6.0 (2.9k Reviews)"),
              ],
            ),

            const SizedBox(height: 15),

            // Description
            const Text(
              "Sigiriya Lion Rock is an engineering and artistic marvel set within "
              "the lush landscapes of Sri Lanka’s Cultural Triangle. It features "
              "preserved frescoes, landscaped gardens, and the imposing lion paws "
              "leading to the summit.",
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),

            const SizedBox(height: 25),

            // Add to Cart Button
            Center(
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    "Add to cart",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
      ),
    );
  }
}

// Image widget
Widget travelAssetImage(String path) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Image.asset(path, fit: BoxFit.cover),
  );
}
