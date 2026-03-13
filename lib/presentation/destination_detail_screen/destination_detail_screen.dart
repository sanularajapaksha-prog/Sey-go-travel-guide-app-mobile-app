import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/destination_header_widget.dart';
import './widgets/destination_info_widget.dart';
import './widgets/highlights_widget.dart';
import './widgets/map_preview_widget.dart';
import './widgets/related_destinations_widget.dart';

class DestinationDetailScreen extends StatefulWidget {
  const DestinationDetailScreen({super.key});

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  bool _isLoading = false;
  bool _isFavorite = false;
  final ScrollController _scrollController = ScrollController();

  // Mock destination data
  final Map<String, dynamic> _destinationData = {
    "id": 1,
    "name": "Ella",
    "location": "Badulla District, Uva Province, Sri Lanka",
    "description":
    "Ella is a small town in the Badulla District of Uva Province, Sri Lanka governed by an Urban Council. It is approximately 200 km east of Colombo and is situated at an elevation of 1,041 m above sea level. The area has a rich bio-diversity, dense with numerous varieties of flora and fauna. Ella is surrounded by the beautiful Ella Rocks and Ravana Falls, making it a perfect destination for nature lovers and adventure seekers.",
    "latitude": 6.8667,
    "longitude": 81.0467,
    "images": [
      {
        "url":
        "https://images.unsplash.com/photo-1522496884773-12ab0d24738e",
        "semanticLabel":
        "Scenic view of Ella town nestled in lush green mountains with tea plantations and misty valleys",
      },
      {
        "url":
        "https://images.unsplash.com/photo-1519576325797-91124298a877",
        "semanticLabel":
        "Nine Arch Bridge in Ella surrounded by dense tropical forest and tea estates",
      },
      {
        "url":
        "https://images.unsplash.com/photo-1707929592353-95578ba630f5",
        "semanticLabel":
        "Panoramic mountain landscape view from Ella Rock with rolling hills and valleys",
      },
      {
        "url":
        "https://images.unsplash.com/photo-1651608018547-dfbc9e41d0e7",
        "semanticLabel":
        "Traditional Sri Lankan tea plantation workers harvesting tea leaves on hillside",
      },
    ],
    "highlights": [
      {
        "icon": "landscape",
        "title": "Nine Arch Bridge",
        "description": "Iconic railway bridge surrounded by tea plantations",
      },
      {
        "icon": "hiking",
        "title": "Ella Rock",
        "description": "Popular hiking destination with panoramic views",
      },
      {
        "icon": "water_drop",
        "title": "Ravana Falls",
        "description": "Beautiful waterfall with swimming opportunities",
      },
      {
        "icon": "local_cafe",
        "title": "Tea Estates",
        "description": "Visit working tea plantations and factories",
      },
      {
        "icon": "train",
        "title": "Scenic Train Ride",
        "description": "One of the world's most beautiful train journeys",
      },
      {
        "icon": "wb_sunny",
        "title": "Little Adam's Peak",
        "description": "Easy hike with stunning sunrise views",
      },
    ],
  };

  final List<Map<String, dynamic>> _relatedDestinations = [
    {
      "id": 2,
      "name": "Kandy",
      "location": "Central Province, Sri Lanka",
      "image":
      "https://img.rocket.new/generatedImages/rocket_gen_img_193f33a5e-1766335454247.png",
      "semanticLabel":
      "Temple of the Sacred Tooth Relic in Kandy with traditional architecture and lake view",
    },
    {
      "id": 3,
      "name": "Jaffna",
      "location": "Northern Province, Sri Lanka",
      "image":
      "https://img.rocket.new/generatedImages/rocket_gen_img_1b20076d0-1768674030531.png",
      "semanticLabel":
      "Jaffna Fort colonial architecture with palm trees and coastal backdrop",
    },
    {
      "id": 4,
      "name": "Sigiriya",
      "location": "Matale District, Central Province",
      "image":
      "https://img.rocket.new/generatedImages/rocket_gen_img_13818a0b1-1765084352309.png",
      "semanticLabel":
      "Ancient Sigiriya Rock Fortress rising from jungle landscape at sunset",
    },
    {
      "id": 5,
      "name": "Galle",
      "location": "Southern Province, Sri Lanka",
      "image":
      "https://images.unsplash.com/photo-1734279135096-2854a06faba8",
      "semanticLabel":
      "Galle Fort Dutch colonial buildings and lighthouse overlooking Indian Ocean",
    },
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshDestination() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    Fluttertoast.showToast(
      msg: "Destination updated",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleShare() {
    // Platform-specific sharing
    Clipboard.setData(
      ClipboardData(
        text:
        '${_destinationData["name"]} - ${_destinationData["location"]}\n\nCheck out this amazing destination!',
      ),
    );

    Fluttertoast.showToast(
      msg: "Destination details copied to clipboard",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    Fluttertoast.showToast(
      msg: _isFavorite ? "Added to favorites" : "Removed from favorites",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleAddToPlaylist() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => _buildPlaylistBottomSheet(),
    );
  }

  Widget _buildPlaylistBottomSheet() {
    final theme = Theme.of(context);
    final playlists = [
      {"name": "Summer Vacation 2026", "count": 12},
      {"name": "Adventure Destinations", "count": 8},
      {"name": "Cultural Heritage Sites", "count": 15},
      {"name": "Beach Getaways", "count": 6},
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add to Playlist', style: theme.textTheme.titleLarge),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: theme.colorScheme.onSurface,
                  size: 6.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Create new playlist button
          ListTile(
            leading: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'add',
                  color: theme.colorScheme.secondary,
                  size: 6.w,
                ),
              ),
            ),
            title: Text(
              'Create New Playlist',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "Create playlist feature coming soon",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
          ),

          Divider(height: 3.h),

          // Existing playlists
          ...playlists.map((playlist) {
            return ListTile(
              leading: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(2.w),
                  border: Border.all(color: theme.dividerColor, width: 1),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'playlist_play',
                    color: theme.colorScheme.onSurface,
                    size: 6.w,
                  ),
                ),
              ),
              title: Text(
                playlist["name"] as String,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                '${playlist["count"]} destinations',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Fluttertoast.showToast(
                  msg: "Added to ${playlist["name"]}",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              },
            );
          }),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  void _handleNavigate() {
    final lat = _destinationData["latitude"];
    final lng = _destinationData["longitude"];
    final name = _destinationData["name"];

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => _buildNavigationBottomSheet(lat, lng, name),
    );
  }

  Widget _buildNavigationBottomSheet(double lat, double lng, String name) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Navigate to $name', style: theme.textTheme.titleLarge),
          SizedBox(height: 3.h),

          // Google Maps option
          ListTile(
            leading: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'map',
                  color: theme.colorScheme.secondary,
                  size: 6.w,
                ),
              ),
            ),
            title: Text(
              'Open in Google Maps',
              style: theme.textTheme.titleMedium,
            ),
            onTap: () {
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "Opening Google Maps...",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
          ),

          // Apple Maps option (iOS)
          ListTile(
            leading: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'navigation',
                  color: theme.colorScheme.secondary,
                  size: 6.w,
                ),
              ),
            ),
            title: Text(
              'Open in Apple Maps',
              style: theme.textTheme.titleMedium,
            ),
            onTap: () {
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "Opening Apple Maps...",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  void _handleRelatedDestinationTap(Map<String, dynamic> destination) {
    // Navigate to the same screen with new destination data
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/destination-detail-screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshDestination,
        child: _isLoading
            ? _buildLoadingSkeleton(theme)
            : CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Hero image header with parallax effect
            SliverAppBar(
              expandedHeight: 50.h,
              pinned: false,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: DestinationHeaderWidget(
                  images: (_destinationData["images"] as List)
                      .cast<Map<String, dynamic>>(),
                  onBack: () => Navigator.of(context).pop(),
                  onShare: _handleShare,
                  onFavorite: _handleFavorite,
                  isFavorite: _isFavorite,
                ),
              ),
            ),

            // Content sections
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2.h),

                  // Destination info
                  DestinationInfoWidget(
                    name: _destinationData["name"] as String,
                    location: _destinationData["location"] as String,
                    description:
                    _destinationData["description"] as String,
                  ),

                  SizedBox(height: 3.h),

                  // Add to playlist button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleAddToPlaylist,
                        icon: CustomIconWidget(
                          iconName: 'playlist_add',
                          color: theme.colorScheme.onPrimary,
                          size: 6.w,
                        ),
                        label: Text('Add to Playlist'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // Key highlights
                  HighlightsWidget(
                    highlights: (_destinationData["highlights"] as List)
                        .cast<Map<String, dynamic>>(),
                  ),

                  SizedBox(height: 4.h),

                  // Map preview
                  MapPreviewWidget(
                    latitude: _destinationData["latitude"] as double,
                    longitude: _destinationData["longitude"] as double,
                    locationName: _destinationData["name"] as String,
                    onNavigate: _handleNavigate,
                  ),

                  SizedBox(height: 4.h),

                  // Related destinations
                  RelatedDestinationsWidget(
                    destinations: _relatedDestinations,
                    onDestinationTap: _handleRelatedDestinationTap,
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 50.h,
          pinned: false,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(color: theme.colorScheme.surface),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(1.w),
                  ),
                ),
                SizedBox(height: 1.h),
                Container(
                  width: 40.w,
                  height: 2.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(1.w),
                  ),
                ),
                SizedBox(height: 3.h),
                ...List.generate(3, (index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Container(
                      width: double.infinity,
                      height: 2.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(1.w),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
