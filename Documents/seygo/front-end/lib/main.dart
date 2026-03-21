import 'dart:async';
import 'dart:developer' as developer; // Implemented for structured logging

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:http/http.dart' as http;

import 'core/app_export.dart'; // AppRoutes
import 'data/services/api_service.dart';
import 'providers/theme_provider.dart';
import 'providers/font_scale_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/places_provider.dart';
import 'providers/user_data_provider.dart';
import 'widgets/custom_error_widget.dart';

/// Global navigator key allows us to navigate context-free from anywhere,
/// such as from auth event listeners or deep link handlers.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// A global robust logger wrapper to replace unstructured print statements.
/// This ensures all app errors are categorized and can easily be connected 
/// to Crashlytics or Sentry later.
class AppLogger {
  static void error(String message, [dynamic error, StackTrace? stack]) {
    developer.log(message, name: 'ERROR', error: error, stackTrace: stack);
  }
  static void info(String message) {
    developer.log(message, name: 'INFO');
  }
  static void warn(String message) {
    developer.log(message, name: 'WARN');
  }
}

Future<void> main() async {
  // Ensure the widget binding is fully initialized before doing async work.
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize environment variables with robust fallback checks.
  await _initializeEnvironment();
  
  // 2. Safely initialize backend services.
  await _initializeSupabaseSafely();

  // 3. Fire-and-forget backend warm-up so Railway wakes before first user action.
  _warmUpBackend();

  bool hasShownError = false;

  // 4. Custom global error boundary to catch Flutter rendering errors.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    AppLogger.error('Flutter global error caught', details.exception, details.stack);
    if (!hasShownError) {
      hasShownError = true;
      Future.delayed(const Duration(seconds: 5), () {
        hasShownError = false;
      });
      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };

  // 4. Lock application to portrait orientation globally.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Bug Fix: Move MultiProvider OUTSIDE of the StatefulWidget to prevent
  // recreation of providers (and states) upon hot reloads or parent rebuilds.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FontScaleProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = FavoritesProvider();
            provider.loadFromPrefs();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => PlacesProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
      ],
      child: const SeygoTravelApp(),
    ),
  );
}

/// Pings the backend health endpoint so Railway wakes up before the user
/// tries to load data. Fire-and-forget — errors are silently ignored.
void _warmUpBackend() {
  final apiUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
  if (apiUrl.isEmpty) return;
  // ignore: avoid_dynamic_calls
  Future(() async {
    try {
      final uri = Uri.parse('$apiUrl/health');
      await http.get(uri).timeout(const Duration(seconds: 30));
      AppLogger.info('Backend warm-up ping sent.');
    } catch (_) {
      // Intentionally silent — this is best-effort only.
    }
  });
}

/// Robust environment initialization. Validates key configuration.
Future<void> _initializeEnvironment() async {
  try {
    await dotenv.load(fileName: '.env');
    AppLogger.info('Environment loaded successfully.');
    
    // Quick validation of critical vars
    if (!dotenv.env.containsKey('API_BASE_URL') && !dotenv.env.containsKey('SUPABASE_URL')) {
      AppLogger.warn('Critical environment variables might be missing from .env');
    }
  } catch (error, stackTrace) {
    // We explicitly flag missing `.env` loudly and cleanly, falling back
    // safely instead of silently swallowing the exception.
    AppLogger.error('Failed to load `.env` file. App may lack configuration.', error, stackTrace);
    // In production, we might load environment from native configs instead here.
  }
}

/// Safely initializes Supabase, accounting for disabled features locally.
Future<void> _initializeSupabaseSafely() async {
  final supabaseUrl = (dotenv.env['SUPABASE_URL'] ?? '').trim();
  final supabaseAnonKey = (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();

  if (supabaseUrl.isEmpty || supabaseUrl.contains('your-project-ref')) {
    AppLogger.warn('Supabase disabled: invalid SUPABASE_URL in configuration.');
    return;
  }

  if (supabaseAnonKey.isEmpty || supabaseAnonKey.contains('your-supabase-anon-key')) {
    AppLogger.warn('Supabase disabled: invalid SUPABASE_ANON_KEY in configuration.');
    return;
  }

  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey)
        .timeout(const Duration(seconds: 8));
    AppLogger.info('Supabase initialized successfully.');
  } on TimeoutException catch (_) {
    AppLogger.error('Supabase initialization timed out checking connectivity. Backend may be offline.');
  } catch (error, stackTrace) {
    AppLogger.error('Supabase initialization failed unexpectedly.', error, stackTrace);
  }
}

class SeygoTravelApp extends StatefulWidget {
  const SeygoTravelApp({super.key});

  @override
  State<SeygoTravelApp> createState() => _SeygoTravelAppState();
}

class _SeygoTravelAppState extends State<SeygoTravelApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupGlobalAuthListener();
  }

  void _setupGlobalAuthListener() {
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        // Bug Fix: We must NOT use appNavigatorKey.currentContext! immediately
        // within the listen callback because it fires before the first frame mounts.
        // We delay navigation check to the next frame to guarantee context stability.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleAuthChangeEvent(data.event);
        });
      });
    } catch (e, stack) {
      AppLogger.error('Error attaching auth state listener', e, stack);
    }
  }

  void _handleAuthChangeEvent(AuthChangeEvent event) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;
    
    // Safely retrieve the current route
    String? currentRoute;
    Navigator.popUntil(context, (route) {
      currentRoute = route.settings.name;
      return true; // We don't actually pop anything, just peek at the top route
    });

    if (event == AuthChangeEvent.passwordRecovery) {
      if (currentRoute != AppRoutes.resetPassword) {
        appNavigatorKey.currentState?.pushNamed(AppRoutes.resetPassword);
      }
    } else if (event == AuthChangeEvent.signedIn) {
      // Ensure we explicitly route to Home but avoid stack duplication
      if (currentRoute != AppRoutes.welcomeHome) {
        appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.welcomeHome,
          (route) => false,
        );
      }
      // Preload all auth-dependent data and rebuild search index in background.
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token != null) {
        ApiService.rebuildSearchIndex(accessToken: token);
        Provider.of<UserDataProvider>(context, listen: false).preload(token);
      }
    } else if (event == AuthChangeEvent.signedOut || event == AuthChangeEvent.userDeleted) {
      // Clear stale user data so it isn't shown on the next login.
      Provider.of<UserDataProvider>(context, listen: false).invalidate();
      if (currentRoute != AppRoutes.loginPage) {
        appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.loginPage,
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Providers are now safely inherited from the top of the tree.
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Consumer3<ThemeProvider, FontScaleProvider, LocaleProvider>(
          builder: (context, themeProvider, fontProvider, localeProvider, child) {
            return MaterialApp(
              navigatorKey: appNavigatorKey,
              title: 'SeyGo Travel',
              debugShowCheckedModeBanner: false,

              // Theming configuration
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              
              // Internalization configuration
              locale: localeProvider.locale,
              supportedLocales: const [
                Locale('en', 'LK'),
                Locale('en', 'US'),
                Locale('si', 'LK'),
                Locale('ta', 'LK'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // Scalable font size builder wrapping application
              builder: (context, child) {
                final scaleFactor = fontProvider.scaleFactor.isFinite && fontProvider.scaleFactor > 0
                    ? fontProvider.scaleFactor
                    : 1.0;
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scaleFactor),
                  ),
                  child: child!,
                );
              },

              // App routing tables
              routes: AppRoutes.routes,
              initialRoute: AppRoutes.initial,
            );
          },
        );
      },
    );
  }
}
