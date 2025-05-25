import 'package:flutter/material.dart';
import 'supabase_service.dart';

class CreatePinboardDialog extends StatefulWidget {
  const CreatePinboardDialog({super.key});

  @override
  State<CreatePinboardDialog> createState() => _CreatePinboardDialogState();
}

class _CreatePinboardDialogState extends State<CreatePinboardDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _coverImgController = TextEditingController();
  bool _isLoading = false;

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
                validator: (v) => v == null || v.isEmpty ? 'Enter a name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Board Description'),
                validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
              ),
              TextFormField(
                controller: _coverImgController,
                decoration: const InputDecoration(labelText: 'Cover Image URL'),
                validator: (v) => v == null || v.isEmpty ? 'Enter image URL' : null,
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
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState?.validate() != true) return;
                  setState(() => _isLoading = true);
                  try {
                    await SupabaseService.createPinboard(
                      name: _nameController.text.trim(),
                      details: _descriptionController.text.trim(),
                      coverImg: _coverImgController.text.trim(),
                    );
                    if (!mounted) return;
                    Navigator.of(context).pop(true);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    if (!mounted) return;
setState(() => _isLoading = false);
                  }
                },
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'),
        ),
      ],
    );
  }
}
