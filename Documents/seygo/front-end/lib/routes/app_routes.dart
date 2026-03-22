import 'package:flutter/material.dart';

import '../presentation/logo_intro_page/logo_intro_page.dart';
import '../presentation/welcome_intro_page/welcome_intro_page.dart';
import '../presentation/planner_intro_page/planner_intro_page.dart';
import '../presentation/feature_intro_page/feature_intro_page.dart';
import '../presentation/signup_page/signup_page.dart';
import '../presentation/login_page/login_page.dart';
import '../presentation/register_page/register_page.dart';
import '../presentation/otp_page/otp_page.dart';
import '../presentation/forgot_password_screen/forgot_password_screen.dart';
import '../presentation/reset_password_screen/reset_password_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/welcome_home_screen/welcome_home_screen.dart';
import '../presentation/favorite_screen/favorites_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/playlists_screen/playlists_screen.dart';
import '../presentation/destination_detail_screen/destination_detail_screen.dart';
import '../presentation/route_planner_screen/route_planner_screen.dart';
import '../presentation/map_view_screen/map_view_screen.dart';
import '../presentation/user_preferences_screen/user_preferences_screen.dart';
import '../presentation/offline_trips/offline_trips_screen.dart';
import '../presentation/playlist_details/playlist_details_screen.dart';

class AppRoutes {
  static const String initial = introLogo;

  static const String introLogo = '/intro-logo';
  static const String introWelcome = '/intro-welcome';
  static const String introPlanner = '/intro-planner';
  static const String introFeature = '/intro-feature';

  static const String signupPage = '/signup-page';
  static const String loginPage = '/login-page';
  static const String registerPage = '/register-page';
  static const String otpPage = '/otp-page';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  static const String splash = '/splash-screen';
  static const String welcomeHome = '/welcome-home-screen';
  static const String welcomeHomeScreen = welcomeHome;
  static const String profile = '/profile-screen';
  static const String playlists = '/playlists-screen';
  static const String favorites = '/favorites-screen';
  static const String mapView = '/map-view-screen';
  static const String destinationDetail = '/destination-detail-screen';
  static const String routePlanner = '/route-planner-screen';
  static const String userPreferences = '/user-preferences-screen';
  static const String offlineTrips = '/offline-trips-screen';
  static const String playlistDetails = '/playlist-details-screen';

  static final Map<String, WidgetBuilder> routes = {
    introLogo: (context) => const LogoIntroPage(),
    introWelcome: (context) => const WelcomeIntroPage(),
    introPlanner: (context) => const PlannerIntroPage(),
    introFeature: (context) => const FeatureIntroPage(),
    signupPage: (context) => const SignupPage(),
    loginPage: (context) => const LoginPage(),
    registerPage: (context) => const RegisterPage(),
    otpPage: (context) => const OtpPage(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    resetPassword: (context) => const ResetPasswordScreen(),
    splash: (context) => const SplashScreen(),
    welcomeHome: (context) => const WelcomeHomeScreen(),
    profile: (context) => const ProfileScreen(),
    playlists: (context) => const PlaylistsScreen(),
    mapView: (context) => const MapViewScreen(),
    favorites: (context) => const FavoritesScreen(),
    destinationDetail: (context) => const DestinationDetailScreen(),
    routePlanner: (context) => const RoutePlannerScreen(),
    userPreferences: (context) => const UserPreferencesScreen(),
    offlineTrips: (context) => const OfflineTripsScreen(),
    playlistDetails: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final playlistId = (args is Map ? args['playlistId'] : args?.toString()) ?? '';
      final initialPlaylist = args is Map ? args['playlist'] as Map<String, dynamic>? : null;
      return PlaylistDetailsScreen(
        playlistId: playlistId,
        initialPlaylist: initialPlaylist,
      );
    },
  };
}
