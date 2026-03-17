import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/api_service.dart';
import '../../widgets/custom_image_widget.dart';
import '../../widgets/place_photo_widget.dart';

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
        title: Text(
          playlistName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
                _buildHeader(theme),
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
                            return _buildStopCard(theme, _stops[index], index);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final count = _stops.length;
    final description = (_playlist?['description'] as String?) ?? '';
    final creatorName = (_playlist?['creator_name'] as String?) ?? '';
    final visibility = (_playlist?['visibility'] as String?) ?? '';
    final isFeatured = (_playlist?['is_featured'] as bool?) ?? false;

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
                      ? '${_totalDistanceKm.toStringAsFixed(1)} km total'
                      : '${(_playlist?['destination_count'] ?? 0)} destinations',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 0.8.h),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (creatorName.isNotEmpty || visibility.isNotEmpty || isFeatured) ...[
                  SizedBox(height: 1.0.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 0.8.h,
                    children: [
                      if (creatorName.isNotEmpty)
                        _metaChip(theme, Icons.person_outline, creatorName),
                      if (visibility.isNotEmpty)
                        _metaChip(theme, Icons.public, visibility),
                      if (isFeatured)
                        _metaChip(theme, Icons.star_outline, 'Featured'),
                    ],
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

  Widget _buildStopCard(ThemeData theme, Map<String, dynamic> stop, int index) {
    final stopName = (stop['name'] as String?) ?? 'Place';
    final category = (stop['category'] as String?) ?? 'Place';
    final location = (stop['location'] as String?) ?? '';
    final description = (stop['description'] as String?) ?? '';
    final imageUrl = (stop['imageUrl'] ?? stop['image_url'])?.toString();
    final googleUrl = (stop['googleUrl'] ?? stop['google_url'])?.toString();
    final distanceKm = (stop['distance_km'] as num?)?.toDouble() ?? 0;
    final rating = (stop['avg_rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (stop['review_count'] as num?)?.toInt() ?? 0;

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
                    if (location.isNotEmpty) ...[
                      SizedBox(height: 0.3.h),
                      Text(
                        location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.4.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 0.8.h,
            children: [
              _metaChip(
                theme,
                Icons.straighten,
                index == 0
                    ? 'Start point'
                    : '~ ${distanceKm.toStringAsFixed(1)} km from previous',
              ),
              if (rating > 0)
                _metaChip(
                  theme,
                  Icons.star_rate_rounded,
                  '${rating.toStringAsFixed(1)} rating',
                ),
              if (reviewCount > 0)
                _metaChip(
                  theme,
                  Icons.reviews_outlined,
                  '$reviewCount reviews',
                ),
            ],
          ),
          SizedBox(height: 2.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: googleUrl != null && googleUrl.isNotEmpty
                ? PlacePhotoWidget(
                    googleUrl: googleUrl,
                    width: double.infinity,
                    height: 20.h,
                    fit: BoxFit.cover,
                    semanticLabel: stopName,
                    useSadFaceFallback: true,
                  )
                : CustomImageWidget(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: 20.h,
                    fit: BoxFit.cover,
                    semanticLabel: stopName,
                  ),
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: 1.4.h),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
          if (googleUrl != null && googleUrl.isNotEmpty) ...[
            SizedBox(height: 1.2.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openPlaceMap(googleUrl),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open Place'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaChip(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.8.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          SizedBox(width: 1.5.w),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps() async {
    final coordinates = _stops.where((stop) {
      return stop['latitude'] != null && stop['longitude'] != null;
    }).toList();

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

  Future<void> _openPlaceMap(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
