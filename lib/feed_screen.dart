import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class FeedScreen extends StatelessWidget {
  FeedScreen({super.key});

  final List<String> imgUrls = [
    'https://via.placeholder.com/400x300',
    'https://via.placeholder.com/600x500',
    'https://via.placeholder.com/350x400',
    'https://via.placeholder.com/500x600',
    'https://via.placeholder.com/800x300',
    'https://via.placeholder.com/450x600',
    'https://via.placeholder.com/300x300',
    'https://via.placeholder.com/600x400',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinterest-like Layout'),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: MasonryGridView.count(
            crossAxisCount: 2, // 2 columns, you can change to 3 if you want tighter grids
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            itemCount: imgUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imgUrls[index],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}