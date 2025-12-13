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
import '../../shop/models/product.dart';
import '../../place/models/place.dart';
import '../../place/services/place_service.dart';
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

  // ===========================================================================
  // Form State Variables
  // ===========================================================================
  late String _category;
  late String _sportCategory;
  late bool _isPinned;
  bool _isLoading = false;
  
  // ---------------------------------------------------------------------------
  // Dropdown Selection State
  // ---------------------------------------------------------------------------
  String? _selectedProductId;   // Selected product UUID for product linking
  int? _selectedLocationId;     // Selected location ID for location linking
  
  // ---------------------------------------------------------------------------
  // Data for dropdowns (loaded from API)
  // ---------------------------------------------------------------------------
  List<Product> _products = [];      // All products for dropdown
  List<Place> _places = [];          // All places for dropdown
  bool _isLoadingProducts = false;
  bool _isLoadingPlaces = false;

  // ===========================================================================
  // Category-Dependent Field Visibility Helpers
  // ===========================================================================
  // These helpers determine when to show Product ID and Location ID fields
  // matching the Django behavior where fields appear based on category selection
  
  /// Returns true if Product ID field should be shown
  /// Product ID is only relevant for 'product_review' category posts
  bool get _shouldShowProductIdField => _category == 'product_review';
  
  /// Returns true if Location ID field should be shown
  /// Location ID is only relevant for 'location_review' category posts
  bool get _shouldShowLocationIdField => _category == 'location_review';

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
    
    // Initialize dropdown selected values from existing post
    _selectedProductId = widget.post.productId;
    _selectedLocationId = widget.post.locationId;
    
    // Initialize dropdown values
    _category = widget.post.category;
    _sportCategory = widget.post.sportCategory;
    _isPinned = widget.post.isPinned;
    
    // Load products and places for dropdown selection
    _loadProducts();
    _loadPlaces();
  }

  // ===========================================================================
  // Data Loading for Dropdowns
  // ===========================================================================

  /// Load all products from API for the product dropdown
  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final request = context.read<CookieRequest>();
      final response = await request.get('$baseUrl/shop/api/products/');
      
      List<dynamic> listData = [];
      if (response is List) {
        listData = response;
      } else if (response is Map<String, dynamic>) {
        final possible = response['data'] ?? response['results'];
        if (possible is List) listData = possible;
      }
      
      if (mounted) {
        setState(() {
          _products = listData.map((json) => Product.fromJson(json)).toList();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  /// Load all places from API for the location dropdown
  Future<void> _loadPlaces() async {
    setState(() => _isLoadingPlaces = true);
    try {
      final placeService = PlaceService();
      final places = await placeService.fetchPlaces();
      
      if (mounted) {
        setState(() {
          _places = places;
          _isLoadingPlaces = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPlaces = false);
      }
    }
  }

  @override
  void dispose() {
    // Clean up controllers
    _titleController.dispose();
    _contentController.dispose();
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

      // Add optional product_id if selected from dropdown
      if (_selectedProductId != null) {
        body['product_id'] = _selectedProductId;
      }

      // Add optional location_id if selected from dropdown
      if (_selectedLocationId != null) {
        body['location_id'] = _selectedLocationId.toString();
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
              // Product Dropdown (Conditional - Only for Product Reviews)
              // -----------------------------------------------------------------
              // Dropdown to select a product from the list of available products
              // Only shown when category is 'product_review'
              if (_shouldShowProductIdField) ...[
                _buildSectionTitle('Link to Product (Optional)'),
                const SizedBox(height: 4),
                Text(
                  'Select a product to review',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                _isLoadingProducts
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedProductId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: const Icon(Icons.shopping_bag_outlined),
                          hintText: 'Select a product',
                        ),
                        isExpanded: true,
                        items: [
                          // Add "None" option to clear selection
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('-- No product selected --'),
                          ),
                          // Product options from API
                          ..._products.map((product) {
                            return DropdownMenuItem<String>(
                              value: product.id,
                              child: Text(
                                '${product.name} (${product.categoryLabel})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedProductId = value);
                        },
                      ),
                const SizedBox(height: 20),
              ],

              // -----------------------------------------------------------------
              // Location Dropdown (Conditional - Only for Location Reviews)
              // -----------------------------------------------------------------
              // Dropdown to select a place/location from the list of available places
              // Only shown when category is 'location_review'
              if (_shouldShowLocationIdField) ...[
                _buildSectionTitle('Link to Location (Optional)'),
                const SizedBox(height: 4),
                Text(
                  'Select a location to review',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                _isLoadingPlaces
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<int>(
                        value: _selectedLocationId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          hintText: 'Select a location',
                        ),
                        isExpanded: true,
                        items: [
                          // Add "None" option to clear selection
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('-- No location selected --'),
                          ),
                          // Place options from API
                          ..._places.map((place) {
                            return DropdownMenuItem<int>(
                              value: place.id,
                              child: Text(
                                '${place.name}${place.city != null ? " - ${place.city}" : ""}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedLocationId = value);
                        },
                      ),
                const SizedBox(height: 20),
              ],

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
