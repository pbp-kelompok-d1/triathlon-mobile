// To parse this JSON data, do
//
//     final forumReply = forumReplyFromJson(jsonString);

import 'dart:convert';

List<ForumReply> forumReplyFromJson(String str) =>
    List<ForumReply>.from(json.decode(str).map((x) => ForumReply.fromJson(x)));

String forumReplyToJson(List<ForumReply> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ForumReply {
  String id;
  String content;
  String createdAt;
  String author;
  int? authorId;
  String authorInitial;
  String authorRole;
  int totalPosts;
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
    this.quoteInfo,
  });

  factory ForumReply.fromJson(Map<String, dynamic> json) => ForumReply(
        id: json["id"],
        content: json["content"],
        createdAt: json["created_at"],
        author: json["author"],
        authorId: json["author_id"],
        authorInitial: json["author_initial"],
        authorRole: json["author_role"],
        totalPosts: json["total_posts"],
        quoteInfo: json["quote_info"] == null
            ? null
            : QuoteInfo.fromJson(json["quote_info"]),
      );

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
}

class QuoteInfo {
  String id;
  String author;
  String content;

  QuoteInfo({
    required this.id,
    required this.author,
    required this.content,
  });

  factory QuoteInfo.fromJson(Map<String, dynamic> json) => QuoteInfo(
        id: json["id"],
        author: json["author"],
        content: json["content"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "author": author,
        "content": content,
      };
}
