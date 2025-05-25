import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'dart:io'; // Required for File type

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
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      profession: json['profession']?.toString() ?? '',
      isVerified: json['is_verified'] is bool ? json['is_verified'] : false,
      verifiedOffset: (json['verified_offset'] as num?)?.toDouble() ?? 4.0,
      postImagePath: json['post_image_path']?.toString() ?? '',
      iconPath: json['icon_path']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      postDate: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      isProduct: json['is_product'] is bool ? json['is_product'] : false,
      productname: json['productname']?.toString(),
      variation: json['variation']?.toString(),
      quantity: json['quantity'] is int ? json['quantity'] : null,
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}

class UserProfile {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String? profession;
  final String? iconPath;
  final bool isVerified;
  final DateTime accountCreationDate;

  UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    this.profession,
    this.iconPath,
    this.isVerified = false,
    required this.accountCreationDate,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['user_id'] as String, // Assuming 'user_id' is the primary key in your 'users' table
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profession: json['category'] as String? ?? 'N/A', // Using 'category' as profession, adjust if different
      iconPath: json['profile_picture'] ?? 'graphics/Profile Icon.png', // Default icon, adjust if you have a field for this
      isVerified: json['is_verified'] as bool? ?? false, // Adjust if you have a field for this
      accountCreationDate: DateTime.parse(json['account_date_creation'] as String? ?? DateTime.now().toIso8601String()),
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
          'user_id': userId,
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
          .eq('user_id', user.id)
          .single();
      return data;
    } catch (e) {
      _logger.severe('Error fetching user profile: $e');
      return null;
    }
  }

  // Create a new pinboard
  static Future<void> createPinboard({
    required String boardName,
    required String boardDescription,
    required String coverImg,
  }) async {
    try {
      await supabase
          .from('pinboards')
          .insert({
            'board_name': boardName,
            'board_description': boardDescription,
            'coverImg': coverImg,
          });
      _logger.info('Pinboard created: $boardName');
    } catch (e) {
      _logger.severe('Error creating pinboard: $e');
      rethrow;
    }
  }

  // Create a new post
  static Future<String> createPost({
    required String userId,
    required String caption,
    required String postType,
    required String imageUrl,
    bool isProduct = false,
  }) async {
    try {
      // Fetch user profile to get required fields
      final userProfile = await supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .single();

      final Map<String, dynamic> postData = {
        'user_id': userId,
        'caption': caption,
        'post_type': postType,
        'image_url': imageUrl,
        'is_product': isProduct,
        'post_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        // Required user fields for posts
        'username': userProfile['username'] ?? '',
        'profession': userProfile['category'] ?? '',
        'is_verified': userProfile['is_verified'] ?? false,
        'verified_offset': userProfile['verified_offset'] ?? 4.0,
        'icon_path': userProfile['profile_picture'] ?? 'graphics/Profile Icon.png',
        'post_image_path': imageUrl, // Use imageUrl as post_image_path
        // Optional product fields
        'productname': null,
        'variation': null,
        'quantity': null,
        'price': null,
      };

      final response = await supabase
          .from('posts')
          .insert(postData)
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
  static Future<void> deletePost(String id) async {
    try {
      await supabase
          .from('posts')
          .delete()
          .eq('id', id);
      _logger.info('Post deleted: $id');
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

  static Future<List<UserProfile>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }
    try {
      final response = await supabase
          .from('users')
          .select()
          // Search in username and full_name. Adjust column names if necessary.
          .or('username.ilike.%$query%,full_name.ilike.%$query%') 
          .limit(10); // Limit results for performance and to avoid overwhelming the UI

      return response.map((data) => UserProfile.fromJson(data)).toList();
    } catch (e) {
      _logger.severe('Error searching users: $e');
      return [];
    }
  }

  static Future<String?> uploadFile(File file, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final String storagePath = 'public/$userId/$fileName'; // Store in a user-specific public folder

      await supabase.storage
          .from('posts_media') // Ensure this is your bucket name
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get the public URL
      final String publicUrl = supabase.storage
          .from('posts_media')
          .getPublicUrl(storagePath);
      
      _logger.info('File uploaded to: $publicUrl');
      return publicUrl;
    } catch (e) {
      _logger.severe('Error uploading file: $e');
      return null;
    }
  }

  // Updated: Support both File (mobile/desktop) and Uint8List (web)
  static Future<String> uploadPostImage(dynamic imageFile, String userId) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      String filePath;
      String publicUrl;

      // Detect platform
      bool isWeb = false;
      try {
        // kIsWeb is only available if you import foundation.dart
        // We'll use a runtime check for web
        isWeb = identical(0, 0.0);
      } catch (_) {}

      if (isWeb) {
        // On web, imageFile should be a List<int> (Uint8List is a subtype)
        filePath = '$userId/$fileName';
        // Try to detect content type from file bytes
        String contentType = 'image/jpeg'; // Default
        if (imageFile is List<int> && imageFile.length > 4) {
          // Simple PNG signature check
          if (imageFile[0] == 0x89 && imageFile[1] == 0x50 && imageFile[2] == 0x4E && imageFile[3] == 0x47) {
            contentType = 'image/png';
          }
        }
        final storageResponse = await supabase.storage
            .from('post-media')
            .uploadBinary(filePath, imageFile, fileOptions: FileOptions(contentType: contentType));
        _logger.info('Image uploaded (web) to: post-media/$filePath, response: $storageResponse');
      } else {
        // On mobile/desktop, imageFile should be a File
        final fileNameWithExt = imageFile.path.split('/').last;
        filePath = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileNameWithExt';
        // Guess content type from extension
        String contentType = fileNameWithExt.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        final storageResponse = await supabase.storage
            .from('post-media')
            .upload(filePath, imageFile, fileOptions: FileOptions(contentType: contentType));
        _logger.info('Image uploaded (mobile/desktop) to: post-media/$filePath, response: $storageResponse');
      }

      // Get the public URL of the uploaded file
      publicUrl = supabase.storage
          .from('post-media')
          .getPublicUrl(filePath);
      _logger.info('Public URL for image: $publicUrl');
      return publicUrl;
    } catch (e) {
      _logger.severe('Error uploading image to Supabase Storage: $e');
      rethrow;
    }
  }
}
