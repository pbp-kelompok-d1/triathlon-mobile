import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/shop/models/product.dart';
import 'package:triathlon_mobile/shop/services/wishlist_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isInWishlist = false;
  bool _isLoadingWishlist = true;
  bool _isTogglingWishlist = false;
  bool _hasWishlistChanged = false;

  @override
  void initState() {
    super.initState();
    _loadWishlistState();
  }

  Future<void> _loadWishlistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localState = prefs.getBool('wishlist_${widget.product.id}');

      // Load local state immediately
      if (localState != null && mounted) {
        setState(() {
          _isInWishlist = localState;
          _isLoadingWishlist = false;
        });
      }

      // Then sync with server
      final request = context.read<CookieRequest>();
      final service = WishlistService(request);
      final serverState = await service.isInWishlist(widget.product.id);

      if (mounted) {
        setState(() {
          _isInWishlist = serverState;
          _isLoadingWishlist = false;
        });

        // Update local state with server state
        await prefs.setBool('wishlist_${widget.product.id}', serverState);
      }
    } catch (e) {
      // Fallback to local state if server check fails
      final prefs = await SharedPreferences.getInstance();
      final localState = prefs.getBool('wishlist_${widget.product.id}') ?? false;
      if (mounted) {
        setState(() {
          _isInWishlist = localState;
          _isLoadingWishlist = false;
        });
      }
    }
  }

  Future<void> _toggleWishlist() async {
    if (_isTogglingWishlist) return;

    setState(() => _isTogglingWishlist = true);

    try {
      final request = context.read<CookieRequest>();
      final service = WishlistService(request);
      final result = await service.toggleWishlist(widget.product.id);

      if (result['success'] == true) {
        final newState = result['inWishlist'] ?? false;

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('wishlist_${widget.product.id}', newState);

        setState(() {
          _isInWishlist = newState;
          _hasWishlistChanged = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Wishlist updated'),
              backgroundColor: _isInWishlist ? Colors.green : Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to update wishlist');
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
    } finally {
      if (mounted) setState(() => _isTogglingWishlist = false);
    }
  }

  Future<void> _addToCart() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(
        '$baseUrl/shop/api/cart/add/${widget.product.id}/',
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
    final t = widget.product.thumbnail.trim();
    if (t.isEmpty) return null;
    return _resolveImageUrl(t);
  }

  @override
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

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    final imageUrl = _imageUrl;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop({
              'hasChanged': _hasWishlistChanged,
              'isInWishlist': _isInWishlist,
            });
          },
        ),
        title: const Text(
          'Product Detail',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.normal,
            fontSize: 20,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Product Image
          SliverToBoxAdapter(
            child: Container(
              height: 300,
              color: Colors.grey[100],
              child: imageUrl != null
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                headers: kIsWeb ? null : cookieHeader,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.blue[50],
                  alignment: Alignment.center,
                  child: Icon(Icons.image,
                      size: 80, color: Colors.blue[200]),
                ),
              )
                  : Container(
                color: Colors.blue[50],
                alignment: Alignment.center,
                child: Icon(Icons.image,
                    size: 80, color: Colors.blue[200]),
              ),
            ),
          ),

          // Product Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.product.categoryLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Product Name
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Seller Info
                  if (widget.product.sellerUsername != null)
                    Row(
                      children: [
                        Icon(Icons.store, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          'Sold by ${widget.product.sellerUsername}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Price & Stock Card
                  Card(
                    elevation: 0,
                    color: Colors.blue[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Price',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormatter.format(widget.product.price),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Stock',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: widget.product.stock > 0
                                      ? Colors.green
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.product.stock > 0
                                      ? '${widget.product.stock} available'
                                      : 'Out of stock',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description Section
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: Colors.grey[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.product.description.isEmpty
                            ? 'No description available.'
                            : widget.product.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Wishlist Button
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isInWishlist ? Colors.pink[600]! : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoadingWishlist
                    ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : IconButton(
                  onPressed: _isTogglingWishlist ? null : _toggleWishlist,
                  icon: Icon(
                    _isInWishlist ? Icons.favorite : Icons.favorite_border,
                    color: _isInWishlist ? Colors.pink[600] : Colors.grey[600],
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),

              const SizedBox(width: 12),

              // Add to Cart Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: widget.product.stock > 0 ? _addToCart : null,
                    icon: const Icon(Icons.shopping_cart, size: 20),
                    label: Text(
                      widget.product.stock > 0 ? 'Add to Cart' : 'Out of Stock',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.product.stock > 0
                          ? Colors.green
                          : Colors.grey[400],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
