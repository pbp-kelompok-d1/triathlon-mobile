import 'dart:convert';

List<ProductEntry> productEntryFromJson(String str) => List<ProductEntry>.from(
      json.decode(str).map((x) => ProductEntry.fromJson(x)),
    );

String productEntryToJson(List<ProductEntry> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ProductEntry {
  final String id;
  final String name;
  final double price;
  final String description;
  final String category;
  final String categoryLabel;
  final String thumbnail;
  final int stock;
  final String? sellerUsername;

  const ProductEntry({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.categoryLabel,
    required this.thumbnail,
    required this.stock,
    required this.sellerUsername,
  });

  factory ProductEntry.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsedValue = double.tryParse(value);
        if (parsedValue == null) {
          return 0;
        }
        return parsedValue;
      }
      return 0;
    }

    int parseStock(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    String readString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    return ProductEntry(
      id: readString(json['id']),
      name: readString(json['name']),
      price: parsePrice(json['price']),
      description: readString(json['description']),
      category: readString(json['category']),
      categoryLabel: readString(json['category_label']).isEmpty
          ? readString(json['category'])
          : readString(json['category_label']),
      thumbnail: readString(json['thumbnail']),
      stock: parseStock(json['stock']),
      sellerUsername: json['seller_username']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'category': category,
      'category_label': categoryLabel,
      'thumbnail': thumbnail,
      'stock': stock,
      'seller_username': sellerUsername,
    };
  }
}
