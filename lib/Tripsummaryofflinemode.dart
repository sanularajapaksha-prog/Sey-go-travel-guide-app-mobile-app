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
      home: TripSummaryPage(),
    );
  }
}
class TripSummaryPage extends StatefulWidget {
  const TripSummaryPage({super.key});

  @override
  State<TripSummaryPage> createState() => _TripSummaryPageState();
}

class _TripSummaryPageState extends State<TripSummaryPage> {
  bool offlineMode = false;
  void startJourney() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Journey Started ")));
  }

  void shareTrip() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Trip Shared")));
  }
   void showEmergencyContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emergency Contact"),
        content: const Text("Call: +94 11 123 4567"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        centerTitle: true,
        title: const Text(
          "Trip Summary",
          style: TextStyle(color: Colors.black),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: shareTrip,
          ),
        ],
      )
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              /// HEADER CARD
              Container(
                height: 200,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),

                  image: const DecorationImage(
                    image: NetworkImage(
                      "https://www.trawell.in/admin/images/upload/07208983Anuradhapura_Ruwanwalisaya.jpg",
                    ),
                    fit: BoxFit.cover,
                  ),
                ),