// =============================================================================
// ForumListPage - Forum Posts List Screen
// =============================================================================
// This screen displays a list of all forum posts with:
// - Filter by category and sport category
// - Pinned posts highlighted at top
// - Post cards with author info, stats, and quick actions
// - Pull-to-refresh functionality
// - Refresh after returning from detail/create/edit screens
// - Post management options (edit/delete) via long-press menu
// =============================================================================

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../widgets/left_drawer.dart';
import '../models/forum_post.dart';
import '../services/forum_service.dart';
import 'forum_detail.dart';
import 'forum_edit.dart';
import 'forum_form.dart';

/// Main forum listing page showing all forum posts
class ForumListPage extends StatefulWidget {
  const ForumListPage({super.key});

  @override
  State<ForumListPage> createState() => _ForumListPageState();
}

class _ForumListPageState extends State<ForumListPage> {
  // ===========================================================================
  // State Variables
  // ===========================================================================
  
  // Filter selections
  String _selectedCategory = 'all';
  String _selectedSportCategory = 'all';
  
  // Future for FutureBuilder - allows manual refresh
  late Future<List<ForumPost>> _postsFuture;

  // ===========================================================================
  // Lifecycle Methods
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }

  // ===========================================================================
  // Data Fetching
  // ===========================================================================

  /// Fetch forum posts from the Django API
  Future<List<ForumPost>> _fetchForumPosts(CookieRequest request) async {
    final response = await request.get('$baseUrl/forum/json/');
    
    List<ForumPost> posts = [];
    for (var d in response) {
      if (d != null) {
        posts.add(ForumPost.fromJson(d));
      }
    }
    return posts;
  }

  /// Trigger a refresh of the posts list
  void _refreshPosts() {
    final request = context.read<CookieRequest>();
    setState(() {
      _postsFuture = _fetchForumPosts(request);
    });
  }

  // ===========================================================================
  // Filtering
  // ===========================================================================

  /// Filter posts based on selected category and sport
  List<ForumPost> _filterPosts(List<ForumPost> posts) {
    return posts.where((post) {
      bool categoryMatch = _selectedCategory == 'all' || 
                          post.category == _selectedCategory;
      bool sportMatch = _selectedSportCategory == 'all' || 
                       post.sportCategory == _selectedSportCategory;
      return categoryMatch && sportMatch;
    }).toList();
  }

  // ===========================================================================
  // Navigation & Actions
  // ===========================================================================

  /// Navigate to post detail and refresh on return if needed
  Future<void> _navigateToDetail(ForumPost post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForumDetailPage(postId: post.id),
      ),
    );
    
    // Refresh list if post was deleted or modified
    if (result == true) {
      _refreshPosts();
    }
  }

  /// Navigate to create post and refresh on return if needed
  Future<void> _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForumFormPage()),
    );
    
    // Refresh list if post was created
    if (result == true) {
      _refreshPosts();
    }
  }

  /// Navigate to edit post and refresh on return if needed
  Future<void> _navigateToEdit(ForumPost post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForumEditPage(post: post),
      ),
    );
    
    // Refresh list if post was edited
    if (result == true) {
      _refreshPosts();
    }
  }

  /// Show delete confirmation and delete post
  Future<void> _deletePost(ForumPost post) async {
    final request = context.read<CookieRequest>();
    
    final success = await ForumService.showDeletePostDialog(
      context,
      request,
      post.id,
      post.title,
    );
    
    // Refresh list if post was deleted
    if (success) {
      _refreshPosts();
    }
  }

  /// Show context menu for post actions (edit/delete)
  void _showPostActions(BuildContext context, ForumPost post) {
    final request = context.read<CookieRequest>();
    // Use username for permission checks (Django returns 'username' on login)
    final currentUsername = request.jsonData['username'];
    final currentUserRole = request.jsonData['role'];
    
    // Use post.author (username string) for comparison
    final canEdit = ForumService.canEditPost(currentUsername, post.author);
    final canDelete = ForumService.canDelete(currentUsername, post.author, currentUserRole);
    
    // Don't show menu if no actions available
    if (!canEdit && !canDelete) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Post title header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (post.isPinned) ...[
                      Icon(Icons.push_pin, size: 18, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        post.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Edit option
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit, color: Color(0xFF1D4ED8)),
                  title: const Text('Edit Post'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToEdit(post);
                  },
                ),
              
              // Delete option
              if (canDelete)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red[600]),
                  title: Text(
                    'Delete Post',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deletePost(post);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Build Method
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // Get current user info for permission checks
    // Django returns 'username' and 'role' on login
    final request = context.watch<CookieRequest>();
    final currentUsername = request.jsonData['username'];
    final currentUserRole = request.jsonData['role'];

    return Scaffold(
      // -----------------------------------------------------------------------
      // App Bar
      // -----------------------------------------------------------------------
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
            tooltip: 'Filter posts',
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
                child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              _buildFilterMenuItem('cat_all', 'All Categories', _selectedCategory == 'all'),
              _buildFilterMenuItem('cat_general', 'General Discussion', _selectedCategory == 'general'),
              _buildFilterMenuItem('cat_product_review', 'Product Review', _selectedCategory == 'product_review'),
              _buildFilterMenuItem('cat_location_review', 'Location Review', _selectedCategory == 'location_review'),
              _buildFilterMenuItem('cat_question', 'Question', _selectedCategory == 'question'),
              _buildFilterMenuItem('cat_announcement', 'Announcement', _selectedCategory == 'announcement'),
              _buildFilterMenuItem('cat_feedback', 'Feedback', _selectedCategory == 'feedback'),
              const PopupMenuDivider(),
              // Sport filters
              const PopupMenuItem(
                enabled: false,
                child: Text('Sport', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              _buildFilterMenuItem('sport_all', 'All Sports', _selectedSportCategory == 'all'),
              _buildFilterMenuItem('sport_running', '🏃 Running', _selectedSportCategory == 'running'),
              _buildFilterMenuItem('sport_cycling', '🚴 Cycling', _selectedSportCategory == 'cycling'),
              _buildFilterMenuItem('sport_swimming', '🏊 Swimming', _selectedSportCategory == 'swimming'),
            ],
          ),
        ],
      ),
      drawer: const LeftDrawer(),
      
      // -----------------------------------------------------------------------
      // FAB - Create Post
      // -----------------------------------------------------------------------
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        backgroundColor: const Color(0xFF1D4ED8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Post', style: TextStyle(color: Colors.white)),
      ),
      
      // -----------------------------------------------------------------------
      // Body - Posts List
      // -----------------------------------------------------------------------
      body: RefreshIndicator(
        onRefresh: () async => _refreshPosts(),
        child: FutureBuilder<List<ForumPost>>(
          future: _postsFuture,
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
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading posts',
                      style: TextStyle(fontSize: 18, color: Colors.red[700]),
                    ),
                    const SizedBox(height: 8),
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
                    Icon(Icons.forum, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No forum posts yet',
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Be the first to start a discussion!',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _navigateToCreate,
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Post'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Filter posts
            final filteredPosts = _filterPosts(snapshot.data!);

            // No results after filtering
            if (filteredPosts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No posts match your filters',
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

            // Posts list
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final post = filteredPosts[index];
                return _buildPostCard(
                  post, 
                  currentUsername, 
                  currentUserRole,
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // Helper Widgets
  // ===========================================================================

  /// Build a filter menu item with checkmark for selected state
  PopupMenuItem<String> _buildFilterMenuItem(String value, String label, bool isSelected) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (isSelected)
            const Icon(Icons.check, size: 18, color: Color(0xFF1D4ED8)),
        ],
      ),
    );
  }

  /// Build a post card widget
  /// Uses username for permission checks
  Widget _buildPostCard(ForumPost post, String? currentUsername, String? currentUserRole) {
    // Check if user can perform actions on this post
    // Use post.author (username string) for comparison
    final canEdit = ForumService.canEditPost(currentUsername, post.author);
    final canDelete = ForumService.canDelete(currentUsername, post.author, currentUserRole);
    final hasActions = canEdit || canDelete;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Highlight pinned posts with border
        side: post.isPinned 
            ? BorderSide(color: Colors.orange[300]!, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(post),
        // Long press shows action menu
        onLongPress: hasActions ? () => _showPostActions(context, post) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------------
              // Title Row with Pinned Badge
              // ---------------------------------------------------------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pinned badge
                  if (post.isPinned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 8, top: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, size: 12, color: Colors.orange[800]),
                          const SizedBox(width: 2),
                          Text(
                            'Pinned',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Title
                  Expanded(
                    child: Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Action menu button (if user has permissions)
                  if (hasActions)
                    IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                      onPressed: () => _showPostActions(context, post),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // ---------------------------------------------------------------
              // Content Preview
              // ---------------------------------------------------------------
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700], height: 1.3),
              ),
              const SizedBox(height: 12),
              
              // ---------------------------------------------------------------
              // Category Chips
              // ---------------------------------------------------------------
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildSmallChip(post.categoryDisplay, Colors.blue[50]!, Colors.blue[700]!),
                  _buildSmallChip(post.sportCategoryDisplay, Colors.green[50]!, Colors.green[700]!),
                  // Show linked indicator if post has product/location
                  if (post.hasLinkedProduct)
                    _buildSmallChip('📦 Product', Colors.purple[50]!, Colors.purple[700]!),
                  if (post.hasLinkedLocation)
                    _buildSmallChip('📍 Location', Colors.teal[50]!, Colors.teal[700]!),
                ],
              ),
              const SizedBox(height: 12),
              
              // ---------------------------------------------------------------
              // Author and Stats Row
              // ---------------------------------------------------------------
              Row(
                children: [
                  // Author avatar
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: _getAvatarColor(post.authorRole),
                    child: Text(
                      post.authorInitial,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Author name
                  Text(
                    post.author,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  // Stats
                  _buildStatItem(Icons.visibility, '${post.postViews}'),
                  const SizedBox(width: 12),
                  _buildStatItem(Icons.favorite, '${post.likeCount}'),
                ],
              ),
              const SizedBox(height: 4),
              
              // ---------------------------------------------------------------
              // Date
              // ---------------------------------------------------------------
              Text(
                post.createdAt,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a small category chip
  Widget _buildSmallChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  /// Build a stat item (icon + value)
  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Get avatar color based on user role
  Color _getAvatarColor(String role) {
    switch (role) {
      case 'ADMIN':
        return Colors.red[700]!;
      case 'SELLER':
        return Colors.green[700]!;
      case 'FACILITY_ADMIN':
        return Colors.blue[700]!;
      default:
        return const Color(0xFF1D4ED8);
    }
  }
}
