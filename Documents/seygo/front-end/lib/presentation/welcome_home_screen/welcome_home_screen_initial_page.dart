import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/place.dart';
import '../../data/services/api_service.dart';
import '../../data/services/offline_trip_service.dart';
import '../../providers/places_provider.dart';
import '../../providers/user_data_provider.dart';
import '../../routes/app_routes.dart';
import './widgets/category_pill_widget.dart';
import './widgets/destination_card_widget.dart';
import './widgets/featured_carousel_widget.dart';
import './widgets/notifications_panel.dart';
import './widgets/settings_drawer.dart';

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
  bool _hasOfflineTrips = false;

  List<Map<String, dynamic>> _featuredDestinations = [
    {
      "id": 1,
      "name": "Mirissa Beach",
      "googleUrl":
          "https://images.unsplash.com/photo-1667723385328-06489b979a88",
      "semanticLabel":
          "Aerial view of turquoise ocean waves meeting golden sandy beach with palm trees along the coastline",
      "category": "Beach Side",
    },
    {
      "id": 2,
      "name": "Sigiriya Rock",
      "googleUrl":
          "https://images.unsplash.com/photo-1683295657287-86c908b256f8",
      "semanticLabel":
          "Ancient rock fortress rising dramatically from green jungle landscape under blue sky",
      "category": "Mountains",
    },
    {
      "id": 3,
      "name": "Temple of Tooth",
      "googleUrl":
          "https://images.unsplash.com/photo-1562777578-3e432ed38f03",
      "semanticLabel":
          "Traditional Buddhist temple with white walls and ornate golden roof against clear sky",
      "category": "Temples",
    },
  ];

  List<Map<String, dynamic>> _destinations = [
    {
      "id": 1,
      "name": "Ella",
      "googleUrl":
          "https://images.unsplash.com/photo-1677392988966-d730d8d506dc",
      "semanticLabel":
          "Lush green tea plantations covering rolling hills with misty mountain peaks in background",
      "category": "Mountains",
    },
    {
      "id": 2,
      "name": "Kandy",
      "googleUrl":
          "https://images.unsplash.com/photo-1614758285266-d385e31826ca",
      "semanticLabel":
          "Sacred Buddhist temple complex with white buildings and golden roofs surrounded by tropical trees",
      "category": "Temples",
    },
    {
      "id": 3,
      "name": "Jaffna",
      "googleUrl":
          "https://images.unsplash.com/photo-1704380755697-338169070234",
      "semanticLabel":
          "Pristine beach with crystal clear turquoise water and white sand under bright sunny sky",
      "category": "Beach Side",
    },
    {
      "id": 4,
      "name": "Yala National Park",
      "googleUrl":
          "https://images.unsplash.com/photo-1595653413391-b8bb647b8fba",
      "semanticLabel":
          "Wild safari landscape with acacia trees and grasslands under golden sunset light",
      "category": "Camping",
    },
    {
      "id": 5,
      "name": "Arugam Bay",
      "googleUrl":
          "https://images.unsplash.com/photo-1665581362630-cd036ac8f1a5",
      "semanticLabel":
          "Tropical beach with palm trees bending over turquoise waves perfect for surfing",
      "category": "Beach Side",
    },
    {
      "id": 6,
      "name": "Adam's Peak",
      "googleUrl":
          "https://images.unsplash.com/photo-1567336975218-31c977ee0a03",
      "semanticLabel":
          "Majestic mountain peak rising above clouds during sunrise with pilgrimage path visible",
      "category": "Mountains",
    },
  ];

  List<String> _dynamicCategories = [];
  bool _initialized = false;

  // Limit the home page grid to 10 destinations for a curated feel
  static const int _homeDestinationLimit = 10;

  List<Map<String, dynamic>> get _filteredDestinations {
    final all = _selectedCategory == 'All'
        ? _destinations
        : _destinations.where((d) {
            final cat =
                (d['category'] ?? d['primary_category'] ?? '').toString();
            return cat == _selectedCategory;
          }).toList();
    return all.take(_homeDestinationLimit).toList();
  }

  List<Map<String, dynamic>> get _displayCategories {
    final base = <Map<String, dynamic>>[
      {"name": "All", "icon": "apps"},
    ];
    final cats = _dynamicCategories.isNotEmpty
        ? _dynamicCategories
        : ["Camping", "Beach Side", "Mountains", "Temples"];
    base.addAll(cats.map((c) => {"name": c, "icon": _iconForCategory(c)}));
    return base;
  }

  String _iconForCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('beach') || c.contains('coast')) { return 'beach_access'; }
    if (c.contains('mountain') || c.contains('hill')) { return 'landscape'; }
    if (c.contains('temple') || c.contains('religious') || c.contains('sacred')) {
      return 'account_balance';
    }
    if (c.contains('camp') || c.contains('wildlife') || c.contains('national')) {
      return 'terrain';
    }
    if (c.contains('ancient') || c.contains('heritage') || c.contains('historic')) {
      return 'castle';
    }
    if (c.contains('bird') || c.contains('nature')) { return 'forest'; }
    if (c.contains('water') || c.contains('fall') || c.contains('river')) {
      return 'water';
    }
    if (c.contains('city') || c.contains('town') || c.contains('urban')) {
      return 'location_city';
    }
    return 'place';
  }

  @override
  void initState() {
    super.initState();
    _checkOfflineTrips();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadPlacesFromProvider();
      _loadPlaylistsFromProvider();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── data loading ─────────────────────────────────────────────────────────────

  Future<void> _loadPlacesFromProvider() async {
    final provider = Provider.of<PlacesProvider>(context, listen: false);

    List<dynamic> rows;
    if (provider.isLoaded && provider.rawRows.isNotEmpty) {
      rows = provider.rawRows;
    } else {
      try {
        rows = await ApiService.fetchPlaces(limit: 60, offset: 0);
      } catch (_) {
        return;
      }
    }

    if (!mounted) return;
    final places = rows
        .whereType<Map>()
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
    if (places.isEmpty) return;

    final catSet = <String>{};
    for (final p in places) {
      final cat =
          (p['category'] ?? p['primary_category'] ?? '').toString().trim();
      if (cat.isNotEmpty && cat != 'unknown') catSet.add(cat);
    }
    final withPhoto = places
        .where((p) {
          final url = (p['photo_url'] ?? p['image_url'] ?? '').toString();
          return url.startsWith('http');
        })
        .take(6)
        .toList();

    setState(() {
      if (withPhoto.isNotEmpty) _featuredDestinations = withPhoto;
      _destinations = places;
      _dynamicCategories = catSet.take(8).toList();
    });
  }

  Future<void> _checkOfflineTrips() async {
    final has = await OfflineTripService.hasOfflineTrip();
    if (!mounted) return;
    setState(() => _hasOfflineTrips = has);
  }

  Future<void> _loadPlaylistsFromProvider({bool forceRefresh = false}) async {
    final udp = Provider.of<UserDataProvider>(context, listen: false);
    if (!forceRefresh && udp.featuredPlaylistsLoaded) {
      if (mounted) {
        setState(() {
          _playlists = udp.featuredPlaylists;
          _playlistsLoading = false;
        });
      }
      return;
    }
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final result = await ApiService.fetchPlaylists(accessToken: token);
    if (mounted) {
      setState(() {
        _playlists = result;
        _playlistsLoading = false;
      });
    }
  }

  Future<void> _loadPlaylists() => _loadPlaylistsFromProvider(forceRefresh: true);

  // ── navigation ───────────────────────────────────────────────────────────────

  void _openOfflineTrips() {
    Navigator.of(context, rootNavigator: true)
        .pushNamed(AppRoutes.offlineTrips)
        .then((_) => _checkOfflineTrips()); // refresh badge after returning
  }

  void _openSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.mapView,
      arguments: {'query': query},
    );
  }

  void _openMapDestinationList() {
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.mapView,
      arguments: {'showList': true},
    );
  }

  // ── build ────────────────────────────────────────────────────────────────────

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
            // ── Top App Bar (pinned, no collapse) ───────────────────────────
            SliverAppBar(
              pinned: true,
              floating: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              toolbarHeight: 7.h,
              automaticallyImplyLeading: false,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu, size: 26),
                      onPressed: () =>
                          _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, size: 26),
                    tooltip: 'Notifications',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => DraggableScrollableSheet(
                          initialChildSize: 0.65,
                          minChildSize: 0.4,
                          maxChildSize: 0.95,
                          builder: (_, scrollController) =>
                              NotificationsPanel(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Greeting + Search (non-collapsing, in body) ─────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 0.5.h, 4.w, 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to SeyGo',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: theme.colorScheme.onSurface.withOpacity(0.65),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      "Let's find a place for you!",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 2.5.h),
                    _buildSearchBar(theme),
                  ],
                ),
              ),
            ),

            // ── Offline trips banner ─────────────────────────────────────────
            if (_hasOfflineTrips)
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: _openOfflineTrips,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 1.h),
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.w, vertical: 1.4.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.offline_bolt_outlined,
                            color: theme.colorScheme.primary, size: 22),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            'You have saved offline trips — tap to view',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Featured carousel ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 1.h),
                  FeaturedCarouselWidget(
                    destinations: _featuredDestinations,
                    onDestinationTap: (destination) {
                      Navigator.of(context, rootNavigator: true).pushNamed(
                        AppRoutes.destinationDetail,
                        arguments: destination,
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Categories ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.5.h),
                child: Text('Categories',
                    style: theme.textTheme.titleLarge),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 5.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: _displayCategories.length,
                  separatorBuilder: (_, _) => SizedBox(width: 2.w),
                  itemBuilder: (context, index) {
                    final category = _displayCategories[index];
                    return CategoryPillWidget(
                      name: category['name'] as String,
                      icon: category['icon'] as String,
                      isSelected:
                          _selectedCategory == category['name'],
                      onTap: () => setState(() =>
                          _selectedCategory = category['name'] as String),
                    );
                  },
                ),
              ),
            ),

            // ── Destinations header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Destinations',
                        style: theme.textTheme.titleLarge),
                  ],
                ),
              ),
            ),

            // ── Destination grid (max 10) ────────────────────────────────────
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 3.w,
                  mainAxisSpacing: 2.h,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final destination = _filteredDestinations[index];
                    return DestinationCardWidget(
                      place: Place.fromMap(destination),
                      onTap: () {
                        Navigator.of(context, rootNavigator: true)
                            .pushNamed(
                          AppRoutes.destinationDetail,
                          arguments: destination,
                        );
                      },
                    );
                  },
                  childCount: _filteredDestinations.length,
                ),
              ),
            ),

            // ── See More button ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 0),
                child: _buildSeeMoreButton(theme),
              ),
            ),

            // ── Playlists header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 3.5.h, 4.w, 1.5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Playlists',
                        style: theme.textTheme.titleLarge),
                    TextButton(
                      onPressed: () => Navigator.of(context,
                              rootNavigator: true)
                          .pushNamed(AppRoutes.playlists),
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

  // ── Search bar (no filter/tune icon) ─────────────────────────────────────────

  Widget _buildSearchBar(ThemeData theme) {
    return SizedBox(
      height: 6.5.h,
      child: Stack(
        alignment: Alignment.centerRight,
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 6.5.h,
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
            padding: EdgeInsets.only(left: 5.w, right: 15.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _openSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search destinations...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0.8.w,
            child: GestureDetector(
              onTap: _openSearch,
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          theme.colorScheme.shadow.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.search,
                    color: theme.colorScheme.onPrimary, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── See More button ───────────────────────────────────────────────────────────

  Widget _buildSeeMoreButton(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: _openMapDestinationList,
      icon: const Icon(Icons.map_outlined, size: 18),
      label: const Text('See More Destinations'),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 6.h),
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.45),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Playlist carousel ─────────────────────────────────────────────────────────

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
          final count = playlist['destination_count'] as int? ?? 0;

          return GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true)
                .pushNamed(AppRoutes.playlists),
            child: Container(
              width: 38.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(3.w),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow
                        .withValues(alpha: 0.06),
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
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    child: Icon(
                      Icons.playlist_play_rounded,
                      color: theme.colorScheme.primary,
                      size: 5.w,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style:
                            theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$count place${count == 1 ? '' : 's'}',
                        style:
                            theme.textTheme.labelSmall?.copyWith(
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
