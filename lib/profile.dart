import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  List<Map<String, dynamic>> userPosts = [];
  final _supabase = Supabase.instance.client;

  Future<void> loadProfile() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      print('DEBUG: Attempting direct data fetch without authentication');
      
      try {
        // Direct fetch of first user from database (for demo purposes)
        final userData = await _supabase
            .from('users')
            .select()
            .limit(1)
            .single();
            
        print('DEBUG: Fetched user data: $userData');
        
        if (userData == null) {
          throw Exception('No user data found');
        }
        
        // Create a mock profile with the user data
        final mockProfile = {
          ...userData as Map<String, dynamic>,
          'post_count': 0,
          'followers': 0,
          'following': 0,
        };
        
        // Fetch this user's posts
        try {
          final posts = await _supabase
              .from('posts')
              .select()
              .eq('user_id', userData['user_id'])
              .order('post_date', ascending: false);
          
          print('DEBUG: User posts: ${posts.length}');
          
          setState(() {
            profileData = mockProfile;
            userPosts = List<Map<String, dynamic>>.from(posts ?? []);
            isLoading = false;
          });
        } catch (postsError) {
          print('DEBUG: Error fetching posts: $postsError');
          setState(() {
            profileData = mockProfile;
            userPosts = [];
            isLoading = false;
          });
        }
      } catch (e) {
        print('DEBUG: Supabase fetch error: $e');
        
        // Fallback to hardcoded mock data
        final mockData = {
          'username': 'demo_user',
          'full_name': 'Demo User',
          'bio_title': 'Flutter Developer',
          'post_count': 0,
          'followers': 0,
          'following': 0,
        };
        
        setState(() {
          profileData = mockData;
          userPosts = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Unexpected error: $e');
      
      // Final fallback
      setState(() {
        profileData = {
          'username': 'error_user',
          'full_name': 'Error occurred',
          'post_count': 0,
          'followers': 0,
          'following': 0,
        };
        isLoading = false;
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
          child: isLoading
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
                            print('Fetching user data directly from users table');
                            setState(() {
                              isLoading = true;
                            });
                            // Fetch a specific user by username (this should work regardless of auth status)
                            final userData = await SupabaseService.supabase
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
                              SnackBar(content: Text('Data fetch failed: $e')),
                            );
                          }
                        },
                        child: Text('Load User Data'),
                      ),
                      
                    // Top Row
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                profileData != null && profileData!['username'] != null
                                    ? profileData!['username'].toString()
                                    : profileData != null && profileData!['email'] != null
                                        ? profileData!['email'].toString().split('@').first
                                        : 'No Username',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 5),
                              // Only show verified icon for artists
                              if (profileData != null && 
                                  profileData!['category'] != null && 
                                  profileData!['category'].toString().toLowerCase() == 'artist')
                                Image.asset(
                                  'graphics/Verified Icon.png', 
                                  width: 16, 
                                  height: 16,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.verified, size: 16, color: Colors.blue);
                                  },
                                ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.menu),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Profile Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[200],
                          child: profileData?['profile_picture'] != null
                              ? CircleAvatar(
                                  radius: 40,
                                  backgroundImage: NetworkImage(profileData!['profile_picture']),
                                  onBackgroundImageError: (exception, stackTrace) {
                                    // Fallback to icon if image fails to load
                                    print('Error loading profile image: $exception');
                                  },
                                  child: null,
                                )
                              : Icon(Icons.person, size: 40, color: Colors.grey[800]),
                        ),
                        Column(
                          children: [
                            Text(
                              profileData?['post_count'].toString() ?? "0",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text("Posts"),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              profileData?['followers'].toString() ?? "0",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text("Followers"),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              profileData?['following'].toString() ?? "0",
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
                            profileData?['bio'] ??
                                'This user has no bio.',
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
                                        child: post['image_url'] != null
                                            ? Image.network(
                                                post['image_url'],
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                              loadingProgress.expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error, stackTrace) =>
                                                    Container(
                                                      color: Colors.grey[200],
                                                      child: const Icon(Icons.error),
                                                    ),
                                              )
                                            : Container(
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.image_not_supported),
                                              ),
                                      ),
                                    );
                                  },
                                ),

                          // Products Tab
                          const Center(child: Text("No products available")),
                        ],
                      ),
                    ),
                  ],
                ),
        ),

        // Bottom Navigation
        bottomNavigationBar: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.5 * 255).round()),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.pushNamed(context, "/home");
                },
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.pin),
                onPressed: () {
                  Navigator.pushNamed(context, "/pinboards");
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_box_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(LucideIcons.vault),
                onPressed: () {
                  Navigator.pushNamed(context, "/vault");
                },
              ),
              IconButton(
                icon: const Icon(Icons.person),
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
