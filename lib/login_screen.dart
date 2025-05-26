import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _logger = Logger('LoginScreen');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Check if user is already authenticated
    // We don't need to listen for auth state changes here anymore
    // This prevents a redirect loop when a user logs out and tries to log back in
  }
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool _passwordVisible = false; // Track password visibility

  void _handleLogin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showDialog('Please enter both username and password');
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Get the user's email from your 'users' table using their username
      final userRecord = await _getUserByUsername(username); // Assuming this returns the user row
      
      if (userRecord == null || userRecord['email'] == null) {
        if (mounted) {
          _showDialog('User not found or email missing for this user.');
          // setState(() => isLoading = false); // isLoading will be set to false in finally block
        }
        return;
      }

      final String email = userRecord['email'];

      // 2. Sign in with Supabase Auth using email and password
      final AuthResponse response = await SupabaseService.supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _logger.info('Supabase login successful for user: ${response.user!.id}');
        
        // Optional: Save additional user info to SharedPreferences if needed
        // The session itself is now managed by Supabase
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', response.user!.id); 
        await prefs.setString('username', username); // You can still store username for display

        if (mounted) {
          // Using pushNamedAndRemoveUntil to clear the login screen from the stack
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        // This case might not be reached if signInWithPassword throws an AuthException for failures
        _logger.warning('Supabase login attempt returned no user, but no error.');
        if (mounted) {
          _showDialog('Login failed. Please check your credentials.');
        }
      }
    } on AuthException catch (e) {
      _logger.severe('Supabase AuthException: ${e.message}');
      if (mounted) {
        _showDialog('Login failed: ${e.message}');
      }
    } catch (e) {
      _logger.severe('Generic login error: $e');
      if (mounted) {
        _showDialog('Login failed: An unexpected error occurred.');
      }
    } finally {
      if (mounted) { 
        setState(() => isLoading = false);
      }
    }
  }
  
  // Helper method to get user data by username
  Future<Map<String, dynamic>?> _getUserByUsername(String username) async {
    try {
      final response = await SupabaseService.supabase
          .from('users')  // Using lowercase table name
          .select()
          .eq('username', username)
          .maybeSingle();
      
      _logger.info('User lookup response: $response');
      return response;
    } catch (e) {
      _logger.severe('Error fetching user by username: $e');
      return null;
    }
  }

  Future<void> _showDialog(String message) async {
    if (!mounted) return;
    
    return showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismiss by tapping outside
      builder: (_) {
        if (!mounted) return const SizedBox(); // Return empty widget if not mounted
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('graphics/Background.png', fit: BoxFit.cover),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('graphics/Logo C.png', width: 70),
                      const SizedBox(width: 10),
                      Image.asset('graphics/Typography.png', width: 250),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Container(
                    width: 357,
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(169, 255, 255, 255),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(95, 157, 156, 156),
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NirmalaUI',
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'NirmalaUI',
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Username field
                        _buildInputField('Username', usernameController),

                        const SizedBox(height: 15),

                        // Password field
                        _buildInputField('Password', passwordController, isPassword: true),

                        const SizedBox(height: 15),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontFamily: 'NirmalaUI',
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0792CD),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontFamily: 'NirmalaUI',
                                      fontWeight: FontWeight.bold,
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
          ),
          Positioned(
            top: 21,
            left: 20,
            child: IconButton(
              icon: Image.asset('graphics/back_button.png', width: 29, height: 29),
              onPressed: () {
                if (mounted) {
                  Navigator.pushNamed(context, '/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String hint, TextEditingController controller,
      {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !_passwordVisible : false,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70, fontSize: 15),
          border: InputBorder.none,
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ) 
            : null,
        ),
      ),
    );
  }
}
