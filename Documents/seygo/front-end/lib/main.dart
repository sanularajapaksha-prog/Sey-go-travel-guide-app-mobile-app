import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_export.dart'; // AppRoutes
import 'providers/theme_provider.dart';
import 'providers/font_scale_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/locale_provider.dart';
import 'widgets/custom_error_widget.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeEnvironment();
  await _initializeSupabaseSafely();

  bool hasShownError = false;

  // Custom global error widget
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;
      Future.delayed(const Duration(seconds: 5), () {
        hasShownError = false;
      });
      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

Future<void> _initializeEnvironment() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (error, stackTrace) {
    debugPrint('Failed to load .env: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initializeSupabaseSafely() async {
  final supabaseUrl = (dotenv.env['SUPABASE_URL'] ?? '').trim();
  final supabaseAnonKey = (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();

  if (supabaseUrl.isEmpty || supabaseUrl.contains('your-project-ref')) {
    debugPrint(
      'Supabase disabled: invalid SUPABASE_URL in front-end/.env.',
    );
    return;
  }

  if (supabaseAnonKey.isEmpty ||
      supabaseAnonKey.contains('your-supabase-anon-key')) {
    debugPrint(
      'Supabase disabled: invalid SUPABASE_ANON_KEY in front-end/.env.',
    );
    return;
  }

  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey)
        .timeout(const Duration(seconds: 8));
  } catch (error, stackTrace) {
    debugPrint('Supabase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((data) {
            if (data.event == AuthChangeEvent.passwordRecovery) {
              appNavigatorKey.currentState?.pushNamed(AppRoutes.resetPassword);
            } else if (data.event == AuthChangeEvent.signedOut ||
                data.event == AuthChangeEvent.userDeleted) {
              appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                AppRoutes.loginPage,
                (route) => false,
              );
            }
          });
    } catch (_) {
      // Supabase may be disabled locally.
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FontScaleProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return Consumer3<ThemeProvider, FontScaleProvider, LocaleProvider>(
            builder: (context, themeProvider, fontProvider, localeProvider, child) {
              return MaterialApp(
                navigatorKey: appNavigatorKey,
                title: 'seygo_travel_app',
                debugShowCheckedModeBanner: false,

                // Your themes
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,
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

                // Apply dynamic font scaling
                builder: (context, child) {
                  final scaleFactor = fontProvider.scaleFactor.isFinite &&
                          fontProvider.scaleFactor > 0
                      ? fontProvider.scaleFactor
                      : 1.0;
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scaleFactor),
                    ),
                    child: child!,
                  );
                },

                // Routes
                routes: AppRoutes.routes,
                initialRoute: AppRoutes.initial,
              );
            },
          );
        },
      ),
    );
  }
}
