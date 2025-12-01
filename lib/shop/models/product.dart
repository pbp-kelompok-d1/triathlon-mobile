// dart
import 'dart:convert';

class Product {
  final String id;
  final String? sellerUsername;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String category;
  final String thumbnail;

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

    // Handle seller username from multiple possible backend formats
    String? parseSeller(dynamic raw) {
      if (raw == null) return null;
      if (raw is String) return raw;
      if (raw is Map) {
        final val = raw['username'];
        return val is String ? val : null;
      }
      return null;
    }

    final sellerField = json['seller_username'] ?? json['seller'];

    return Product(
      id: (json['id'] ?? '').toString(),
      sellerUsername: parseSeller(sellerField),
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
    // Keep both keys if you ever send back; adjust as needed.
    'seller_username': sellerUsername,
    'seller': sellerUsername,
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'category': category,
    'thumbnail': thumbnail,
  };
}

// dart
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

// dart
String productListToJson(List<Product> data) =>
    json.encode(data.map((e) => e.toJson()).toList());
