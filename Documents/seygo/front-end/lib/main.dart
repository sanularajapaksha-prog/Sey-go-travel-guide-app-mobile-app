import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_export.dart'; // AppRoutes
import 'providers/theme_provider.dart';
import 'providers/font_scale_provider.dart';
import 'providers/favorites_provider.dart';
import 'widgets/custom_error_widget.dart';


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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FontScaleProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return Consumer2<ThemeProvider, FontScaleProvider>(
            builder: (context, themeProvider, fontProvider, child) {
              return MaterialApp(
                title: 'seygo_travel_app',
                debugShowCheckedModeBanner: false,

                // Your themes
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,

                // Apply dynamic font scaling
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(fontProvider.scaleFactor),
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
