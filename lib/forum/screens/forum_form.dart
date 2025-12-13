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
import '../../shop/models/product.dart';
import '../../place/models/place.dart';
import '../../place/services/place_service.dart';

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
  
  // Optional linking fields
  // These fields are shown/hidden based on the selected category
  // (matching Django's category-dependent field visibility)
  String? _selectedProductId;   // Selected product UUID for product linking
  int? _selectedLocationId;     // Selected location ID for location linking
  bool _isPinned = false;       // Admin-only: pin post toggle
  
  // Loading state
  bool _isLoading = false;
  
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
    // Pre-load products and places for dropdown selection
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

      // Add optional product_id if selected from dropdown
      if (_selectedProductId != null) {
        body['product_id'] = _selectedProductId;
      }

      // Add optional location_id if selected from dropdown
      if (_selectedLocationId != null) {
        body['location_id'] = _selectedLocationId.toString();
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
