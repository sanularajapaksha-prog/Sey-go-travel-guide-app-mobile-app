import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _featuredDestinations = [
    {
      "id": 1,
      "name": "Mirissa Beach",
      "image": "https://images.unsplash.com/photo-1667723385328-06489b979a88",
      "semanticLabel":
          "Aerial view of turquoise ocean waves meeting golden sandy beach with palm trees along the coastline",
      "category": "Beach Side",
    },
    {
      "id": 2,
      "name": "Sigiriya Rock",
      "image": "https://images.unsplash.com/photo-1683295657287-86c908b256f8",
      "semanticLabel":
          "Ancient rock fortress rising dramatically from green jungle landscape under blue sky",
      "category": "Mountains",
    },
    {
      "id": 3,
      "name": "Temple of Tooth",
      "image": "https://images.unsplash.com/photo-1562777578-3e432ed38f03",
      "semanticLabel":
          "Traditional Buddhist temple with white walls and ornate golden roof against clear sky",
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

  final List<Map<String, dynamic>> _destinations = [
    {
      "id": 1,
      "name": "Ella",
      "image": "https://images.unsplash.com/photo-1677392988966-d730d8d506dc",
      "semanticLabel":
          "Lush green tea plantations covering rolling hills with misty mountain peaks in background",
      "category": "Mountains",
    },
    {
      "id": 2,
      "name": "Kandy",
      "image": "https://images.unsplash.com/photo-1614758285266-d385e31826ca",
      "semanticLabel":
          "Sacred Buddhist temple complex with white buildings and golden roofs surrounded by tropical trees",
      "category": "Temples",
    },
    {
      "id": 3,
      "name": "Jaffna",
      "image": "https://images.unsplash.com/photo-1704380755697-338169070234",
      "semanticLabel":
          "Pristine beach with crystal clear turquoise water and white sand under bright sunny sky",
      "category": "Beach Side",
    },
    {
      "id": 4,
      "name": "Yala National Park",
      "image": "https://images.unsplash.com/photo-1595653413391-b8bb647b8fba",
      "semanticLabel":
          "Wild safari landscape with acacia trees and grasslands under golden sunset light",
      "category": "Camping",
    },
    {
      "id": 5,
      "name": "Arugam Bay",
      "image": "https://images.unsplash.com/photo-1665581362630-cd036ac8f1a5",
      "semanticLabel":
          "Tropical beach with palm trees bending over turquoise waves perfect for surfing",
      "category": "Beach Side",
    },
    {
      "id": 6,
      "name": "Adam's Peak",
      "image": "https://images.unsplash.com/photo-1567336975218-31c977ee0a03",
      "semanticLabel":
          "Majestic mountain peak rising above clouds during sunrise with pilgrimage path visible",
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: SettingsDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() {});
        },
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
                                    Scaffold.of(context).openDrawer();
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
                    name: destination['name'] as String,
                    imageUrl: destination['image'] as String,
                    semanticLabel: destination['semanticLabel'] as String,
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

            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          ],
        ),
      ),
    );
  }
}
