import './product.dart';

class CartItem {
  final int? id;
  final Product product;
  final int quantity;

  const CartItem({
    this.id,
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final p = json['product'];
    final Product prod = p is Map<String, dynamic>
        ? Product.fromJson(p)
        : Product(
      id: (p ?? '').toString(),
      sellerUsername: null,
      name: '',
      description: '',
      price: 0,
      stock: 0,
      category: 'other',
      thumbnail: '',
    );
    return CartItem(
      id: json['id'] as int?,
      product: prod,
      quantity: (json['quantity'] is int)
          ? json['quantity'] as int
          : int.tryParse('${json['quantity']}') ?? 1,
    );
  }

  Map<String, dynamic> toJson({bool embedProduct = false}) => {
    'id': id,
    'product': embedProduct ? product.toJson() : product.id,
    'quantity': quantity,
  };
}
