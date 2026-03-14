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
