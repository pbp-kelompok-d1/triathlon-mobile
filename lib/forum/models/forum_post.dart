// To parse this JSON data, do
//
//     final forumPost = forumPostFromJson(jsonString);

import 'dart:convert';

List<ForumPost> forumPostFromJson(String str) =>
    List<ForumPost>.from(json.decode(str).map((x) => ForumPost.fromJson(x)));

String forumPostToJson(List<ForumPost> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ForumPost {
  String id;
  String title;
  String content;
  String fullContent;
  String category;
  String categoryDisplay;
  String sportCategory;
  String sportCategoryDisplay;
  int postViews;
  bool isPinned;
  String? productId;
  int? locationId;
  String createdAt;
  String author;
  int? authorId;
  String authorInitial;
  String authorRole;
  int likeCount;

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
    required this.author,
    this.authorId,
    required this.authorInitial,
    required this.authorRole,
    required this.likeCount,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) => ForumPost(
        id: json["id"],
        title: json["title"],
        content: json["content"],
        fullContent: json["full_content"],
        category: json["category"],
        categoryDisplay: json["category_display"],
        sportCategory: json["sport_category"],
        sportCategoryDisplay: json["sport_category_display"],
        postViews: json["post_views"],
        isPinned: json["is_pinned"],
        productId: json["product_id"],
        locationId: json["location_id"],
        createdAt: json["created_at"],
        author: json["author"],
        authorId: json["author_id"],
        authorInitial: json["author_initial"],
        authorRole: json["author_role"],
        likeCount: json["like_count"],
      );

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
        "author": author,
        "author_id": authorId,
        "author_initial": authorInitial,
        "author_role": authorRole,
        "like_count": likeCount,
      };
}
