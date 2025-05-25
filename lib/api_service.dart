import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Post model
class Post {
  final String username;
  final String profession;
  final bool isVerified;
  final String postImagePath;
  final String iconPath;

  Post({
    required this.username,
    required this.profession,
    required this.isVerified,
    required this.postImagePath,
    required this.iconPath,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      username: json['username'],
      profession: json['profession'],
      isVerified: json['isVerified'] ?? false,
      postImagePath: json['postImagePath'],
      iconPath: json['iconPath'],
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
      print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
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

  // Fetch posts
  static Future<List<Post>> fetchPosts() async {
  final token = await getToken(); // Securely retrieve your JWT token

  final response = await http.get(
    Uri.parse('$baseUrl/posts'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Post.fromJson(json)).toList();
  } else {
    throw Exception('Failed to fetch posts');
  }
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
  static Future<void> addProductToVault(Map<String, dynamic> productData) async {
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
