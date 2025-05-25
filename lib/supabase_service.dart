import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';

class VaultItem {
  final String username;
  final String productname;
  final String variation;
  final int quantity;
  final double price;
  final String iconUrl;
  final String imageUrl;

  VaultItem({
    required this.username,
    required this.productname,
    required this.variation,
    required this.quantity,
    required this.price,
    required this.iconUrl,
    required this.imageUrl,
  });

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      username: json['username'] as String,
      productname: json['productname'] as String,
      variation: json['variation'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      iconUrl: json['icon_url'] as String,
      imageUrl: json['image_url'] as String,
    );
  }
}

class Post {
  final String id;
  final String username;
  final String profession;
  final bool isVerified;
  final double verifiedOffset;
  final String postImagePath;
  final String iconPath;
  final String caption;
  final DateTime postDate;
  final bool isProduct;
  final String? productname;
  final String? variation;
  final int? quantity;
  final double? price;

  Post({
    required this.id,
    required this.username,
    required this.profession,
    required this.isVerified,
    required this.verifiedOffset,
    required this.postImagePath,
    required this.iconPath,
    required this.caption,
    required this.postDate,
    required this.isProduct,
    this.productname,
    this.variation,
    this.quantity,
    this.price,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      username: json['username'] as String,
      profession: json['profession'] as String,
      isVerified: json['is_verified'] as bool,
      verifiedOffset: (json['verified_offset'] as num?)?.toDouble() ?? 4.0,
      postImagePath: json['post_image_path'] as String,
      iconPath: json['icon_path'] as String,
      caption: json['caption'] as String? ?? '',
      postDate: DateTime.parse(json['created_at'] as String),
      isProduct: json['is_product'] as bool? ?? false,
      productname: json['productname'] as String?,
      variation: json['variation'] as String?,
      quantity: json['quantity'] as int?,
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}

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
      final data = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      return data;
    } catch (e) {
      _logger.severe('Error fetching user profile: $e');
      return null;
    }
  }

  // Create a new pinboard
  static Future<void> createPinboard({
    required String name,
    required String details,
    required String coverImg,
  }) async {
    try {
      await supabase
          .from('pinboards')
          .insert({
            'name': name,
            'description': details,
            'coverImg': coverImg,
          });
      _logger.info('Pinboard created: $name');
    } catch (e) {
      _logger.severe('Error creating pinboard: $e');
      rethrow;
    }
  }

  // Create a new post
  static Future<String> createPost({
    required String username,
    required String profession,
    required bool isVerified,
    required String postImagePath,
    required String iconPath,
    required bool isProduct,
    String? productname,
    String? variation,
    int? quantity,
    double? price,
  }) async {
    try {
      final response = await supabase
          .from('posts')
          .insert({
            'username': username,
            'profession': profession,
            'is_verified': isVerified,
            'post_image_path': postImagePath,
            'icon_path': iconPath,
            'is_product': isProduct,
            'productname': productname,
            'variation': variation,
            'quantity': quantity,
            'price': price,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      
      final String postId = response['id'] as String;
      _logger.info('Post created with ID: $postId');
      return postId;
    } catch (e) {
      _logger.severe('Error creating post: $e');
      rethrow;
    }
  }

  // Add product post to vault
  static Future<void> addToVault({
    required String username,
    required String productname,
    required String variation,
    required int quantity,
    required double price,
    required String iconUrl,
    required String imageUrl,
  }) async {
    try {
      await supabase
          .from('vault_items')
          .insert({
            'username': username,
            'productname': productname,
            'variation': variation,
            'quantity': quantity,
            'price': price,
            'icon_url': iconUrl,
            'image_url': imageUrl,
            'created_at': DateTime.now().toIso8601String(),
          });
      _logger.info('Added to vault: $productname');
    } catch (e) {
      _logger.severe('Error adding to vault: $e');
      rethrow;
    }
  }

  // Delete post
  static Future<void> deletePost(String postId) async {
    try {
      await supabase
          .from('posts')
          .delete()
          .eq('id', postId);
      _logger.info('Post deleted: $postId');
    } catch (e) {
      _logger.severe('Error deleting post: $e');
      rethrow;
    }
  }

  // Get posts
  static Future<List<Post>> getPosts() async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      return response.map((post) => Post.fromJson(post)).toList();
    } catch (e) {
      _logger.severe('Error fetching posts: $e');
      return [];
    }
  }

  // Get pinboards
  static Future<List<Map<String, String>>> getPinboards(String token) async {
    try {
      final pinboards = await supabase
          .from('pinboards')
          .select()
          .order('created_at', ascending: false);

      // Convert dynamic values to String
      return pinboards.map((pinboard) => {
        'name': pinboard['name']?.toString() ?? '',
        'coverImg': pinboard['coverImg']?.toString() ?? '',
      }).toList();
    } catch (e) {
      _logger.severe('Error fetching pinboards: $e');
      return [];
    }
  }

  // Fetch vault items
  static Future<List<VaultItem>> fetchVaultItems() async {
    try {
      final response = await supabase
          .from('vault_items')
          .select()
          .order('created_at', ascending: false);

      return response.map((item) => VaultItem.fromJson(item)).toList();
    } catch (e) {
      _logger.severe('Error fetching vault items: $e');
      return [];
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
