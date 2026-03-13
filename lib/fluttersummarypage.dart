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
      home: RouteSummaryPage(),
    );
  }
}
// RouteSummaryPage is a StatelessWidget because the UI does not change dynamically
class RouteSummaryPage extends StatelessWidget {

  // Constructor for the widget
  const RouteSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {

    // Scaffold provides the basic page structure (AppBar, body, etc.)
    return Scaffold(

      // Set the background color of the whole screen
      backgroundColor: const Color(0xfff5f5f5),

      // AppBar at the top of the page
      appBar: AppBar(

        // Make the app bar transparent
        backgroundColor: Colors.transparent,

        // Remove shadow under the AppBar
        elevation: 0,

        // Center the title text
        centerTitle: true,

        // Leading widget (left side of AppBar)
        // This is a back arrow icon
        leading: const Icon(
          Icons.arrow_back,
          color: Colors.black,
        ),

        // Title displayed in the center of the AppBar
        title: const Text(
          "Route Summary",
          style: TextStyle(color: Colors.black),
        ),

        // Widgets displayed on the right side of the AppBar
        actions: const [

          // Padding is added to create space from the right edge
          Padding(
            padding: EdgeInsets.only(right: 16),

            // Share icon button
            child: Icon(
              Icons.share,
              color: Colors.black,
            ),
          )
        ],
      ),
    );
  }
}