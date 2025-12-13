// =============================================================================
// Forum Service - API calls and utility functions for Forum feature
// =============================================================================
// This service provides:
// - Delete post functionality with confirmation dialog
// - Delete reply functionality with confirmation dialog
// - Reusable dialog widgets
// =============================================================================

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../../constants.dart';

/// Service class for forum-related API operations
class ForumService {
  // ===========================================================================
  // Delete Post
  // ===========================================================================

  /// Delete a forum post by ID
  /// Returns true if successful, false otherwise
  /// Only authors and admins can delete posts
  static Future<bool> deletePost(
    CookieRequest request,
    String postId,
  ) async {
    try {
      final response = await request.post(
        '$baseUrl/forum/$postId/delete/',
        {},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }

  /// Show delete post confirmation dialog
  /// Returns true if user confirms deletion and deletion is successful
  static Future<bool> showDeletePostDialog(
    BuildContext context,
    CookieRequest request,
    String postId,
    String postTitle,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // Dialog title with warning icon
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
            const SizedBox(width: 8),
            const Text('Delete Post'),
          ],
        ),
        // Dialog content
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this post?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            // Show post title in a card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.article, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      postTitle,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Warning text
            Text(
              'This action cannot be undone. All replies will also be deleted.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        // Dialog actions
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          // Delete button
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // If user didn't confirm, return false
    if (confirmed != true) return false;

    // Show loading dialog while deleting
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Perform deletion
    final success = await deletePost(request, postId);

    // Close loading dialog
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
    }

    // Show result message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Post deleted successfully' : 'Failed to delete post',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }

    return success;
  }

  // ===========================================================================
  // Delete Reply
  // ===========================================================================

  /// Delete a forum reply by ID
  /// Returns true if successful, false otherwise
  /// Only authors and admins can delete replies
  static Future<bool> deleteReply(
    CookieRequest request,
    String replyId,
  ) async {
    try {
      final response = await request.post(
        '$baseUrl/forum/reply/$replyId/delete/',
        {},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error deleting reply: $e');
      return false;
    }
  }

  /// Show delete reply confirmation dialog
  /// Returns true if user confirms deletion and deletion is successful
  static Future<bool> showDeleteReplyDialog(
    BuildContext context,
    CookieRequest request,
    String replyId,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // Dialog title with warning icon
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
            const SizedBox(width: 8),
            const Text('Delete Reply'),
          ],
        ),
        // Dialog content
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this reply?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        // Dialog actions
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          // Delete button
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // If user didn't confirm, return false
    if (confirmed != true) return false;

    // Show loading dialog while deleting
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Perform deletion
    final success = await deleteReply(request, replyId);

    // Close loading dialog
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
    }

    // Show result message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Reply deleted successfully' : 'Failed to delete reply',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }

    return success;
  }

  // ===========================================================================
  // Permission Helpers
  // ===========================================================================
  // These methods use USERNAME comparison (not user ID) because:
  // - Django login returns 'username' and 'role' in the response
  // - Django forum API returns 'author' (username string) for posts/replies
  // ===========================================================================

  /// Check if current user can edit a post
  /// Only the post author can edit their own posts
  static bool canEditPost(String? currentUsername, String? authorUsername) {
    // Both usernames must be present and match
    return currentUsername != null && 
           authorUsername != null && 
           currentUsername == authorUsername;
  }

  /// Check if current user can delete a post/reply
  /// Authors can delete their own, Admins can delete ANY post/reply
  static bool canDelete(String? currentUsername, String? authorUsername, String? currentUserRole) {
    // Admin can delete ANY post/reply regardless of authorship
    if (currentUserRole == 'ADMIN') return true;
    
    // For non-admins, they can only delete their own content
    if (currentUsername == null || authorUsername == null) return false;
    return currentUsername == authorUsername;
  }

  /// Check if current user can pin posts
  /// Only admins can pin/unpin posts
  static bool canPin(String? currentUserRole) {
    return currentUserRole == 'ADMIN';
  }
}
