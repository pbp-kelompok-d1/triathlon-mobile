// =============================================================================
// Forum Detail Page
// =============================================================================
// This page displays a single forum post with all its details and replies.
// Features:
// - View full post content with author info
// - Edit post (author only)
// - Delete post (author or admin)
// - Like/Unlike post
// - View and add replies
// - Quote reply feature (select a reply to quote)
// - Delete reply (author or admin)
// - Display linked product/location
// - Show last edited timestamp
// =============================================================================

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../models/forum_post.dart';
import '../models/forum_reply.dart';
import 'forum_edit_form.dart';

class ForumDetailPage extends StatefulWidget {
  final String postId;

  const ForumDetailPage({super.key, required this.postId});

  @override
  State<ForumDetailPage> createState() => _ForumDetailPageState();
}

class _ForumDetailPageState extends State<ForumDetailPage> {
  // ---------------------------------------------------------------------------
  // Controllers & State Variables
  // ---------------------------------------------------------------------------
  final TextEditingController _replyController = TextEditingController();
  
  /// ScrollController for auto-scrolling to reply input when quoting
  final ScrollController _scrollController = ScrollController();
  
  /// The post data loaded from API
  Map<String, dynamic>? _postData;
  
  /// Parsed ForumPost object for helper methods
  ForumPost? _post;
  
  /// List of replies to this post
  List<ForumReply> _replies = [];
  
  /// Loading state
  bool _isLoading = true;
  
  /// Whether current user has liked this post
  bool _userHasLiked = false;
  
  /// Current user's ID (for permission checks)
  int? _currentUserId;
  
  /// Current user's role (for admin features)
  String? _currentUserRole;
  
  /// The reply being quoted (null if not quoting any reply)
  ForumReply? _quotedReply;

  // ---------------------------------------------------------------------------
  // Lifecycle Methods
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data Loading Methods
  // ---------------------------------------------------------------------------

  /// Load post data from the API
  Future<void> _loadPostData() async {
    final request = context.read<CookieRequest>();
    try {
      final response =
          await request.get('$baseUrl/forum/${widget.postId}/?format=json');
      
      setState(() {
        _postData = response['post'];
        _userHasLiked = response['user_has_liked'] ?? false;
        _replies = (response['replies'] as List)
            .map((r) => ForumReply.fromJson(r))
            .toList();
        
        // Parse post data into ForumPost object
        if (_postData != null) {
          _post = ForumPost.fromJson(_postData!);
        }
        
        // Extract current user info from cookies/session if available
        _currentUserId = response['current_user_id'];
        _currentUserRole = response['current_user_role'];
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading post: $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Action Methods
  // ---------------------------------------------------------------------------

  /// Toggle like/unlike on the post
  Future<void> _toggleLike() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(
        '$baseUrl/forum/${widget.postId}/like/',
        {},
      );
      if (response['success']) {
        setState(() {
          _userHasLiked = response['liked'];
          _postData!['like_count'] = response['like_count'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Submit a new reply (with optional quote)
  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    final request = context.read<CookieRequest>();
    try {
      // Build request body with optional quote_reply_id
      final Map<String, dynamic> body = {
        'content': _replyController.text,
      };
      
      // If quoting a reply, include the quote_reply_id
      if (_quotedReply != null) {
        body['quote_reply_id'] = _quotedReply!.id;
      }
      
      final response = await request.post(
        '$baseUrl/forum/${widget.postId}/reply/',
        body,
      );
      if (response['success']) {
        _replyController.clear();
        // Clear the quoted reply after successful submission
        setState(() {
          _quotedReply = null;
        });
        await _loadPostData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reply posted!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting reply: $e')),
        );
      }
    }
  }

  /// Set a reply to be quoted
  void _quoteReply(ForumReply reply) {
    setState(() {
      _quotedReply = reply;
    });
    // Scroll to the bottom where the reply input is
    // and focus the text field
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Clear the quoted reply
  void _clearQuote() {
    setState(() {
      _quotedReply = null;
    });
  }

  /// Navigate to edit post page
  Future<void> _navigateToEdit() async {
    if (_post == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForumEditFormPage(
          post: _post!,
          currentUserRole: _currentUserRole,
        ),
      ),
    );
    
    // Reload post data if edit was successful
    if (result == true && mounted) {
      await _loadPostData();
    }
  }

  /// Show delete confirmation dialog and delete post
  Future<void> _confirmDeletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Post'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this post? '
          'This action cannot be undone and all replies will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePost();
    }
  }

  /// Delete the post via API
  Future<void> _deletePost() async {
    final request = context.read<CookieRequest>();
    
    try {
      final response = await request.post(
        '$baseUrl/forum/${widget.postId}/delete/',
        {},
      );
      
      if (!mounted) return;
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Return true to indicate post was deleted
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Failed to delete post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Delete a reply
  Future<void> _deleteReply(String replyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(
        '$baseUrl/forum/reply/$replyId/delete/',
        {},
      );
      
      if (!mounted) return;
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply deleted'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadPostData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Failed to delete reply'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Permission Check Methods
  // ---------------------------------------------------------------------------

  /// Check if current user can edit this post (author only)
  bool get _canEdit {
    if (_postData == null || _currentUserId == null) return false;
    return _postData!['author_id'] == _currentUserId;
  }

  /// Check if current user can delete this post (author or admin)
  bool get _canDelete {
    if (_postData == null || _currentUserId == null) return false;
    // Author can delete
    if (_postData!['author_id'] == _currentUserId) return true;
    // Admin can delete
    if (_currentUserRole == 'ADMIN') return true;
    return false;
  }

  /// Check if current user can delete a reply
  bool _canDeleteReply(ForumReply reply) {
    if (_currentUserId == null) return false;
    // Reply author can delete
    if (reply.authorId == _currentUserId) return true;
    // Admin can delete
    if (_currentUserRole == 'ADMIN') return true;
    return false;
  }

  // ---------------------------------------------------------------------------
  // Build Methods
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Forum Post'),
          backgroundColor: const Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error state if post not found
    if (_postData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Forum Post'),
          backgroundColor: const Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Post not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum Post'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        actions: [
          // Edit button (visible only to author)
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Post',
              onPressed: _navigateToEdit,
            ),
          // Delete button (visible to author and admin)
          if (_canDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Post',
              onPressed: _confirmDeletePost,
            ),
          // More options menu
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _loadPostData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------------------------------------------------------
                  // Post Header (Title + Pin Status)
                  // ---------------------------------------------------------------
                  Row(
                    children: [
                      if (_postData!['is_pinned'] == true)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.push_pin, size: 14, color: Colors.orange),
                              SizedBox(width: 4),
                              Text(
                                'Pinned',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _postData!['title'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ---------------------------------------------------------------
                  // Category Chips
                  // ---------------------------------------------------------------
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: _getCategoryIcon(_postData!['category']),
                        label: Text(_postData!['category_display']),
                        backgroundColor: Colors.blue[50],
                      ),
                      Chip(
                        avatar: _getSportIcon(_postData!['sport_category']),
                        label: Text(_postData!['sport_category_display']),
                        backgroundColor: Colors.green[50],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ---------------------------------------------------------------
                  // Author Info Card
                  // ---------------------------------------------------------------
                  _buildAuthorCard(),
                  const SizedBox(height: 16),

                  // ---------------------------------------------------------------
                  // Post Content
                  // ---------------------------------------------------------------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      _postData!['full_content'],
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---------------------------------------------------------------
                  // Linked Product/Location (if any)
                  // ---------------------------------------------------------------
                  _buildExternalLinks(),

                  // ---------------------------------------------------------------
                  // Like Button and Stats
                  // ---------------------------------------------------------------
                  _buildStatsRow(),
                  
                  const Divider(height: 32),

                  // ---------------------------------------------------------------
                  // Replies Section Header
                  // ---------------------------------------------------------------
                  Row(
                    children: [
                      const Icon(Icons.forum, color: Color(0xFF1D4ED8)),
                      const SizedBox(width: 8),
                      Text(
                        'Replies (${_replies.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ---------------------------------------------------------------
                  // Replies List
                  // ---------------------------------------------------------------
                  if (_replies.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No replies yet. Be the first to reply!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._replies
                        .asMap()
                        .entries
                        .map((entry) => _buildReplyCard(entry.value, entry.key + 2)),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // Reply Input Area (with Quote Preview)
          // -------------------------------------------------------------------
          _buildReplyInputArea(),
        ],
      ),
    );
  }

  /// Build the reply input area with optional quote preview
  Widget _buildReplyInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------------
            // Quote Preview (shown when quoting a reply)
            // -----------------------------------------------------------------
            if (_quotedReply != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: Colors.blue[400]!, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quote header with close button
                    Row(
                      children: [
                        Icon(Icons.format_quote, 
                            size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Replying to ${_quotedReply!.author}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                        const Spacer(),
                        // Close button to cancel quote
                        InkWell(
                          onTap: _clearQuote,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Quoted content preview (truncated)
                    Text(
                      _quotedReply!.contentPreview,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            
            // -----------------------------------------------------------------
            // Reply Input Field and Send Button
            // -----------------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: _quotedReply != null 
                          ? 'Write your reply to ${_quotedReply!.author}...'
                          : 'Write a reply...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF1D4ED8),
                  child: IconButton(
                    onPressed: _submitReply,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build the author info card
  Widget _buildAuthorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Author Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: _getRoleColor(_postData!['author_role']),
            child: Text(
              _postData!['author_initial'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Author Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _postData!['author'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleBadge(_postData!['author_role']),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Posted on ${_postData!['created_at']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                // Show last edited timestamp if post was edited
                if (_postData!['last_edited'] != null)
                  Text(
                    'Edited: ${_postData!['last_edited']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                // Show original poster total posts if available
                if (_postData!['original_poster_total_posts'] != null)
                  Text(
                    '${_postData!['original_poster_total_posts']} posts',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build external links section (product/location)
  Widget _buildExternalLinks() {
    final hasProduct = _postData!['product_id'] != null;
    final hasLocation = _postData!['location_id'] != null;
    
    if (!hasProduct && !hasLocation) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Linked Resources',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Product Link
            if (hasProduct)
              ActionChip(
                avatar: const Icon(Icons.shopping_bag, size: 18),
                label: Text('Product: ${_postData!['product_id']}'),
                backgroundColor: Colors.green[50],
                onPressed: () {
                  // TODO: Navigate to product detail page
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Product ID: ${_postData!['product_id']}'),
                    ),
                  );
                },
              ),
            
            // Location Link
            if (hasLocation)
              ActionChip(
                avatar: const Icon(Icons.location_on, size: 18),
                label: Text('Location: ${_postData!['location_id']}'),
                backgroundColor: Colors.blue[50],
                onPressed: () {
                  // TODO: Navigate to location detail page
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Location ID: ${_postData!['location_id']}'),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Build stats row (likes, views)
  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Like button
          InkWell(
            onTap: _toggleLike,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _userHasLiked ? Colors.red[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _userHasLiked ? Icons.favorite : Icons.favorite_border,
                    color: _userHasLiked ? Colors.red : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_postData!['like_count']}',
                    style: TextStyle(
                      color: _userHasLiked ? Colors.red : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Views count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_postData!['post_views']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a reply card with post number, quote button, and delete button
  Widget _buildReplyCard(ForumReply reply, int postNumber) {
    // Check if this reply is currently being quoted
    final bool isBeingQuoted = _quotedReply?.id == reply.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // Highlight if this reply is being quoted
      color: isBeingQuoted ? Colors.blue[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------------
            // Reply Header (Author info + Action buttons)
            // -----------------------------------------------------------------
            Row(
              children: [
                // Author Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _getRoleColor(reply.authorRole),
                  child: Text(
                    reply.authorInitial,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Author Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            reply.author,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          _buildRoleBadge(reply.authorRole, small: true),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            reply.createdAt,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '#$postNumber',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // ---------------------------------------------------------------
                // Action Buttons (Quote + Delete)
                // ---------------------------------------------------------------
                
                // Quote button - allows user to quote this reply
                IconButton(
                  icon: Icon(
                    isBeingQuoted ? Icons.format_quote : Icons.format_quote_outlined,
                    size: 18, 
                    color: isBeingQuoted ? Colors.blue : Colors.grey[600],
                  ),
                  tooltip: isBeingQuoted ? 'Quoting this reply' : 'Quote reply',
                  onPressed: () {
                    if (isBeingQuoted) {
                      // If already quoting, clear the quote
                      _clearQuote();
                    } else {
                      // Set this reply as quoted
                      _quoteReply(reply);
                    }
                  },
                ),
                
                // Delete reply button (only visible if user has permission)
                if (_canDeleteReply(reply))
                  IconButton(
                    icon: Icon(Icons.delete_outline, 
                        size: 18, color: Colors.red[300]),
                    tooltip: 'Delete reply',
                    onPressed: () => _deleteReply(reply.id),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // -----------------------------------------------------------------
            // Quoted Reply Display (if this reply quotes another)
            // -----------------------------------------------------------------
            if (reply.quoteInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border(
                    left: BorderSide(color: Colors.grey[400]!, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quoted author with icon
                    Row(
                      children: [
                        Icon(Icons.format_quote, 
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          reply.quoteInfo!.author,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Quoted content
                    Text(
                      reply.quoteInfo!.content,
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            
            // -----------------------------------------------------------------
            // Reply Content
            // -----------------------------------------------------------------
            Text(reply.content, style: const TextStyle(height: 1.5)),
            
            // -----------------------------------------------------------------
            // Reply Footer (Total posts by author)
            // -----------------------------------------------------------------
            if (reply.totalPosts > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${reply.totalPosts} posts',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper Methods
  // ---------------------------------------------------------------------------

  /// Get icon for post category
  Widget _getCategoryIcon(String category) {
    switch (category) {
      case 'general':
        return const Text('💬', style: TextStyle(fontSize: 14));
      case 'product_review':
        return const Text('⭐', style: TextStyle(fontSize: 14));
      case 'location_review':
        return const Text('📍', style: TextStyle(fontSize: 14));
      case 'question':
        return const Text('❓', style: TextStyle(fontSize: 14));
      case 'announcement':
        return const Text('📢', style: TextStyle(fontSize: 14));
      case 'feedback':
        return const Text('💭', style: TextStyle(fontSize: 14));
      default:
        return const Icon(Icons.chat, size: 14);
    }
  }

  /// Get icon for sport category
  Widget _getSportIcon(String sport) {
    switch (sport) {
      case 'running':
        return const Text('🏃', style: TextStyle(fontSize: 14));
      case 'cycling':
        return const Text('🚴', style: TextStyle(fontSize: 14));
      case 'swimming':
        return const Text('🏊', style: TextStyle(fontSize: 14));
      default:
        return const Icon(Icons.sports, size: 14);
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

  /// Build role badge widget
  Widget _buildRoleBadge(String? role, {bool small = false}) {
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
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : 6,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: small ? 9 : 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
