// lib/shop/models/wishlist.dart
import 'product.dart';

class Wishlist {
  final int? id;
  final int userId;
  final List<Product> products;

  const Wishlist({
    this.id,
    required this.userId,
    required this.products,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    final prods = (json['products'] as List?) ?? const [];
    return Wishlist(
      id: json['id'] as int?,
      userId: (json['user'] ?? json['user_id']) as int,
      products: prods
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson({bool sendProductsAsObjects = false}) => {
    'id': id,
    'user': userId,
    'products': sendProductsAsObjects
        ? products.map((p) => p.toJson()).toList()
        : products.map((p) => p.id).toList(),
  };
}
