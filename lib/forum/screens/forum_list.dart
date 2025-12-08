// =============================================================================
// Forum List Page
// =============================================================================
// This page displays all forum posts in a scrollable list.
// Features:
// - View all forum posts with preview
// - Filter by category and sport category
// - Navigate to post detail
// - Create new posts
// - Refresh after edit/delete operations
// - Pull-to-refresh support
// =============================================================================

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../widgets/left_drawer.dart';
import '../models/forum_post.dart';
import 'forum_detail.dart';
import 'forum_form.dart';

/// Main forum list page showing all posts
class ForumListPage extends StatefulWidget {
  const ForumListPage({super.key});

  @override
  State<ForumListPage> createState() => _ForumListPageState();
}

class _ForumListPageState extends State<ForumListPage> {
  // ---------------------------------------------------------------------------
  // State Variables
  // ---------------------------------------------------------------------------
  
  /// Selected post category filter
  String _selectedCategory = 'all';
  
  /// Selected sport category filter
  String _selectedSportCategory = 'all';
  
  /// Key to force refresh of FutureBuilder
  int _refreshKey = 0;
  
  /// Current user's role (for admin features)
  String? _currentUserRole;

  // ---------------------------------------------------------------------------
  // Data Fetching Methods
  // ---------------------------------------------------------------------------

  /// Fetch all forum posts from the API
  Future<List<ForumPost>> fetchForumPosts(CookieRequest request) async {
    final response = await request.get('$baseUrl/forum/json/');
    
    List<ForumPost> posts = [];
    for (var d in response) {
      if (d != null) {
        posts.add(ForumPost.fromJson(d));
      }
    }
    return posts;
  }

  /// Filter posts based on selected categories
  List<ForumPost> _filterPosts(List<ForumPost> posts) {
    return posts.where((post) {
      bool categoryMatch = _selectedCategory == 'all' || 
                          post.category == _selectedCategory;
      bool sportMatch = _selectedSportCategory == 'all' || 
                       post.sportCategory == _selectedSportCategory;
      return categoryMatch && sportMatch;
    }).toList();
  }

  /// Refresh the post list
  void _refreshPosts() {
    setState(() {
      _refreshKey++;
    });
  }

  // ---------------------------------------------------------------------------
  // Navigation Methods
  // ---------------------------------------------------------------------------

  /// Navigate to create post page
  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForumFormPage(
          currentUserRole: _currentUserRole,
        ),
      ),
    );
    
    // Refresh list if post was created
    if (result == true) {
      _refreshPosts();
    }
  }

  /// Navigate to post detail page
  Future<void> _navigateToPostDetail(ForumPost post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForumDetailPage(postId: post.id),
      ),
    );
    
    // Refresh list if post was edited or deleted
    if (result == true) {
      _refreshPosts();
    }
  }

  // ---------------------------------------------------------------------------
  // Build Methods
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshPosts,
          ),
          // Filter menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (value) {
              setState(() {
                if (value.startsWith('cat_')) {
                  _selectedCategory = value.substring(4);
                } else if (value.startsWith('sport_')) {
                  _selectedSportCategory = value.substring(6);
                }
              });
            },
            itemBuilder: (context) => [
              // Category filters
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  'POST CATEGORY',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'cat_all',
                child: _buildFilterItem('All Categories', _selectedCategory == 'all'),
              ),
              PopupMenuItem(
                value: 'cat_general',
                child: _buildFilterItem('💬 General Discussion', _selectedCategory == 'general'),
              ),
              PopupMenuItem(
                value: 'cat_product_review',
                child: _buildFilterItem('⭐ Product Review', _selectedCategory == 'product_review'),
              ),
              PopupMenuItem(
                value: 'cat_location_review',
                child: _buildFilterItem('📍 Location Review', _selectedCategory == 'location_review'),
              ),
              PopupMenuItem(
                value: 'cat_question',
                child: _buildFilterItem('❓ Question', _selectedCategory == 'question'),
              ),
              const PopupMenuDivider(),
              // Sport category filters
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  'SPORT CATEGORY',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'sport_all',
                child: _buildFilterItem('All Sports', _selectedSportCategory == 'all'),
              ),
              PopupMenuItem(
                value: 'sport_running',
                child: _buildFilterItem('🏃 Running', _selectedSportCategory == 'running'),
              ),
              PopupMenuItem(
                value: 'sport_cycling',
                child: _buildFilterItem('🚴 Cycling', _selectedSportCategory == 'cycling'),
              ),
              PopupMenuItem(
                value: 'sport_swimming',
                child: _buildFilterItem('🏊 Swimming', _selectedSportCategory == 'swimming'),
              ),
            ],
          ),
        ],
      ),
      drawer: const LeftDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreatePost,
        backgroundColor: const Color(0xFF1D4ED8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Post', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshPosts(),
        child: FutureBuilder<List<ForumPost>>(
          key: ValueKey(_refreshKey),
          future: fetchForumPosts(request),
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error state
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshPosts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Empty state
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.forum, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No forum posts yet.',
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Be the first to start a discussion!',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _navigateToCreatePost,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Post'),
                    ),
                  ],
                ),
              );
            }

            final filteredPosts = _filterPosts(snapshot.data!);

            // No matching posts
            if (filteredPosts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No posts match your filters.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = 'all';
                          _selectedSportCategory = 'all';
                        });
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              );
            }

            // Display active filters if any
            final hasActiveFilters = _selectedCategory != 'all' || 
                                     _selectedSportCategory != 'all';

            return Column(
              children: [
                // Active filters indicator
                if (hasActiveFilters)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: Colors.blue[50],
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filtered: ${_selectedCategory != 'all' ? _selectedCategory : ''}'
                            '${_selectedCategory != 'all' && _selectedSportCategory != 'all' ? ', ' : ''}'
                            '${_selectedSportCategory != 'all' ? _selectedSportCategory : ''}',
                            style: const TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = 'all';
                              _selectedSportCategory = 'all';
                            });
                          },
                          child: const Text('Clear', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                
                // Posts list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      return _buildPostCard(post);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build a filter menu item with checkmark
  Widget _buildFilterItem(String label, bool isSelected) {
    return Row(
      children: [
        if (isSelected)
          const Icon(Icons.check, size: 16, color: Color(0xFF1D4ED8))
        else
          const SizedBox(width: 16),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  /// Build a post card widget
  Widget _buildPostCard(ForumPost post) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: post.isPinned 
            ? const BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _navigateToPostDetail(post),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with pin indicator
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.isPinned)
                    Container(
                      margin: const EdgeInsets.only(right: 8, top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, size: 12, color: Colors.orange),
                          SizedBox(width: 2),
                          Text(
                            'Pinned',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Content preview
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 12),
              
              // Category chips
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildCategoryChip(post.category, post.categoryDisplay, Colors.blue),
                  _buildCategoryChip(post.sportCategory, post.sportCategoryDisplay, Colors.green),
                  // Show linked indicators
                  if (post.hasLinkedProduct)
                    Chip(
                      avatar: const Icon(Icons.shopping_bag, size: 14),
                      label: const Text('Product', style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.purple[50],
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (post.hasLinkedLocation)
                    Chip(
                      avatar: const Icon(Icons.location_on, size: 14),
                      label: const Text('Location', style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.teal[50],
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Author and stats row
              Row(
                children: [
                  // Author avatar
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: _getRoleColor(post.authorRole),
                    child: Text(
                      post.authorInitial,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Author name with role badge
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          post.author,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        if (post.authorRole != 'USER') ...[
                          const SizedBox(width: 4),
                          _buildRoleBadge(post.authorRole),
                        ],
                      ],
                    ),
                  ),
                  
                  // Stats
                  Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${post.postViews}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.favorite, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likeCount}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Date and edited indicator
              Row(
                children: [
                  Text(
                    post.createdAt,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  if (post.wasEdited) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(edited)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a category chip with icon
  Widget _buildCategoryChip(String category, String display, Color color) {
    return Chip(
      avatar: _getCategoryIcon(category),
      label: Text(display, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.1),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Get icon for category
  Widget? _getCategoryIcon(String category) {
    switch (category) {
      case 'general':
        return const Text('💬', style: TextStyle(fontSize: 12));
      case 'product_review':
        return const Text('⭐', style: TextStyle(fontSize: 12));
      case 'location_review':
        return const Text('📍', style: TextStyle(fontSize: 12));
      case 'question':
        return const Text('❓', style: TextStyle(fontSize: 12));
      case 'announcement':
        return const Text('📢', style: TextStyle(fontSize: 12));
      case 'feedback':
        return const Text('💭', style: TextStyle(fontSize: 12));
      case 'running':
        return const Text('🏃', style: TextStyle(fontSize: 12));
      case 'cycling':
        return const Text('🚴', style: TextStyle(fontSize: 12));
      case 'swimming':
        return const Text('🏊', style: TextStyle(fontSize: 12));
      default:
        return null;
    }
  }

  /// Get color for user role
  Color _getRoleColor(String? role) {
    switch (role) {
      case 'ADMIN':
        return Colors.red;
      case 'SELLER':
        return Colors.green;
      case 'FACILITY_ADMIN':
        return Colors.blue;
      default:
        return const Color(0xFF1D4ED8);
    }
  }

  /// Build role badge
  Widget _buildRoleBadge(String? role) {
    String label;
    Color color;
    
    switch (role) {
      case 'ADMIN':
        label = 'Admin';
        color = Colors.red;
        break;
      case 'SELLER':
        label = 'Seller';
        color = Colors.green;
        break;
      case 'FACILITY_ADMIN':
        label = 'Facility';
        color = Colors.blue;
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
