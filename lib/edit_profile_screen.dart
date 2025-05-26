import 'package:flutter/material.dart';
import 'supabase_service.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'dart:io'; 

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  String? _profileImageUrl;
  bool _isLoading = true;
  XFile? _selectedImageFile; 

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userProfile = await SupabaseService.getUserProfile();
      if (userProfile != null && mounted) {
        setState(() {
          _usernameController.text = userProfile['username'] ?? '';
          _bioController.text = userProfile['bio'] ?? ''; 
          _profileImageUrl = userProfile['profile_image_url']; 
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: $e')),
        );
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null && mounted) {
        setState(() {
          _selectedImageFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do not proceed
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final userId = SupabaseService.supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      String? newProfileImageUrl = _profileImageUrl; // Keep old image URL by default

      // 1. Upload new profile image if changed
      if (_selectedImageFile != null) {
        final uploadedUrl = await SupabaseService.uploadProfileImage(_selectedImageFile!, userId);
        if (uploadedUrl != null) {
          newProfileImageUrl = uploadedUrl;
        } else {
          // Handle image upload failure, maybe show a specific message
          throw Exception('Failed to upload new profile image.');
        }
      }

      // 2. Prepare data for Supabase update
      final Map<String, dynamic> updates = {
        'username': _usernameController.text,
        'bio': _bioController.text,
        // Only include profile_image_url if it has changed or was initially null and now has a value
        // This prevents unnecessarily setting it to the same value or to null if it wasn't changed.
        if (newProfileImageUrl != _profileImageUrl || (_profileImageUrl == null && newProfileImageUrl != null))
          'profile_image_url': newProfileImageUrl,
      };

      // Remove keys with null values if your backend/updateUserProfile method doesn't handle them well
      // or if you only want to send actual changes.
      // updates.removeWhere((key, value) => value == null && key != 'profile_image_url'); 
      // Special care for profile_image_url if you want to allow setting it to null explicitly.

      print('Updating profile with data: $updates');

      // Call SupabaseService.updateUserProfile
      final bool success = await SupabaseService.updateUserProfile(userId, updates);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          // Optionally, pass back a value to indicate success if the ProfileScreen needs to refresh
          Navigator.pop(context, true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile. Please try again.')),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _selectedImageFile != null
                                ? FileImage(File(_selectedImageFile!.path)) 
                                : (_profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!) 
                                    : null) as ImageProvider?,
                            child: _selectedImageFile == null && _profileImageUrl == null
                                ? const Icon(Icons.person, size: 50) 
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt),
                              onPressed: _pickImage, 
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
