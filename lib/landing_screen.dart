import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset("graphics/Background.png", fit: BoxFit.cover),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset('graphics/Logo B.png', width: 250),

                const SizedBox(height: 20),

                // Centered Text
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Join artists and art enthusiasts around the globe!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontFamily: 'IstokWeb-Bold',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 130),

                // Box around buttons
                Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(162, 255, 255, 255),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, "/log"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0792CD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontFamily: 'IstokWeb-Bold',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // "OR" Divider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Divider(color: Colors.white, thickness: 1),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontFamily: 'IstokWeb-Bold',
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Colors.white, thickness: 1),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, "/signup"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDA0590),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: const Text(
                            'SIGN UP',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontFamily: 'IstokWeb-Bold',
                            ),
                          ),
                        ),
                      ),
                    ],
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
