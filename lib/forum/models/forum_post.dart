// =============================================================================
// ForumPost Model
// =============================================================================
// This model represents a forum post in the triathlon mobile application.
// It includes all fields returned by the Django API including:
// - Basic post info (id, title, content, category, sport_category)
// - Author info (author, authorId, authorInitial, authorRole)
// - Engagement metrics (postViews, likeCount, userHasLiked)
// - Timestamps (createdAt, lastEdited)
// - External links (productId, locationId)
// - Status flags (isPinned)
// =============================================================================

import 'dart:convert';

/// Parse a JSON string into a list of ForumPost objects
List<ForumPost> forumPostFromJson(String str) =>
    List<ForumPost>.from(json.decode(str).map((x) => ForumPost.fromJson(x)));

/// Convert a list of ForumPost objects to a JSON string
String forumPostToJson(List<ForumPost> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

/// Represents a forum post in the triathlon community
class ForumPost {
  // -------------------------------------------------------------------------
  // Basic Post Information
  // -------------------------------------------------------------------------
  final String id;           // UUID of the post
  final String title;        // Post title
  final String content;      // Truncated content for list view
  final String fullContent;  // Full content for detail view

  // -------------------------------------------------------------------------
  // Category Information
  // -------------------------------------------------------------------------
  final String category;           // Category key (e.g., 'general', 'product_review')
  final String categoryDisplay;    // Human-readable category name
  final String sportCategory;      // Sport key (e.g., 'running', 'cycling', 'swimming')
  final String sportCategoryDisplay; // Human-readable sport name

  // -------------------------------------------------------------------------
  // Engagement Metrics
  // -------------------------------------------------------------------------
  int postViews;    // Number of times the post has been viewed
  int likeCount;    // Number of likes on the post
  bool userHasLiked; // Whether the current user has liked this post

  // -------------------------------------------------------------------------
  // Status Flags
  // -------------------------------------------------------------------------
  final bool isPinned; // Whether the post is pinned (admin only)

  // -------------------------------------------------------------------------
  // External Links (for product/location reviews)
  // -------------------------------------------------------------------------
  final String? productId;   // UUID of linked product (if any)
  final int? locationId;     // ID of linked location/place (if any)

  // -------------------------------------------------------------------------
  // Timestamps
  // -------------------------------------------------------------------------
  final String createdAt;    // When the post was created
  final String? lastEdited;  // When the post was last edited (null if never edited)

  // -------------------------------------------------------------------------
  // Author Information
  // -------------------------------------------------------------------------
  final String author;         // Author's username
  final int? authorId;         // Author's user ID
  final String authorInitial;  // First letter of author's username (for avatar)
  final String authorRole;     // Author's role (USER, ADMIN, SELLER, FACILITY_ADMIN)

  ForumPost({
    required this.id,
    required this.title,
    required this.content,
    required this.fullContent,
    required this.category,
    required this.categoryDisplay,
    required this.sportCategory,
    required this.sportCategoryDisplay,
    required this.postViews,
    required this.isPinned,
    this.productId,
    this.locationId,
    required this.createdAt,
    this.lastEdited,
    required this.author,
    this.authorId,
    required this.authorInitial,
    required this.authorRole,
    required this.likeCount,
    this.userHasLiked = false,
  });

  /// Factory constructor to create a ForumPost from JSON data
  factory ForumPost.fromJson(Map<String, dynamic> json) => ForumPost(
        id: json["id"],
        title: json["title"],
        content: json["content"],
        fullContent: json["full_content"] ?? json["content"], // Fallback to content if full_content not provided
        category: json["category"],
        categoryDisplay: json["category_display"],
        sportCategory: json["sport_category"],
        sportCategoryDisplay: json["sport_category_display"],
        postViews: json["post_views"],
        isPinned: json["is_pinned"],
        productId: json["product_id"],
        locationId: json["location_id"],
        createdAt: json["created_at"],
        lastEdited: json["last_edited"], // New field for tracking edits
        author: json["author"],
        authorId: json["author_id"],
        authorInitial: json["author_initial"],
        authorRole: json["author_role"],
        likeCount: json["like_count"],
        userHasLiked: json["user_has_liked"] ?? false, // New field for like status
      );

  /// Convert this ForumPost to a JSON map
  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "content": content,
        "full_content": fullContent,
        "category": category,
        "category_display": categoryDisplay,
        "sport_category": sportCategory,
        "sport_category_display": sportCategoryDisplay,
        "post_views": postViews,
        "is_pinned": isPinned,
        "product_id": productId,
        "location_id": locationId,
        "created_at": createdAt,
        "last_edited": lastEdited,
        "author": author,
        "author_id": authorId,
        "author_initial": authorInitial,
        "author_role": authorRole,
        "like_count": likeCount,
        "user_has_liked": userHasLiked,
      };

  // ===========================================================================
  // Helper Methods
  // ===========================================================================

  /// Check if the current user can edit this post
  /// Only the author can edit their own posts
  bool canEdit(int? currentUserId) {
    return authorId != null && currentUserId != null && authorId == currentUserId;
  }

  /// Check if the current user can delete this post
  /// Authors can delete their own posts, Admins can delete any post
  bool canDelete(int? currentUserId, String? currentUserRole) {
    if (currentUserId == null) return false;
    // Author can delete their own post
    if (authorId == currentUserId) return true;
    // Admin can delete any post
    if (currentUserRole == 'ADMIN') return true;
    return false;
  }

  /// Check if the current user can pin/unpin this post
  /// Only admins can pin/unpin posts
  bool canPin(String? currentUserRole) {
    return currentUserRole == 'ADMIN';
  }

  /// Check if this post has been edited
  bool get hasBeenEdited => lastEdited != null;

  /// Check if this post has a linked product
  bool get hasLinkedProduct => productId != null && productId!.isNotEmpty;

  /// Check if this post has a linked location
  bool get hasLinkedLocation => locationId != null;
}
