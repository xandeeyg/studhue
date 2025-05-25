import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

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

  dynamic _selectedImageData; // File (mobile/desktop) or Uint8List (web)
  String? _selectedImageName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // This method can be used to load any additional user data if needed
    // Currently, we don't need to load anything here
    await Future.delayed(Duration.zero); // To avoid async/await lint warning
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageData = bytes;
            _selectedImageName = image.name;
          });
        } else {
          setState(() {
            _selectedImageData = File(image.path);
            _selectedImageName = image.name;
          });
        }
      }
    } catch (e) {
      _logger.severe('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
      }
    }
  }

  Future<void> _createPost() async {
    final user = SupabaseService.supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('User not logged in');
      return;
    }

    if (_selectedImageData == null) {
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

    String imageUrl;
    try {
      // Upload the image to Supabase Storage and get its URL
      _logger.info('Starting image upload...');
      imageUrl = await SupabaseService.uploadPostImage(_selectedImageData, user.id);
      _logger.info('Image uploaded successfully. URL: $imageUrl');

      // Determine post type based on whether it's a product or regular post
      final postType = _postType == PostType.product ? 'product' : 'regular';
      
      // For product posts, include product details in the caption
      String caption = _descriptionController.text;
      if (_postType == PostType.product) {
        caption = '${_titleController.text}\n\n$caption\n\n';
        caption += 'Variation: ${_variationController.text}\n';
        caption += 'Price: ${_priceController.text}\n';
        caption += 'Quantity: ${_quantityController.text}';
      }

      // Fetch user profile data
      final userProfile = await SupabaseService.getUserProfile();
      if (userProfile == null) {
        _showErrorSnackBar('Could not fetch user profile');
        setState(() { _isLoading = false; });
        return;
      }

      // Compose the extra fields for the post
      final postData = {
        'user_id': user.id,
        'caption': caption,
        'post_type': postType,
        'image_url': imageUrl,
        'is_product': _postType == PostType.product,
        'post_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        // Required fields for Post.fromJson
        'username': userProfile['username'] ?? '',
        'profession': userProfile['category'] ?? '',
        'is_verified': userProfile['is_verified'] ?? false,
        'verified_offset': 4.0,
        'post_image_path': imageUrl,
        'icon_path': userProfile['icon_path'] ?? 'graphics/Profile Icon.png',
        // Optional product fields
        'productname': _postType == PostType.product ? _titleController.text : null,
        'variation': _postType == PostType.product ? _variationController.text : null,
        'quantity': _postType == PostType.product ? int.tryParse(_quantityController.text) : null,
        'price': _postType == PostType.product ? double.tryParse(_priceController.text) : null,
      };

      // Insert post with all fields
      await SupabaseService.supabase
        .from('posts')
        .insert(postData);


      _logger.info('Post created successfully');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );

      Navigator.of(context).pop(true); // Signal HomeScreen to refresh
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
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
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
            // Image Picker Buttons (Gallery and Camera)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Image Preview
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedImageData == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 50,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No image selected',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    )
                  : kIsWeb
                      ? Image.memory(_selectedImageData as Uint8List, fit: BoxFit.cover)
                      : Image.file(_selectedImageData as File, fit: BoxFit.cover),
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
