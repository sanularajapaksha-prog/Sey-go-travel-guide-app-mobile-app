import 'package:flutter/material.dart';

import '../../widgets/custom_bottom_bar.dart';
import './welcome_home_screen_initial_page.dart';
import '../map_view_screen/map_view_screen.dart';
import '../playlists_screen/playlists_screen.dart';
import '../favorite_screen/favorites_screen.dart';
import '../profile_screen/profile_screen.dart';

class WelcomeHomeScreen extends StatefulWidget {
  const WelcomeHomeScreen({super.key});

  @override
  WelcomeHomeScreenState createState() => WelcomeHomeScreenState();
}

class WelcomeHomeScreenState extends State<WelcomeHomeScreen> {
  int currentIndex = 0;

  final List<Widget> _pages = [
    const WelcomeHomeScreenInitialPage(),
    const MapViewScreen(),
    const PlaylistsScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (currentIndex != index && index < _pages.length) {
            setState(() => currentIndex = index);
          }
        },
      ),
    );
  }
}
