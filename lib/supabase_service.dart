import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';

class SupabaseService {
  static final _logger = Logger('SupabaseService');
  
  // Supabase client instance
  static final SupabaseClient supabase = Supabase.instance.client;
  
  // Initialize Supabase - call this in main.dart before runApp()
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://guhabojbordlqekofdlz.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd1aGFib2pib3JkbHFla29mZGx6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxNTc1NzMsImV4cCI6MjA2MzczMzU3M30.rAuS0CARpDZzB1K-X71PtZWDIeXDpN-wrVNhQT5wMvk',
    );
    _logger.info('Supabase initialized');
  }

  // Register a new user
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String username,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String age,
    required String address,
    required String category,
  }) async {
    try {
      // First, create the auth user with email and password
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (authResponse.user == null) {
        throw Exception('Failed to create user account');
      }
      
      final String userId = authResponse.user!.id;
      _logger.info('Auth user created with ID: $userId');
      
      // Now insert the user profile data into the users table (lowercase as per Supabase convention)
      _logger.info('Attempting to insert user data into users table');
      try {
        final response = await supabase.from('users').insert({
          'user_id': userId,  // Using lowercase column names to match Supabase conventions
          'email': email,
          'full_name': fullName,
          'username': username,
          'age': int.tryParse(age),
          'address': address,
          'phone_number': phoneNumber,
          'password': password,  // Store the password in the users table
          'category': category,
          'account_date_creation': DateTime.now().toIso8601String(),
        }).select();
        _logger.info('Insert response: $response');
      } catch (e) {
        _logger.severe('Error inserting user data: $e');
        // Try to continue anyway since the auth user was created
      }
      
      _logger.info('User profile created successfully');
      
      return {
        'success': true,
        'message': 'Account created successfully',
        'user': {
          'id': userId,
          'email': email,
          'username': username,
        }
      };
    } on AuthException catch (e) {
      _logger.severe('Auth error during signup: ${e.message}');
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      _logger.severe('Error during signup: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Login failed');
      }
      
      // Get user profile data
      Map<String, dynamic>? userData;
      try {
        userData = await supabase
            .from('users')  // Using lowercase table name
            .select()
            .eq('user_id', response.user!.id)  // Using lowercase column name
            .single();
        _logger.info('Retrieved user data: $userData');
      } catch (e) {
        _logger.warning('Could not retrieve user profile: $e');
        // Continue anyway with basic user info
      }
      
      _logger.info('User logged in successfully');
      
      return {
        'success': true,
        'message': 'Login successful',
        'user': userData,
        'session': response.session?.toJson(),
      };
    } on AuthException catch (e) {
      _logger.severe('Auth error during login: ${e.message}');
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      _logger.severe('Error during login: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Logout user
  static Future<void> logout() async {
    await supabase.auth.signOut();
    _logger.info('User logged out');
  }

  // Get current user
  static User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // Get user profile data
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return null;
    }
    
    try {
      final response = await supabase
          .from('users')  // Using lowercase table name
          .select()
          .eq('user_id', user.id)  // Using lowercase column name
          .single();
      
      return response;
    } catch (e) {
      _logger.severe('Error fetching user profile: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      final response = await SupabaseService.supabase
          .from('users')  // Using lowercase table name
          .select()
          .eq('username', username)
          .maybeSingle();
      
      return response;
    } catch (e) {
      _logger.severe('Error fetching user by username: $e');
      return null;
    }
  }
}
