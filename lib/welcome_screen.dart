import 'package:flutter/material.dart';
import 'signup_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudHue',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WelcomeScreen(),
      routes: {
        '/signup': (context) => const SignUpScreen(),
      },
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              "graphics/Background.png",
              fit: BoxFit.cover,
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset(
                  'graphics/Logo B.png',
                  width: 300,
                ),

                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'The all-in-one art e-commerce platform',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontFamily: 'IstokWeb',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 150),

                // Get Started Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/login");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0027D),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'GET STARTED',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'IstokWeb',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}