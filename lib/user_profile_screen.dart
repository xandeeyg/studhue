import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'supabase_service.dart';
import 'package:flutter/cupertino.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  bool isFollowing = false;
  bool isProcessing = false;

  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
    });

    // Fetch user profile data
    final data = await SupabaseService.getUserByUsername(widget.username);
    
    if (data != null && data['user_id'] != null) {
      // Check if current user is following this user
      final followStatus = await SupabaseService.isFollowing(data['user_id']);
      
      setState(() {
        profileData = data;
        isFollowing = followStatus;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> toggleFollow() async {
    if (profileData == null || profileData!['user_id'] == null) return;
    
    setState(() {
      isProcessing = true;
    });

    bool success;
    if (isFollowing) {
      // Unfollow
      success = await SupabaseService.unfollowUser(profileData!['user_id']);
    } else {
      // Follow
      success = await SupabaseService.followUser(profileData!['user_id']);
    }

    if (success) {
      setState(() {
        isFollowing = !isFollowing;
        isProcessing = false;
      });
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFollowing 
              ? 'Failed to unfollow ${widget.username}' 
              : 'Failed to follow ${widget.username}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> postImages = [
      'graphics/profile posts/post1.jpg',
      'graphics/profile posts/post2.jpg',
      'graphics/profile posts/post3.jpg',
      'graphics/profile posts/post4.jpg',
      'graphics/profile posts/post5.jpg',
      'graphics/profile posts/post6.jpg',
      'graphics/profile posts/post7.jpg',
      'graphics/profile posts/post8.jpg',
      'graphics/profile posts/post9.jpg',
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Top Row
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          Text(
                            profileData?['username'] ?? "User",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 5),
                          Image.asset('graphics/Verified Icon.png'),
                          const Spacer(),
                          const Icon(Icons.more_vert),
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
                          backgroundImage: NetworkImage(profileData?['profile_picture'] ??
                              'https://via.placeholder.com/150'),
                        ),
                        Column(
                          children: [
                            Text(
                              profileData?['post_count']?.toString() ?? "0",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text("Posts"),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              profileData?['followers']?.toString() ?? "0",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text("Followers"),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              profileData?['following']?.toString() ?? "0",
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
                            profileData?['full_name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            profileData?['bio_title'] ?? profileData?['category'] ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            profileData?['bio'] ??
                                'This user has no bio.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Follow Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isProcessing ? null : toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing ? Colors.grey[200] : const Color.fromRGBO(20, 193, 225, 100),
                            foregroundColor: isFollowing ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                  ),
                                )
                              : Text(
                                  isFollowing ? 'Following' : 'Follow',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

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
                          // Posts Tab (placeholder images for now)
                          GridView.builder(
                            padding: const EdgeInsets.all(10),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5,
                            ),
                            itemCount: postImages.length,
                            itemBuilder: (context, index) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                postImages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          // Products Tab
                          const Center(child: Text("Products Coming Soon")),
                        ],
                      ),
                    ),
                  ],
                ),
        ),

        // Bottom Navigation
        bottomNavigationBar: Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
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
                    onPressed: () {
                      Navigator.pushNamed(context, "/createpost");
                    },
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.vault),
                    onPressed: () {
                      Navigator.pushNamed(context, "/vault");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () {
                      Navigator.pushNamed(context, "/profile");
                    },
                  ),
                ],
              ),
            ),
          ),
      ),
    );
  }
}
