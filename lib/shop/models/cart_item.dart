import 'dart:convert';

List<CartItem> cartItemsFromJson(String str) =>
    List<CartItem>.from(json.decode(str).map((x) => CartItem.fromJson(x)));

class CartItem {
  final int itemId;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  final String thumbnail;
  final int stock;
  final String? sellerUsername;

  CartItem({
    required this.itemId,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.thumbnail,
    required this.stock,
    required this.sellerUsername,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    itemId: json["item_id"] ?? 0,
    productId: json["product_id"] ?? "",
    name: json["name"] ?? "",
    price: (json["price"] ?? 0).toDouble(),
    quantity: json["quantity"] ?? 0,
    subtotal: (json["subtotal"] ?? 0).toDouble(),
    thumbnail: json["thumbnail"] ?? "",
    stock: json["stock"] ?? 0,
    sellerUsername: json["seller_username"],
  );
}

class CartResponse {
  final String status;
  final int? cartId;
  final List<CartItem> items;
  final double total;
  final String? message;

  CartResponse({
    required this.status,
    this.cartId,
    required this.items,
    required this.total,
    this.message,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) => CartResponse(
    status: json["status"] ?? "",
    cartId: json["cart_id"],
    items: json["items"] != null
        ? List<CartItem>.from(
        json["items"].map((x) => CartItem.fromJson(x)))
        : [],
    total: (json["total"] ?? 0).toDouble(),
    message: json["message"],
  );
}
