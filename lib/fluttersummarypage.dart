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
    );
  }
}
appBar: AppBar(
  elevation: 0, // Remove shadow under the AppBar
  backgroundColor: Colors.white, // Set AppBar background to white
  title: Container(
    height: 45, // Set fixed height for the search bar container
    padding: const EdgeInsets.symmetric(horizontal: 15), // Add horizontal padding inside the container
    decoration: BoxDecoration(
      color: Colors.grey.shade200, // Light grey background for the search bar
      borderRadius: BorderRadius.circular(25), // Rounded corners for the search bar
    ),
    child: const Row(
      children: [
        Icon(Icons.search, color: Colors.grey), // Search icon at the start
        SizedBox(width: 10), // Space between icon and text
        Text("Sigiriya", style: TextStyle(color: Colors.grey)), // Placeholder text inside the search bar
        Spacer(), // Pushes the icons to the edges, creating space in between
        Icon(Icons.tune, color: Colors.grey), // Filter or options icon at the end
      ],
    ),
  ),
)

// Travel category tabs
Row(
  children: const [

    // All category (default selected)
    Text(
      "All",
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    SizedBox(width: 20),

    // Latest category
    Text(
      "Latest",
    ),

    SizedBox(width: 20),

    // Popular category (highlighted)
    Text(
      "Popular",
      style: TextStyle(
        color: Colors.blue,
      ),
    ),
  ],
),
// List of images for the travel carousel
final List<String> travelImages = [
  "Imagesnew/sigiriya.jpeg",
  "Imagesnew/sigiriya.jpeg",
  "Imagesnew/sigiriya.jpeg",
];

// Image carousel widget
SizedBox(
  height: 220, // Fixed height for the slider
  child: PageView(
    scrollDirection: Axis.horizontal, // Allows horizontal swipe
    children: travelImages.map((imagePath) {
      return travelAssetImage(imagePath); // Display each image
    }).toList(),
  ),
),
// Destination title and distance information
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between title and distance
  children: [

    // Travel destination name
    const Text(
      "Sigiriya Lion Rock",
      style: TextStyle(
        fontSize:23; // Large font size for title
        fontWeight: FontWeight.bold, // Bold text for emphasis
      ),
    ),

    // Location and distance information
    Row(
      children: const [

        // Location icon
        Icon(
          Icons.location_on,
          color: Colors.blue,
        ),

        // Small spacing between icon and text
        SizedBox(width: 5),

        // Distance from current location
        Text("185 km"),
      ],
    ),
  ],
)