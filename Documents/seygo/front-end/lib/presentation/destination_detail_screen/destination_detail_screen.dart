import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../data/services/api_service.dart';
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
  bool _didLoadArguments = false;
  bool _isLoadingRelated = false;
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic> _destinationData = {
    "id": 1,
    "name": "Ella",
    "location": "Badulla District, Uva Province, Sri Lanka",
    "description":
    "Ella is a small town in the Badulla District of Uva Province, Sri Lanka governed by an Urban Council. It is approximately 200 km east of Colombo and is situated at an elevation of 1,041 m above sea level. The area has a rich bio-diversity, dense with numerous varieties of flora and fauna. Ella is surrounded by the beautiful Ella Rocks and Ravana Falls, making it a perfect destination for nature lovers and adventure seekers.",
    "latitude": 6.8667,
    "longitude": 81.0467,
    "images": [
      {
        "googleUrl":
        "https://images.unsplash.com/photo-1522496884773-12ab0d24738e",
        "semanticLabel":
        "Scenic view of Ella town nestled in lush green mountains with tea plantations and misty valleys",
      },
      {
        "googleUrl":
        "https://images.unsplash.com/photo-1519576325797-91124298a877",
        "semanticLabel":
        "Nine Arch Bridge in Ella surrounded by dense tropical forest and tea estates",
      },
      {
        "googleUrl":
        "https://images.unsplash.com/photo-1707929592353-95578ba630f5",
        "semanticLabel":
        "Panoramic mountain landscape view from Ella Rock with rolling hills and valleys",
      },
      {
        "googleUrl":
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

  List<Map<String, dynamic>> _relatedDestinations = [
    {
      "id": 2,
      "name": "Kandy",
      "location": "Central Province, Sri Lanka",
      "googleUrl":
      "https://img.rocket.new/generatedImages/rocket_gen_img_193f33a5e-1766335454247.png",
      "semanticLabel":
      "Temple of the Sacred Tooth Relic in Kandy with traditional architecture and lake view",
    },
    {
      "id": 3,
      "name": "Jaffna",
      "location": "Northern Province, Sri Lanka",
      "googleUrl":
      "https://img.rocket.new/generatedImages/rocket_gen_img_1b20076d0-1768674030531.png",
      "semanticLabel":
      "Jaffna Fort colonial architecture with palm trees and coastal backdrop",
    },
    {
      "id": 4,
      "name": "Sigiriya",
      "location": "Matale District, Central Province",
      "googleUrl":
      "https://img.rocket.new/generatedImages/rocket_gen_img_13818a0b1-1765084352309.png",
      "semanticLabel":
      "Ancient Sigiriya Rock Fortress rising from jungle landscape at sunset",
    },
    {
      "id": 5,
      "name": "Galle",
      "location": "Southern Province, Sri Lanka",
      "googleUrl":
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadArguments) {
      return;
    }

    final arguments = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic>? destination;
    List<Map<String, dynamic>>? allDestinations;

    if (arguments is Map<String, dynamic>) {
      final rawDestination = arguments['destination'];
      if (rawDestination is Map) {
        destination = Map<String, dynamic>.from(rawDestination);
      } else {
        destination = Map<String, dynamic>.from(arguments);
      }

      final rawAllDestinations = arguments['allDestinations'];
      if (rawAllDestinations is List) {
        allDestinations = rawAllDestinations
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    if (destination != null) {
      _destinationData = _buildDestinationData(destination);
      if (allDestinations != null && allDestinations.isNotEmpty) {
        _relatedDestinations = allDestinations
            .where((item) => item['id'] != destination!['id'])
            .take(6)
            .map(_buildRelatedDestination)
            .toList();
      } else {
        // Fetch real related places from backend after frame is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchRelatedPlaces();
        });
      }
    }

    _didLoadArguments = true;
  }

  Future<void> _fetchRelatedPlaces() async {
    final category = (_destinationData['category'] ?? '').toString().trim();
    final district = (_destinationData['district'] ?? '').toString().trim();
    final currentId = _destinationData['id']?.toString() ?? '';

    if (!mounted) return;
    setState(() => _isLoadingRelated = true);

    try {
      List<dynamic> rows = [];

      // 1st try: search by category
      if (category.isNotEmpty && category != 'unknown') {
        rows = await ApiService.searchPlacesFromDb(query: category, limit: 8);
      }

      // 2nd try: search by district if not enough results
      if (rows.length < 3 && district.isNotEmpty) {
        final more = await ApiService.searchPlacesFromDb(query: district, limit: 8);
        rows = [...rows, ...more];
      }

      // 3rd fallback: just fetch next batch of places
      if (rows.length < 3) {
        rows = await ApiService.fetchPlaces(limit: 12, offset: 0);
      }

      if (!mounted) return;

      final related = rows
          .whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r))
          .where((r) => r['id']?.toString() != currentId &&
              r['place_id']?.toString() != currentId)
          .take(6)
          .map(_buildRelatedDestination)
          .toList();

      setState(() {
        if (related.isNotEmpty) _relatedDestinations = related;
        _isLoadingRelated = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingRelated = false);
    }
  }

  Map<String, dynamic> _buildDestinationData(Map<String, dynamic> destination) {
    final googleUrl = (destination['googleUrl'] ?? destination['google_url'])?.toString();
    final photoUrl = (destination['imageUrl'] ?? destination['image_url'] ?? destination['photo_url'] ?? googleUrl)?.toString();
    return {
      'id': destination['id'],
      'name': destination['name'] ?? 'Unknown Place',
      'location': destination['location'] ?? destination['formatted_address'] ?? destination['address'] ?? 'Sri Lanka',
      'description': destination['description'] ?? 'No description available.',
      'latitude': _toDouble(destination['latitude']) ?? 7.8731,
      'longitude': _toDouble(destination['longitude']) ?? 80.7718,
      'images': [
        {
          'googleUrl': photoUrl,
          'semanticLabel': destination['semanticLabel'] ?? destination['name'] ?? 'Place photo',
        },
      ],
      'highlights': _buildHighlights(destination),
      'rating': _toDouble(destination['rating'] ?? destination['avg_rating']) ?? 0.0,
      'reviews': destination['reviews'] is num ? (destination['reviews'] as num).toInt()
          : destination['review_count'] is num ? (destination['review_count'] as num).toInt() : 0,
      'phone': destination['phone']?.toString(),
      'website': destination['website']?.toString(),
      'opening_hours': destination['opening_hours'],
      'category': destination['category']?.toString(),
      'tags': destination['tags'],
      // Rich fields
      'district': destination['district']?.toString(),
      'city': destination['city']?.toString(),
      'subcategory': destination['subcategory']?.toString(),
      'price_level': destination['price_level']?.toString(),
      'ai_description': destination['ai_description']?.toString(),
      'safety_tips': destination['safety_tips']?.toString(),
      'crowd_level': destination['crowd_level']?.toString(),
      'best_for': destination['best_for']?.toString(),
      'avoid_if': destination['avoid_if']?.toString(),
      'hidden_gem': destination['hidden_gem'],
      'instagram_worthy': destination['instagram_worthy'],
      'photo_tip': destination['photo_tip']?.toString(),
      'best_time_of_day': destination['best_time_of_day']?.toString(),
      'best_months': destination['best_months']?.toString(),
      'avoid_months': destination['avoid_months']?.toString(),
      'visit_duration_minutes': destination['visit_duration_minutes'],
      'budget_level': destination['budget_level']?.toString(),
      'estimated_cost_usd': destination['estimated_cost_usd']?.toString(),
      'transport_options': destination['transport_options']?.toString(),
      'parking_available': destination['parking_available'],
      'fun_fact': destination['fun_fact']?.toString(),
      'bucket_list_score': destination['bucket_list_score'],
      'wheelchair_accessible': destination['wheelchair_accessible'],
      'child_friendly': destination['child_friendly'],
      'senior_friendly': destination['senior_friendly'],
    };
  }

  List<Map<String, dynamic>> _buildHighlights(Map<String, dynamic> destination) {
    // Try to build highlights from real tags/categories
    final rawTags = destination['tags'];
    final rawCategories = destination['categories'];
    final List<String> tags = [];
    if (rawTags is List) {
      tags.addAll(rawTags.map((t) => t.toString()));
    } else if (rawTags is String && rawTags.isNotEmpty) {
      tags.addAll(rawTags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty));
    }
    if (rawCategories is List) {
      for (final c in rawCategories) {
        final s = c.toString();
        if (!tags.contains(s)) tags.add(s);
      }
    }

    if (tags.isNotEmpty) {
      return tags.take(6).map((tag) {
        return {
          'icon': _iconForTag(tag),
          'title': tag,
          'description': '',
        };
      }).toList();
    }

    // Fallback: single category card
    final cat = destination['category']?.toString() ?? '';
    if (cat.isNotEmpty) {
      return [{'icon': _iconForTag(cat), 'title': cat, 'description': ''}];
    }
    return [];
  }

  String _iconForTag(String tag) {
    final t = tag.toLowerCase();
    if (t.contains('beach') || t.contains('coast') || t.contains('sea')) return 'beach_access';
    if (t.contains('mountain') || t.contains('hill') || t.contains('hik')) return 'landscape';
    if (t.contains('temple') || t.contains('cultural') || t.contains('heritage')) return 'account_balance';
    if (t.contains('water') || t.contains('fall') || t.contains('river') || t.contains('lake')) return 'water';
    if (t.contains('camp')) return 'camping';
    if (t.contains('hotel') || t.contains('resort') || t.contains('stay')) return 'hotel';
    if (t.contains('food') || t.contains('restaurant') || t.contains('cafe')) return 'local_cafe';
    if (t.contains('wildlife') || t.contains('safari') || t.contains('park') || t.contains('national')) return 'forest';
    if (t.contains('train') || t.contains('rail')) return 'train';
    if (t.contains('fort') || t.contains('ancient') || t.contains('ruins')) return 'castle';
    if (t.contains('tea') || t.contains('plantation')) return 'eco';
    if (t.contains('dive') || t.contains('snorkel') || t.contains('surf')) return 'pool';
    if (t.contains('city') || t.contains('town') || t.contains('urban')) return 'location_city';
    if (t.contains('view') || t.contains('scenic') || t.contains('panoram')) return 'wb_sunny';
    return 'place';
  }

  Map<String, dynamic> _buildRelatedDestination(Map<String, dynamic> destination) {
    final photoUrl = (destination['imageUrl'] ?? destination['image_url'] ??
        destination['photo_url'] ?? destination['googleUrl'] ??
        destination['google_url'])?.toString();
    return {
      'id': destination['id'] ?? destination['place_id'],
      'name': destination['name'] ?? 'Unknown Place',
      'location': destination['location'] ?? destination['city'] ??
          destination['district'] ?? destination['address'] ?? 'Sri Lanka',
      'googleUrl': photoUrl,
      'imageUrl': photoUrl,
      'image_url': destination['image_url'] ?? destination['photo_url'],
      'photo_url': destination['photo_url'],
      'category': destination['category'] ?? destination['primary_category'],
      'rating': destination['avg_rating'] ?? destination['rating'],
      'semanticLabel': destination['semanticLabel'] ?? destination['name'] ?? 'Place photo',
    };
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
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
            onTap: () async {
              Navigator.pop(context);
              // Google Maps: directions to destination
              final uri = Uri.parse(
                'https://www.google.com/maps/dir/?api=1'
                '&destination=$lat,$lng'
                '&travelmode=driving',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                Fluttertoast.showToast(
                  msg: 'Google Maps is not installed',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              }
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
            onTap: () async {
              Navigator.pop(context);
              // Apple Maps: directions to destination
              final uri = Uri.parse(
                'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                Fluttertoast.showToast(
                  msg: 'Apple Maps is not available on this device',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              }
            },
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  void _handleRelatedDestinationTap(Map<String, dynamic> destination) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/destination-detail-screen',
      arguments: {'destination': destination},
    );
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
                    description: _destinationData["description"] as String,
                    rating: (_destinationData["rating"] as num?)?.toDouble() ?? 0.0,
                    reviews: (_destinationData["reviews"] as num?)?.toInt() ?? 0,
                    phone: _destinationData["phone"] as String?,
                    website: _destinationData["website"] as String?,
                    openingHours: _destinationData["opening_hours"],
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

                  // Key highlights (only when data available)
                  if ((_destinationData["highlights"] as List).isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    HighlightsWidget(
                      highlights: (_destinationData["highlights"] as List)
                          .cast<Map<String, dynamic>>(),
                    ),
                  ],

                  // Badges row (hidden gem / instagram worthy / bucket list)
                  if (_hasBadges()) ...[
                    SizedBox(height: 3.h),
                    _buildBadgesSection(theme),
                  ],

                  // Visit planning section
                  if (_hasVisitPlanningData()) ...[
                    SizedBox(height: 3.h),
                    _buildSectionHeader('Visit Planning', 'calendar_today', theme),
                    SizedBox(height: 1.5.h),
                    _buildVisitPlanningSection(theme),
                  ],

                  // Tips & Insights section
                  if (_hasTipsData()) ...[
                    SizedBox(height: 3.h),
                    _buildSectionHeader('Tips & Insights', 'lightbulb', theme),
                    SizedBox(height: 1.5.h),
                    _buildTipsSection(theme),
                  ],

                  // Accessibility & Family section
                  if (_hasAccessibilityData()) ...[
                    SizedBox(height: 3.h),
                    _buildSectionHeader('Accessibility & Family', 'accessibility', theme),
                    SizedBox(height: 1.5.h),
                    _buildAccessibilitySection(theme),
                  ],

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
                  if (_isLoadingRelated)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Related Destinations', style: theme.textTheme.titleLarge),
                          SizedBox(height: 2.h),
                          const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                    )
                  else if (_relatedDestinations.isNotEmpty)
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

  // ── helpers for conditional sections ──────────────────────────────────────

  bool _isTrue(dynamic v) => v == true;
  bool _notEmpty(String? s) => s != null && s.trim().isNotEmpty;

  bool _hasBadges() =>
      _isTrue(_destinationData['hidden_gem']) ||
      _isTrue(_destinationData['instagram_worthy']) ||
      (_destinationData['bucket_list_score'] != null);

  bool _hasVisitPlanningData() =>
      _notEmpty(_destinationData['crowd_level']) ||
      _notEmpty(_destinationData['best_time_of_day']) ||
      _notEmpty(_destinationData['best_months']) ||
      _notEmpty(_destinationData['avoid_months']) ||
      _destinationData['visit_duration_minutes'] != null ||
      _notEmpty(_destinationData['budget_level']) ||
      _notEmpty(_destinationData['estimated_cost_usd']) ||
      _notEmpty(_destinationData['transport_options']) ||
      _destinationData['parking_available'] != null ||
      _notEmpty(_destinationData['price_level']);

  bool _hasTipsData() =>
      _notEmpty(_destinationData['safety_tips']) ||
      _notEmpty(_destinationData['best_for']) ||
      _notEmpty(_destinationData['avoid_if']) ||
      _notEmpty(_destinationData['photo_tip']) ||
      _notEmpty(_destinationData['fun_fact']) ||
      _notEmpty(_destinationData['ai_description']);

  bool _hasAccessibilityData() =>
      _destinationData['wheelchair_accessible'] != null ||
      _destinationData['child_friendly'] != null ||
      _destinationData['senior_friendly'] != null;

  // ── section builders ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, String icon, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          CustomIconWidget(iconName: icon, color: theme.colorScheme.primary, size: 5.w),
          SizedBox(width: 2.w),
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(ThemeData theme) {
    final badges = <Widget>[];
    if (_isTrue(_destinationData['hidden_gem']))
      badges.add(_badge('Hidden Gem', Icons.diamond, const Color(0xFF9C27B0), theme));
    if (_isTrue(_destinationData['instagram_worthy']))
      badges.add(_badge('Instagram Worthy', Icons.camera_alt, const Color(0xFFE91E63), theme));
    final score = _destinationData['bucket_list_score'];
    if (score != null)
      badges.add(_badge('Bucket List $score/100', Icons.star, const Color(0xFFFF9800), theme));
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Wrap(spacing: 2.w, runSpacing: 1.h, children: badges),
    );
  }

  Widget _badge(String label, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 4.w, color: color),
        SizedBox(width: 1.5.w),
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildVisitPlanningSection(ThemeData theme) {
    final items = <Widget>[];
    final d = _destinationData;
    if (_notEmpty(d['visit_duration_minutes']?.toString()) || d['visit_duration_minutes'] != null) {
      final mins = d['visit_duration_minutes'];
      if (mins != null) {
        final h = (mins as num).toInt();
        final label = h >= 60 ? '${h ~/ 60}h ${h % 60}min' : '${h}min';
        items.add(_infoTile(Icons.schedule, 'Visit Duration', label, theme));
      }
    }
    if (_notEmpty(d['crowd_level']))
      items.add(_infoTile(Icons.people, 'Crowd Level', d['crowd_level']!, theme));
    if (_notEmpty(d['best_time_of_day']))
      items.add(_infoTile(Icons.wb_sunny, 'Best Time of Day', d['best_time_of_day']!, theme));
    if (_notEmpty(d['best_months']))
      items.add(_infoTile(Icons.calendar_month, 'Best Months', d['best_months']!, theme));
    if (_notEmpty(d['avoid_months']))
      items.add(_infoTile(Icons.event_busy, 'Avoid Months', d['avoid_months']!, theme));
    if (_notEmpty(d['price_level']))
      items.add(_infoTile(Icons.attach_money, 'Price Level', d['price_level']!, theme));
    if (_notEmpty(d['budget_level']))
      items.add(_infoTile(Icons.account_balance_wallet, 'Budget', d['budget_level']!, theme));
    if (_notEmpty(d['estimated_cost_usd']))
      items.add(_infoTile(Icons.payments, 'Est. Cost', '\$${d['estimated_cost_usd']}', theme));
    if (_notEmpty(d['transport_options']))
      items.add(_infoTile(Icons.directions_bus, 'Transport', d['transport_options']!, theme));
    if (d['parking_available'] != null)
      items.add(_infoTile(Icons.local_parking, 'Parking',
          d['parking_available'] == true ? 'Available' : 'Not Available', theme));
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(children: items),
    );
  }

  Widget _buildTipsSection(ThemeData theme) {
    final items = <Widget>[];
    final d = _destinationData;
    if (_notEmpty(d['ai_description']))
      items.add(_tipCard(Icons.auto_awesome, 'AI Summary', d['ai_description']!, const Color(0xFF2196F3), theme));
    if (_notEmpty(d['best_for']))
      items.add(_tipCard(Icons.thumb_up, 'Best For', d['best_for']!, const Color(0xFF4CAF50), theme));
    if (_notEmpty(d['avoid_if']))
      items.add(_tipCard(Icons.info_outline, 'Avoid If', d['avoid_if']!, const Color(0xFFFF9800), theme));
    if (_notEmpty(d['safety_tips']))
      items.add(_tipCard(Icons.health_and_safety, 'Safety Tips', d['safety_tips']!, const Color(0xFFE53935), theme));
    if (_notEmpty(d['photo_tip']))
      items.add(_tipCard(Icons.photo_camera, 'Photo Tip', d['photo_tip']!, const Color(0xFF9C27B0), theme));
    if (_notEmpty(d['fun_fact']))
      items.add(_tipCard(Icons.lightbulb, 'Fun Fact', d['fun_fact']!, const Color(0xFFFF9800), theme));
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(children: items),
    );
  }

  Widget _buildAccessibilitySection(ThemeData theme) {
    final d = _destinationData;
    final chips = <Widget>[];
    void addChip(String label, IconData icon, dynamic val) {
      if (val == null) return;
      final yes = val == true;
      chips.add(_accessChip(label, icon, yes, theme));
    }
    addChip('Wheelchair Access', Icons.accessible, d['wheelchair_accessible']);
    addChip('Child Friendly', Icons.child_care, d['child_friendly']);
    addChip('Senior Friendly', Icons.elderly, d['senior_friendly']);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Wrap(spacing: 2.w, runSpacing: 1.h, children: chips),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.h),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 4.5.w, color: theme.colorScheme.secondary),
        SizedBox(width: 3.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          SizedBox(height: 0.3.h),
          Text(value, style: theme.textTheme.bodyMedium),
        ])),
      ]),
    );
  }

  Widget _tipCard(IconData icon, String label, String value, Color color, ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 5.w, color: color),
        SizedBox(width: 3.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(
              color: color, fontWeight: FontWeight.w700)),
          SizedBox(height: 0.4.h),
          Text(value, style: theme.textTheme.bodyMedium),
        ])),
      ]),
    );
  }

  Widget _accessChip(String label, IconData icon, bool yes, ThemeData theme) {
    final color = yes ? const Color(0xFF4CAF50) : theme.colorScheme.onSurfaceVariant.withOpacity(0.4);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: yes ? const Color(0xFF4CAF50).withOpacity(0.1) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 4.w, color: color),
        SizedBox(width: 1.5.w),
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
        SizedBox(width: 1.w),
        Icon(yes ? Icons.check_circle : Icons.cancel, size: 3.5.w, color: color),
      ]),
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
