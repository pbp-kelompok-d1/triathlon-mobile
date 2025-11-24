// dart
import 'dart:convert';

class Product {
  final String id; // UUID
  final String? sellerUsername;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String category; // running | cycling | swimming | other
  final String thumbnail; // URL or asset path (may be empty)

  const Product({
    required this.id,
    this.sellerUsername,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.category,
    required this.thumbnail,
  });

  String get categoryLabel {
    switch (category.toLowerCase()) {
      case 'running':
        return 'Running';
      case 'cycling':
        return 'Cycling';
      case 'swimming':
        return 'Swimming';
      default:
        return category.isEmpty
            ? 'Other'
            : '${category[0].toUpperCase()}${category.substring(1)}';
    }
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      final s = v.toString().trim();
      if (s.isEmpty) return 0.0;
      return double.tryParse(s.replaceAll(',', '')) ?? 0.0;
    }

    int parseInt(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? fallback;
    }

    return Product(
      id: (json['id'] ?? '').toString(),
      sellerUsername: json['seller_username'] as String?,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: parsePrice(json['price']),
      stock: parseInt(json['stock']),
      category: (json['category'] ?? 'other').toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seller_username': sellerUsername,
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'category': category,
    'thumbnail': thumbnail,
  };
}

// Parse a JSON string representing a list of products.
List<Product> productFromJson(String str) {
  final dynamic data = json.decode(str);
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }
  return const <Product>[];
}

String productListToJson(List<Product> data) =>
    json.encode(data.map((e) => e.toJson()).toList());
