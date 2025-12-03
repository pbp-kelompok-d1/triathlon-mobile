import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/shop/models/cart.dart';
import '../models/cart_item.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<CartResponse> _cartFuture;
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cartFuture = _fetchCart();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<CartResponse> _fetchCart() async {
    final request = context.read<CookieRequest>();
    final response = await request.get('$baseUrl/shop/api/cart/');
    return CartResponse.fromJson(response);
  }

  Future<void> _refresh() async {
    setState(() {
      _cartFuture = _fetchCart();
    });
    await _cartFuture;
  }

  Future<void> _removeItem(String productId) async {
    final request = context.read<CookieRequest>();
    try {
      final response =
      await request.post('$baseUrl/shop/api/cart/remove/$productId/', {});

      if (response['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Item removed'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _refresh();
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to remove item');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateQuantity(int itemId, int newQuantity) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(
        '$baseUrl/shop/api/cart/update/$itemId/',
        {'quantity': newQuantity.toString()},
      );

      if (response['status'] == 'success') {
        _refresh();
      } else {
        throw Exception(response['message'] ?? 'Failed to update quantity');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _checkout() async {
    final request = context.read<CookieRequest>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Checkout'),
        content: const Text('Proceed with checkout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Checkout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await request.post('$baseUrl/shop/api/checkout/', {});

      if (response['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Checkout successful'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _refresh();
        }
      } else {
        throw Exception(response['message'] ?? 'Checkout failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.normal,
            fontSize: 23,
          ),
        ),
      ),
      body: FutureBuilder<CartResponse>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final cart = snapshot.data!;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero Section dengan fancy scrolling
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, child) {
                    final offset = _scrollController.hasClients
                        ? _scrollController.offset
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(0, offset * 0.5),
                      child: Opacity(
                        opacity: (1 - (offset / 200)).clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1D4ED8),
                          Colors.blue[600]!,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -50,
                          bottom: -30,
                          child: Icon(
                            Icons.shopping_cart,
                            size: 200,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.shopping_cart,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Shopping Cart',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cart.items.isEmpty
                                    ? 'Your cart is empty'
                                    : '${cart.items.length} item(s) in your cart',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Empty State
              if (cart.items.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add products to get started!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Cart Items
              if (cart.items.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CartItemCard(
                          item: cart.items[i],
                          currencyFormatter: _currencyFormatter,
                          onRemove: () => _removeItem(cart.items[i].productId),
                          onUpdateQuantity: (qty) =>
                              _updateQuantity(cart.items[i].itemId, qty),
                        ),
                      ),
                      childCount: cart.items.length,
                    ),
                  ),
                ),

              // Bottom Padding untuk Checkout Button
              if (cart.items.isNotEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
            ],
          );
        },
      ),
      // Checkout Bottom Sheet
      bottomSheet: FutureBuilder<CartResponse>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done ||
              snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.items.isEmpty) {
            return const SizedBox.shrink();
          }

          final cart = snapshot.data!;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currencyFormatter.format(cart.total),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _checkout,
                      icon: const Icon(Icons.payment),
                      label: const Text(
                        'Checkout',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.currencyFormatter,
    required this.onRemove,
    required this.onUpdateQuantity,
  });

  final CartItem item;
  final NumberFormat currencyFormatter;
  final VoidCallback onRemove;
  final ValueChanged<int> onUpdateQuantity;

  String _normalizeHost(String host) {
    if (host == 'localhost' || host == '127.0.0.1') return '10.0.2.2';
    return host;
  }

  Uri _absoluteFrom(String raw) {
    final trimmed = raw.trim();
    final normalizedBase = Uri.parse(baseUrl);
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final u = Uri.parse(trimmed);
      return u.replace(host: _normalizeHost(u.host));
    }
    final baseHasSlash = baseUrl.endsWith('/');
    final pathHasSlash = trimmed.startsWith('/');
    final path = baseHasSlash || pathHasSlash
        ? '${normalizedBase.path}$trimmed'
        : '${normalizedBase.path}/$trimmed';
    return normalizedBase.replace(path: path);
  }

  String _resolveImageUrl(String raw) {
    final abs = _absoluteFrom(raw);
    final baseUri = Uri.parse(baseUrl);
    final crossOrigin = kIsWeb &&
        abs.hasScheme &&
        (abs.scheme == 'http' || abs.scheme == 'https') &&
        abs.host != baseUri.host;
    if (crossOrigin) {
      return buildProxyImageUrl(abs.toString());
    }
    return abs.toString();
  }

  String? get _imageUrl {
    final t = item.thumbnail.trim();
    if (t.isEmpty) return null;
    return _resolveImageUrl(t);
  }

  @override
  Widget build(BuildContext context) {
    final request = context.read<CookieRequest>();
    final cookieHeader = request.cookies.isNotEmpty
        ? {
      'Cookie': request.cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ')
    }
        : null;

    final imageUrl = _imageUrl;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                headers: kIsWeb ? null : cookieHeader,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  color: Colors.grey[200],
                  child: Icon(Icons.image, size: 32, color: Colors.grey[400]),
                ),
              )
                  : Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                color: Colors.grey[200],
                child: Icon(Icons.image, size: 32, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item.sellerUsername != null)
                    Row(
                      children: [
                        Icon(Icons.store, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.sellerUsername!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(item.price),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Quantity Controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: item.quantity > 1
                                  ? () => onUpdateQuantity(item.quantity - 1)
                                  : null,
                              icon: const Icon(Icons.remove, size: 18),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: item.quantity < item.stock
                                  ? () => onUpdateQuantity(item.quantity + 1)
                                  : null,
                              icon: const Icon(Icons.add, size: 18),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Subtotal
                      Text(
                        currencyFormatter.format(item.subtotal),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete Button
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Remove',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
