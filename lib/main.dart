import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Import your new screen

void main() {
  runApp(const SeygoApp());
}

class SeygoApp extends StatelessWidget {
  const SeygoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Seygo Maps',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(), // ✅ App starts here!
    );
  }
}