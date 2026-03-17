import 'package:flutter/material.dart';
import '../../widgets/place_photo_widget.dart';

/// Trip Summary screen with offline mode toggle and emergency contact.
///
/// Pass [googleUrl] from `places.google_url` in the database so the
/// header hero photo is loaded via [PlacePhotoWidget].
class TripSummaryOfflineScreen extends StatefulWidget {
  final String tripName;
  final String tripDates;
  final String tripDuration;
  final String transport;
  final String travelTime;
  final String stopsCount;

  /// The full google_url from the database.
  /// e.g. "https://maps.google.com/?cid=272618206"
  final String? googleUrl;

  const TripSummaryOfflineScreen({
    super.key,
    this.tripName = 'Ruwan weli maha seya',
    this.tripDates = 'Jan 15 - Jan 17, 2025',
    this.tripDuration = '3 days',
    this.transport = 'Car',
    this.travelTime = '6h 45m',
    this.stopsCount = '4 places',
    this.googleUrl,
  });

  @override
  State<TripSummaryOfflineScreen> createState() =>
      _TripSummaryOfflineScreenState();
}

class _TripSummaryOfflineScreenState extends State<TripSummaryOfflineScreen> {
  bool offlineMode = false;

  void _startJourney() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journey Started')),
    );
  }

  void _shareTrip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip Shared')),
    );
  }

  void _showEmergencyContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Contact'),
        content: const Text('Call: +94 11 123 4567'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Trip Summary',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: _shareTrip,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // HEADER CARD — hero image from Google Places via CID
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Hero image loaded from google_url
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: PlacePhotoWidget(
                        googleUrl: widget.googleUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        semanticLabel: widget.tripName,
                        useSadFaceFallback: true,
                      ),
                    ),

                    // Gradient overlay + text
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.transparent, Colors.black54],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.tripName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.tripDates,
                                  style:
                                      const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(width: 20),
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.tripDuration,
                                  style:
                                      const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // INFO CARDS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoCard(Icons.directions_car, 'Transport', widget.transport),
                  _InfoCard(Icons.access_time, 'Travel Time', widget.travelTime),
                  _InfoCard(Icons.location_on, 'Stops', widget.stopsCount),
                ],
              ),

              const SizedBox(height: 25),

              // SAFETY SECTION
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
                      'Safety & Preparation',
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
                              Text('Offline Mode'),
                              Text(
                                'Download maps & details',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: offlineMode,
                          onChanged: (value) {
                            setState(() => offlineMode = value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  offlineMode
                                      ? 'Offline Mode Enabled'
                                      : 'Offline Mode Disabled',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 25),
                    GestureDetector(
                      onTap: _showEmergencyContact,
                      child: const Row(
                        children: [
                          Icon(Icons.phone),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Emergency Contact'),
                                Text(
                                  '+94 11 XXX XXXX',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // START JOURNEY BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _startJourney,
                  icon: const Icon(Icons.navigation),
                  label: const Text(
                    'Start Journey',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard(this.icon, this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
