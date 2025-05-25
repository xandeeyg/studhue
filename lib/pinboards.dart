import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter/cupertino.dart';
import 'supabase_service.dart';
import 'pinboards_create_dialog.dart';

class PinboardsScreen extends StatefulWidget {
  const PinboardsScreen({super.key});

  @override
  State<PinboardsScreen> createState() => _PinboardsScreenState();
}

class _PinboardsScreenState extends State<PinboardsScreen> {
  // ... existing code ...

  late Future<List<Map<String, String>>> _pinboardsFuture;

  @override
  void initState() {
    super.initState();
    // Replace with actual token logic
    const dummyToken = 'your_jwt_token_here';
    _pinboardsFuture = SupabaseService.getPinboards(dummyToken);
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('graphics/Homeheader.png',  height: 32),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.notifications_none_outlined), onPressed: () {
                      Navigator.pushNamed(context, "/notifications");
                    },),
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
                          setState(() {
                            // Replace with actual token logic if needed
                            const dummyToken = 'your_jwt_token_here';
                            _pinboardsFuture = SupabaseService.getPinboards(dummyToken);
                          });
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
              child: FutureBuilder<List<Map<String, String>>>(
                future: _pinboardsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No pinboards found.'));
                  }

                  final pinboards = snapshot.data!;
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: pinboards.length,
                    itemBuilder: (context, index) {
                      final board = pinboards[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(board['coverImg']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [Colors.black.withAlpha((0.7 * 255).round()), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                board['name']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
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
                    color: const Color.fromRGBO(20, 193, 225, 100),
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
                    icon: const Icon(Icons.person_outline),
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
