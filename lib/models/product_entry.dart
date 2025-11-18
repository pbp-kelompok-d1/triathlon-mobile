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
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return ProductEntry(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      price: parseInt(json['price']),
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      isFeatured: json['is_featured'] ?? false,
      stock: parseInt(json['stock']),
      userId: json['user_id'] == null ? null : parseInt(json['user_id']),
      createdAt: json['created_at'] != null && json['created_at'] != ''
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'description': description,
        'category': category,
        'thumbnail': thumbnail,
        'is_featured': isFeatured,
        'stock': stock,
        'user_id': userId,
        'created_at': createdAt?.toIso8601String(),
      };
}
