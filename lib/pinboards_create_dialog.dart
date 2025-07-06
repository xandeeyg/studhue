import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class CreatePinboardDialog extends StatefulWidget {
  const CreatePinboardDialog({super.key});

  @override
  State<CreatePinboardDialog> createState() => _CreatePinboardDialogState();
}

class _CreatePinboardDialogState extends State<CreatePinboardDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = pickedFile.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Pinboard'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Board Name'),
                validator:
                    (v) => v == null || v.isEmpty ? 'Enter a name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Board Description',
                ),
                validator:
                    (v) => v == null || v.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child:
                      _selectedImageBytes != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                          )
                          : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: Colors.grey[600],
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to select cover image',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                ),
              ),
              if (_selectedImageBytes == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Optional: Add a cover image for your pinboard.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _isLoading
                  ? null
                  : () async {
                    if (_formKey.currentState?.validate() != true) return;
                    setState(() => _isLoading = true);
                    try {
                      final currentUser =
                          Supabase.instance.client.auth.currentUser;
                      if (currentUser == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error: User not logged in.'),
                            ),
                          );
                        }
                        return;
                      }
                      final userId = currentUser.id;

                      String coverImageUrl = '';
                      if (_selectedImageBytes != null &&
                          _selectedImageName != null) {
                        // In the NEXT STEP, we will upload _selectedImageBytes to Supabase Storage
                        // using _selectedImageName.
                        print(
                          'Image bytes selected: $_selectedImageName - UPLOAD LOGIC PENDING',
                        );
                      }

                      await SupabaseService.createPinboard(
                        boardName: _nameController.text.trim(),
                        boardDescription: _descriptionController.text.trim(),
                        coverImg: coverImageUrl,
                        userId: userId,
                      );
                      if (!mounted) return;
                      Navigator.of(context).pop(true);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error creating pinboard: $e'),
                          ),
                        );
                      }
                    } finally {
                      if (!mounted) return;
                      setState(() => _isLoading = false);
                    }
                  },
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Create'),
        ),
      ],
    );
  }
}
