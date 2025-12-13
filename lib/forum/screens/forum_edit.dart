// =============================================================================
// ForumEditPage - Edit Forum Post Screen
// =============================================================================
// This screen allows users to edit their existing forum posts.
// Features:
// - Edit title, content, category, sport_category
// - Link to products (UUID) or locations (Integer ID)
// - Admin-only: toggle is_pinned status
// - Form validation with minimum length requirements
// - Shows last_edited timestamp after successful edit
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../models/forum_post.dart';

/// Screen for editing an existing forum post
class ForumEditPage extends StatefulWidget {
  /// The post to edit - contains all current values
  final ForumPost post;

  const ForumEditPage({super.key, required this.post});

  @override
  State<ForumEditPage> createState() => _ForumEditPageState();
}

class _ForumEditPageState extends State<ForumEditPage> {
  // ===========================================================================
  // Form Key and Controllers
  // ===========================================================================
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers for form fields
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _productIdController;
  late TextEditingController _locationIdController;

  // ===========================================================================
  // Form State Variables
  // ===========================================================================
  late String _category;
  late String _sportCategory;
  late bool _isPinned;
  bool _isLoading = false;

  // ===========================================================================
  // Category Options (matching Django choices)
  // ===========================================================================
  
  /// Post category choices - matches Django ForumPost.CATEGORY_CHOICES
  static const List<Map<String, String>> _categoryOptions = [
    {'value': 'general', 'label': 'General Discussion'},
    {'value': 'product_review', 'label': 'Product Review'},
    {'value': 'location_review', 'label': 'Location Review'},
    {'value': 'question', 'label': 'Question'},
    {'value': 'announcement', 'label': 'Announcement'},
    {'value': 'feedback', 'label': 'Feedback'},
  ];

  /// Sport category choices - matches Django ForumPost.SPORT_CATEGORY_CHOICES
  static const List<Map<String, String>> _sportCategoryOptions = [
    {'value': 'running', 'label': 'Running'},
    {'value': 'cycling', 'label': 'Cycling'},
    {'value': 'swimming', 'label': 'Swimming'},
  ];

  // ===========================================================================
  // Lifecycle Methods
  // ===========================================================================

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

  // ===========================================================================
  // Form Submission
  // ===========================================================================

  /// Submit the edited post to the Django API
  Future<void> _submitEdit() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final request = context.read<CookieRequest>();

    try {
      // Build request body
      final Map<String, dynamic> body = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _category,
        'sport_category': _sportCategory,
        'is_pinned': _isPinned,
      };

      // Add optional product_id if provided
      if (_productIdController.text.trim().isNotEmpty) {
        body['product_id'] = _productIdController.text.trim();
      }

      // Add optional location_id if provided (convert to int)
      if (_locationIdController.text.trim().isNotEmpty) {
        body['location_id'] = _locationIdController.text.trim();
      }

      // Send POST request to edit endpoint
      final response = await request.postJson(
        '$baseUrl/forum/${widget.post.id}/edit/',
        jsonEncode(body),
      );

      if (!mounted) return;

      // Handle response
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
        // Show error from server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Failed to update post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Show error message
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

  // ===========================================================================
  // Build Method
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // Get current user info from request
    final request = context.watch<CookieRequest>();
    final isAdmin = request.jsonData['role'] == 'ADMIN';

    return Scaffold(
      // -----------------------------------------------------------------------
      // App Bar
      // -----------------------------------------------------------------------
      appBar: AppBar(
        title: const Text('Edit Post'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      
      // -----------------------------------------------------------------------
      // Body - Edit Form
      // -----------------------------------------------------------------------
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -----------------------------------------------------------------
              // Info Banner - Shows what fields were changed
              // -----------------------------------------------------------------
              if (widget.post.hasBeenEdited)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Last edited: ${widget.post.lastEdited}',
                          style: TextStyle(color: Colors.amber[900], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // -----------------------------------------------------------------
              // Title Field
              // -----------------------------------------------------------------
              _buildSectionTitle('Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter post title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title cannot be empty';
                  }
                  // Match Django validation: min 5 characters
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // -----------------------------------------------------------------
              // Content Field
              // -----------------------------------------------------------------
              _buildSectionTitle('Content'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Write your post content...',
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
                  // Match Django validation: min 10 characters
                  if (value.trim().length < 10) {
                    return 'Content must be at least 10 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // -----------------------------------------------------------------
              // Category Dropdown
              // -----------------------------------------------------------------
              _buildSectionTitle('Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: _categoryOptions.map((option) {
                  return DropdownMenuItem(
                    value: option['value'],
                    child: Text(option['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 20),

              // -----------------------------------------------------------------
              // Sport Category Dropdown
              // -----------------------------------------------------------------
              _buildSectionTitle('Sport Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _sportCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: _sportCategoryOptions.map((option) {
                  return DropdownMenuItem(
                    value: option['value'],
                    child: Text(option['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sportCategory = value);
                  }
                },
              ),
              const SizedBox(height: 20),

              // -----------------------------------------------------------------
              // Product ID Field (Optional - for Product Reviews)
              // -----------------------------------------------------------------
              _buildSectionTitle('Link to Product (Optional)'),
              const SizedBox(height: 4),
              Text(
                'Enter product UUID for product reviews',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _productIdController,
                decoration: InputDecoration(
                  hintText: 'e.g., 123e4567-e89b-12d3-a456-426614174000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // -----------------------------------------------------------------
              // Location ID Field (Optional - for Location Reviews)
              // -----------------------------------------------------------------
              _buildSectionTitle('Link to Location (Optional)'),
              const SizedBox(height: 4),
              Text(
                'Enter location/place ID for location reviews',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 42',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    // Validate it's a valid integer
                    if (int.tryParse(value.trim()) == null) {
                      return 'Please enter a valid location ID (number)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // -----------------------------------------------------------------
              // Pin Post Toggle (Admin Only)
              // -----------------------------------------------------------------
              if (isAdmin) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin: Pin this post',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[900],
                              ),
                            ),
                            Text(
                              'Pinned posts appear at the top of the forum',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isPinned,
                        onChanged: (value) {
                          setState(() => _isPinned = value);
                        },
                        activeColor: Colors.red[700],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // -----------------------------------------------------------------
              // Submit Button
              // -----------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
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
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // -----------------------------------------------------------------
              // Cancel Button
              // -----------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Helper Widgets
  // ===========================================================================

  /// Build a section title with consistent styling
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }
}
