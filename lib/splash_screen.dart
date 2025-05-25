import 'package:flutter/material.dart';
import 'supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatusAndNavigate();
  }

  Future<void> _checkAuthStatusAndNavigate() async {
    // Wait for a short period to allow Supabase to initialize and restore session
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final currentUser = SupabaseService.supabase.auth.currentUser;
    if (currentUser != null) {
      // User is logged in, navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // User is not logged in, navigate to welcome screen
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image (full screen)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('graphics/Background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Centered logo
          Center(
            child: const Center(
              child: Image(
                image: AssetImage("graphics/Logo C.png"),
                width: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
