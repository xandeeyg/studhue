import 'package:flutter/material.dart';
import 'supabase_service.dart'; // Import your existing API service
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool _isSearchBarVisible = false;
  late Future<List<Post>> _postsFuture;
  String? _loggedInUsername;
  final _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsernameAndPosts();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty && _currentSearchQuery.isNotEmpty) {
        _clearSearch();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsernameAndPosts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInUsername = prefs.getString('username');
      _postsFuture = SupabaseService.getPosts();
    });
  }

  Future<void> _deletePost(String postId) async {
    await SupabaseService.deletePost(postId);
    // Refresh posts after deletion
    setState(() {
      _postsFuture = SupabaseService.getPosts();
    });
  }

  void _toggleSearchBar() {
    setState(() {
      _isSearchBarVisible = !_isSearchBarVisible;
      if (!_isSearchBarVisible) {
        _clearSearch(); // Clear search when hiding the bar
      }
    });
  }

  Future<void> _performSearch(String query) async {
    _currentSearchQuery = query;
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await SupabaseService.searchUsers(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      // Handle error, e.g., show a snackbar
      print('Error searching users: $e');
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _currentSearchQuery = '';
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _isSearchBarVisible
            ? SearchBarWidget(
                controller: _searchController,
                onChanged: _performSearch,
              )
            : Image.asset('graphics/Homeheader.png', height: 32),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearchBar,
          ),
          IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none_outlined), onPressed: () {
            Navigator.pushNamed(context, "/notifications");
          }),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 70), // space for nav bar
            child: _isSearchBarVisible && _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : FutureBuilder<List<Post>>(
                    future: _postsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No posts available.'));
                      }

                      final posts = snapshot.data!;

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return _buildPost(post);
                        },
                      );
                    },
                  ),
          ),
          Positioned(
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
                    color: const Color.fromRGBO(20, 193, 225, 100),
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
                    icon: const Icon(Icons.person_outline),
                    onPressed: () {
                      Navigator.pushNamed(context, "/profile");
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: Text('No users found.'));
    }
    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
      return const Center(child: Text('Type to search for users.')); // Or any placeholder
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        // Navigate to user's profile on tap, or implement other interaction
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.iconPath != null && user.iconPath!.startsWith('http')
                ? NetworkImage(user.iconPath!)
                : AssetImage(user.iconPath ?? 'graphics/Profile Icon.png') as ImageProvider,
          ),
          title: Text(user.fullName.isNotEmpty ? user.fullName : user.username),
          subtitle: Text(user.profession ?? 'No profession listed'),
          onTap: () {
            // Example: Navigate to a user profile screen
            // Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: user.id)));
            print('Tapped on user: ${user.username}');
          },
        );
      },
    );
  }

  Widget _buildPost(Post post) {
    // Determine if the logged-in user is the owner of the post
    bool isOwner = post.username == _loggedInUsername;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and delete button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(post.iconPath),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (post.isVerified)
                          Padding(
                            padding: EdgeInsets.only(left: post.verifiedOffset),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      post.profession,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 28),
                    onPressed: () {
                      // Show delete confirmation dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete Post'),
                            content: const Text(
                                'Are you sure you want to delete this post?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text('Delete'),
                                onPressed: () {
                                  _deletePost(post.id);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
          // Post image
          if (post.postImagePath.isNotEmpty)
            Image.network(
              post.postImagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300, // Adjust height as needed
            ),
          // Action buttons (like, comment, share, bookmark)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.heart, size: 28),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.message_circle, size: 28),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.send, size: 28),
                      onPressed: () {},
                    ),
                  ],
                ),
                // Product details section
                if (post.isProduct &&
                    post.productname != null &&
                    post.productname!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SHOP NOW',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border, size: 28),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // Like count and caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1,234 likes', // Placeholder for actual like count
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (post.caption.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        TextSpan(
                          text: '${post.username} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: post.caption),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                const Text(
                  'View all 42 comments', // Placeholder for comment count
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeAgo(post.postDate),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} MONTHS AGO';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} DAYS AGO';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} HOURS AGO';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} MINUTES AGO';
    } else {
      return 'JUST NOW';
    }
  }
}

// Renamed to avoid conflict with Flutter's built-in SearchBar class
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SearchBarWidget({super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xffd6d6d6),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Icon(Icons.search, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(color: Color.fromRGBO(123, 123, 123, 1)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 12),
              ),
            ),
          ),
          // Optional: Add a clear button
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
              onPressed: () {
                controller.clear();
                onChanged(''); // Notify that search query is now empty
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
