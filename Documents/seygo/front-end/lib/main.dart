import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_export.dart'; // AppRoutes
import 'providers/theme_provider.dart';
import 'providers/font_scale_provider.dart';
import 'theme/app_theme.dart'; // your AppTheme class
import 'widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl != null &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey != null &&
      supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FontScaleProvider()),
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
