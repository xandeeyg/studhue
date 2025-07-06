import 'package:flutter/material.dart';
import 'supabase_service.dart'; // Import your existing API service
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
// import 'package:flutter_lucide/icons.dart'; // Removed incorrect import
import 'user_profile_screen.dart';

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

  Future<void> _deletePost(String id) async {
    await SupabaseService.deletePost(id);
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

  Future<void> _showPinboardsDialog(BuildContext context, Post post) async {
    final List<PinboardInfo> userPinboards =
        await SupabaseService.getUserPinboards();

    if (!mounted) return; // Check if the widget is still in the tree

    if (userPinboards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have no pinboards. Create one first!'),
        ),
      );
      return;
    }

    // For each pinboard, check if the current post is on it
    List<bool> isPostOnEachPinboard = [];
    try {
      isPostOnEachPinboard = await Future.wait(
        userPinboards
            .map(
              (pinboard) =>
                  SupabaseService.isPostOnPinboard(post.id, pinboard.id),
            )
            .toList(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking pinboard statuses: $e')),
      );
      return;
    }

    if (!mounted) return; // Re-check after async operations

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use a StatefulWidget for the dialog content if it needs its own internal state management for checkboxes
        // For simplicity here, we'll manage it by rebuilding the dialog or relying on the post-action refresh
        return AlertDialog(
          title: Text(
            'Save to Pinboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: userPinboards.length,
              itemBuilder: (BuildContext listContext, int index) {
                final pinboard = userPinboards[index];
                final bool isPinnedToThisBoard = isPostOnEachPinboard[index];
                return ListTile(
                  title: Text(pinboard.name, style: TextStyle(fontSize: 16)),
                  trailing: Checkbox(
                    value: isPinnedToThisBoard,
                    onChanged: (bool? newValue) async {
                      if (!mounted) return;
                      Navigator.pop(dialogContext); // Close dialog immediately

                      bool success;
                      if (isPinnedToThisBoard) {
                        // If it was pinned, unpin it
                        success = await SupabaseService.removePostFromPinboard(
                          post.id,
                          pinboard.id,
                        );
                      } else {
                        // If it was not pinned, pin it
                        success = await SupabaseService.addPostToPinboard(
                          post.id,
                          pinboard.id,
                        );
                      }

                      if (!mounted) return;
                      if (success) {
                        // Refresh all posts to update isBookmarked status correctly
                        _loadUsernameAndPosts();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update pinboard.')),
                        );
                      }
                    },
                    activeColor: Color(0xFF5E4AD4), // Theme color
                  ),
                  onTap: () async {
                    // Also allow tapping the row
                    if (!mounted) return;
                    Navigator.pop(dialogContext);
                    bool success;
                    if (isPinnedToThisBoard) {
                      success = await SupabaseService.removePostFromPinboard(
                        post.id,
                        pinboard.id,
                      );
                    } else {
                      success = await SupabaseService.addPostToPinboard(
                        post.id,
                        pinboard.id,
                      );
                    }
                    if (!mounted) return;
                    if (success) {
                      _loadUsernameAndPosts();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update pinboard.')),
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF5E4AD4)),
              ), // Theme color
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title:
            _isSearchBarVisible
                ? SearchBarWidget(
                  controller: _searchController,
                  onChanged: _performSearch,
                )
                : Image.asset('graphics/Logo A.png', height: 70),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearchBar,
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {
              Navigator.pushNamed(context, "/notifications");
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 70), // space for nav bar
            child:
                _isSearchBarVisible && _searchController.text.isNotEmpty
                    ? _buildSearchResults()
                    : FutureBuilder<List<Post>>(
                      future: _postsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('No posts available.'),
                          );
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
                    color: const Color.fromRGBO(20, 193, 225, 100),
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
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    onPressed:
                        () => Navigator.pushNamed(context, "/createpost"),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.vault, size: 24),
                    onPressed: () {
                      Navigator.pushNamed(context, "/vault");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline, size: 28),
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
      return const Center(
        child: Text('Type to search for users.'),
      ); // Or any placeholder
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        // Navigate to user's profile on tap, or implement other interaction
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                user.iconPath != null && user.iconPath!.startsWith('http')
                    ? NetworkImage(user.iconPath!)
                    : const AssetImage('graphics/Profile Icon.png'),
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
                GestureDetector(
                  onTap: () {
                    // Navigate to user profile screen when profile picture is clicked
                    if (post.username != _loggedInUsername) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  UserProfileScreen(username: post.username),
                        ),
                      );
                    } else {
                      // If it's the current user, go to their own profile
                      Navigator.pushNamed(context, "/profile");
                    }
                  },
                  child: CircleAvatar(
                    backgroundImage:
                        post.iconPath.isNotEmpty &&
                                post.iconPath.startsWith('http')
                            ? NetworkImage(post.iconPath)
                            : const AssetImage('graphics/Profile Icon.png'),
                    radius: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Navigate to user profile screen when username is clicked
                            if (post.username != _loggedInUsername) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => UserProfileScreen(
                                        username: post.username,
                                      ),
                                ),
                              );
                            } else {
                              // If it's the current user, go to their own profile
                              Navigator.pushNamed(context, "/profile");
                            }
                          },
                          child: Text(
                            post.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                              'Are you sure you want to delete this post?',
                            ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    StatefulBuilder(
                      builder: (context, sbSetState) {
                        // Create local state variables that start with the post's values
                        bool isLiked = post.isLiked;
                        int likesCount = post.likesCount;
                        bool isLiking = false;

                        return IconButton(
                          icon: Icon(
                            isLiked ? LucideIcons.heart : LucideIcons.heart,
                            color: isLiked ? Colors.red : Colors.black,
                            size: 25,
                          ),
                          onPressed:
                              isLiking
                                  ? null
                                  : () async {
                                    sbSetState(() => isLiking = true);
                                    bool success;

                                    if (!isLiked) {
                                      // Like the post
                                      success = await SupabaseService.likePost(
                                        post.id,
                                      );
                                      if (success) {
                                        sbSetState(() {
                                          isLiked = true;
                                          likesCount++;
                                        });
                                        // update underlying post model then rebuild outer widget
                                        post.isLiked = true;
                                        post.likesCount = likesCount;
                                        if (mounted) setState(() {});
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Failed to like post.',
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      // Unlike the post
                                      success =
                                          await SupabaseService.unlikePost(
                                            post.id,
                                          );
                                      if (success) {
                                        sbSetState(() {
                                          isLiked = false;
                                          likesCount =
                                              likesCount > 0
                                                  ? likesCount - 1
                                                  : 0;
                                        });
                                        post.isLiked = false;
                                        post.likesCount = likesCount;
                                        if (mounted) setState(() {});
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Failed to unlike post.',
                                            ),
                                          ),
                                        );
                                      }
                                    }

                                    setState(() => isLiking = false);
                                  },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.message_circle, size: 25),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.send, size: 25),
                      onPressed: () {},
                    ),
                    // Cart button
                    if (post.isProduct &&
                        post.productname != null &&
                        post.productname!.isNotEmpty)
                      StatefulBuilder(
                        builder: (context, cartSetState) {
                          bool isInCart = post.isInCart;
                          bool working = false;

                          return IconButton(
                            icon: Icon(
                              LucideIcons.shopping_bag,
                              color:
                                  isInCart
                                      ? const Color.fromARGB(255, 250, 221, 4)
                                      : Colors.black,
                              size: 25,
                            ),
                            onPressed:
                                working
                                    ? null
                                    : () async {
                                      cartSetState(() => working = true);
                                      final currentUser =
                                          SupabaseService
                                              .supabase
                                              .auth
                                              .currentUser;
                                      if (currentUser == null) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please sign in first',
                                              ),
                                            ),
                                          );
                                        }
                                        cartSetState(() => working = false);
                                        return;
                                      }

                                      bool actionSuccess = false;
                                      if (!isInCart) {
                                        actionSuccess =
                                            await SupabaseService.addToCart(
                                              currentUser.id,
                                              post.id,
                                              post.productname!,
                                              post.variation,
                                              post.price ?? 0.0,
                                              post.postImagePath,
                                            );
                                        if (actionSuccess) {
                                          await SupabaseService.addToVault(
                                            username: post.username,
                                            productname: post.productname!,
                                            variation: post.variation ?? '',
                                            quantity: 1,
                                            price: post.price ?? 0.0,
                                            iconUrl: post.iconPath,
                                            imageUrl: post.postImagePath,
                                          );
                                          isInCart = true;
                                          post.isInCart = true;
                                        }
                                      } else {
                                        actionSuccess =
                                            await SupabaseService.removeFromCart(
                                              currentUser.id,
                                              post.productname!,
                                              variation: post.variation,
                                            );
                                        if (actionSuccess) {
                                          isInCart = false;
                                          post.isInCart = false;
                                        }
                                      }

                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              actionSuccess
                                                  ? (isInCart
                                                      ? 'Added to vault!'
                                                      : 'Removed from vault')
                                                  : 'Action failed',
                                            ),
                                          ),
                                        );
                                      }

                                      cartSetState(() => working = false);
                                    },
                          );
                        },
                      ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    post.isBookmarked ? LucideIcons.pin : LucideIcons.pin,
                    size: 24,
                    color:
                        post.isBookmarked
                            ? Color(0xFF5E4AD4)
                            : Colors.black, // Theme color if bookmarked
                  ),
                  onPressed: () {
                    _showPinboardsDialog(context, post);
                  },
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
                Text(
                  '${post.likesCount} likes',
                  style: const TextStyle(
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

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(18),
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
