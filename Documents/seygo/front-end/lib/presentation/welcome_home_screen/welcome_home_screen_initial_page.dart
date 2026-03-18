import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../data/models/place.dart';
import '../../data/services/api_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/category_pill_widget.dart';
import './widgets/destination_card_widget.dart';
import './widgets/featured_carousel_widget.dart';
import './widgets/settings_drawer.dart';
import './widgets/notifications_panel.dart';

class WelcomeHomeScreenInitialPage extends StatefulWidget {
  const WelcomeHomeScreenInitialPage({super.key});

  @override
  State<WelcomeHomeScreenInitialPage> createState() =>
      _WelcomeHomeScreenInitialPageState();
}

class _WelcomeHomeScreenInitialPageState
    extends State<WelcomeHomeScreenInitialPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  List<Map<String, dynamic>> _playlists = [];
  bool _playlistsLoading = true;
  bool _placesLoading = true;

  List<Map<String, dynamic>> _featuredDestinations = [
    {
      "id": 1,
      "name": "Mirissa Beach",
      "googleUrl": "https://images.unsplash.com/photo-1667723385328-06489b979a88",
      "semanticLabel": "Aerial view of turquoise ocean waves meeting golden sandy beach",
      "category": "Beach Side",
    },
    {
      "id": 2,
      "name": "Sigiriya Rock",
      "googleUrl": "https://images.unsplash.com/photo-1683295657287-86c908b256f8",
      "semanticLabel": "Ancient rock fortress rising dramatically from green jungle",
      "category": "Mountains",
    },
    {
      "id": 3,
      "name": "Temple of Tooth",
      "googleUrl": "https://images.unsplash.com/photo-1562777578-3e432ed38f03",
      "semanticLabel": "Traditional Buddhist temple with ornate golden roof",
      "category": "Temples",
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {"id": "all", "name": "All", "icon": "apps"},
    {"id": "camping", "name": "Camping", "icon": "terrain"},
    {"id": "beach", "name": "Beach Side", "icon": "beach_access"},
    {"id": "mountains", "name": "Mountains", "icon": "landscape"},
    {"id": "temples", "name": "Temples", "icon": "account_balance"},
  ];

  // ignore: prefer_final_fields
  List<Map<String, dynamic>> _destinations = [
    {
      "id": 1,
      "name": "Ella",
      "googleUrl": "https://images.unsplash.com/photo-1677392988966-d730d8d506dc",
      "semanticLabel": "Lush green tea plantations covering rolling hills",
      "category": "Mountains",
    },
    {
      "id": 2,
      "name": "Kandy",
      "googleUrl": "https://images.unsplash.com/photo-1614758285266-d385e31826ca",
      "semanticLabel": "Sacred Buddhist temple complex with golden roofs",
      "category": "Temples",
    },
    {
      "id": 3,
      "name": "Jaffna",
      "googleUrl": "https://images.unsplash.com/photo-1704380755697-338169070234",
      "semanticLabel": "Pristine beach with crystal clear turquoise water",
      "category": "Beach Side",
    },
    {
      "id": 4,
      "name": "Yala National Park",
      "googleUrl": "https://images.unsplash.com/photo-1595653413391-b8bb647b8fba",
      "semanticLabel": "Wild safari landscape under golden sunset light",
      "category": "Camping",
    },
    {
      "id": 5,
      "name": "Arugam Bay",
      "googleUrl": "https://images.unsplash.com/photo-1665581362630-cd036ac8f1a5",
      "semanticLabel": "Tropical beach with palm trees and turquoise waves",
      "category": "Beach Side",
    },
    {
      "id": 6,
      "name": "Adam's Peak",
      "googleUrl": "https://images.unsplash.com/photo-1567336975218-31c977ee0a03",
      "semanticLabel": "Majestic mountain peak rising above clouds at sunrise",
      "category": "Mountains",
    },
  ];

  List<Map<String, dynamic>> get _filteredDestinations {
    if (_selectedCategory == 'All') {
      return _destinations;
    }
    return _destinations
        .where((dest) => dest['category'] == _selectedCategory)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final rows = await ApiService.fetchPlaces(accessToken: token);
      if (rows.isEmpty || !mounted) return;

      final mapped = rows
          .whereType<Map>()
          .map((row) {
            final r = Map<String, dynamic>.from(row);
            final name = (r['name'] ?? 'Unknown').toString();
            final category = _resolveCategory(r['primary_category'] ?? r['category']);
            final googleUrl = r['google_url']?.toString() ?? r['googleUrl']?.toString() ?? r['image_url']?.toString();
            final id = r['place_id'] ?? r['id'] ?? name;
            return {
              'id': id,
              'name': name,
              'category': category,
              'googleUrl': googleUrl,
              'google_url': googleUrl,
              'image_url': r['image_url'],
              'photo_public_urls': r['photo_public_urls'] ?? [],
              'imageSource': r['image_source'],
              'semanticLabel': 'Photo of $name',
              'description': (r['description'] ?? r['location'] ?? '').toString(),
              'latitude': r['latitude'],
              'longitude': r['longitude'],
              'rating': r['avg_rating'] ?? r['rating'] ?? 0.0,
              'reviews': r['review_count'] ?? 0,
              'location': (r['location'] ?? r['address'] ?? '').toString(),
            };
          })
          .toList();

      if (!mounted) return;
      setState(() {
        _destinations = List<Map<String, dynamic>>.from(mapped);
        _featuredDestinations = mapped.take(3).toList();
        _placesLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _placesLoading = false);
    }
  }

  String _resolveCategory(dynamic raw) {
    final s = (raw ?? '').toString().trim().toLowerCase();
    if (s.contains('beach') || s.contains('coast')) return 'Beach Side';
    if (s.contains('mountain') || s.contains('hill') || s.contains('peak')) return 'Mountains';
    if (s.contains('temple') || s.contains('religious') || s.contains('heritage')) return 'Temples';
    if (s.contains('camp') || s.contains('wild') || s.contains('park') || s.contains('forest')) return 'Camping';
    return raw?.toString() ?? 'Other';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken;
    final result = await ApiService.fetchPlaylists(accessToken: token);
    if (mounted) {
      setState(() {
        _playlists = result;
        _playlistsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: SettingsDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadPlaylists,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              toolbarHeight: 0,
              expandedHeight: 26.h,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.only(bottom: 1.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 1.h),

                          // Top Icons – opens drawer correctly
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Builder(
                                builder: (context) => IconButton(
                                  icon: const Icon(Icons.menu, size: 26),
                                  onPressed: () {
                                    _scaffoldKey.currentState?.openDrawer();
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_none,
                                  size: 26,
                                ),
                                tooltip: "Notifications",
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        DraggableScrollableSheet(
                                          initialChildSize: 0.65,
                                          minChildSize: 0.4,
                                          maxChildSize: 0.95,
                                          builder: (_, scrollController) {
                                            return NotificationsPanel();
                                          },
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),

                          SizedBox(height: 3.5.h), // reduced from 4.h
                          // Welcome text
                          Text(
                            "Welcome to SeyGo",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.65,
                              ),
                              height: 1.1,
                            ),
                          ),

                          SizedBox(height: 0.5.h),

                          Text(
                            "Let’s find a place for you !!!",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.2,
                            ),
                          ),

                          SizedBox(height: 2.5.h), // reduced from 3.h
                          // Modern Search Bar
                          SizedBox(
                            height: 6.2.h, // slightly reduced
                            child: Stack(
                              alignment: Alignment.centerRight,
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  height: 6.2.h,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(60),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.shadow,
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.only(
                                    left: 4.w,
                                    right: 14.w,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          onChanged: (_) => setState(() {}),
                                          decoration: InputDecoration(
                                            hintText: "Search...",
                                            hintStyle: theme
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.tune,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),

                                Positioned(
                                  right: 1.w,
                                  child: GestureDetector(
                                    onTap: () {
                                      final query = _searchController.text
                                          .trim();
                                      print("Search pressed: '$query'");
                                      // TODO: real search logic here
                                    },
                                    child: Container(
                                      width: 11.w,
                                      height: 11.w,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme
                                                .colorScheme
                                                .shadow
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.search,
                                        color: theme.colorScheme.onPrimary,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2.h),
                  FeaturedCarouselWidget(
                    destinations: _featuredDestinations,
                    onDestinationTap: (destination) {
                      Navigator.of(context, rootNavigator: true).pushNamed(
                        '/destination-detail-screen',
                        arguments: destination,
                      );
                    },
                  ),
                  SizedBox(height: 3.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Categories', style: theme.textTheme.titleLarge),
                      ],
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  SizedBox(
                    height: 5.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(width: 2.w),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return CategoryPillWidget(
                          name: category['name'] as String,
                          icon: category['icon'] as String,
                          isSelected: _selectedCategory == category['name'],
                          onTap: () {
                            setState(() {
                              _selectedCategory = category['name'] as String;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Destinations', style: theme.textTheme.titleLarge),
                      ],
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                ],
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 3.w,
                  mainAxisSpacing: 2.h,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final destination = _filteredDestinations[index];
                  return DestinationCardWidget(
                    place: Place.fromMap(destination),
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pushNamed(
                        '/destination-detail-screen',
                        arguments: destination,
                      );
                    },
                  );
                }, childCount: _filteredDestinations.length),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 3.h)),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Playlists', style: theme.textTheme.titleLarge),
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamed('/playlists-screen');
                      },
                      child: Text(
                        'See all',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: _buildPlaylistCarousel(theme)),

            SliverToBoxAdapter(child: SizedBox(height: 4.h)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCarousel(ThemeData theme) {
    if (_playlistsLoading) {
      return SizedBox(
        height: 14.h,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (_playlists.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Text(
          'No playlists yet. Tap "See all" to create one.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return SizedBox(
      height: 14.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _playlists.length,
        separatorBuilder: (_, _) => SizedBox(width: 3.w),
        itemBuilder: (context, index) {
          final playlist = _playlists[index];
          final name = playlist['name'] as String? ?? 'Playlist';
          final icon = playlist['icon'] as String? ?? 'playlist_play';
          final count = playlist['destination_count'] as int? ?? 0;

          return GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true)
                .pushNamed('/playlists-screen'),
            child: Container(
              width: 38.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(3.w),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    child: CustomIconWidget(
                      iconName: icon,
                      color: theme.colorScheme.primary,
                      size: 5.w,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$count place${count == 1 ? '' : 's'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}

