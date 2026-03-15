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
      ),

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

                child: Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),

                    gradient: const LinearGradient(
                      colors: [Colors.transparent, Colors.black54],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: const [
                      Text(
                        "Ruwan weli maha seya",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 6),

                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.white,
                          ),

                          SizedBox(width: 5),

                          Text(
                            "Jan 15 - Jan 17, 2025",
                            style: TextStyle(color: Colors.white),
                          ),

                          SizedBox(width: 20),

                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.white,
                          ),

                          SizedBox(width: 5),

                          Text("3 days", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// INFO CARDS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  InfoCard(Icons.directions_car, "Transport", "Car"),
                  InfoCard(Icons.access_time, "Travel Time", "6h 45m"),
                  InfoCard(Icons.location_on, "Stops", "4 places"),
                ],
              ),

              const SizedBox(height: 25),

              /// SAFETY SECTION
              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "Safety & Preparation",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        const Icon(Icons.download),

                        const SizedBox(width: 10),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Offline Mode"),
                              Text(
                                "Download maps & details",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        Switch(
                          value: offlineMode,
                          onChanged: (value) {
                            setState(() {
                              offlineMode = value;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  offlineMode
                                      ? "Offline Mode Enabled"
                                      : "Offline Mode Disabled",
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const Divider(height: 25),

                    