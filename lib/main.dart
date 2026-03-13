import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // ✅ Import
import 'map_page.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // ✅ Keep the splash screen on screen while initializing
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const SeyGoApp());
}

class SeyGoApp extends StatefulWidget {
  const SeyGoApp({super.key});

  @override
  State<SeyGoApp> createState() => _SeyGoAppState();
}

class _SeyGoAppState extends State<SeyGoApp> {
  @override
  void initState() {
    super.initState();
    initialization();
  }

  void initialization() async {
    // ✅ Simulate loading (e.g., getting location or API data)
    await Future.delayed(const Duration(seconds: 2));
    // ✅ Remove the splash screen once everything is ready
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MapPage(),
    );
  }
}