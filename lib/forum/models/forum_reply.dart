// =============================================================================
// Forum Reply Model
// =============================================================================
// This model represents a single reply/comment on a forum post.
// Features:
// - Reply content and metadata (author, date)
// - Quote reply support (quoting another reply)
// - Author role badges (Admin, Seller, etc.)
// - Post count for author
// =============================================================================

import 'dart:convert';

/// Parse a JSON string into a list of ForumReply objects
List<ForumReply> forumReplyFromJson(String str) =>
    List<ForumReply>.from(json.decode(str).map((x) => ForumReply.fromJson(x)));

/// Convert a list of ForumReply objects to a JSON string
String forumReplyToJson(List<ForumReply> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

// =============================================================================
// ForumReply Class
// =============================================================================
/// Represents a single reply to a forum post
class ForumReply {
  // ---------------------------------------------------------------------------
  // Properties
  // ---------------------------------------------------------------------------
  
  /// Unique identifier for the reply (UUID string)
  String id;
  
  /// The content/text of the reply
  String content;
  
  /// Formatted date string when the reply was created
  String createdAt;
  
  /// Username of the reply author
  String author;
  
  /// Numeric ID of the author (for permission checks)
  int? authorId;
  
  /// First letter of author's username (for avatar)
  String authorInitial;
  
  /// Author's role (ADMIN, SELLER, USER, etc.)
  String authorRole;
  
  /// Total number of posts + replies by this author
  int totalPosts;
  
  /// Information about the quoted reply (if this reply quotes another)
  QuoteInfo? quoteInfo;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  ForumReply({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.author,
    this.authorId,
    required this.authorInitial,
    required this.authorRole,
    required this.totalPosts,
    this.quoteInfo,
  });

  // ---------------------------------------------------------------------------
  // JSON Serialization
  // ---------------------------------------------------------------------------
  
  /// Create a ForumReply from JSON data
  factory ForumReply.fromJson(Map<String, dynamic> json) => ForumReply(
        id: json["id"],
        content: json["content"],
        createdAt: json["created_at"],
        author: json["author"],
        authorId: json["author_id"],
        authorInitial: json["author_initial"],
        authorRole: json["author_role"] ?? 'USER',
        totalPosts: json["total_posts"] ?? 0,
        quoteInfo: json["quote_info"] == null
            ? null
            : QuoteInfo.fromJson(json["quote_info"]),
      );

  /// Convert this ForumReply to JSON
  Map<String, dynamic> toJson() => {
        "id": id,
        "content": content,
        "created_at": createdAt,
        "author": author,
        "author_id": authorId,
        "author_initial": authorInitial,
        "author_role": authorRole,
        "total_posts": totalPosts,
        "quote_info": quoteInfo?.toJson(),
      };

  // ---------------------------------------------------------------------------
  // Helper Methods
  // ---------------------------------------------------------------------------
  
  /// Check if the current user can delete this reply
  /// - Reply author can delete their own reply
  /// - Admins can delete any reply
  bool canDelete(int? currentUserId, String? currentUserRole) {
    if (currentUserId == null) return false;
    // Author can delete their own reply
    if (authorId == currentUserId) return true;
    // Admin can delete any reply
    if (currentUserRole == 'ADMIN') return true;
    return false;
  }

  /// Check if this reply has a quote
  bool get hasQuote => quoteInfo != null;

  /// Check if author is admin
  bool get isAuthorAdmin => authorRole == 'ADMIN';

  /// Check if author is seller
  bool get isAuthorSeller => authorRole == 'SELLER';

  /// Get a short preview of the content (for quoting)
  String get contentPreview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }
}

// =============================================================================
// QuoteInfo Class
// =============================================================================
/// Information about a quoted reply
class QuoteInfo {
  // ---------------------------------------------------------------------------
  // Properties
  // ---------------------------------------------------------------------------
  
  /// ID of the quoted reply
  String id;
  
  /// Author of the quoted reply
  String author;
  
  /// Content of the quoted reply (may be truncated)
  String content;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  QuoteInfo({
    required this.id,
    required this.author,
    required this.content,
  });

  // ---------------------------------------------------------------------------
  // JSON Serialization
  // ---------------------------------------------------------------------------
  
  /// Create a QuoteInfo from JSON data
  factory QuoteInfo.fromJson(Map<String, dynamic> json) => QuoteInfo(
        id: json["id"],
        author: json["author"],
        content: json["content"],
      );

  /// Convert this QuoteInfo to JSON
  Map<String, dynamic> toJson() => {
        "id": id,
        "author": author,
        "content": content,
      };
}

