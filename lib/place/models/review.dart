import 'dart:convert';

List<Review> reviewFromJson(String str) => List<Review>.from(json.decode(str).map((x) => Review.fromJson(x)));

class Review {
    int id;
    String userName; // Di serializer Django namanya 'user_name'
    int rating;
    String comment;
    String createdAt;

    Review({
        required this.id,
        required this.userName,
        required this.rating,
        required this.comment,
        required this.createdAt,
    });

    factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json["id"],
        userName: json["user_name"], // Mapping dari snake_case Django
        rating: json["rating"],
        comment: json["comment"],
        createdAt: json["created_at"],
    );
}