import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';

class ForumFormPage extends StatefulWidget {
  const ForumFormPage({super.key});

  @override
  State<ForumFormPage> createState() => _ForumFormPageState();
}

class _ForumFormPageState extends State<ForumFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _content = '';
  String _category = 'general';
  String _sportCategory = 'running';

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Forum Post'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter post title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => _title = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Title cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Content',
                  hintText: 'Write your post content...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => _content = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Content cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'general', child: Text('General Discussion')),
                  DropdownMenuItem(
                      value: 'product_review', child: Text('Product Review')),
                  DropdownMenuItem(
                      value: 'location_review', child: Text('Location Review')),
                  DropdownMenuItem(value: 'question', child: Text('Question')),
                  DropdownMenuItem(
                      value: 'announcement', child: Text('Announcement')),
                  DropdownMenuItem(value: 'feedback', child: Text('Feedback')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _sportCategory,
                decoration: InputDecoration(
                  labelText: 'Sport Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'running', child: Text('Running')),
                  DropdownMenuItem(value: 'cycling', child: Text('Cycling')),
                  DropdownMenuItem(value: 'swimming', child: Text('Swimming')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sportCategory = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    try {
                      final response = await request.postJson(
                        '$baseUrl/forum/ajax/add/',
                        jsonEncode({
                          'title': _title,
                          'content': _content,
                          'category': _category,
                          'sport_category': _sportCategory,
                        }),
                      );

                      if (!context.mounted) return;

                      if (response['status'] == 'success') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Post created successfully!')),
                        );
                        Navigator.pop(context, true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  response['message'] ?? 'Failed to create post')),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: const Text(
                    'Create Post',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
