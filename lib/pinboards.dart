import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter/cupertino.dart';
import 'supabase_service.dart';
import 'pinboards_create_dialog.dart';
import 'pinned_posts_screen.dart';

class PinboardsScreen extends StatefulWidget {
  const PinboardsScreen({super.key});

  @override
  State<PinboardsScreen> createState() => _PinboardsScreenState();
}

class _PinboardsScreenState extends State<PinboardsScreen> {
  // ... existing code ...

  late Future<List<PinboardInfo>> _pinboardsFuture;

  @override
  void initState() {
    super.initState();
    _loadPinboards();
  }

  void _loadPinboards() {
    setState(() {
      _pinboardsFuture = SupabaseService.getUserPinboards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Nav
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset("graphics/Logo A.png", height: 70),
                  Row(
                    children: [
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
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search your saved arts',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => const CreatePinboardDialog(),
                        );
                        if (result == true) {
                          _loadPinboards();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Grid of Pinboards from API
            Expanded(
              child: FutureBuilder<List<PinboardInfo>>(
                future: _pinboardsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5E4AD4),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No pinboards yet. Create one!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  final pinboards = snapshot.data!;
                  // Log the cover image URLs for debugging
                  for (var board in pinboards) {
                    print(
                      'Pinboard: ${board.name}, Cover Image URL: ${board.coverImageUrl}',
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: pinboards.length,
                    itemBuilder: (context, index) {
                      final board = pinboards[index];
                      Widget coverImageWidget;
                      if (board.coverImageUrl != null &&
                          board.coverImageUrl!.isNotEmpty) {
                        coverImageWidget = Image.network(
                          board.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(
                                  LucideIcons.image_off,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (
                            BuildContext context,
                            Widget child,
                            ImageChunkEvent? loadingProgress,
                          ) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                color: Color(0xFF5E4AD4),
                              ),
                            );
                          },
                        );
                      } else {
                        coverImageWidget = Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              LucideIcons.image,
                              size: 50,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        );
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PinnedPostsScreen(
                                    pinboardId: board.id,
                                    pinboardName: board.name,
                                  ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned.fill(child: coverImageWidget),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.0),
                                      Colors.black.withOpacity(0.7),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: [0.5, 1.0],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: Text(
                                  board.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    shadows: <Shadow>[
                                      Shadow(
                                        offset: Offset(0.0, 1.0),
                                        blurRadius: 3.0,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Bottom Nav
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
              onPressed: () => Navigator.pushNamed(context, "/home"),
            ),
            IconButton(
              icon: const Icon(LucideIcons.pin, size: 22),
              color: const Color.fromRGBO(20, 193, 225, 100),
              onPressed: () => Navigator.pushNamed(context, "/pinboards"),
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
              onPressed: () => Navigator.pushNamed(context, "/vault"),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, size: 28),
              onPressed: () => Navigator.pushNamed(context, "/profile"),
            ),
          ],
        ),
      ),
    );
  }
}
