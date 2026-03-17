import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/api_service.dart';
import '../../widgets/custom_image_widget.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  const PlaylistDetailsScreen({
    super.key,
    required this.playlistId,
    this.initialPlaylist,
  });

  final String playlistId;
  final Map<String, dynamic>? initialPlaylist;

  @override
  State<PlaylistDetailsScreen> createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _playlist;
  List<Map<String, dynamic>> _stops = [];
  double _totalDistanceKm = 0;

  @override
  void initState() {
    super.initState();
    _playlist = widget.initialPlaylist;
    _load();
  }

  Future<void> _load() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final result = await ApiService.fetchPlaylistDetails(
      playlistId: widget.playlistId,
      accessToken: token,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result != null) {
        _playlist = (result['playlist'] as Map?)?.cast<String, dynamic>();
        _stops = ((result['stops'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList();
        _totalDistanceKm =
            (result['total_distance_km'] as num?)?.toDouble() ?? 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlistName = (_playlist?['name'] as String?) ?? 'Playlist';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(playlistName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(context, theme),
                Expanded(
                  child: _stops.isEmpty
                      ? Center(
                          child: Text(
                            'No playlist places found.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _stops.length,
                          separatorBuilder: (_, _) => SizedBox(height: 2.h),
                          itemBuilder: (context, index) {
                            final stop = _stops[index];
                            return _buildStopCard(context, theme, stop, index);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final count = _stops.length;
    final description = (_playlist?['description'] as String?) ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.h),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Stop${count == 1 ? '' : 's'}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.6.h),
                Text(
                  _totalDistanceKm > 0
                      ? '${_totalDistanceKm.toStringAsFixed(1)} km'
                      : '${(_playlist?['destination_count'] ?? 0)} destinations',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 0.8.h),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 3.w),
          ElevatedButton.icon(
            onPressed: _stops.isEmpty ? null : _openInMaps,
            icon: const Icon(Icons.place_outlined, size: 18),
            label: const Text('View on Maps'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopCard(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> stop,
    int index,
  ) {
    final stopName = (stop['name'] as String?) ?? 'Place';
    final category = (stop['category'] as String?) ?? 'Place';
    final imageUrl = (stop['imageUrl'] ?? stop['image_url'])?.toString();
    final distanceKm = (stop['distance_km'] as num?)?.toDouble() ?? 0;
    final description = (stop['description'] as String?) ?? '';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 9.w,
                height: 9.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stopName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 0.4.h),
                    Text(
                      category,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.4.h),
          Row(
            children: [
              Icon(
                Icons.straighten,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Text(
                index == 0
                    ? 'Start point'
                    : '≈ ${distanceKm.toStringAsFixed(1)} km from previous',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CustomImageWidget(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 18.h,
              fit: BoxFit.cover,
              semanticLabel: stopName,
            ),
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: 1.4.h),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openInMaps() async {
    final coordinates = _stops
        .where(
          (stop) =>
              stop['latitude'] != null &&
              stop['longitude'] != null,
        )
        .toList();

    if (coordinates.isEmpty) return;

    final origin = coordinates.first;
    final destination = coordinates.last;
    final waypointStops = coordinates.length > 2
        ? coordinates
            .sublist(1, coordinates.length - 1)
            .map(
              (stop) =>
                  '${(stop['latitude'] as num).toDouble()},${(stop['longitude'] as num).toDouble()}',
            )
            .join('|')
        : '';

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${origin['latitude']},${origin['longitude']}'
      '&destination=${destination['latitude']},${destination['longitude']}'
      '${waypointStops.isNotEmpty ? '&waypoints=$waypointStops' : ''}'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
