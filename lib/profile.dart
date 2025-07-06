import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  List<Map<String, dynamic>> userPosts = [];
  List<Map<String, dynamic>> userProducts = []; // only is_product == true
  final _supabase = Supabase.instance.client;

  Future<void> loadProfile() async {
    try {
      setState(() {
        isLoading = true;
      });

      print(
        'DEBUG: Attempting to fetch current user profile using SupabaseService.getUserProfile',
      );

      final fetchedProfileData = await SupabaseService.getUserProfile();

      if (fetchedProfileData == null) {
        print('DEBUG: Failed to fetch profile data from SupabaseService.');
        // Attempt to get username from shared preferences as fallback or handle error
        try {
          final prefs = await SharedPreferences.getInstance();
          final username = prefs.getString('username');
          if (username != null) {
            setState(() {
              profileData = {
                'username': username,
                'profile_picture': 'graphics/Profile Icon.png', // Default icon
                'post_count': 0,
                'followers': 0,
                'following': 0,
              };
              userPosts = [];
              isLoading = false;
            });
            print(
              'DEBUG: Using fallback profile data from SharedPreferences for username: $username',
            );
          } else {
            throw Exception(
              'No user data found and no username in SharedPreferences',
            );
          }
        } catch (e) {
          print('DEBUG: Error in fallback or no fallback available: $e');
          setState(() {
            isLoading = false;
            // Optionally, set profileData to an error state or leave it null
            profileData = null;
            userPosts = [];
          });
        }
        return; // Exit if profile data couldn't be fetched
      }

      print(
        'DEBUG: Fetched user data via SupabaseService: $fetchedProfileData',
      );

      // Fetch this user's posts
      // Ensure 'user_id' is present in fetchedProfileData before using it.
      final userId = fetchedProfileData['user_id'] ?? fetchedProfileData['id'];
      // The key might be 'id' or 'user_id' depending on how SupabaseService.getUserProfile structures it after combining results.
      // It's safer to check both or standardize in SupabaseService.
      // For now, assuming 'user_id' is the primary key from the 'users' table part of the response.

      if (userId == null) {
        print(
          'DEBUG: User ID is null in fetchedProfileData. Cannot fetch posts.',
        );
        setState(() {
          profileData = fetchedProfileData;
          userPosts = [];
          isLoading = false;
        });
        return;
      }

      try {
        final posts = await _supabase
            .from('posts')
            .select()
            .eq('user_id', userId) // Use the userId from fetchedProfileData
            .order('post_date', ascending: false);

        print('DEBUG: User posts: ${posts.length}');

        // Separate regular posts and product posts
        final List<Map<String, dynamic>> allPosts = List<Map<String, dynamic>>.from(posts);
        final List<Map<String, dynamic>> productsOnly = allPosts.where((p) => p['is_product'] == true || p['is_product'] == 1 || p['is_product'] == 't' || p['is_product'] == 'true').toList();
        final List<Map<String, dynamic>> regularOnly = allPosts.where((p) => !(p['is_product'] == true || p['is_product'] == 1 || p['is_product'] == 't' || p['is_product'] == 'true')).toList();

        setState(() {
          profileData = fetchedProfileData; // This already contains the counts
          userProducts = productsOnly;
          userPosts = regularOnly;
          isLoading = false;
        });
      } catch (postsError) {
        print('DEBUG: Error fetching posts: $postsError');
        setState(() {
          profileData =
              fetchedProfileData; // Still set profileData, even if posts fail
          userPosts = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: General error in loadProfile: $e');
      setState(() {
        isLoading = false;
        // Optionally, set profileData to an error state or leave it null
        profileData = null;
        userPosts = [];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    // Removed fixed post images

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    children: [
                      // Debug Button for Direct Data Fetch
                      if (isLoading)
                        Center(child: CircularProgressIndicator())
                      else if (profileData == null)
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              // Direct data fetch without authentication
                              print(
                                'Fetching user data directly from users table',
                              );
                              setState(() {
                                isLoading = true;
                              });
                              // Fetch a specific user by username (this should work regardless of auth status)
                              final userData =
                                  await SupabaseService.supabase
                                      .from('users')
                                      .select('*')
                                      .limit(1)
                                      .single();

                              print('Fetched user data directly: $userData');

                              setState(() {
                                profileData = userData;
                                isLoading = false;
                              });
                            } catch (e) {
                              print('Data fetch error: $e');
                              setState(() {
                                isLoading = false;
                              });
                              // Show error to user
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Data fetch failed: $e'),
                                ),
                              );
                            }
                          },
                          child: Text('Load User Data'),
                        ),

                      // Top Row - App Bar with username
                      AppBar(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        centerTitle: true,
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              profileData != null &&
                                      profileData!['username'] != null
                                  ? profileData!['username'].toString()
                                  : profileData != null &&
                                      profileData!['email'] != null
                                  ? profileData!['email']
                                      .toString()
                                      .split('@')
                                      .first
                                  : 'No Username',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 5),
                            // Only show verified icon for artists
                            if (profileData != null &&
                                profileData!['category'] != null &&
                                profileData!['category']
                                        .toString()
                                        .toLowerCase() ==
                                    'artist')
                              Image.asset(
                                'graphics/Verified Icon.png',
                                width: 18,
                                height: 18,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.verified,
                                    size: 18,
                                    color: Colors.blue,
                                  );
                                },
                              ),
                          ],
                        ),
                        actions: <Widget>[
                          Builder(
                            builder: (BuildContext menuContext) {
                              // Use this new context for the SnackBar
                              return PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.menu,
                                  color: Colors.black,
                                ),
                                onSelected: (String result) async {
                                  switch (result) {
                                    case 'editProfile':
                                      print(
                                        'Edit Profile selected (from Builder context)',
                                      );
                                      Navigator.pushNamed(
                                        menuContext,
                                        '/edit_profile',
                                      );
                                      break;
                                    case 'logout':
                                      print('Logout selected');
                                      try {
                                        await SupabaseService.signOutUser();
                                        if (mounted) {
                                          // Navigate to the login screen and clear navigation stack
                                          Navigator.of(
                                            menuContext,
                                          ).pushNamedAndRemoveUntil(
                                            '/log',
                                            (Route<dynamic> route) => false,
                                          );
                                        }
                                      } catch (e) {
                                        print('Error during logout: $e');
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            menuContext,
                                          ).showSnackBar(
                                            // menuContext here
                                            SnackBar(
                                              content: Text(
                                                'Logout failed: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                      break;
                                  }
                                },
                                itemBuilder:
                                    (BuildContext context) =>
                                        <PopupMenuEntry<String>>[
                                          const PopupMenuItem<String>(
                                            value: 'editProfile',
                                            child: Text('Edit Profile'),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'logout',
                                            child: Text('Logout'),
                                          ),
                                        ],
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Profile Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            child:
                                profileData?['profile_image_url'] != null
                                    ? CircleAvatar(
                                      radius: 40,
                                      backgroundImage: NetworkImage(
                                        profileData!['profile_image_url'],
                                      ),
                                      onBackgroundImageError: (
                                        exception,
                                        stackTrace,
                                      ) {
                                        // Fallback to icon if image fails to load
                                        print(
                                          'Error loading profile image: $exception',
                                        );
                                      },
                                      child: null,
                                    )
                                    : Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.grey[800],
                                    ),
                          ),
                          Column(
                            children: [
                              Text(
                                (profileData?['post_count'] ?? 0).toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text("Posts"),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                (profileData?['followers'] ?? 0).toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text("Followers"),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                (profileData?['following'] ?? 0).toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text("Following"),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Bio
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profileData?['bio_title'] ?? '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              profileData?['bio'] ?? 'This user has no bio.',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Tabs
                      const TabBar(
                        labelColor: Colors.pink,
                        unselectedLabelColor: Colors.black,
                        indicatorColor: Colors.pink,
                        tabs: [
                          Tab(icon: Icon(Icons.grid_view), text: "Posts"),
                          Tab(
                            icon: Icon(LucideIcons.shopping_basket),
                            text: "Products",
                          ),
                        ],
                      ),

                      // Tab Views
                      Expanded(
                        child: TabBarView(
                          children: [
                            // User's Posts Grid
                            userPosts.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No posts yet',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                                : GridView.builder(
                                  padding: const EdgeInsets.all(10),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 5,
                                        mainAxisSpacing: 5,
                                      ),
                                  itemCount: userPosts.length,
                                  itemBuilder: (context, index) {
                                    final post = userPosts[index];
                                    return GestureDetector(
                                      onTap: () {
                                        // TODO: Show post details
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child:
                                            post['image_url'] != null
                                                ? Image.network(
                                                  post['image_url'],
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (
                                                    context,
                                                    child,
                                                    loadingProgress,
                                                  ) {
                                                    if (loadingProgress ==
                                                        null) {
                                                      return child;
                                                    }
                                                    return Center(
                                                      child: CircularProgressIndicator(
                                                        value:
                                                            loadingProgress
                                                                        .expectedTotalBytes !=
                                                                    null
                                                                ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                    loadingProgress
                                                                        .expectedTotalBytes!
                                                                : null,
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        color: Colors.grey[200],
                                                        child: const Icon(
                                                          Icons.error,
                                                        ),
                                                      ),
                                                )
                                                : Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                  ),
                                                ),
                                      ),
                                    );
                                  },
                                ),

                            // Products Tab
                            userProducts.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No products yet',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                )
                                : GridView.builder(
                                  padding: const EdgeInsets.all(10),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 5,
                                    mainAxisSpacing: 5,
                                  ),
                                  itemCount: userProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = userProducts[index];
                                    return GestureDetector(
                                      onTap: () {
                                        // TODO: Show product post details
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: product['image_url'] != null
                                            ? Image.network(
                                              product['image_url'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.error)),
                                            )
                                            : Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                                      ),
                                    );
                                  },
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
        ),

        // Bottom Navigation
        bottomNavigationBar: Container(
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.house, size: 24),
                onPressed: () {
                  Navigator.pushNamed(context, "/home");
                },
              ),
              IconButton(
                icon: const Icon(LucideIcons.pin, size: 22),
                onPressed: () {
                  Navigator.pushNamed(context, "/pinboards");
                },
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xff14c1e1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
                onPressed: () => Navigator.pushNamed(context, "/createpost"),
              ),
              IconButton(
                icon: const Icon(LucideIcons.vault, size: 25),
                onPressed: () {
                  Navigator.pushNamed(context, "/vault");
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, size: 28),
                color: const Color.fromRGBO(20, 193, 225, 100),
                onPressed: () {
                  Navigator.pushNamed(context, "/profile");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
