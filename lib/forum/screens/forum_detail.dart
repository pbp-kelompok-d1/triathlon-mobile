// =============================================================================
// ForumDetailPage - Forum Post Detail Screen
// =============================================================================
// This screen displays the full details of a forum post including:
// - Post header with title, categories, pinned status
// - Author information with role badge (clickable username → profile)
// - Full post content
// - Linked product/location (if any)
// - Like/view stats
// - Edit/Delete buttons (for author/admin)
// - Last edited timestamp
// - Replies section with quote support and "OP" badge
// - Reply input form
// =============================================================================

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../shop/models/product.dart';
import '../../shop/screens/product_detail.dart';
import '../../place/models/place.dart';
import '../../place/screens/place_detail_screen.dart';
import '../../place/services/place_service.dart';
import '../models/forum_post.dart';
import '../models/forum_reply.dart';
import '../services/forum_service.dart';
import '../widgets/shimmer_loading.dart';  // Shimmer loading widgets
import '../widgets/page_transitions.dart';  // Custom page transitions
import 'forum_edit.dart';
import 'forum_user_profile.dart';  // Import user profile page for navigation

/// Screen for displaying forum post details and replies
class ForumDetailPage extends StatefulWidget {
  final String postId;

  const ForumDetailPage({super.key, required this.postId});

  @override
  State<ForumDetailPage> createState() => _ForumDetailPageState();
}

class _ForumDetailPageState extends State<ForumDetailPage> {
  // ===========================================================================
  // State Variables
  // ===========================================================================
  final TextEditingController _replyController = TextEditingController();
  
  Map<String, dynamic>? _postData;  // Raw post data from API
  ForumPost? _post;                  // Parsed ForumPost object
  List<ForumReply> _replies = [];
  bool _isLoading = true;
  bool _userHasLiked = false;
  
  // ---------------------------------------------------------------------------
  // Quote Reply State
  // ---------------------------------------------------------------------------
  // These variables track the currently selected reply to quote
  // When a user clicks "Quote" on a reply, we store that reply here
  // The quoted content is shown as a preview above the reply input field
  ForumReply? _quotedReply;  // The reply being quoted (null if none)

  // ===========================================================================
  // Lifecycle Methods
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }
  
  // ===========================================================================
  // Quote Reply Methods
  // ===========================================================================

  /// Set a reply as the quoted reply for the new reply being composed
  /// This shows a preview of the quoted content above the reply input
  void _setQuotedReply(ForumReply reply) {
    setState(() {
      _quotedReply = reply;
    });
    // Focus the reply text field after selecting a quote
    // This improves UX by directing user to type their response
  }

  /// Cancel the quote selection, removing the preview
  void _cancelQuote() {
    setState(() {
      _quotedReply = null;
    });
  }

  // ===========================================================================
  // Data Loading
  // ===========================================================================

  /// Load post data and replies from the Django API
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
        
        // Parse into ForumPost object for helper methods
        if (_postData != null) {
          _post = ForumPost.fromJson(_postData!);
        }
        
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

  // ===========================================================================
  // Post Actions
  // ===========================================================================

  /// Toggle like status for the post
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

  /// Navigate to edit screen with fade transition
  Future<void> _navigateToEdit() async {
    if (_post == null) return;
    
    final result = await Navigator.push(
      context,
      ForumPageTransitions.fadeIn(
        ForumEditPage(post: _post!),
      ),
    );
    
    // Refresh data if post was edited
    if (result == true) {
      _loadPostData();
    }
  }

  /// Delete the current post
  Future<void> _deletePost() async {
    final request = context.read<CookieRequest>();
    
    final success = await ForumService.showDeletePostDialog(
      context,
      request,
      widget.postId,
      _postData!['title'],
    );
    
    // If deletion was successful, go back to forum list
    if (success && mounted) {
      Navigator.pop(context, true); // Return true to trigger refresh
    }
  }

  /// Delete a reply
  Future<void> _deleteReply(String replyId) async {
    final request = context.read<CookieRequest>();
    
    final success = await ForumService.showDeleteReplyDialog(
      context,
      request,
      replyId,
    );
    
    // Refresh replies if deletion was successful
    if (success) {
      _loadPostData();
    }
  }

  // ===========================================================================
  // Reply Submission
  // ===========================================================================

  /// Submit a new reply to the post
  /// If a quote is selected (_quotedReply is not null), includes the quote_reply_id
  /// in the request body so Django can store the quote relationship
  Future<void> _submitReply() async {
    // Validate reply content is not empty
    if (_replyController.text.trim().isEmpty) return;

    final request = context.read<CookieRequest>();
    try {
      // Build request body with content and optional quote_reply_id
      final Map<String, dynamic> requestBody = {
        'content': _replyController.text,
      };
      
      // If user is quoting another reply, include the quote_reply_id
      // This tells Django to store the foreign key relationship
      if (_quotedReply != null) {
        requestBody['quote_reply_id'] = _quotedReply!.id;
      }
      
      final response = await request.post(
        '$baseUrl/forum/${widget.postId}/reply/',
        requestBody,
      );
      
      if (response['success']) {
        // Clear the input field
        _replyController.clear();
        // Clear the quoted reply state
        _cancelQuote();
        // Refresh to show the new reply
        await _loadPostData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reply posted!')),
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

    // Show loading state with shimmer effect
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Forum Post'),
          backgroundColor: const Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
        ),
        body: const ForumDetailShimmer(),
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

    // Check permissions using username (Django returns 'author' as username string)
    final authorUsername = _postData!['author'];
    final canEdit = ForumService.canEditPost(currentUsername, authorUsername);
    final canDelete = ForumService.canDelete(currentUsername, authorUsername, currentUserRole);

    return Scaffold(
      // -----------------------------------------------------------------------
      // App Bar with Edit/Delete Actions
      // -----------------------------------------------------------------------
      appBar: AppBar(
        title: const Text('Forum Post'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        actions: [
          // Edit button (only for author)
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Post',
              onPressed: _navigateToEdit,
            ),
          // Delete button (for author or admin)
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Post',
              onPressed: _deletePost,
            ),
        ],
      ),
      
      // -----------------------------------------------------------------------
      // Body
      // -----------------------------------------------------------------------
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------------------------------------------------------------
                  // Post Header (Title + Pinned Badge)
                  // -------------------------------------------------------------
                  Row(
                    children: [
                      if (_postData!['is_pinned'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.push_pin, size: 16, color: Colors.orange[800]),
                              const SizedBox(width: 4),
                              Text(
                                'Pinned',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (_postData!['is_pinned'] == true) const SizedBox(height: 8),
                  
                  // Title with Hero animation
                  Hero(
                    tag: 'post_title_${widget.postId}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        _postData!['title'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // -------------------------------------------------------------
                  // Category Badges
                  // -------------------------------------------------------------
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCategoryChip(
                        _postData!['category_display'],
                        Colors.blue[50]!,
                        Colors.blue[700]!,
                      ),
                      _buildCategoryChip(
                        _postData!['sport_category_display'],
                        Colors.green[50]!,
                        Colors.green[700]!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // -------------------------------------------------------------
                  // Author Info Section
                  // -------------------------------------------------------------
                  _buildAuthorSection(),
                  const SizedBox(height: 16),
                  
                  // -------------------------------------------------------------
                  // Last Edited Timestamp (if applicable)
                  // -------------------------------------------------------------
                  if (_postData!['last_edited'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_note, size: 16, color: Colors.amber[800]),
                          const SizedBox(width: 4),
                          Text(
                            'Last edited: ${_postData!['last_edited']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[800],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // -------------------------------------------------------------
                  // Post Content
                  // -------------------------------------------------------------
                  Text(
                    _postData!['full_content'],
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  
                  // -------------------------------------------------------------
                  // Linked Product/Location (if any)
                  // -------------------------------------------------------------
                  _buildLinkedContent(),
                  
                  // -------------------------------------------------------------
                  // Like Button and Stats
                  // -------------------------------------------------------------
                  const Divider(height: 32),
                  _buildStatsRow(),
                  const Divider(height: 32),
                  
                  // -------------------------------------------------------------
                  // Replies Section
                  // -------------------------------------------------------------
                  Row(
                    children: [
                      const Icon(Icons.forum, size: 20, color: Color(0xFF1D4ED8)),
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
                  
                  // Render each reply with staggered animation and swipe-to-delete
                  ..._replies.asMap().entries.map((entry) {
                    final index = entry.key;
                    final reply = entry.value;
                    final canDelete = ForumService.canDelete(
                      currentUsername,
                      reply.author,
                      currentUserRole,
                    );
                    
                    // Wrap with Dismissible for swipe-to-delete (if user has permission)
                    Widget replyCard = _buildReplyCard(reply, index + 2, currentUsername, currentUserRole);
                    
                    if (canDelete) {
                      replyCard = Dismissible(
                        key: Key('reply_${reply.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white, size: 28),
                        ),
                        confirmDismiss: (_) async {
                          // Show confirmation dialog before deleting
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Reply'),
                              content: const Text('Are you sure you want to delete this reply?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ) ?? false;
                        },
                        onDismissed: (_) => _deleteReply(reply.id),
                        child: replyCard,
                      );
                    }
                    
                    // Wrap with animated entry (slide + fade with stagger)
                    return TweenAnimationBuilder<double>(
                      key: ValueKey('reply_anim_${reply.id}'),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(30 * (1 - value), 0),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: replyCard,
                    );
                  }),
                  
                  // Empty state for no replies
                  if (_replies.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'No replies yet. Be the first to respond!',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // -------------------------------------------------------------------
          // Reply Input Section with Quote Preview
          // -------------------------------------------------------------------
          // This section contains:
          // 1. Quote preview (if a reply is being quoted)
          // 2. Reply text input field
          // 3. Send button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -----------------------------------------------------------------
                // Quote Preview Section (shown when quoting a reply)
                // -----------------------------------------------------------------
                // Displays the quoted content with author attribution
                // User can click X to cancel the quote
                if (_quotedReply != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(color: Colors.blue[400]!, width: 3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quote icon
                        Icon(Icons.format_quote, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        // Quote content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // "Quoting @username" header
                              Text(
                                'Quoting @${_quotedReply!.author}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Quoted content preview (max 2 lines)
                              Text(
                                _quotedReply!.content,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Cancel quote button (X icon)
                        GestureDetector(
                          onTap: _cancelQuote,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // -----------------------------------------------------------------
                // Reply Input Row
                // -----------------------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: InputDecoration(
                          // Change hint text based on whether quoting
                          hintText: _quotedReply != null 
                              ? 'Write your response to the quote...' 
                              : 'Write a reply...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4ED8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: _submitReply,
                        icon: const Icon(Icons.send, color: Colors.white),
                        tooltip: 'Send reply',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Helper Widgets
  // ===========================================================================

  /// Build a category chip with icon
  Widget _buildCategoryChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  // ===========================================================================
  // Navigation Helper
  // ===========================================================================

  /// Navigate to a user's public profile page
  /// Called when tapping on a username in the post or reply sections
  void _navigateToUserProfile(String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForumUserProfilePage(username: username),
      ),
    );
  }

  /// Build the author info section with clickable username
  Widget _buildAuthorSection() {
    final authorRole = _postData!['author_role'] ?? 'USER';
    final authorUsername = _postData!['author'] ?? 'Anonymous';
    final totalPosts = _postData!['original_poster_total_posts'] ?? 0;
    
    return Row(
      children: [
        // Author avatar - clickable to navigate to profile
        GestureDetector(
          onTap: () => _navigateToUserProfile(authorUsername),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: _getAvatarColor(authorRole),
            child: Text(
              _postData!['author_initial'],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Author name and metadata
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Clickable username - navigates to user profile
                  GestureDetector(
                    onTap: () => _navigateToUserProfile(authorUsername),
                    child: Text(
                      authorUsername,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1D4ED8),  // Blue color to indicate clickable
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Role badge
                  _buildRoleBadge(authorRole),
                  const SizedBox(width: 8),
                  // Total posts badge (user stats)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.article_outlined, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$totalPosts posts',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Posted on ${_postData!['created_at']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build role badge for author
  Widget _buildRoleBadge(String role) {
    Color bgColor;
    Color textColor;
    String label;
    
    switch (role) {
      case 'ADMIN':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        label = 'Admin';
        break;
      case 'SELLER':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        label = 'Seller';
        break;
      case 'FACILITY_ADMIN':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        label = 'Facility Admin';
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        label = 'User';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  /// Get avatar color based on role
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

  /// Build linked product/location section
  Widget _buildLinkedContent() {
    final productId = _postData!['product_id'];
    final locationId = _postData!['location_id'];
    
    if (productId == null && locationId == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Linked Product - Clickable to navigate to ProductDetailPage
        if (productId != null)
          InkWell(
            onTap: () => _navigateToProductDetail(productId),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Linked Product',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Tap to view product details',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.green[700], size: 16),
                ],
              ),
            ),
          ),
        
        // Linked Location - Clickable to navigate to PlaceDetailScreen
        if (locationId != null)
          InkWell(
            onTap: () => _navigateToPlaceDetail(locationId),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Linked Location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Tap to view location details',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.blue[700], size: 16),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ===========================================================================
  // Navigation Methods for Linked Content
  // ===========================================================================

  /// Navigate to ProductDetailPage by fetching the product from API
  Future<void> _navigateToProductDetail(String productId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final request = context.read<CookieRequest>();
      // Fetch all products and find the matching one
      final response = await request.get('$baseUrl/shop/api/products/');
      
      List<dynamic> listData = [];
      if (response is List) {
        listData = response;
      } else if (response is Map<String, dynamic>) {
        final possible = response['data'] ?? response['results'];
        if (possible is List) listData = possible;
      }
      
      // Find the product by ID
      final productJson = listData.firstWhere(
        (json) => json['id'] == productId,
        orElse: () => null,
      );
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      if (productJson != null) {
        final product = Product.fromJson(productJson);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading product: $e')),
      );
    }
  }

  /// Navigate to PlaceDetailScreen by fetching the place from API
  Future<void> _navigateToPlaceDetail(int locationId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final placeService = PlaceService();
      final places = await placeService.fetchPlaces();
      
      // Find the place by ID
      final place = places.firstWhere(
        (p) => p.id == locationId,
        orElse: () => throw Exception('Place not found'),
      );
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PlaceDetailScreen(place: place),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading location: $e')),
      );
    }
  }

  /// Build stats row (likes, views)
  Widget _buildStatsRow() {
    return Row(
      children: [
        // Like button
        InkWell(
          onTap: _toggleLike,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _userHasLiked ? Colors.red[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _userHasLiked ? Icons.favorite : Icons.favorite_border,
                  color: _userHasLiked ? Colors.red : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_postData!['like_count']} ${_userHasLiked ? 'Liked' : 'Like'}',
                  style: TextStyle(
                    color: _userHasLiked ? Colors.red[700] : Colors.grey[700],
                    fontWeight: _userHasLiked ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Views counter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.visibility, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                '${_postData!['post_views']} views',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a reply card
  /// Displays the reply content with author info, optional quoted content,
  /// and action buttons (Quote, Delete)
  /// Shows "OP" (Original Poster) badge if the reply author is the post author
  Widget _buildReplyCard(ForumReply reply, int replyNumber, String? currentUsername, String? currentUserRole) {
    // Check if current user can delete this reply
    // (authors can delete their own replies, admins can delete any)
    // Use reply.author (username string) for comparison
    final canDeleteReply = ForumService.canDelete(
      currentUsername,
      reply.author,  // author is the username string
      currentUserRole,
    );
    
    // Check if this reply is currently being quoted
    // Used to highlight the card visually when selected
    final isBeingQuoted = _quotedReply?.id == reply.id;
    
    // ---------------------------------------------------------------------------
    // Check if this reply author is the Original Poster (OP)
    // ---------------------------------------------------------------------------
    // Compare the reply author with the post author to determine if they are the OP
    // This helps users quickly identify when the post author is responding
    final postAuthor = _postData?['author'] ?? '';
    final isOriginalPoster = reply.author == postAuthor;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isBeingQuoted ? 3 : 1, // Higher elevation when quoted
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        // Blue border when this reply is being quoted
        side: isBeingQuoted 
            ? BorderSide(color: Colors.blue[400]!, width: 2) 
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------------
            // Reply Header (Avatar, Author Info, Action Buttons)
            // -----------------------------------------------------------------
            Row(
              children: [
                // Author avatar - clickable to navigate to profile
                GestureDetector(
                  onTap: () => _navigateToUserProfile(reply.author),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: _getAvatarColor(reply.authorRole),
                    child: Text(
                      reply.authorInitial,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Author name, badges, and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row with author name, OP badge, role badge, and total posts
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Clickable author name - navigates to user profile
                          GestureDetector(
                            onTap: () => _navigateToUserProfile(reply.author),
                            child: Text(
                              reply.author,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),  // Blue to indicate clickable
                              ),
                            ),
                          ),
                          // Original Poster (OP) badge - shown when reply author is post author
                          if (isOriginalPoster)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'OP',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[800],
                                ),
                              ),
                            ),
                          // Role badge (Admin, Seller, etc.)
                          _buildRoleBadge(reply.authorRole),
                          // Total posts badge (user stats)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.article_outlined, size: 10, color: Colors.grey[600]),
                                const SizedBox(width: 2),
                                Text(
                                  '${reply.totalPosts}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            reply.createdAt,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 8),
                          // Reply number indicator (e.g., #2, #3, etc.)
                          Text(
                            '#$replyNumber',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // -----------------------------------------------------------------
                // Action Buttons (Quote, Delete)
                // -----------------------------------------------------------------
                // Quote button - allows user to quote this reply
                // Shows different visual state when already quoting this reply
                IconButton(
                  icon: Icon(
                    isBeingQuoted ? Icons.format_quote : Icons.format_quote_outlined,
                    color: isBeingQuoted ? Colors.blue[700] : Colors.grey[600],
                    size: 20,
                  ),
                  onPressed: () {
                    if (isBeingQuoted) {
                      // If already quoting this reply, cancel the quote
                      _cancelQuote();
                    } else {
                      // Set this reply as the quoted reply
                      _setQuotedReply(reply);
                    }
                  },
                  tooltip: isBeingQuoted ? 'Cancel quote' : 'Quote this reply',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                // Delete button (only shown if user has permission)
                if (canDeleteReply)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                    onPressed: () => _deleteReply(reply.id),
                    tooltip: 'Delete reply',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // -----------------------------------------------------------------
            // Quoted Reply Section (if this reply quotes another reply)
            // -----------------------------------------------------------------
            // Shows the quoted content with author attribution
            // Styled with a left border and grey background
            if (reply.quoteInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                  border: Border(
                    left: BorderSide(color: Colors.blue[300]!, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quote header with icon and author name
                    Row(
                      children: [
                        Icon(Icons.format_quote, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '@${reply.quoteInfo!.author}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Quoted content (truncated to 2 lines)
                    Text(
                      reply.quoteInfo!.content,
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
            ],
            
            // -----------------------------------------------------------------
            // Reply Content
            // -----------------------------------------------------------------
            Text(reply.content, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}
