import './cart_item.dart';

class Cart {
  final int? id;
  final int userId;
  final DateTime createdAt;
  final List<CartItem> items;

  const Cart({
    this.id,
    required this.userId,
    required this.createdAt,
    required this.items,
  });

  double get totalPrice =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  factory Cart.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final rawItems = (json['items'] as List?) ?? const [];
    return Cart(
      id: json['id'] as int?,
      userId: (json['user'] ?? json['user_id']) is int
          ? (json['user'] ?? json['user_id']) as int
          : int.tryParse('${json['user'] ?? json['user_id']}') ?? 0,
      createdAt: parseDate(json['created_at']),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(CartItem.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson({bool embedItems = false}) => {
    'id': id,
    'user': userId,
    'created_at': createdAt.toIso8601String(),
    'items': items
        //.map((e) => e.toJson(embedProduct: embedItems))
        .toList(),
  };
}
