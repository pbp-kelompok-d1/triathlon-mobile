// =============================================================================
// ForumFormPage - Create New Forum Post Screen
// =============================================================================
// This screen allows users to create new forum posts.
// Features:
// - Title and content fields with validation (min 5 and 10 chars respectively)
// - Category selection (general, product_review, location_review, etc.)
// - Sport category selection (running, cycling, swimming)
// - Optional product ID linking (UUID for product reviews)
// - Optional location ID linking (Integer for location reviews)
// - Admin-only: pin post toggle
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';

/// Screen for creating a new forum post
class ForumFormPage extends StatefulWidget {
  const ForumFormPage({super.key});

  @override
  State<ForumFormPage> createState() => _ForumFormPageState();
}

class _ForumFormPageState extends State<ForumFormPage> {
  // ===========================================================================
  // Form Key and State Variables
  // ===========================================================================
  final _formKey = GlobalKey<FormState>();
  
  // Basic post fields
  String _title = '';
  String _content = '';
  String _category = 'general';
  String _sportCategory = 'running';
  
  // Optional linking fields (new)
  String _productId = '';      // UUID string for product linking
  String _locationId = '';     // Integer string for location linking
  bool _isPinned = false;      // Admin-only: pin post toggle
  
  // Loading state
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
  // Form Submission
  // ===========================================================================

  /// Submit the new post to the Django API
  Future<void> _submitPost() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final request = context.read<CookieRequest>();

    try {
      // Build request body with all fields
      final Map<String, dynamic> body = {
        'title': _title.trim(),
        'content': _content.trim(),
        'category': _category,
        'sport_category': _sportCategory,
        'is_pinned': _isPinned,
      };

      // Add optional product_id if provided
      if (_productId.trim().isNotEmpty) {
        body['product_id'] = _productId.trim();
      }

      // Add optional location_id if provided
      if (_locationId.trim().isNotEmpty) {
        body['location_id'] = _locationId.trim();
      }

      // Send POST request to create endpoint
      final response = await request.postJson(
        '$baseUrl/forum/ajax/add/',
        jsonEncode(body),
      );

      if (!mounted) return;

      // Handle response
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Return true to indicate successful creation
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to create post'),
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

  // ===========================================================================
  // Build Method
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // Get current user info from request to check if admin
    final request = context.watch<CookieRequest>();
    final isAdmin = request.jsonData['role'] == 'ADMIN';

    return Scaffold(
      // -----------------------------------------------------------------------
      // App Bar
      // -----------------------------------------------------------------------
      appBar: AppBar(
        title: const Text('Create Forum Post'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      
      // -----------------------------------------------------------------------
      // Body - Create Form
      // -----------------------------------------------------------------------
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
              _buildSectionTitle('Title'),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter post title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) => _title = value,
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
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Write your post content...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) => _content = value,
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
                decoration: InputDecoration(
                  hintText: 'e.g., 123e4567-e89b-12d3-a456-426614174000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                ),
                onChanged: (value) => _productId = value,
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
                onChanged: (value) => _locationId = value,
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
                  onPressed: _isLoading ? null : _submitPost,
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
                          'Create Post',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
