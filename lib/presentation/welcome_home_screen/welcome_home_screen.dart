import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/custom_bottom_bar.dart';
import './welcome_home_screen_initial_page.dart';

class WelcomeHomeScreen extends StatefulWidget {
  const WelcomeHomeScreen({super.key});

  @override
  WelcomeHomeScreenState createState() => WelcomeHomeScreenState();
}

class WelcomeHomeScreenState extends State<WelcomeHomeScreen> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int currentIndex = 0;

  final List<String> routes = [
    '/welcome-home-screen',
    '/map-view-screen',
    '/playlists-screen',
    '/profile-screen',
    '/profile-screen',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        initialRoute: '/welcome-home-screen',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/welcome-home-screen':
            case '/':
              return MaterialPageRoute(
                builder: (context) => const WelcomeHomeScreenInitialPage(),
                settings: settings,
              );
            default:
              if (AppRoutes.routes.containsKey(settings.name)) {
                return MaterialPageRoute(
                  builder: AppRoutes.routes[settings.name]!,
                  settings: settings,
                );
              }
              return null;
          }
        },
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (!AppRoutes.routes.containsKey(routes[index])) {
            return;
          }
          if (currentIndex != index) {
            setState(() => currentIndex = index);
            navigatorKey.currentState?.pushReplacementNamed(routes[index]);
          }
        },
      ),
    );
  }
}
