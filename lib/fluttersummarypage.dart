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
//add travel category tabs
Row(
  children: const [
    Text("All", style: TextStyle(fontWeight: FontWeight.bold)),//all bold
    SizedBox(width: 20),
    Text("Latest"),
    SizedBox(width: 20),//sizedbox 20
    Text("Popular", style: TextStyle(color: Colors.blue)),
  ],
),
