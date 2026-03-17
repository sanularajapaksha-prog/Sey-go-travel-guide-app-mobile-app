import 'package:flutter/material.dart';
import '../../widgets/place_photo_widget.dart';

/// Route Summary page showing a list of stops in your itinerary.
/// Each [StopCard] accepts a [googleUrl] from `places.google_url`
/// and loads the real place photo via [PlacePhotoWidget].
class FlutterSummaryScreen extends StatelessWidget {
  const FlutterSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text(
          'Route Summary',
          style: TextStyle(color: Colors.black),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.share, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                Text(
                  'Your Itinerary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                // Replace googleUrl values with the actual google_url from your DB
                StopCard(
                  index: 1,
                  title: 'Temple of the Sacred Tooth Relic',
                  location: 'Kandy',
                  time: '09:00 AM',
                  duration: '2 hours',
                  googleUrl: 'https://maps.google.com/?cid=55190463',
                ),
                StopCard(
                  index: 2,
                  title: 'Royal Botanical Gardens',
                  location: 'Peradeniya',
                  time: '12:00 PM',
                  duration: '1.5 hours',
                  distance: '5.8 km from previous',
                  googleUrl: 'https://maps.google.com/?cid=272618206',
                ),
                StopCard(
                  index: 3,
                  title: 'Kandy Lake',
                  location: 'Kandy City',
                  time: '03:30 PM',
                  duration: '1 hour',
                  distance: '6.2 km from previous',
                  googleUrl: 'https://maps.google.com/?cid=152803161',
                ),
                StopCard(
                  index: 4,
                  title: 'Bahiravokanda Vihara Buddha',
                  location: 'Bahirawakanda',
                  time: '05:00 PM',
                  duration: '45 minutes',
                  distance: '3.1 km from previous',
                  googleUrl: 'https://maps.google.com/?cid=386150969',
                ),

                SizedBox(height: 80),
              ],
            ),
          ),

          // Bottom Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff3a3a3a),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.navigation_outlined),
                label: const Text('view on google maps'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single stop card in the itinerary.
/// Provide [googleUrl] from `places.google_url` to load a real place photo,
/// or leave it null to show the default no-image placeholder.
class StopCard extends StatelessWidget {
  final int index;
  final String title;
  final String location;
  final String time;
  final String duration;
  final String? distance;

  /// The full google_url value from the database, e.g.
  /// "https://maps.google.com/?cid=55190463"
  final String? googleUrl;

  const StopCard({
    super.key,
    required this.index,
    required this.title,
    required this.location,
    required this.time,
    required this.duration,
    this.googleUrl,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number indicator
          Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Text(
                  index.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Container(
                width: 2,
                height: 120,
                color: Colors.grey.shade300,
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Place photo from Google Places API
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: PlacePhotoWidget(
                          googleUrl: googleUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          semanticLabel: title,
                        ),
                      ),

                      const SizedBox(width: 10),

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
                            Text(
                              location,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$time  •  $duration',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (distance != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffe6f3f7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        distance!,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  const Divider(),

                  Row(
                    children: const [
                      Icon(Icons.drag_indicator, size: 18, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Reorder'),
                      SizedBox(width: 16),
                      Icon(Icons.visibility, size: 18, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('View'),
                      SizedBox(width: 16),
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 4),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
