import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';



class FavoriteButton extends StatelessWidget {
  final String placeId;
  final String placeName;
  final String imageUrl;
  final String location;
  final String semanticLabel;
  final double size;

  const FavoriteButton({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.imageUrl,
    required this.location,
    required this.semanticLabel,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favorites, child) {
        final isFavorite = favorites.isFavorite(placeId);
        return Semantics(
          button: true,
          label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: IconButton(
              key: ValueKey<bool>(isFavorite),
              onPressed: () {
                favorites.toggleFavorite(
                  FavoritePlace(
                    id: placeId,
                    name: placeName,
                    imageUrl: imageUrl,
                    googleUrl: imageUrl,
                    location: location,
                    semanticLabel: semanticLabel,
                  ),
                );
              },
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.redAccent : Theme.of(context).colorScheme.onSurfaceVariant,
                size: size,
              ),
              splashRadius: size * 1.2,
              tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            ),
          ),
        );
      },
    );
  }
}
