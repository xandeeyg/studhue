import 'package:flutter/material.dart';
import 'supabase_service.dart';
// We'll need to import the Post model and potentially a PostCard widget later

class PinnedPostsScreen extends StatefulWidget {
  final String pinboardId;
  final String pinboardName;

  const PinnedPostsScreen({
    super.key,
    required this.pinboardId,
    required this.pinboardName,
  });

  @override
  State<PinnedPostsScreen> createState() => _PinnedPostsScreenState();
}

class _PinnedPostsScreenState extends State<PinnedPostsScreen> {
  late Future<List<Post>> _pinnedPostsFuture;

  @override
  void initState() {
    super.initState();
    _loadPinnedPosts();
  }

  void _loadPinnedPosts() {
    setState(() {
      _pinnedPostsFuture = SupabaseService.getPostsForPinboard(widget.pinboardId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pinboardName, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black), // Ensure back button is visible
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Post>>(
        future: _pinnedPostsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF5E4AD4)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading posts: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No posts pinned to this board yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          final posts = snapshot.data!;

          // TODO: Replace this with a proper PostCard widget similar to home_screen.dart
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: post.postImagePath.isNotEmpty
                      ? Image.network(post.postImagePath, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported, size: 50),
                  title: Text(post.username, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(post.caption.isNotEmpty ? post.caption : 'No caption'),
                  trailing: IconButton(
                    icon: const Icon(Icons.bookmark, color: Color(0xFF5E4AD4)), // Still shows as saved
                    tooltip: 'Remove from this pinboard',
                    onPressed: () async {
                      bool success = await SupabaseService.removePostFromPinboard(post.id, widget.pinboardId);
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Removed "${post.caption.isNotEmpty ? post.caption : 'Post'}" from ${widget.pinboardName}')),
                        );
                        _loadPinnedPosts(); // Refresh the list
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to remove post. Please try again.')),
                        );
                      }
                    },
                  ), 
                ),
              );
            },
          );
        },
      ),
    );
  }
}
