import 'package:flutter/material.dart';
import '../presentation/feature_intro_page/feature_intro_page.dart';
import '../presentation/login_page/login_page.dart';
import '../presentation/logo_intro_page/logo_intro_page.dart';
import '../presentation/otp_page/otp_page.dart';
import '../presentation/planner_intro_page/planner_intro_page.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/destination_detail_screen/destination_detail_screen.dart';
import '../presentation/map_view_screen/map_view_screen.dart';
import '../presentation/playlists_screen/playlists_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/register_page/register_page.dart';
import '../presentation/route_planner_screen/route_planner_screen.dart';
import '../presentation/signup_page/signup_page.dart';
import '../presentation/welcome_home_screen/welcome_home_screen.dart';
import '../presentation/welcome_intro_page/welcome_intro_page.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String introWelcome = '/intro-welcome';
  static const String introPlanner = '/intro-planner';
  static const String introFeature = '/intro-feature';
  static const String loginPage = '/login-page';
  static const String registerPage = '/register-page';
  static const String signupPage = '/signup-page';
  static const String otpPage = '/otp-page';
  static const String welcomeHome = '/welcome-home-screen';
  static const String welcomeHomeScreen = welcomeHome;
  static const String profile = '/profile-screen';
  static const String playlists = '/playlists-screen';
  static const String mapView = '/map-view-screen';
  static const String destinationDetail = '/destination-detail-screen';
  static const String routePlanner = '/route-planner-screen';

  static final Map<String, WidgetBuilder> routes = {
    initial: (context) => const LogoIntroPage(),
    splash: (context) => const SplashScreen(),
    introWelcome: (context) => const WelcomeIntroPage(),
    introPlanner: (context) => const PlannerIntroPage(),
    introFeature: (context) => const FeatureIntroPage(),
    loginPage: (context) => const LoginPage(),
    registerPage: (context) => const RegisterPage(),
    signupPage: (context) => const SignupPage(),
    otpPage: (context) => const OtpPage(),
    welcomeHome: (context) => const WelcomeHomeScreen(),
    profile: (context) => const ProfileScreen(),
    playlists: (context) => const PlaylistsScreen(),
    mapView: (context) => const MapViewScreen(),
    destinationDetail: (context) => const DestinationDetailScreen(),
    routePlanner: (context) => const RoutePlannerScreen(),
  };
}
