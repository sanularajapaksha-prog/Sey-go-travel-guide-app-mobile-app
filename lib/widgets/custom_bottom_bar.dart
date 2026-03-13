import 'package:flutter/material.dart';

/// Custom bottom navigation bar for SeyGo travel discovery app
/// Implements spatial bottom navigation with generous touch targets
/// and subtle active state indicators following Contemporary Tropical Minimalism design
class CustomBottomBar extends StatelessWidget {
  /// Current selected index
  final int currentIndex;

  /// Callback when navigation item is tapped
  final Function(int) onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 8.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor:
          theme.bottomNavigationBarTheme.unselectedItemColor,
          selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle,
          unselectedLabelStyle:
          theme.bottomNavigationBarTheme.unselectedLabelStyle,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            // Home/Discover - Central discovery hub
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.explore_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.explore, size: 24),
              ),
              label: 'Discover',
              tooltip: 'Discover destinations',
            ),

            // Map - Geographic visualization
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.map_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.map, size: 24),
              ),
              label: 'Map',
              tooltip: 'View map',
            ),

            // Playlists - Content curation
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.playlist_play_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.playlist_play, size: 24),
              ),
              label: 'Playlists',
              tooltip: 'Your playlists',
            ),

            // Favorites - Quick access to liked destinations
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.favorite_outline, size: 24),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.favorite, size: 24),
              ),
              label: 'Favorites',
              tooltip: 'Favorite destinations',
            ),

            // Profile - Account management
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.person_outline, size: 24),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.person, size: 24),
              ),
              label: 'Profile',
              tooltip: 'Your profile',
            ),
          ],
        ),
      ),
    );
  }
}
