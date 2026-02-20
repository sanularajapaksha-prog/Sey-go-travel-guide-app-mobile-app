import 'package:flutter/material.dart';
import 'dart:async';
import 'map_page.dart'; // Ensure this matches your filename

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup Fade-in Animation
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500)
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // ✅ Transition to MapPage after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MapPage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Your Seygo Logo
              Image.asset(
                'assets/images/logo.png',
                width: 220,
                height: 220,
              ),
              const SizedBox(height: 30),
              const Text(
                "Welcome to Seygo Maps",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0077B6), // Matching your logo blue
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Explore the hidden gems of Sri Lanka",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00B4D8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}