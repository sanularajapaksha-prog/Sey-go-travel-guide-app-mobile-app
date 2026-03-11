import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/favorites_provider.dart';
import '../../widgets/custom_image_widget.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  _SortOption _sortOption = _SortOption.recent;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort by',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 1.h),
                ..._SortOption.values.map(
                  (option) => RadioListTile<_SortOption>(
                    value: option,
                    groupValue: _sortOption,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _sortOption = value);
                      Navigator.of(context).pop();
                    },
                    title: Text(option.label),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

 @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final favorites = favoritesProvider.favorites; //


        final query = _searchController.text.trim().toLowerCase();
        final categories = <String>{
          for (final place in favorites) place.location,
        }.toList()
          ..sort();
        final activeCategory =
            _selectedCategory == 'All' ? null : _selectedCategory;
        final filtered = favorites.where((place) {
          final matchesCategory =
              activeCategory == null || place.location == activeCategory;
          final matchesQuery = query.isEmpty ||
              place.name.toLowerCase().contains(query) ||
              place.location.toLowerCase().contains(query);
          return matchesCategory && matchesQuery;
        }).toList();

        switch (_sortOption) {
          case _SortOption.recent:
            break;
          case _SortOption.nameAsc:
            filtered.sort((a, b) => a.name.compareTo(b.name));
            break;
          case _SortOption.nameDesc:
            filtered.sort((a, b) => b.name.compareTo(a.name));
            break;
          case _SortOption.category:
            filtered.sort((a, b) => a.location.compareTo(b.location));
            break;
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('Favorites (${favoritesProvider.count})'),
            actions: [
              IconButton(
                tooltip: 'Sort',
                onPressed: () => _showSortSheet(context),
                icon: const Icon(Icons.sort),
              ),
              TextButton(
                onPressed:
                    favorites.isEmpty ? null : favoritesProvider.clearFavorites,
                child: const Text('Clear all'),
              ),
              SizedBox(width: 2.w),
            ],
          ),

          body: favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: 1.5.h),
                      Text(
                        'No favorites yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 0.8.h),
                      Text(
                        'Tap the heart on a place to save it here.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      child: Column(
                        children: [
                          _FavoritesSummaryCard(
                            total: favoritesProvider.count,
                            categories: categories.length,
                          ),
                          SizedBox(height: 1.2.h),
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search favorites...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          SizedBox(height: 1.2.h),
                          SizedBox(
                            height: 4.6.h,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length + 1,
                              separatorBuilder: (context, index) =>
                                  SizedBox(width: 2.w),
                              itemBuilder: (context, index) {
                                final label = index == 0
                                    ? 'All'
                                    : categories[index - 1];
                                final isSelected =
                                    _selectedCategory == label;
                                return ChoiceChip(
                                  selected: isSelected,
                                  label: Text(label),
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedCategory = label;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your saved places',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${filtered.length} shown',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1.h),