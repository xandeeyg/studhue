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

  @override
  void initState() {
    super.initState();
    _loadUsernameAndPosts();
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
            ? const SearchBar()
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
            child: FutureBuilder<List<Post>>(
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
                    return _buildPost(
                      id: post.id,
                      username: post.username,
                      profession: post.profession,
                      isVerified: post.isVerified,
                      verifiedOffset: 128,
                      postImagePath: post.postImagePath,
                      iconPath: post.iconPath,
                      isOwner: post.username == _loggedInUsername,
                      isProduct: post.isProduct,
                      productname: post.productname,
                      variation: post.variation,
                      quantity: post.quantity,
                      price: post.price,
                    );
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

  Widget _buildPost({
    required String id,
    required String username,
    required String profession,
    required bool isVerified,
    required double verifiedOffset,
    required String postImagePath,
    required String iconPath,
    required bool isOwner,
    bool isProduct = false,
    String? productname,
    String? variation,
    int? quantity,
    double? price,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            child: Row(
              children: [
                Image.asset(iconPath, width: 43, height: 43),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          Image.asset(
                            'graphics/Verified Icon.png',
                            width: 13,
                            height: 12,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      profession,
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Post'),
                          content: const Text('Are you sure you want to delete this post?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _deletePost(id);
                      }
                    },
                  )
                else
                  const Icon(Icons.more_vert),
              ],
            ),
          ),
          Image.asset(
            postImagePath,
            height: 393,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          if (isProduct)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Add to ArtVault'),
                onPressed: () async {
                  if (_loggedInUsername == null) return;
                  await SupabaseService.addToVault(
                    username: _loggedInUsername!,
                    productname: productname ?? '',
                    variation: variation ?? '',
                    quantity: quantity ?? 1,
                    price: price ?? 0.0,
                    iconUrl: iconPath,
                    imageUrl: postImagePath,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to ArtVault!')),
                    );
                  }
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Row(
              children: [
                Image.asset('graphics/Heart.png', width: 25.5, height: 22.667),
                const SizedBox(width: 15),
                Image.asset('graphics/Comment.png', width: 25.5, height: 22.667),
                const SizedBox(width: 15),
                const Icon(Icons.send_outlined, size: 24),
                const Spacer(),
                const Icon(Icons.bookmark_border, size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  const SearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xffd6d6d6),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Row(
        children: [
          SizedBox(width: 8),
          Icon(Icons.search, size: 20, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Color.fromRGBO(123, 123, 123, 1)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 12),
              ),
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
    );
  }
}
