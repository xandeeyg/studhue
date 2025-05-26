import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'supabase_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? profileData;
  List<Map<String, dynamic>> userPosts = [];
  bool isLoading = true;
  bool isFollowing = false;
  bool isProcessing = false;
  final _logger = Logger('UserProfileScreen');

  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch initial user data to get user_id
      _logger.info('Fetching initial data for ${widget.username}');
      final initialData = await SupabaseService.getUserByUsername(widget.username);

      if (initialData != null && (initialData['user_id'] != null || initialData['id'] != null)) {
        final userId = initialData['user_id'] ?? initialData['id'] as String?;
        if (userId == null) {
            _logger.warning('User ID is null after fetching initial data for ${widget.username}.');
            setState(() {
                isLoading = false;
                // Handle error: essential ID missing
            });
            return;
        }
        _logger.info('Fetched initial data for ${widget.username}, user ID: $userId. Now fetching full profile with counts.');

        // Fetch full profile data including counts using the userId
        final fullProfileData = await SupabaseService.getUserProfileById(userId);

        if (fullProfileData != null) {
          // Check if current user is following this user
          final followStatus = await SupabaseService.isFollowing(userId);
          _logger.info('Follow status for $userId: $followStatus');

          // Fetch user's posts
          List<Map<String, dynamic>> fetchedPosts = [];
          try {
            _logger.info('Fetching posts for user ID: $userId');
            final postsResponse = await SupabaseService.supabase
                .from('posts')
                .select()
                .eq('user_id', userId)
                .order('created_at', ascending: false); // Assuming 'created_at' field for ordering
            
            fetchedPosts = List<Map<String, dynamic>>.from(postsResponse);
            _logger.info('Fetched ${fetchedPosts.length} posts for user ID: $userId');
          } catch (e) {
            _logger.severe('Error fetching posts for user ID $userId: $e');
            // Continue without posts if fetching fails, or handle error appropriately
          }

          setState(() {
            profileData = fullProfileData; // Use the data with counts
            userPosts = fetchedPosts; // Set the fetched posts
            isFollowing = followStatus;
            isLoading = false;
          });
        } else {
          _logger.warning('Failed to fetch full profile data for user ID: $userId');
          setState(() {
            // Keep initial data if full profile fails, or handle error appropriately
            profileData = initialData; 
            isLoading = false;
            // Consider showing an error message to the user
          });
        }
      } else {
        _logger.warning('Failed to fetch initial user data for ${widget.username} or user_id/id is null.');
        setState(() {
          isLoading = false;
          // Handle error: user not found or essential ID missing
        });
      }
    } catch (e) {
      _logger.severe('Error in loadProfile for ${widget.username}: $e');
      setState(() {
        isLoading = false;
        // Handle general error
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
            content: Text(
              isFollowing
                  ? 'Failed to unfollow ${widget.username}'
                  : 'Failed to follow ${widget.username}',
            ),
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
    _logger.info('UserProfileScreen initState for ${widget.username}');
    loadProfile();
  }

  @override
  Widget build(BuildContext context) {
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                            backgroundImage: NetworkImage(
                              profileData?['profile_picture'] ??
                                  'https://via.placeholder.com/150',
                            ),
                          ),
                          // Post Count
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

                          // Followers Count
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

                          // Following Count
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
                              profileData?['full_name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              profileData?['bio_title'] ??
                                  profileData?['category'] ??
                                  '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              profileData?['bio'] ?? 'This user has no bio.',
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
                              backgroundColor:
                                  isFollowing
                                      ? Colors.grey[200]
                                      : const Color.fromRGBO(20, 193, 225, 100),
                              foregroundColor:
                                  isFollowing ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child:
                                isProcessing
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.grey,
                                            ),
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
                            // Posts Tab
                            userPosts.isEmpty && !isLoading
                                ? const Center(child: Text("This user hasn't posted yet."))
                                : GridView.builder(
                                    padding: const EdgeInsets.all(10),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 5,
                                          mainAxisSpacing: 5,
                                        ),
                                    itemCount: userPosts.length, // Use actual post count
                                    itemBuilder:
                                        (context, index) {
                                          final post = userPosts[index];
                                          final imageUrl = post['post_image_path'] as String?;
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: imageUrl != null && imageUrl.isNotEmpty
                                                ? Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Center(
                                                        child: CircularProgressIndicator(
                                                          value: loadingProgress.expectedTotalBytes != null
                                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                              : null,
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      _logger.warning('Failed to load image: $imageUrl, Error: $error');
                                                      return Container(
                                                        color: Colors.grey[200],
                                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                                      );
                                                    },
                                                  )
                                                : Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                                  ),
                                          );
                                        },
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
