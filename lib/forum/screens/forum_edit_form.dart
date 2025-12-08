// =============================================================================
// Forum Edit Form Page
// =============================================================================
// This page allows users to edit their existing forum posts.
// Features:
// - Edit title, content, category, sport_category
// - Link to products (UUID) and locations (Integer ID)
// - Admin-only: Pin/Unpin posts
// - Form validation with minimum character requirements
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../models/forum_post.dart';

/// Page for editing an existing forum post
class ForumEditFormPage extends StatefulWidget {
  /// The post to be edited
  final ForumPost post;
  
  /// Current user's role (needed for admin-only features like pinning)
  final String? currentUserRole;

  const ForumEditFormPage({
    super.key,
    required this.post,
    this.currentUserRole,
  });

  @override
  State<ForumEditFormPage> createState() => _ForumEditFormPageState();
}

class _ForumEditFormPageState extends State<ForumEditFormPage> {
  // ---------------------------------------------------------------------------
  // Form Key & Controllers
  // ---------------------------------------------------------------------------
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers for editable fields
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _productIdController;
  late TextEditingController _locationIdController;
  
  // ---------------------------------------------------------------------------
  // Form State Variables
  // ---------------------------------------------------------------------------
  late String _category;
  late String _sportCategory;
  late bool _isPinned;
  bool _isLoading = false;

  // ---------------------------------------------------------------------------
  // Category Options (matching Django model choices)
  // ---------------------------------------------------------------------------
  
  /// Post category options
  static const List<Map<String, String>> categoryOptions = [
    {'value': 'general', 'label': 'General Discussion'},
    {'value': 'product_review', 'label': 'Product Review'},
    {'value': 'location_review', 'label': 'Location Review'},
    {'value': 'question', 'label': 'Question'},
    {'value': 'announcement', 'label': 'Announcement'},
    {'value': 'feedback', 'label': 'Feedback'},
  ];

  /// Sport category options
  static const List<Map<String, String>> sportCategoryOptions = [
    {'value': 'running', 'label': 'Running'},
    {'value': 'cycling', 'label': 'Cycling'},
    {'value': 'swimming', 'label': 'Swimming'},
  ];

  // ---------------------------------------------------------------------------
  // Lifecycle Methods
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing post data
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.fullContent);
    _productIdController = TextEditingController(text: widget.post.productId ?? '');
    _locationIdController = TextEditingController(
      text: widget.post.locationId?.toString() ?? '',
    );
    
    // Initialize dropdown values
    _category = widget.post.category;
    _sportCategory = widget.post.sportCategory;
    _isPinned = widget.post.isPinned;
  }

  @override
  void dispose() {
    // Clean up controllers
    _titleController.dispose();
    _contentController.dispose();
    _productIdController.dispose();
    _locationIdController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helper Methods
  // ---------------------------------------------------------------------------

  /// Check if current user is an admin
  bool get isAdmin => widget.currentUserRole == 'ADMIN';

  /// Submit the edited post to the server
  Future<void> _submitEdit() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = context.read<CookieRequest>();
      
      // Build the request body
      final Map<String, dynamic> body = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _category,
        'sport_category': _sportCategory,
      };
      
      // Add optional product_id if provided
      if (_productIdController.text.trim().isNotEmpty) {
        body['product_id'] = _productIdController.text.trim();
      }
      
      // Add optional location_id if provided
      if (_locationIdController.text.trim().isNotEmpty) {
        body['location_id'] = _locationIdController.text.trim();
      }
      
      // Add is_pinned only if user is admin
      if (isAdmin) {
        body['is_pinned'] = _isPinned;
      }

      // Send PUT/POST request to edit endpoint
      final response = await request.postJson(
        '$baseUrl/forum/${widget.post.id}/edit/',
        jsonEncode(body),
      );

      if (!mounted) return;

      if (response['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Return true to indicate successful edit
        Navigator.pop(context, true);
      } else {
        // Show error message from server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Failed to update post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build Methods
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
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
              // -----------------------------------------------------------------
              // Title Field
              // -----------------------------------------------------------------
              _buildSectionHeader('Title', Icons.title),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter post title (min 5 characters)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title cannot be empty';
                  }
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // -----------------------------------------------------------------
              // Content Field
              // -----------------------------------------------------------------
              _buildSectionHeader('Content', Icons.article),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: 'Write your post content (min 10 characters)...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Content cannot be empty';
                  }
                  if (value.trim().length < 10) {
                    return 'Content must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // -----------------------------------------------------------------
              // Category Dropdowns
              // -----------------------------------------------------------------
              _buildSectionHeader('Categories', Icons.category),
              const SizedBox(height: 8),
              
              // Post Category Dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Post Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: categoryOptions
                    .map((option) => DropdownMenuItem(
                          value: option['value'],
                          child: Text(option['label']!),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Sport Category Dropdown
              DropdownButtonFormField<String>(
                value: _sportCategory,
                decoration: InputDecoration(
                  labelText: 'Sport Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: sportCategoryOptions
                    .map((option) => DropdownMenuItem(
                          value: option['value'],
                          child: Row(
                            children: [
                              _getSportIcon(option['value']!),
                              const SizedBox(width: 8),
                              Text(option['label']!),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sportCategory = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              // -----------------------------------------------------------------
              // External Links Section
              // -----------------------------------------------------------------
              _buildSectionHeader('External Links (Optional)', Icons.link),
              const SizedBox(height: 8),
              
              // Product ID Field
              TextFormField(
                controller: _productIdController,
                decoration: InputDecoration(
                  labelText: 'Product ID (UUID)',
                  hintText: 'Enter product UUID to link',
                  prefixIcon: const Icon(Icons.shopping_bag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  helperText: 'Link to a product from the shop',
                ),
                validator: (value) {
                  // Optional field, but validate UUID format if provided
                  if (value != null && value.trim().isNotEmpty) {
                    // Basic UUID format check
                    final uuidRegex = RegExp(
                      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
                    );
                    if (!uuidRegex.hasMatch(value.trim())) {
                      return 'Invalid UUID format';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location ID Field
              TextFormField(
                controller: _locationIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Location ID',
                  hintText: 'Enter location/place ID to link',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  helperText: 'Link to a location/place',
                ),
                validator: (value) {
                  // Optional field, but validate integer format if provided
                  if (value != null && value.trim().isNotEmpty) {
                    if (int.tryParse(value.trim()) == null) {
                      return 'Location ID must be a number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // -----------------------------------------------------------------
              // Admin-Only: Pin Post Section
              // -----------------------------------------------------------------
              if (isAdmin) ...[
                _buildSectionHeader('Admin Options', Icons.admin_panel_settings),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Pin this post',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      'Pinned posts appear at the top of the forum list',
                      style: TextStyle(fontSize: 12),
                    ),
                    secondary: Icon(
                      Icons.push_pin,
                      color: _isPinned ? Colors.orange : Colors.grey,
                    ),
                    value: _isPinned,
                    activeColor: Colors.orange,
                    onChanged: (value) {
                      setState(() => _isPinned = value);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // -----------------------------------------------------------------
              // Submit Button
              // -----------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitEdit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Update Post',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a section header with icon and text
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1D4ED8)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D4ED8),
          ),
        ),
      ],
    );
  }

  /// Get sport category icon
  Widget _getSportIcon(String sport) {
    switch (sport) {
      case 'running':
        return const Text('🏃', style: TextStyle(fontSize: 16));
      case 'cycling':
        return const Text('🚴', style: TextStyle(fontSize: 16));
      case 'swimming':
        return const Text('🏊', style: TextStyle(fontSize: 16));
      default:
        return const Icon(Icons.sports, size: 16);
    }
  }
}
