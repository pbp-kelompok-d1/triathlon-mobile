// =============================================================================
// ForumPost Model
// =============================================================================
// This model represents a forum post with all its metadata including:
// - Basic info: id, title, content, categories
// - Author info: author name, id, initial, role
// - Engagement: views, likes, pinned status
// - External links: product_id (UUID), location_id (Integer)
// - Timestamps: created_at, last_edited
// =============================================================================

import 'dart:convert';

/// Parse a JSON string into a list of ForumPost objects
List<ForumPost> forumPostFromJson(String str) =>
    List<ForumPost>.from(json.decode(str).map((x) => ForumPost.fromJson(x)));

/// Convert a list of ForumPost objects to JSON string
String forumPostToJson(List<ForumPost> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

/// ForumPost represents a discussion thread in the forum
class ForumPost {
  // -------------------------------------------------------------------------
  // Core Post Properties
  // -------------------------------------------------------------------------
  
  /// Unique identifier (UUID) for the post
  String id;
  
  /// Post title (max 255 characters)
  String title;
  
  /// Truncated content preview (first 150 chars + '...')
  String content;
  
  /// Full post content without truncation
  String fullContent;
  
  // -------------------------------------------------------------------------
  // Category Properties
  // -------------------------------------------------------------------------
  
  /// Category key: general, product_review, location_review, question, announcement, feedback
  String category;
  
  /// Human-readable category name
  String categoryDisplay;
  
  /// Sport category key: running, cycling, swimming
  String sportCategory;
  
  /// Human-readable sport category name
  String sportCategoryDisplay;
  
  // -------------------------------------------------------------------------
  // Engagement & Status Properties
  // -------------------------------------------------------------------------
  
  /// Number of times this post has been viewed
  int postViews;
  
  /// Whether the post is pinned (appears at top of list)
  bool isPinned;
  
  /// Number of likes on this post
  int likeCount;
  
  // -------------------------------------------------------------------------
  // External Link Properties
  // -------------------------------------------------------------------------
  
  /// Optional UUID linking to a Product from the shop
  String? productId;
  
  /// Optional integer ID linking to a Place/Location
  int? locationId;
  
  // -------------------------------------------------------------------------
  // Timestamp Properties
  // -------------------------------------------------------------------------
  
  /// When the post was created (formatted string)
  String createdAt;
  
  /// When the post was last edited (null if never edited)
  String? lastEdited;
  
  // -------------------------------------------------------------------------
  // Author Properties
  // -------------------------------------------------------------------------
  
  /// Author's username
  String author;
  
  /// Author's user ID (for permission checks)
  int? authorId;
  
  /// First letter of author's username (for avatar)
  String authorInitial;
  
  /// Author's role: USER, SELLER, FACILITY_ADMIN, ADMIN
  String authorRole;
  
  // -------------------------------------------------------------------------
  // Additional Properties (for detail view)
  // -------------------------------------------------------------------------
  
  /// Total posts by the original poster (posts + replies)
  int? originalPosterTotalPosts;

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
    this.originalPosterTotalPosts,
  });

  /// Factory constructor to create ForumPost from JSON map
  factory ForumPost.fromJson(Map<String, dynamic> json) => ForumPost(
        id: json["id"],
        title: json["title"],
        content: json["content"],
        fullContent: json["full_content"] ?? json["content"],
        category: json["category"],
        categoryDisplay: json["category_display"],
        sportCategory: json["sport_category"],
        sportCategoryDisplay: json["sport_category_display"],
        postViews: json["post_views"],
        isPinned: json["is_pinned"],
        productId: json["product_id"],
        locationId: json["location_id"],
        createdAt: json["created_at"],
        lastEdited: json["last_edited"],
        author: json["author"],
        authorId: json["author_id"],
        authorInitial: json["author_initial"],
        authorRole: json["author_role"],
        likeCount: json["like_count"],
        originalPosterTotalPosts: json["original_poster_total_posts"],
      );

  /// Convert ForumPost to JSON map for API requests
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
        "original_poster_total_posts": originalPosterTotalPosts,
      };
  
  // -------------------------------------------------------------------------
  // Helper Methods
  // -------------------------------------------------------------------------
  
  /// Check if the current user can edit this post
  /// Only the author can edit their own posts
  bool canEdit(int? currentUserId) {
    return currentUserId != null && authorId == currentUserId;
  }
  
  /// Check if the current user can delete this post
  /// Authors can delete their own posts, Admins can delete any post
  bool canDelete(int? currentUserId, String? currentUserRole) {
    if (currentUserId == null) return false;
    // Author can always delete their own post
    if (authorId == currentUserId) return true;
    // Admin can delete any post
    if (currentUserRole == 'ADMIN') return true;
    return false;
  }
  
  /// Check if the user is an admin (for pin/unpin functionality)
  static bool isAdmin(String? role) {
    return role == 'ADMIN';
  }
  
  /// Check if post has linked product
  bool get hasLinkedProduct => productId != null && productId!.isNotEmpty;
  
  /// Check if post has linked location
  bool get hasLinkedLocation => locationId != null;
  
  /// Check if post was edited
  bool get wasEdited => lastEdited != null && lastEdited!.isNotEmpty;
}
