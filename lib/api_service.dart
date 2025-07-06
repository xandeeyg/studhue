import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

// Post model
class Post {
  final String id;
  final String userId;
  final String caption;
  final String postType;
  final DateTime postDate;
  final String? imageUrl;
  // User details (joined from users table)
  final String username;
  final String? profilePicture;
  final String? userProfession;

  Post({
    required this.id,
    required this.userId,
    required this.caption,
    required this.postType,
    required this.postDate,
    this.imageUrl,
    required this.username,
    this.profilePicture,
    this.userProfession = 'Artist', // Default value
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      caption: json['caption'] ?? '',
      postType: json['post_type'] ?? 'regular',
      postDate:
          json['post_date'] != null
              ? DateTime.parse(json['post_date'])
              : DateTime.now(),
      imageUrl: json['image_url'],
      username: json['username'] ?? 'Unknown',
      profilePicture: json['profile_picture'],
      userProfession: json['profession'],
    );
  }
}

// VaultItem model
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
      iconUrl: json['iconUrl'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'productname': productname,
      'variation': variation,
      'quantity': quantity,
      'price': price,
      'iconUrl': iconUrl,
      'imageUrl': imageUrl,
    };
  }
}

class ApiService {
  static const String baseUrl = 'http://192.168.0.111:3000/api';

  static final _logger = Logger('ApiService');

  // Initialize logging — call once, e.g. in main()
  static void setupLogging() {
    Logger.root.level = Level.ALL; // Capture all logs
    Logger.root.onRecord.listen((record) {
      print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
      );
    });
  }

  // Get JWT token from SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // LOGIN
  static Future<Map<String, dynamic>> loginUser({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/users/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      _logger.info('User logged in successfully.');
      return jsonDecode(response.body);
    } else {
      _logger.severe('Failed to login: ${response.body}');
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // SIGN UP
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
    final url = Uri.parse('$baseUrl/users/signup');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "username": username,
        "password": password,
        "fullName": fullName,
        "phoneNumber": phoneNumber,
        "age": age,
        "address": address,
        "category": category, // 'artist' or 'regular'
      }),
    );

    if (response.statusCode == 201) {
      _logger.info('User registered successfully.');
      return jsonDecode(response.body);
    } else {
      _logger.severe('Signup failed: ${response.body}');
      throw Exception('Signup failed: ${response.body}');
    }
  }

  // Fetch user profile
  static Future<Map<String, dynamic>?> fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      _logger.warning('JWT token not found; user might not be logged in.');
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      _logger.info('Fetched profile data successfully.');
      return jsonDecode(response.body);
    } else {
      _logger.warning('Failed to fetch profile: ${response.body}');
      return null;
    }
  }

  // Fetch posts with user details
  static Future<List<Post>> fetchPosts() async {
    final logger = Logger('ApiService');
    try {
      // First, try to fetch from Supabase
      try {
        // Check if user is authenticated
        final user = SupabaseService.supabase.auth.currentUser;
        if (user == null) {
          logger.warning(
            'JWT token not found; user might not be logged in. Using mock data.',
          );
          throw Exception('Not authenticated');
        }

        // Add timeout to avoid hanging
        final response = await SupabaseService.supabase
            .from('posts')
            .select('''
              *, 
              user:user_id (username, profile_picture, category)
            ''')
            .order('post_date', ascending: false)
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                throw TimeoutException('Supabase request timed out');
              },
            );

        logger.info(
          'Successfully fetched ${response.length} posts from Supabase',
        );

        return (response as List).map((data) => Post.fromJson(data)).toList();
      } catch (e) {
        logger.warning('Error fetching from Supabase: $e');
        // Continue to the HTTP fallback
      }

      // Fallback to HTTP API if Supabase fails
      final token = await getToken();
      final response = await http
          .get(
            Uri.parse('$baseUrl/posts'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Post.fromJson(json)).toList();
      }
      logger.warning('Failed to fetch posts: ${response.statusCode}');
    } catch (e) {
      logger.warning('Error fetching posts: $e');
    }

    // Return mock data when all else fails
    return [
      Post(
        id: 'mock-1',
        userId: 'user-1',
        caption: 'Check out my latest design!',
        postType: 'regular',
        postDate: DateTime.now(),
        // imageUrl: 'graphics/Background.png',
        username: 'johndoe',
        profilePicture: 'graphics/Profile Icon.png',
        userProfession: 'Graphic Designer',
      ),
      Post(
        id: 'mock-2',
        userId: 'user-2',
        caption: 'New product available in my store!',
        postType: 'product',
        postDate: DateTime.now().subtract(const Duration(hours: 2)),
        imageUrl: 'graphics/Logo 1.png',
        username: 'janedoe',
        profilePicture: 'graphics/Profile Icon.png',
        userProfession: 'UI/UX Designer',
      ),
    ];
  }

  // Fetch vault items
  static Future<List<VaultItem>> fetchVaultItems() async {
    final response = await http.get(Uri.parse('$baseUrl/vault'));

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((item) => VaultItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load vault items');
    }
  }

  // Add product to vault
  static Future<void> addProductToVault(
    Map<String, dynamic> productData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vault/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(productData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add product to vault');
    }
  }

  Future<List<Map<String, String>>> fetchPinboards(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/pinboards'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) {
        return {
          'name': item['name']?.toString() ?? '',
          'coverImg': item['coverImg']?.toString() ?? '',
        };
      }).toList();
    } else {
      throw Exception('Failed to load pinboards');
    }
  }
}
