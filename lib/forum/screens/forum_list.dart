// =============================================================================
// ForumListPage - Forum Posts List Screen
// =============================================================================
// This screen displays a list of all forum posts with comprehensive filtering:
//
// FILTERING OPTIONS:
// - Search: Real-time text search across post titles and content
// - Category Filter: Multi-select checkboxes for post categories
// - Sport Filter: Multi-select checkboxes for sport categories
// - Pinned Only: Toggle to show only pinned posts
// - My Posts: Toggle between "All Posts" and "My Posts"
//
// SORTING OPTIONS:
// - Most Recent (default) - by last_activity/created_at descending
// - Most Views - by post_views descending
// - Most Likes - by like_count descending  
// - Oldest First - by created_at ascending
//
// OTHER FEATURES:
// - Pinned posts highlighted with orange border
// - Post cards with author info, stats, and quick actions
// - Clickable usernames navigate to user profile
// - Pull-to-refresh functionality
// - Refresh after returning from detail/create/edit screens
// - Post management options (edit/delete) via long-press or menu button
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
import 'forum_user_profile.dart';  // Import for user profile navigation

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
  
  // ---------------------------------------------------------------------------
  // Search State
  // ---------------------------------------------------------------------------
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';  // Current search text (initialized to empty)
  
  // ---------------------------------------------------------------------------
  // Sorting State
  // ---------------------------------------------------------------------------
  // Available sort options matching Django's sorting capabilities
  String _sortBy = 'recent';  // 'recent', 'views', 'likes', 'oldest'
  
  // ---------------------------------------------------------------------------
  // Filter State - Multi-select Categories
  // ---------------------------------------------------------------------------
  // Using Sets for multi-select (empty set = all selected)
  // Initialize with const to ensure they're properly created
  Set<String> _selectedCategories = <String>{};      // Empty = all categories
  Set<String> _selectedSportCategories = <String>{}; // Empty = all sports
  
  // ---------------------------------------------------------------------------
  // Special Filters
  // ---------------------------------------------------------------------------
  bool _showPinnedOnly = false;  // Filter to show only pinned posts
  bool _showMyPostsOnly = false; // Filter to show only current user's posts
  
  // ---------------------------------------------------------------------------
  // Data Loading State
  // ---------------------------------------------------------------------------
  late Future<List<ForumPost>> _postsFuture;

  // ===========================================================================
  // Category Options (matching Django choices)
  // ===========================================================================
  
  /// Post category options - matches Django ForumPost.CATEGORY_CHOICES
  static const List<Map<String, String>> _categoryOptions = [
    {'value': 'general', 'label': 'General Discussion'},
    {'value': 'product_review', 'label': 'Product Review'},
    {'value': 'location_review', 'label': 'Location Review'},
    {'value': 'question', 'label': 'Question'},
    {'value': 'announcement', 'label': 'Announcement'},
    {'value': 'feedback', 'label': 'Feedback'},
  ];

  /// Sport category options - matches Django ForumPost.SPORT_CATEGORY_CHOICES
  static const List<Map<String, String>> _sportCategoryOptions = [
    {'value': 'running', 'label': '🏃 Running'},
    {'value': 'cycling', 'label': '🚴 Cycling'},
    {'value': 'swimming', 'label': '🏊 Swimming'},
  ];

  /// Sort options for the dropdown
  static const List<Map<String, String>> _sortOptions = [
    {'value': 'recent', 'label': 'Most Recent'},
    {'value': 'views', 'label': 'Most Views'},
    {'value': 'likes', 'label': 'Most Likes'},
    {'value': 'oldest', 'label': 'Oldest First'},
  ];

  // ===========================================================================
  // Lifecycle Methods
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _refreshPosts();
    // Listen to search input changes for real-time filtering
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Called when search text changes - updates filter state
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
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
  // Filtering & Sorting
  // ===========================================================================

  /// Filter and sort posts based on all current filter/sort settings
  /// This method applies filters in order: search -> categories -> special filters -> sort
  List<ForumPost> _filterAndSortPosts(List<ForumPost> posts, String? currentUsername) {
    var filtered = posts.where((post) {
      // -----------------------------------------------------------------------
      // Search Filter
      // -----------------------------------------------------------------------
      // Match search query against title and content (case-insensitive)
      if (_searchQuery.isNotEmpty) {
        final titleMatch = post.title.toLowerCase().contains(_searchQuery);
        final contentMatch = post.content.toLowerCase().contains(_searchQuery);
        if (!titleMatch && !contentMatch) return false;
      }
      
      // -----------------------------------------------------------------------
      // Category Filter (Multi-select)
      // -----------------------------------------------------------------------
      // If _selectedCategories is empty, show all categories
      // Otherwise, post must match one of the selected categories
      if (_selectedCategories.isNotEmpty) {
        if (!_selectedCategories.contains(post.category)) return false;
      }
      
      // -----------------------------------------------------------------------
      // Sport Category Filter (Multi-select)
      // -----------------------------------------------------------------------
      // If _selectedSportCategories is empty, show all sports
      // Otherwise, post must match one of the selected sports
      if (_selectedSportCategories.isNotEmpty) {
        if (!_selectedSportCategories.contains(post.sportCategory)) return false;
      }
      
      // -----------------------------------------------------------------------
      // Pinned Only Filter
      // -----------------------------------------------------------------------
      if (_showPinnedOnly && !post.isPinned) return false;
      
      // -----------------------------------------------------------------------
      // My Posts Filter
      // -----------------------------------------------------------------------
      // Compare post author username with current logged-in username
      if (_showMyPostsOnly) {
        if (currentUsername == null || post.author != currentUsername) return false;
      }
      
      return true;
    }).toList();

    // -------------------------------------------------------------------------
    // Sorting
    // -------------------------------------------------------------------------
    // Always show pinned posts first, then apply selected sort
    filtered.sort((a, b) {
      // Pinned posts always come first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      // Then apply selected sort order
      switch (_sortBy) {
        case 'views':
          return b.postViews.compareTo(a.postViews); // Descending
        case 'likes':
          return b.likeCount.compareTo(a.likeCount); // Descending
        case 'oldest':
          return a.createdAt.compareTo(b.createdAt); // Ascending
        case 'recent':
        default:
          return b.createdAt.compareTo(a.createdAt); // Descending
      }
    });

    return filtered;
  }

  /// Clear all filters and reset to default state
  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategories = <String>{};
      _selectedSportCategories = <String>{};
      _showPinnedOnly = false;
      _showMyPostsOnly = false;
      _sortBy = 'recent';
    });
  }

  /// Check if any filters are currently active
  /// Returns true if any filter is applied that changes the default view
  bool get _hasActiveFilters {
    // Check search query (default is empty string '')
    final hasSearch = _searchQuery.isNotEmpty;
    // Check if any category filters are selected
    final hasCategories = _selectedCategories.isNotEmpty;
    // Check if any sport filters are selected
    final hasSports = _selectedSportCategories.isNotEmpty;
    // Check special filters
    return hasSearch || hasCategories || hasSports || _showPinnedOnly || _showMyPostsOnly;
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
      // App Bar with Search and Filter Actions
      // -----------------------------------------------------------------------
      appBar: AppBar(
        title: const Text('Forum'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh posts',
            onPressed: _refreshPosts,
          ),
          // Filter button - opens comprehensive filter bottom sheet
          IconButton(
            icon: Badge(
              // Show badge if filters are active
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filter & Sort',
            onPressed: () => _showFilterBottomSheet(context, currentUsername),
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
      // Body - Search Bar + Filter Chips + Posts List
      // -----------------------------------------------------------------------
      body: Column(
        children: [
          // -----------------------------------------------------------------
          // Search Bar
          // -----------------------------------------------------------------
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search posts by title or content...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                // Show clear button when there's text
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // -----------------------------------------------------------------
          // Quick Filter Chips Row
          // -----------------------------------------------------------------
          // Shows active filters and quick toggles
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Sort dropdown chip
                  _buildSortChip(),
                  const SizedBox(width: 8),
                  
                  // My Posts toggle chip
                  FilterChip(
                    label: const Text('My Posts'),
                    selected: _showMyPostsOnly,
                    onSelected: (selected) {
                      setState(() {
                        _showMyPostsOnly = selected;
                      });
                    },
                    avatar: _showMyPostsOnly 
                        ? const Icon(Icons.person, size: 18)
                        : const Icon(Icons.person_outline, size: 18),
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  
                  // Pinned Only toggle chip
                  FilterChip(
                    label: const Text('Pinned Only'),
                    selected: _showPinnedOnly,
                    onSelected: (selected) {
                      setState(() {
                        _showPinnedOnly = selected;
                      });
                    },
                    avatar: Icon(
                      _showPinnedOnly ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 18,
                      color: _showPinnedOnly ? Colors.orange[700] : null,
                    ),
                    selectedColor: Colors.orange[100],
                    checkmarkColor: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  
                  // Show active category filter chips
                  ..._selectedCategories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(_getCategoryLabel(cat)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedCategories.remove(cat);
                        });
                      },
                      backgroundColor: Colors.blue[50],
                      labelStyle: TextStyle(color: Colors.blue[700], fontSize: 12),
                    ),
                  )),
                  
                  // Show active sport filter chips
                  ..._selectedSportCategories.map((sport) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(_getSportLabel(sport)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedSportCategories.remove(sport);
                        });
                      },
                      backgroundColor: Colors.green[50],
                      labelStyle: TextStyle(color: Colors.green[700], fontSize: 12),
                    ),
                  )),
                  
                  // Clear all filters button (shown when filters active)
                  if (_hasActiveFilters)
                    TextButton.icon(
                      onPressed: _clearAllFilters,
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear All'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          
          // -----------------------------------------------------------------
          // Posts List with RefreshIndicator
          // -----------------------------------------------------------------
          Expanded(
            child: RefreshIndicator(
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

                  // Empty state (no posts at all)
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

                  // Apply filtering and sorting
                  final filteredPosts = _filterAndSortPosts(snapshot.data!, currentUsername);

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
                          ElevatedButton.icon(
                            onPressed: _clearAllFilters,
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear All Filters'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Posts list with count indicator
                  return Column(
                    children: [
                      // Results count
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.grey[50],
                        child: Text(
                          '${filteredPosts.length} post${filteredPosts.length == 1 ? '' : 's'} found',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      // Posts list
                      Expanded(
                        child: ListView.builder(
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
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Filter Bottom Sheet
  // ===========================================================================
  
  /// Show comprehensive filter and sort options in a bottom sheet
  void _showFilterBottomSheet(BuildContext context, String? currentUsername) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        // Use StatefulBuilder to update UI within bottom sheet
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter & Sort',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          _clearAllFilters();
                        });
                        setState(() {});
                      },
                      child: const Text('Reset All'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Filter content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ==========================================================
                    // Sort Options
                    // ==========================================================
                    const Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _sortOptions.map((option) => ChoiceChip(
                        label: Text(option['label']!),
                        selected: _sortBy == option['value'],
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() {
                              _sortBy = option['value']!;
                            });
                            setState(() {});
                          }
                        },
                        selectedColor: Colors.blue[100],
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    // ==========================================================
                    // Special Filters
                    // ==========================================================
                    const Text(
                      'Quick Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // My Posts toggle
                    SwitchListTile(
                      title: const Text('My Posts Only'),
                      subtitle: Text('Show only posts by $currentUsername'),
                      value: _showMyPostsOnly,
                      onChanged: (value) {
                        setSheetState(() {
                          _showMyPostsOnly = value;
                        });
                        setState(() {});
                      },
                      secondary: const Icon(Icons.person),
                    ),
                    // Pinned Only toggle
                    SwitchListTile(
                      title: const Text('Pinned Posts Only'),
                      subtitle: const Text('Show only pinned posts'),
                      value: _showPinnedOnly,
                      onChanged: (value) {
                        setSheetState(() {
                          _showPinnedOnly = value;
                        });
                        setState(() {});
                      },
                      secondary: const Icon(Icons.push_pin),
                    ),
                    const SizedBox(height: 24),
                    
                    // ==========================================================
                    // Post Category Filters (Multi-select)
                    // ==========================================================
                    const Text(
                      'Post Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedCategories.isEmpty 
                          ? 'All categories (tap to filter)'
                          : '${_selectedCategories.length} selected',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categoryOptions.map((option) => FilterChip(
                        label: Text(option['label']!),
                        selected: _selectedCategories.contains(option['value']),
                        onSelected: (selected) {
                          setSheetState(() {
                            if (selected) {
                              _selectedCategories.add(option['value']!);
                            } else {
                              _selectedCategories.remove(option['value']);
                            }
                          });
                          setState(() {});
                        },
                        selectedColor: Colors.blue[100],
                        checkmarkColor: Colors.blue[700],
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    // ==========================================================
                    // Sport Category Filters (Multi-select)
                    // ==========================================================
                    const Text(
                      'Sport Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedSportCategories.isEmpty 
                          ? 'All sports (tap to filter)'
                          : '${_selectedSportCategories.length} selected',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sportCategoryOptions.map((option) => FilterChip(
                        label: Text(option['label']!),
                        selected: _selectedSportCategories.contains(option['value']),
                        onSelected: (selected) {
                          setSheetState(() {
                            if (selected) {
                              _selectedSportCategories.add(option['value']!);
                            } else {
                              _selectedSportCategories.remove(option['value']);
                            }
                          });
                          setState(() {});
                        },
                        selectedColor: Colors.green[100],
                        checkmarkColor: Colors.green[700],
                      )).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              
              // Apply button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  /// Build sort dropdown chip for quick filter row
  Widget _buildSortChip() {
    // Find current sort option label
    final currentSortLabel = _sortOptions
        .firstWhere((opt) => opt['value'] == _sortBy)['label']!;
    
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _sortBy = value;
        });
      },
      itemBuilder: (context) => _sortOptions.map((option) => PopupMenuItem(
        value: option['value'],
        child: Row(
          children: [
            Expanded(child: Text(option['label']!)),
            if (_sortBy == option['value'])
              const Icon(Icons.check, size: 18, color: Color(0xFF1D4ED8)),
          ],
        ),
      )).toList(),
      child: Chip(
        avatar: const Icon(Icons.sort, size: 18),
        label: Text(currentSortLabel),
        backgroundColor: Colors.grey[100],
      ),
    );
  }

  /// Get human-readable label for category value
  String _getCategoryLabel(String value) {
    return _categoryOptions
        .firstWhere((opt) => opt['value'] == value, orElse: () => {'label': value})['label']!;
  }

  /// Get human-readable label for sport value
  String _getSportLabel(String value) {
    return _sportCategoryOptions
        .firstWhere((opt) => opt['value'] == value, orElse: () => {'label': value})['label']!;
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
                  // Author avatar - clickable to navigate to user profile
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForumUserProfilePage(username: post.author),
                        ),
                      );
                    },
                    child: CircleAvatar(
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
                  ),
                  const SizedBox(width: 8),
                  // Author name - clickable to navigate to user profile
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForumUserProfilePage(username: post.author),
                        ),
                      );
                    },
                    child: Text(
                      post.author,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Color(0xFF1D4ED8),  // Blue to indicate clickable
                      ),
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
