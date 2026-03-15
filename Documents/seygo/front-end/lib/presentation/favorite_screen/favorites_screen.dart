import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/favorites_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_image_widget.dart';
import '../../widgets/favorite_button.dart';


class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FavoritePlace> _filterFavorites(List<FavoritePlace> favorites) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return favorites;
    }
    return favorites.where((place) {
      return place.name.toLowerCase().contains(query) ||
          place.location.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final favorites = favoritesProvider.favorites;
        final filteredFavorites = _filterFavorites(favorites);
        final uniqueLocations = favorites
            .map((place) => place.location.trim())
            .where((location) => location.isNotEmpty)
            .toSet()
            .length;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Favorites'),
            actions: [
              if (favorites.isNotEmpty)
                TextButton.icon(
                  onPressed: favoritesProvider.clearFavorites,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                ),
              SizedBox(width: 2.w),
            ],
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _FavoritesHero(
                  count: favorites.length,
                  locations: uniqueLocations,
                ),
              ),
              if (favorites.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _FavoritesEmptyState(
                    onExplorePressed: () {
                      // Navigate back to the discover tab.
                      // Using pushReplacement to ensure the favorites screen isn't
                      // stacked on top of the main navigator stack.
                      Navigator.of(context).pushReplacementNamed(
                        AppRoutes.welcomeHomeScreen,
                      );
                    },
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FavoritesSearchField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _query = value);
                          },
                          onClear: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          showClear: _query.trim().isNotEmpty,
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Saved places',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${filteredFavorites.length} of ${favorites.length}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.4.h),
                      ],
                    ),
                  ),
                ),
                if (filteredFavorites.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _NoResultsState(
                      query: _query.trim(),
                      onClear: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
                  )
                else
                  SliverPadding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final place = filteredFavorites[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 2.h),
                            child: _FavoritePlaceCard(
                              place: place,
                            ),
                          );
                        },
                        childCount: filteredFavorites.length,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}


class _FavoritesHero extends StatelessWidget {
  final int count;
  final int locations;

  const _FavoritesHero({
    required this.count,
    required this.locations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface.withOpacity(0.9);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.12),
              theme.colorScheme.secondary.withOpacity(0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8.w,
              top: -4.h,
              child: Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              left: -6.w,
              bottom: -5.h,
              child: Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary.withOpacity(0.08),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved for your next trip',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Text(
                  'Keep the places you love in one elegant space.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: 'Places',
                        value: count.toString(),
                        backgroundColor: cardColor,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: _StatPill(
                        label: 'Cities',
                        value: locations.toString(),
                        backgroundColor: cardColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;

  const _StatPill({
    required this.label,
    required this.value,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.4.h),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;

  const _FavoritesSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by place or city',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: showClear
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }
}


class _FavoritesEmptyState extends StatelessWidget {
  final VoidCallback onExplorePressed;

  const _FavoritesEmptyState({
    required this.onExplorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow,
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_border,
                size: 8.w,
                color: theme.colorScheme.secondary,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'No favorites yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 1.2.h),
            Text(
              'Start exploring and tap the heart on any place to save it here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: onExplorePressed,
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Explore places'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.4.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritePlaceCard extends StatelessWidget {
  final FavoritePlace place;

  const _FavoritePlaceCard({
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      shadowColor: theme.colorScheme.shadow,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          // Placeholder: tap could navigate to a place detail screen.
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              CustomImageWidget(
                imageUrl: place.imageUrl,
                width: double.infinity,
                height: 24.h,
                fit: BoxFit.cover,
                semanticLabel: place.semanticLabel,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        theme.colorScheme.surface.withOpacity(0.92),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 3.w,
                top: 2.h,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FavoriteButton(
                    placeId: place.id,
                    placeName: place.name,
                    imageUrl: place.imageUrl,
                    location: place.location,
                    semanticLabel: place.semanticLabel,
                    size: 26,
                  ),
                ),
              ),
              Positioned(
                left: 3.w,
                top: 2.h,
                child: _Pill(
                  label: 'Saved',
                  icon: Icons.bookmark_border,
                ),
              ),
              Positioned(
                left: 4.w,
                right: 4.w,
                bottom: 2.2.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.6.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            place.location,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Pill({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.secondary,
          ),
          SizedBox(width: 1.w),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _NoResultsState({
    required this.query,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 10.w,
              color: theme.colorScheme.onSurfaceVariant,
            ),

             SizedBox(height: 2.h),
            Text(
              'No matches for "$query"',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try a different keyword or clear the search.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.4.h),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              label: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }
}



