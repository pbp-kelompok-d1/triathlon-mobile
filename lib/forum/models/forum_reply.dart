// =============================================================================
// ForumReply Model
// =============================================================================
// This model represents a reply to a forum post in the triathlon application.
// 
// Key Features:
// - Reply content with author information
// - Author role and total posts count (for reputation display)
// - Quote support via QuoteInfo (for quoting other replies)
// 
// The quote system works as follows:
// - When creating a reply, user can optionally quote another reply
// - The quote_reply_id is sent to Django, which stores the FK relationship
// - When fetching replies, Django returns quote_info with the quoted content
// - This allows displaying "Originally posted by @user: ..." in the UI
// =============================================================================

import 'dart:convert';

/// Parse a JSON string into a list of ForumReply objects
List<ForumReply> forumReplyFromJson(String str) =>
    List<ForumReply>.from(json.decode(str).map((x) => ForumReply.fromJson(x)));

/// Convert a list of ForumReply objects to a JSON string
String forumReplyToJson(List<ForumReply> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

/// Represents a reply to a forum post
class ForumReply {
  // ---------------------------------------------------------------------------
  // Basic Reply Information
  // ---------------------------------------------------------------------------
  String id;           // UUID of the reply
  String content;      // Reply text content
  String createdAt;    // Formatted creation timestamp (e.g., "Dec 08, 2024")

  // ---------------------------------------------------------------------------
  // Author Information
  // ---------------------------------------------------------------------------
  String author;         // Author's username
  int? authorId;         // Author's user ID (for permission checks)
  String authorInitial;  // First letter of username (for avatar)
  String authorRole;     // Author's role (USER, ADMIN, SELLER, FACILITY_ADMIN)
  int totalPosts;        // Author's total post count (for reputation display)

  String postId;      // ID post induk
  String postTitle;   // Judul post induk
  String postCategory; // Kategori post (opsional, buat badge)
  // ---------------------------------------------------------------------------
  // Quote Information (optional)
  // ---------------------------------------------------------------------------
  // If this reply quotes another reply, quoteInfo contains:
  // - The quoted reply's ID
  // - The quoted reply's author
  // - The quoted content (may be truncated)
  QuoteInfo? quoteInfo;

  ForumReply({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.author,
    this.authorId,
    required this.authorInitial,
    required this.authorRole,
    required this.totalPosts,
    required this.postId,      // Wajib
    required this.postTitle,   // Wajib
    this.postCategory = '',
    this.quoteInfo,
  });

  /// Factory constructor to create a ForumReply from JSON data
  factory ForumReply.fromJson(Map<String, dynamic> json) => ForumReply(
        id: json["id"],
        content: json["content"],
        createdAt: json["created_at"],
        author: json["author"],
        authorId: json["author_id"],
        authorInitial: json["author_initial"],
        authorRole: json["author_role"],
        totalPosts: json["total_posts"],
        postId: json["post_id"]?.toString() ?? "",
        postTitle: json["post_title"] ?? "Unknown Post",
        postCategory: json["post_sport_category"] ?? "",
        quoteInfo: json["quote_info"] == null
            ? null
            : QuoteInfo.fromJson(json["quote_info"]),
      );

  /// Convert this ForumReply to a JSON map
  Map<String, dynamic> toJson() => {
        "id": id,
        "content": content,
        "created_at": createdAt,
        "author": author,
        "author_id": authorId,
        "author_initial": authorInitial,
        "author_role": authorRole,
        "total_posts": totalPosts,
        "post_id": postId,
        "post_title": postTitle,
        "post_sport_category": postCategory,
        "quote_info": quoteInfo?.toJson(),
      };

  // ===========================================================================
  // Helper Methods
  // ===========================================================================

  /// Check if this reply has quoted content
  bool get hasQuote => quoteInfo != null;

  /// Check if the current user can delete this reply
  /// Authors can delete their own replies, Admins can delete any reply
  bool canDelete(int? currentUserId, String? currentUserRole) {
    if (currentUserId == null) return false;
    // Author can delete their own reply
    if (authorId != null && authorId == currentUserId) return true;
    // Admin can delete any reply
    if (currentUserRole == 'ADMIN') return true;
    return false;
  }
}

// =============================================================================
// QuoteInfo Model
// =============================================================================
// Represents the quoted content when a reply quotes another reply.
// This is returned by Django when fetching replies that have a quote_reply FK.
// =============================================================================

/// Information about a quoted reply
class QuoteInfo {
  String id;       // UUID of the quoted reply
  String author;   // Author of the quoted reply
  String content;  // Content of the quoted reply (may be truncated)

  QuoteInfo({
    required this.id,
    required this.author,
    required this.content,
  });

  /// Factory constructor to create a QuoteInfo from JSON data
  factory QuoteInfo.fromJson(Map<String, dynamic> json) => QuoteInfo(
        id: json["id"],
        author: json["author"],
        content: json["content"],
      );

  /// Convert this QuoteInfo to a JSON map
  Map<String, dynamic> toJson() => {
        "id": id,
        "author": author,
        "content": content,
      };
}
