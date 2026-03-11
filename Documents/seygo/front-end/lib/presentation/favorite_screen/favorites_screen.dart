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

