import 'package:flutter/material.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/welcome_home_screen/welcome_home_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/playlists_screen/playlists_screen.dart';
import '../presentation/map_view_screen/map_view_screen.dart';
import '../presentation/destination_detail_screen/destination_detail_screen.dart';
import '../presentation/route_planner_screen/route_planner_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = onboardingScreen;
  static const String onboardingScreen = '/onboarding_screen';
  static const String splash = '/splash-screen';
  static const String welcomeHome = '/welcome-home-screen';
  static const String welcomeHomeScreen = welcomeHome;
  static const String profile = '/profile-screen';
  static const String playlists = '/playlists-screen';
  static const String mapView = '/map-view-screen';
  static const String destinationDetail = '/destination-detail-screen';
  static const String routePlanner = '/route-planner-screen';

  static Map<String, WidgetBuilder> routes = {
    onboardingScreen: (context) => const OnboardingScreen(),
    splash: (context) => const SplashScreen(),
    welcomeHome: (context) => const WelcomeHomeScreen(),
    profile: (context) => const ProfileScreen(),
    playlists: (context) => const PlaylistsScreen(),
    mapView: (context) => const MapViewScreen(),
    destinationDetail: (context) => const DestinationDetailScreen(),
    routePlanner: (context) => const RoutePlannerScreen(),
    // TODO: Add your other routes here
  };
}
