import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/shop/models/product.dart';
import 'package:triathlon_mobile/shop/services/wishlist_service.dart';
import 'package:triathlon_mobile/shop/screens/product_detail.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  late Future<List<Product>> _wishlistFuture;
  bool _hasChanges = false;
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _wishlistFuture = _fetchWishlist();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Product>> _fetchWishlist() async {
    final request = context.read<CookieRequest>();
    final service = WishlistService(request);
    return await service.getWishlist();
  }

  Future<void> _refresh() async {
    setState(() {
      _wishlistFuture = _fetchWishlist();
    });
    await _wishlistFuture;
  }

  Future<void> _removeFromWishlist(Product product) async {
    final request = context.read<CookieRequest>();
    final service = WishlistService(request);

    try {
      final result = await service.toggleWishlist(product.id);
      if (result['success'] == true) {
        _hasChanges = true;
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Removed from wishlist'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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

  Future<void> _addToCart(BuildContext context, Product product) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(
        '$baseUrl/shop/api/cart/add/${product.id}/',
        {},
      );

      if (response['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Added to cart'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to add to cart');
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Pop dengan result _hasChanges
          Navigator.of(context).pop(_hasChanges);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1D4ED8),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'My Wishlist',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 23,
            ),
          ),
        ),
        body: CustomScrollView(
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
                          Icons.favorite,
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
                                  Icons.favorite,
                                  color: Colors.pink,
                                  size: 32,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Your Favorites',
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
                              'Save products you love for later',
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

            // Content
            SliverPadding(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              sliver: FutureBuilder<List<Product>>(
                future: _wishlistFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red[300]),
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
                      ),
                    );
                  }

                  final products = snapshot.data ?? const <Product>[];
                  if (products.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Your wishlist is empty',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start adding products you love!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return isDesktop
                      ? SliverGrid(
                    gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisExtent: 160,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, i) => _WishlistProductCard(
                        product: products[i],
                        currencyFormatter: _currencyFormatter,
                        onRemove: () => _removeFromWishlist(products[i]),
                        onAddToCart: () => _addToCart(context, products[i]),
                      ),
                      childCount: products.length,
                    ),
                  )
                      : SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _WishlistProductCard(
                          product: products[i],
                          currencyFormatter: _currencyFormatter,
                          onRemove: () =>
                              _removeFromWishlist(products[i]),
                          onAddToCart: () =>
                              _addToCart(context, products[i]),
                        ),
                      ),
                      childCount: products.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistProductCard extends StatelessWidget {
  const _WishlistProductCard({
    required this.product,
    required this.currencyFormatter,
    required this.onRemove,
    required this.onAddToCart,
  });

  final Product product;
  final NumberFormat currencyFormatter;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

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
    final t = product.thumbnail.trim();
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(product: product),
            ),
          );
        },
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius:
              const BorderRadius.horizontal(left: Radius.circular(12)),
              child: imageUrl != null
                  ? Image.network(
                imageUrl,
                width: 120,
                height: 160,
                fit: BoxFit.cover,
                headers: kIsWeb ? null : cookieHeader,
                errorBuilder: (_, __, ___) => Container(
                  width: 120,
                  height: 160,
                  alignment: Alignment.center,
                  color: Colors.blue[50],
                  child: Icon(Icons.image,
                      size: 48, color: Colors.blue[200]),
                ),
              )
                  : Container(
                width: 120,
                height: 160,
                alignment: Alignment.center,
                color: Colors.blue[50],
                child:
                Icon(Icons.image, size: 48, color: Colors.blue[200]),
              ),
            ),

            // Product Info
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Nama Penjual
                        if (product.sellerUsername != null)
                          Row(
                            children: [
                              Icon(Icons.store, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  product.sellerUsername!,
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
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.categoryLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormatter.format(product.price),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: ElevatedButton.icon(
                              onPressed: onAddToCart,
                              icon: const Icon(Icons.shopping_cart, size: 16),
                              label: const Text(
                                'Add to Cart',
                                style: TextStyle(fontSize: 11),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 32,
                          width: 32,
                          child: IconButton(
                            onPressed: onRemove,
                            icon: const Icon(Icons.delete, size: 18),
                            color: Colors.red,
                            padding: EdgeInsets.zero,
                            tooltip: 'Remove',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}