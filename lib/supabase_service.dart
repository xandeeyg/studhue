import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int likesCount;
  bool isLiked;
  final bool isBookmarked;

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
    this.likesCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
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
      postDate:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      isProduct: json['is_product'] is bool ? json['is_product'] : false,
      productname: json['productname']?.toString(),
      variation: json['variation']?.toString(),
      quantity: json['quantity'] is int ? json['quantity'] : null,
      price: (json['price'] as num?)?.toDouble(),
      likesCount: json['likecount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
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
      id: json['user_id'] as String,
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profession: json['category'] as String? ?? 'N/A',
      iconPath: json['profile_picture'] ?? 'graphics/Profile Icon.png',
      isVerified: json['is_verified'] as bool? ?? false,
      accountCreationDate: DateTime.parse(
        json['account_date_creation'] as String? ??
            DateTime.now().toIso8601String(),
      ),
    );
  }
}

class PinboardInfo {
  final String id;
  final String name;
  final String? coverImageUrl;

  PinboardInfo({required this.id, required this.name, this.coverImageUrl});

  factory PinboardInfo.fromJson(Map<String, dynamic> json) {
    return PinboardInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      coverImageUrl: json['cover_img_url'] as String?, 
    );
  }
}

class SupabaseService {
  static final SupabaseClient supabase = Supabase.instance.client;
  static final Logger _logger = Logger('SupabaseService');

  /// Prints the current user's id to the debug console. Use this for Supabase troubleshooting.
  static void printCurrentUserId() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      print('Current user id: ${user.id}');
    } else {
      print('No user is currently logged in.');
    }
  }

  // Initialize Supabase - call this in main.dart before runApp()
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://guhabojbordlqekofdlz.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd1aGFib2pib3JkbHFla29mZGx6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxNTc1NzMsImV4cCI6MjA2MzczMzU3M30.rAuS0CARpDZzB1K-X71PtZWDIeXDpN-wrVNhQT5wMvk',
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
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (authResponse.user == null) {
        throw Exception('Failed to create user account');
      }
      final String userId = authResponse.user!.id;
      _logger.info('Auth user created with ID: $userId');
      try {
        final response =
            await supabase.from('users').insert({
              'user_id': userId,
              'email': email,
              'full_name': fullName,
              'username': username,
              'age': int.tryParse(age),
              'address': address,
              'phone_number': phoneNumber,
              'password': password,
              'category': category,
              'account_date_creation': DateTime.now().toIso8601String(),
            }).select();
        _logger.info('Insert response: $response');
      } catch (e) {
        _logger.severe('Error inserting user data: $e');
      }
      _logger.info('User profile created successfully');
      return {
        'success': true,
        'message': 'Account created successfully',
        'user': {'user_id': userId, 'email': email, 'username': username},
      };
    } on AuthException catch (e) {
      _logger.severe('Auth error during signup: ${e.message}');
      return {'success': false, 'message': e.message};
    } catch (e) {
      _logger.severe('Error during signup: $e');
      return {'success': false, 'message': e.toString()};
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
      Map<String, dynamic>? userData;
      try {
        userData =
            await supabase
                .from('users')
                .select()
                .eq('user_id', response.user!.id)
                .single();
        _logger.info('Retrieved user data: $userData');
      } catch (e) {
        _logger.warning('Could not retrieve user profile: $e');
      }
      return {
        'success': true,
        'message': 'Login successful',
        'user': {
          'user_id': response.user!.id,
          'email': response.user!.email,
          'username': userData?['username'] ?? '',
        },
      };
    } on AuthException catch (e) {
      _logger.severe('Auth error during login: ${e.message}');
      return {'success': false, 'message': e.message};
    } catch (e) {
      _logger.severe('Error during login: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Logout user
  static Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      _logger.info('User logged out');
    } catch (e) {
      _logger.severe('Error during logout: $e');
    }
  }

  // Get current user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _logger.warning('No user is currently logged in');
        return null;
      }

      // Fetch basic user profile data
      final profileResponse =
          await supabase.from('users').select().eq('user_id', user.id).single();

      // Fetch post count
      final postCountResponse = await supabase
          .from('posts')
          .select('id') 
          .eq('user_id', user.id)
          .count(); 
      final postCount = postCountResponse.count;

      // Fetch followers count
      final followersCountResponse = await supabase
          .from('followers')
          .select('follower_id') 
          .eq('following_id', user.id)
          .count(); 
      final followersCount = followersCountResponse.count;

      // Fetch following count
      final followingCountResponse = await supabase
          .from('followers')
          .select('following_id') 
          .eq('follower_id', user.id)
          .count(); 
      final followingCount = followingCountResponse.count;

      // Combine all data
      final Map<String, dynamic> userProfileData = Map.from(profileResponse);
      userProfileData['post_count'] = postCount;
      userProfileData['followers'] = followersCount;
      userProfileData['following'] = followingCount;

      _logger.info('User profile data with counts: $userProfileData');
      return userProfileData;
    } catch (e) {
      _logger.severe('Error getting user profile with counts: $e');
      return null;
    }
  }

  // Method to get user profile by specific ID, including counts
  static Future<Map<String, dynamic>?> getUserProfileById(String userId) async {
    try {
      _logger.info('Fetching profile for user ID: $userId');

      // Fetch basic user profile data
      final profileResponse = await supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .single();

      // Fetch post count
      final postCountResponse = await supabase
          .from('posts')
          .select('id') 
          .eq('user_id', userId)
          .count();
      final postCount = postCountResponse.count;

      // Fetch followers count
      final followersCountResponse = await supabase
          .from('followers')
          .select('follower_id') 
          .eq('following_id', userId)
          .count();
      final followersCount = followersCountResponse.count;

      // Fetch following count
      final followingCountResponse = await supabase
          .from('followers')
          .select('following_id') 
          .eq('follower_id', userId)
          .count();
      final followingCount = followingCountResponse.count;

      // Combine all data
      final Map<String, dynamic> userProfileData = Map.from(profileResponse);
      userProfileData['post_count'] = postCount;
      userProfileData['followers'] = followersCount;
      userProfileData['following'] = followingCount;

      _logger.info('User profile data with counts for $userId: $userProfileData');
      return userProfileData;
    } catch (e) {
      _logger.severe('Error getting user profile by ID for $userId: $e');
      if (e is PostgrestException && e.code == 'PGRST116') {
        _logger.warning('User with ID $userId not found.');
        return null; 
      }
      return null;
    }
  }

  // Create a post
  static Future<String> createPost({
    required String userId,
    required String caption,
    required String postType,
    required String imageUrl,
    bool isProduct = false,
  }) async {
    try {
      final userProfileResponse =
          await supabase.from('users').select().eq('user_id', userId).single();
      final Map<String, dynamic> postData = {
        'user_id': userId,
        'caption': caption,
        'post_type': postType,
        'image_url': imageUrl,
        'is_product': isProduct,
        'created_at': DateTime.now().toIso8601String(),
        'username': userProfileResponse['username'] ?? '',
        'profession': userProfileResponse['category'] ?? '',
        'is_verified': userProfileResponse['is_verified'] ?? false,
        'verified_offset': 4.0,
        'post_image_path': imageUrl,
        'icon_path':
            userProfileResponse['profile_picture'] ??
            'graphics/Profile Icon.png',
        'productname': null,
        'variation': null,
        'quantity': null,
        'price': null,
      };
      final response =
          await supabase.from('posts').insert(postData).select('id').single();
      final String postId = response['id'] as String;
      _logger.info('Post created with ID: $postId');
      return postId;
    } catch (e) {
      _logger.severe('Error creating post: $e');
      rethrow;
    }
  }

  // Create a new pinboard
  static Future<void> createPinboard({
    required String boardName,
    required String boardDescription,
    required String coverImg,
    required String userId,
  }) async {
    try {
      await supabase
          .from('pinboards') 
          .insert({
            'name': boardName, 
            'board_description': boardDescription, 
            'cover_img_url': coverImg, 
            'user_id': userId, 
            'created_at': DateTime.now().toIso8601String(),
          });
      _logger.info('Pinboard created: $boardName');
    } catch (e) {
      _logger.severe('Error creating pinboard: $e');
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
      await supabase.from('vault_items').insert({
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
      await supabase.from('posts').delete().eq('id', id);
      _logger.info('Post deleted: $id');
    } catch (e) {
      _logger.severe('Error deleting post: $e');
      rethrow;
    }
  }

  // Get posts
  static Future<List<Post>> getPosts() async {
    try {
      final currentUser = supabase.auth.currentUser;
      
      // First, get all posts with like counts
      final allPostsResponse = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> allPostsData = List<Map<String, dynamic>>.from(allPostsResponse);
      
      // Get the current user's liked post IDs if logged in
      Set<String> likedPostIds = {};
      Set<String> allUserPinnedPostIds = {}; 

      if (currentUser != null) {
        // Get user's liked posts
        final likedPostsResponse = await supabase
            .from('post_likes')
            .select('post_id')
            .eq('user_id', currentUser.id);
            
        if (likedPostsResponse != null) {
          likedPostIds = likedPostsResponse
              .map<String>((data) => data['post_id'] as String)
              .toSet();
        }
        
        // Get user's pinned posts
        final userBoardsResponse = await supabase
            .from('pinboards')
            .select('id')
            .eq('user_id', currentUser.id);
            
        if (userBoardsResponse != null && userBoardsResponse.isNotEmpty) {
          final List<String> boardIds = userBoardsResponse
              .map<String>((board) => board['id'] as String)
              .toList();
              
          final pinnedPostsResponse = await supabase
              .from('pinboard_posts')
              .select('post_id')
              .inFilter('board_id', boardIds);
              
          if (pinnedPostsResponse != null) {
            allUserPinnedPostIds = pinnedPostsResponse
                .map<String>((data) => data['post_id'] as String)
                .toSet();
          }
        }
      }

      // Process posts with like and bookmark status
      final postsToReturn = allPostsData.map<Post>((postJson) {
        final String postId = postJson['id']?.toString() ?? '';
        final bool isBookmarked = allUserPinnedPostIds.contains(postId);
        final bool isLiked = likedPostIds.contains(postId);
        
        final Map<String, dynamic> enrichedPostJson = Map<String, dynamic>.from(postJson);
        enrichedPostJson['is_bookmarked'] = isBookmarked;
        enrichedPostJson['isLiked'] = isLiked;
        
        // Ensure like count is set
        if (!enrichedPostJson.containsKey('likecount')) {
          enrichedPostJson['likecount'] = 0;
        }
        
        return Post.fromJson(enrichedPostJson);
      }).toList();

      _logger.info('SupabaseService.getPosts: Returning ${postsToReturn.length} posts.');
      for (var post in postsToReturn) {
        _logger.info('SupabaseService.getPosts: Post ID: ${post.id}, Caption: ${post.caption.substring(0, (post.caption.length > 20 ? 20 : post.caption.length))}..., isLiked: ${post.isLiked}');
      }
      
      return postsToReturn;
    } catch (e) {
      _logger.severe('Error fetching posts with like and bookmark status: $e');
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
      return pinboards
          .map<Map<String, String>>(
            (pinboard) => {
              'name': pinboard['name']?.toString() ?? '',
              'coverImg': pinboard['coverImg']?.toString() ?? '',
            },
          )
          .toList();
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
      return response
          .map<VaultItem>((item) => VaultItem.fromJson(item))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching vault items: $e');
      return [];
    }
  }

  // Get user by username
  static Future<Map<String, dynamic>?> getUserByUsername(
    String username,
  ) async {
    try {
      final response =
          await supabase
              .from('users')
              .select()
              .eq('username', username)
              .maybeSingle();
      return response;
    } catch (e) {
      _logger.severe('Error fetching user by username: $e');
      return null;
    }
  }

  // Search users
  static Future<List<UserProfile>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }
    try {
      final response = await supabase
          .from('users')
          .select()
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .limit(10);
      return response
          .map<UserProfile>((data) => UserProfile.fromJson(data))
          .toList();
    } catch (e) {
      _logger.severe('Error searching users: $e');
      return [];
    }
  }

  // Upload a file
  static Future<String?> uploadFile(File file, String userId) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final String storagePath = 'public/$userId/$fileName';
      await supabase.storage
          .from('posts_media')
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
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

  // Upload post image (supports both File and Uint8List)
  static Future<String> uploadPostImage(
    dynamic imageFile,
    String userId,
  ) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      String filePath;
      String publicUrl;
      if (kIsWeb) {
        filePath = '$userId/$fileName';
        String contentType = 'image/jpeg';
        if (imageFile is List<int> && imageFile.length > 4) {
          if (imageFile[0] == 0x89 &&
              imageFile[1] == 0x50 &&
              imageFile[2] == 0x4E &&
              imageFile[3] == 0x47) {
            contentType = 'image/png';
          }
        }
        final storageResponse = await supabase.storage
            .from('post-media')
            .uploadBinary(
              filePath,
              imageFile,
              fileOptions: FileOptions(contentType: contentType),
            );
        _logger.info(
          'Image uploaded (web) to: post-media/$filePath, response: $storageResponse',
        );
      } else {
        final fileNameWithExt = imageFile.path.split('/').last;
        filePath =
            '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileNameWithExt';
        String contentType =
            fileNameWithExt.toLowerCase().endsWith('.png')
                ? 'image/png'
                : 'image/jpeg';
        final storageResponse = await supabase.storage
            .from('post-media')
            .upload(
              filePath,
              imageFile,
              fileOptions: FileOptions(contentType: contentType),
            );
        _logger.info(
          'Image uploaded (mobile/desktop) to: post-media/$filePath, response: $storageResponse',
        );
      }
      publicUrl = supabase.storage.from('post-media').getPublicUrl(filePath);
      _logger.info('Public URL for image: $publicUrl');
      return publicUrl;
    } catch (e) {
      _logger.severe('Error uploading image to Supabase Storage: $e');
      rethrow;
    }
  }

  // Get all pinboards (id and name) for the current user
  static Future<List<PinboardInfo>> getUserPinboards() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      _logger.warning('Cannot get user pinboards: No user logged in.');
      return [];
    }
    _logger.info('Fetching pinboards for user ID: ${currentUser.id}');

    try {
      final response = await supabase
          .from('pinboards')
          .select('id, name, cover_img_url') 
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: true); 

      final pinboards = response
          .map((item) => PinboardInfo.fromJson(item))
          .toList();
      _logger.info('Fetched ${pinboards.length} pinboards for user ${currentUser.id}');
      return pinboards;
    } catch (e) {
      _logger.severe('Error fetching pinboards for user ${currentUser.id}: $e');
      return [];
    }
  }

  // Add a post to a specific pinboard
  static Future<bool> addPostToPinboard(String postId, String boardId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      _logger.warning('Cannot add post to pinboard: No user logged in.');
      return false;
    }
    try {
      final existingPin = await supabase
          .from('pinboard_posts')
          .select('post_id') 
          .eq('board_id', boardId)
          .eq('post_id', postId)
          .maybeSingle();
      
      if (existingPin != null) {
        _logger.info('Post $postId is already pinned to board $boardId.');
        return true; 
      }

      await supabase.from('pinboard_posts').insert({
        'board_id': boardId,
        'post_id': postId,
      });
      _logger.info('Post $postId added to pinboard $boardId.');
      return true;
    } catch (e) {
      _logger.severe('Error adding post $postId to pinboard $boardId: $e');
      return false;
    }
  }

  // Remove a post from a specific pinboard
  static Future<bool> removePostFromPinboard(String postId, String boardId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      _logger.warning('Cannot remove post from pinboard: No user logged in.');
      return false;
    }

    try {
      await supabase
          .from('pinboard_posts')
          .delete()
          .eq('board_id', boardId)
          .eq('post_id', postId);
      _logger.info('Post $postId removed from pinboard $boardId.');
      return true;
    } catch (e) {
      _logger.severe('Error removing post $postId from pinboard $boardId: $e');
      return false;
    }
  }

  // Get all posts for a specific pinboard_id
  static Future<List<Post>> getPostsForPinboard(String boardId) async {
    try {
      final pinboardPostsResponse = await supabase
          .from('pinboard_posts')
          .select('post_id')
          .eq('board_id', boardId);

      if (pinboardPostsResponse.isEmpty) {
        _logger.info('No posts found for pinboard $boardId.');
        return [];
      }

      final List<String> postIds = pinboardPostsResponse
          .map<String>((data) => data['post_id'] as String)
          .toList();

      if (postIds.isEmpty) return [];

      final postsData = await supabase
          .from('posts')
          .select()
          .inFilter('id', postIds)
          .order('created_at', ascending: false);

      return postsData.map<Post>((postJson) {
        final enrichedJson = Map<String, dynamic>.from(postJson);
        enrichedJson['is_bookmarked'] = true; 
        return Post.fromJson(enrichedJson);
      }).toList();

    } catch (e) {
      _logger.severe('Error fetching posts for pinboard $boardId: $e');
      return [];
    }
  }

  // Check if a specific post is on a specific pinboard
  static Future<bool> isPostOnPinboard(String postId, String boardId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      return false; 
    }
    try {
      final existingPin = await supabase
          .from('pinboard_posts')
          .select('post_id') 
          .eq('board_id', boardId)
          .eq('post_id', postId)
          .maybeSingle();
      
      return existingPin != null;
    } catch (e) {
      _logger.severe('Error checking if post $postId is on pinboard $boardId: $e');
      return false; 
    }
  }

  // Follow a user
  static Future<bool> followUser(String targetUserId) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        _logger.warning('Cannot follow user: No user is logged in');
        return false;
      }
      final existingFollow =
          await supabase
              .from('followers')
              .select()
              .eq('follower_id', currentUser.id)
              .eq('following_id', targetUserId)
              .maybeSingle();
      if (existingFollow != null) {
        _logger.info('Already following this user');
        return true;
      }
      await supabase.from('followers').insert({
        'follower_id': currentUser.id,
        'following_id': targetUserId,
      });
      _logger.info('Successfully followed user: $targetUserId');
      return true;
    } catch (e) {
      _logger.severe('Error following user: $e');
      return false;
    }
  }

  // Unfollow a user
  static Future<bool> unfollowUser(String targetUserId) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        _logger.warning('Cannot unfollow user: No user is logged in');
        return false;
      }
      await supabase
          .from('followers')
          .delete()
          .eq('follower_id', currentUser.id)
          .eq('following_id', targetUserId);
      _logger.info('Successfully unfollowed user: $targetUserId');
      return true;
    } catch (e) {
      _logger.severe('Error unfollowing user: $e');
      return false;
    }
  }

  // Check if current user is following a specific user
  static Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        return false;
      }
      final existingFollow =
          await supabase
              .from('followers')
              .select()
              .eq('follower_id', currentUser.id)
              .eq('following_id', targetUserId)
              .maybeSingle();
      return existingFollow != null;
    } catch (e) {
      _logger.severe('Error checking follow status: $e');
      return false;
    }
  }

  static Future<String?> uploadPinboardCoverImage({
    required String userId,
    required Uint8List imageBytes,
    required String fileName, 
    String? mimeType,       
  }) async {
    const String storageBucket = 'pinboard_covers'; 
    _logger.info('Attempting to upload cover image. Bucket: $storageBucket, User: $userId, Filename: $fileName, MimeType: $mimeType');

    try {
      String extension = 'jpg'; 
      if (fileName.contains('.')) {
        final parts = fileName.split('.');
        if (parts.length > 1) {
          extension = parts.last.toLowerCase();
        }
      }
      
      final uniqueFileNameWithExtension = '${const Uuid().v4()}.$extension';
      final filePath = '$userId/$uniqueFileNameWithExtension'; 

      _logger.info('Uploading to path: $filePath');

      await supabase.storage.from(storageBucket).uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              contentType: mimeType ?? (extension == 'png' ? 'image/png' : 'image/jpeg'), 
            ),
          );
      _logger.info('Binary upload successful for path: $filePath');

      final publicUrl = supabase.storage.from(storageBucket).getPublicUrl(filePath);
      _logger.info('Image successfully uploaded. Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      _logger.severe('Error uploading pinboard cover image to Supabase Storage: $e');
      if (e is StorageException) {
        _logger.severe('StorageException details: ${e.message}, statusCode: ${e.statusCode}, error: ${e.error}');
      }
      return null; 
    }
  }

  static Future<void> signOutUser() async {
    try {
      // Sign out from Supabase auth
      await supabase.auth.signOut();
      _logger.info('User signed out successfully from Supabase auth.');
      
      // Clear all local user session data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('email');
      // Clear any other user-related keys
      await prefs.remove('profile_data');
      await prefs.remove('auth_token');
      
      // Log the cleanup
      _logger.info('Local user session data cleared successfully.');
    } catch (e) {
      _logger.severe('Error during sign out process: $e');
      // Still attempt to clear local data even if Supabase signOut fails
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_id');
        await prefs.remove('username');
        await prefs.remove('email');
        await prefs.remove('profile_data');
        await prefs.remove('auth_token');
        _logger.info('Attempted to clear local data after signOut error.');
      } catch (localError) {
        _logger.severe('Error clearing local data: $localError');
      }
      
      // Rethrow the original error to allow UI to handle it
      rethrow;
    }
  }

  // --- Like/Heart Functionality ---
  static Future<bool> isPostLiked(String postId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;
    final result = await supabase
        .from('post_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();
    return result != null;
  }

  static Future<bool> likePost(String postId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("Not logged in");
      
      // First check if post is already liked
      final isAlreadyLiked = await isPostLiked(postId);
      if (isAlreadyLiked) {
        _logger.info('Post $postId is already liked by user ${user.id}');
        return true; // Return success as the intended state is achieved
      }
      
      // Start a transaction
      await supabase.rpc('like_post', params: {
        'p_post_id': postId,  
        'p_user_id': user.id,  
      });
      
      return true;
    } catch (e) {
      _logger.severe('Error liking post: $e');
      return false;
    }
  }

  static Future<bool> unlikePost(String postId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("Not logged in");
      
      // Start a transaction
      await supabase.rpc('unlike_post', params: {
        'post_id': postId,
        'user_id': user.id,
      });
      
      return true;
    } catch (e) {
      _logger.severe('Error unliking post: $e');
      return false;
    }
  }

  static Future<String?> uploadProfileImage(XFile imageFile, String userId) async {
    try {
      final String originalFileName = imageFile.name; // XFile.name usually includes the extension
      final String fileExtension = originalFileName.contains('.') 
          ? originalFileName.split('.').last 
          : (imageFile.mimeType?.split('/').last ?? 'jpg'); // Fallback extension
      
      final String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}.${const Uuid().v4()}.$fileExtension';
      final String filePath = '$userId/profile_pictures/$uniqueFileName';
      String publicUrl;

      if (kIsWeb) {
        final Uint8List imageBytes = await imageFile.readAsBytes();
        final String contentType = imageFile.mimeType ?? (fileExtension == 'png' ? 'image/png' : 'image/jpeg');
        
        await supabase.storage.from('profilepictures').uploadBinary(
              filePath,
              imageBytes,
              fileOptions: FileOptions(contentType: contentType, upsert: false, cacheControl: '3600'),
            );
        _logger.info('Profile image uploaded (web) to: profilepictures/$filePath');
      } else {
        await supabase.storage.from('profilepictures').upload(
              filePath,
              File(imageFile.path),
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
            );
        _logger.info('Profile image uploaded (mobile/desktop) to: profilepictures/$filePath');
      }

      publicUrl = supabase.storage.from('profilepictures').getPublicUrl(filePath);
      _logger.info('Public URL for profile image: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      _logger.severe('Error uploading profile image for user $userId: $e');
      _logger.severe('Stack trace for profile image upload error: $stackTrace'); 
      if (e is StorageException) {
        _logger.severe('StorageException details: ${e.message}, statusCode: ${e.statusCode}, error: ${e.error}');
      }
      // Consider re-throwing a more specific error or returning a result object
      return null;
    }
  }

  // Method to update user profile information
  static Future<bool> updateUserProfile(String userId, Map<String, dynamic> dataToUpdate) async {
    try {
      // Ensure we don't try to update with an empty map, though Supabase might handle it.
      if (dataToUpdate.isEmpty) {
        _logger.info('No data provided to update for user $userId.');
        return true; // Or false, depending on desired behavior for no-op
      }

      await supabase.from('users').update(dataToUpdate).eq('user_id', userId);
      _logger.info('User profile updated successfully for user $userId with data: $dataToUpdate');
      return true;
    } catch (e) {
      _logger.severe('Error updating user profile for user $userId: $e');
      if (e is PostgrestException) {
        _logger.severe('PostgrestException details: ${e.message}, code: ${e.code}, details: ${e.details}');
      }
      return false;
    }
  }
}
