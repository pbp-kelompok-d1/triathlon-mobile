import 'dart:convert';

List<ProductEntry> productEntryFromJson(String str) =>
    List<ProductEntry>.from(json.decode(str).map((x) => ProductEntry.fromJson(x)));

String productEntryToJson(List<ProductEntry> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ProductEntry {
  final String id;
  final String name;
  final int price;
  final String description;
  final String category;
  final String thumbnail;
  final bool isFeatured;
  final int stock;
  final int? userId;
  final DateTime? createdAt;

  ProductEntry({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.thumbnail,
    required this.isFeatured,
    required this.stock,
    required this.userId,
    required this.createdAt,
  });

  factory ProductEntry.fromJson(Map<String, dynamic> json) {
    // Helper so every numeric field is parsed consistently from whatever JSON sends us.
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsedValue = int.tryParse(value);
        if (parsedValue == null) {
          return 0;
        }
        return parsedValue;
      }
      return 0;
    }

    final dynamic rawUserId = json['user_id'];
    int? parsedUserId;
    if (rawUserId == null) {
      parsedUserId = null;
    } else {
      parsedUserId = parseInt(rawUserId);
    }

    final dynamic rawCreatedAt = json['created_at'];
    DateTime? parsedCreatedAt;
    if (rawCreatedAt != null && rawCreatedAt != '') {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    } else {
      parsedCreatedAt = null;
    }

  // All of the following sections normalize nullable JSON fields into safe defaults.
  String nameValue = '';
    if (json['name'] != null) {
      nameValue = json['name'].toString();
    }

    String descriptionValue = '';
    if (json['description'] != null) {
      descriptionValue = json['description'].toString();
    }

    String categoryValue = '';
    if (json['category'] != null) {
      categoryValue = json['category'].toString();
    }

    String thumbnailValue = '';
    if (json['thumbnail'] != null) {
      thumbnailValue = json['thumbnail'].toString();
    }

    bool isFeaturedValue = false;
    if (json['is_featured'] is bool) {
      isFeaturedValue = json['is_featured'];
    }

    return ProductEntry(
      id: json['id'].toString(),
      name: nameValue,
      price: parseInt(json['price']),
      description: descriptionValue,
      category: categoryValue,
      thumbnail: thumbnailValue,
      isFeatured: isFeaturedValue,
      stock: parseInt(json['stock']),
      userId: parsedUserId,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
  // Preserve the timestamp format Django expects while still tolerating nulls.
  final DateTime? createdAtValue = createdAt;
    String? createdAtString;
    if (createdAtValue != null) {
      createdAtString = createdAtValue.toIso8601String();
    } else {
      createdAtString = null;
    }

    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'category': category,
      'thumbnail': thumbnail,
      'is_featured': isFeatured,
      'stock': stock,
      'user_id': userId,
      'created_at': createdAtString,
    };
  }
}
