import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'dart:io';

import 'supabase_service.dart';

enum PostType { regular, product }

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _logger = Logger('CreatePostScreen');
  PostType _postType = PostType.regular;
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _variationController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  
  File? _selectedImage;
  bool _isLoading = false;
  String? _username;
  String? _profession;
  bool _isVerified = false;
  final String _iconPath = 'graphics/icons/icon1.jpg'; // Default icon
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username');
      _profession = prefs.getString('profession') ?? 'Artist';
      _isVerified = prefs.getBool('isVerified') ?? false;
      // You could also load the user's icon path from preferences if available
    });
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _logger.severe('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  Future<void> _createPost() async {
    if (_username == null) {
      _showErrorSnackBar('User not logged in');
      return;
    }
    
    if (_selectedImage == null) {
      _showErrorSnackBar('Please select an image for your post');
      return;
    }
    
    if (_postType == PostType.product) {
      if (_titleController.text.isEmpty ||
          _priceController.text.isEmpty ||
          _variationController.text.isEmpty ||
          _quantityController.text.isEmpty) {
        _showErrorSnackBar('Please fill all required fields for product post');
        return;
      }
    } else {
      if (_descriptionController.text.isEmpty) {
        _showErrorSnackBar('Please add a description for your post');
        return;
      }
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // In a real app, you would upload the image to storage first and get its URL
      // For this example, we'll just use a placeholder image path
      final String postImagePath = _selectedImage != null 
          ? 'graphics/uploads/${DateTime.now().millisecondsSinceEpoch}.jpg' 
          : 'graphics/placeholder.jpg';
      
      await SupabaseService.createPost(
        username: _username!,
        profession: _profession!,
        isVerified: _isVerified,
        postImagePath: postImagePath,
        iconPath: _iconPath,
        isProduct: _postType == PostType.product,
        productname: _postType == PostType.product ? _titleController.text : null,
        variation: _postType == PostType.product ? _variationController.text : null,
        quantity: _postType == PostType.product && _quantityController.text.isNotEmpty 
          ? int.tryParse(_quantityController.text) 
          : null,
        price: _postType == PostType.product && _priceController.text.isNotEmpty 
          ? double.tryParse(_priceController.text) 
          : null,
      );
      
      _logger.info('Post created successfully');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
      
      Navigator.of(context).pop(true); // Return success to previous screen
    } catch (e) {
      _logger.severe('Error creating post: $e');
      if (context.mounted) {
        _showErrorSnackBar('Failed to create post: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showErrorSnackBar(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          _isLoading 
            ? const Center(child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ))
            : TextButton(
                onPressed: _createPost,
                child: const Text('Post', style: TextStyle(color: Colors.blue)),
              ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Type Selector
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<PostType>(
                    segments: const [
                      ButtonSegment<PostType>(
                        value: PostType.regular,
                        label: Text('Regular Post'),
                        icon: Icon(Icons.photo),
                      ),
                      ButtonSegment<PostType>(
                        value: PostType.product,
                        label: Text('Product Post'),
                        icon: Icon(Icons.shopping_bag),
                      ),
                    ],
                    selected: {_postType},
                    onSelectionChanged: (Set<PostType> selection) {
                      setState(() {
                        _postType = selection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: _selectedImage != null 
                    ? DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Tap to add image', style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  : null,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Fields specific to post type
            if (_postType == PostType.product) ...[  
              // Product Title
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Product Title',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Price
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
              
              const SizedBox(height: 16),
              
              // Variation
              TextField(
                controller: _variationController,
                decoration: const InputDecoration(
                  labelText: 'Variation (Size, Color, etc.)',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Quantity
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Available Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              
              const SizedBox(height: 16),
            ] else ...[  
              // Description for regular post
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Write a caption...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ],
        ),
      ),
    );
  }
}