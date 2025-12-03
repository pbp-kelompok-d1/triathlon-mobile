import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/shop/models/product.dart';
import 'package:triathlon_mobile/shop/screens/wishlist_list.dart';
import 'package:triathlon_mobile/widgets/left_drawer.dart';
import 'package:triathlon_mobile/shop/screens/product_detail.dart';
import 'package:triathlon_mobile/shop/screens/product_form.dart';
import 'package:triathlon_mobile/shop/screens/cart_list.dart';
import 'package:triathlon_mobile/shop/screens/admin_product_management.dart';
import '../services/wishlist_service.dart';

enum ProductListMode { all, mine }

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const ProductListPage(mode: ProductListMode.all);
}

class MyGearPage extends StatelessWidget {
  const MyGearPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const ProductListPage(mode: ProductListMode.mine);
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key, required this.mode});
  final ProductListMode mode;

  String get title => mode == ProductListMode.all ? 'Shop' : 'My Product';

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Product>> _productsFuture;
  String? _selectedCategory;
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Uri _buildEndpoint() {
    final baseEndpoint = widget.mode == ProductListMode.all
        ? '$baseUrl/shop/api/products/'
        : '$baseUrl/shop/api/products/mine/';
    return Uri.parse(baseEndpoint).replace(
      queryParameters:
      _selectedCategory == null ? null : {'category': _selectedCategory!},
    );
  }

  Future<List<Product>> _fetchProducts() async {
    final request = context.read<CookieRequest>();
    final uri = _buildEndpoint();
    final response = await request.get(uri.toString());

    List<dynamic> listData = const [];

    if (response is List) {
      listData = response;
    } else if (response is Map<String, dynamic>) {
      final possible = response['data'] ?? response['results'];
      if (possible is List) listData = possible;
    }

    if (listData.isEmpty) return const [];
    return productFromJson(jsonEncode(listData));
  }

  Future<void> _refresh() async {
    setState(() {
      _productsFuture = _fetchProducts();
    });
    await _productsFuture;
  }

  bool _isProductMine(Product product) {
    if (widget.mode == ProductListMode.mine) return true;
    final request = context.read<CookieRequest>();
    final currentUsername = request.jsonData['username'] as String?;
    return currentUsername != null &&
        product.sellerUsername != null &&
        currentUsername == product.sellerUsername;
  }

  void _showCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _CategoryBottomSheet(
        selectedCategory: _selectedCategory,
        onCategoryChanged: (cat) {
          setState(() {
            _selectedCategory = cat;
            _productsFuture = _fetchProducts();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                  fontSize: 23,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: isDesktop
            ? [
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const WishlistPage()),
              );
              if (result == true) {
                _refresh();
              }
            },
            icon: const Icon(Icons.favorite, size: 16),
            label: const Text('Wishlist', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[600],
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
            icon: const Icon(Icons.shopping_cart, size: 16),
            label: const Text('Cart', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormPage()),
              );
              if (result == true) _refresh();
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Product', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 16),
        ]
            : [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const WishlistPage()),
              );
              if (result == true) {
                _refresh();
              }
            },
            icon: const Icon(Icons.favorite),
            color: Colors.pink[600],
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
            icon: const Icon(Icons.shopping_cart),
            color: Colors.green,
          ),
          IconButton(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormPage()),
              );
              if (result == true) _refresh();
            },
            icon: const Icon(Icons.add),
            color: Colors.white,
          ),
        ],
      ),
      drawer: const LeftDrawer(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Container(
              width: 200,
              color: Colors.white,
              child: _CategorySidebar(
                selectedCategory: _selectedCategory,
                onCategoryChanged: (cat) {
                  setState(() {
                    _selectedCategory = cat;
                    _productsFuture = _fetchProducts();
                  });
                },
              ),
            ),
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
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
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.blue.shade900.withOpacity(0.6),
                            Colors.indigo.shade800.withOpacity(0.5),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.1,
                              child: Image.asset(
                                'assets/images/hero-cycling.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(),
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'TRIATHLON SHOP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Discover and shop triathlon gears with a clean experience.',
                                  style: TextStyle(
                                    color: Colors.blue.shade100,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isDesktop)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showCategorySheet(context),
                              icon: const Icon(Icons.filter_list, size: 18),
                              label: Text(
                                _selectedCategory == null
                                    ? 'All Categories'
                                    : _getCategoryLabel(_selectedCategory!),
                                style: const TextStyle(fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverFillRemaining(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: FutureBuilder<List<Product>>(
                      future: _productsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 64, color: Colors.red[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _refresh,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final products = snapshot.data ?? const <Product>[];
                        if (products.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 80, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No products found',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: EdgeInsets.all(isDesktop ? 20 : 12),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            childAspectRatio: 0.55,
                            crossAxisSpacing: isDesktop ? 20 : 12,
                            mainAxisSpacing: isDesktop ? 20 : 12,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, i) => InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailPage(product: products[i]),
                                ),
                              );
                            },
                            child: _ProductCard(
                              product: products[i],
                              currencyFormatter: _currencyFormatter,
                              isMine: _isProductMine(products[i]),
                              onDeleted: _refresh,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(String key) {
    const categories = {
      'running': 'Running',
      'cycling': 'Cycling',
      'swimming': 'Swimming',
    };
    return categories[key] ?? key;
  }
}

class _CategoryBottomSheet extends StatelessWidget {
  const _CategoryBottomSheet({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  static const List<Map<String, String>> _categories = [
    {'key': 'running', 'label': 'Running'},
    {'key': 'cycling', 'label': 'Cycling'},
    {'key': 'swimming', 'label': 'Swimming'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('All'),
            leading: Radio<String?>(
              value: null,
              groupValue: selectedCategory,
              onChanged: (_) => onCategoryChanged(null),
            ),
            onTap: () => onCategoryChanged(null),
          ),
          ..._categories.map(
                (cat) => ListTile(
              title: Text(cat['label']!),
              leading: Radio<String?>(
                value: cat['key'],
                groupValue: selectedCategory,
                onChanged: (_) => onCategoryChanged(cat['key']),
              ),
              onTap: () => onCategoryChanged(cat['key']),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySidebar extends StatelessWidget {
  const _CategorySidebar({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  static const List<Map<String, String>> _categories = [
    {'key': 'running', 'label': 'Running'},
    {'key': 'cycling', 'label': 'Cycling'},
    {'key': 'swimming', 'label': 'Swimming'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _CategoryButton(
            label: 'All',
            isSelected: selectedCategory == null,
            onTap: () => onCategoryChanged(null),
          ),
          ..._categories.map(
                (cat) => _CategoryButton(
              label: cat['label']!,
              isSelected: selectedCategory == cat['key'],
              onTap: () => onCategoryChanged(cat['key']),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? Colors.grey[900] : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.currencyFormatter,
    this.isMine = false,
    this.onDeleted,
  });

  final Product product;
  final NumberFormat currencyFormatter;
  final bool isMine;
  final VoidCallback? onDeleted;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isInWishlist = false;
  bool _isTogglingWishlist = false;
  bool _isLoadingWishlistState = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isMine) {
      _checkWishlistStatus();
    } else {
      _isLoadingWishlistState = false;
    }
  }

  Future<void> _checkWishlistStatus() async {
    try {
      final request = context.read<CookieRequest>();
      final service = WishlistService(request);
      final inWishlist = await service.isInWishlist(widget.product.id);
      if (mounted) {
        setState(() {
          _isInWishlist = inWishlist;
          _isLoadingWishlistState = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWishlistState = false);
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

  Future<void> _toggleWishlist() async {
    if (_isTogglingWishlist) return;

    setState(() => _isTogglingWishlist = true);

    try {
      final request = context.read<CookieRequest>();
      final service = WishlistService(request);
      final result = await service.toggleWishlist(widget.product.id);

      if (result['success'] == true) {
        setState(() => _isInWishlist = result['inWishlist'] ?? false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Wishlist updated'),
              backgroundColor: Colors.green,
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

  Future<void> _deleteProduct(BuildContext context) async {
    final request = context.read<CookieRequest>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Delete "${widget.product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final url = '$baseUrl/shop/api/products/${widget.product.id}/delete/';

    try {
      final resp = await request.post(url, {});
      final status = resp is Map<String, dynamic>
          ? (resp['status']?.toString() ?? '')
          : '';
      final message = resp is Map<String, dynamic>
          ? (resp['message']?.toString() ?? 'Deleted')
          : 'Deleted';

      if (status == 'success') {
        widget.onDeleted?.call();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      } else {
        throw Exception(message);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _editProduct(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditProductDialog(product: widget.product),
    );
    if (result == true) {
      widget.onDeleted?.call();
    }
  }

  String? get _imageUrl {
    final t = widget.product.thumbnail.trim();
    if (t.isEmpty) return null;
    return _resolveImageUrl(t);
  }

  Future<void> _addToCart(BuildContext context) async {
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

    // Cek apakah user adalah admin
    final isAdmin = request.jsonData['is_admin'] == true ||
        request.jsonData['is_staff'] == true ||
        request.jsonData['is_superuser'] == true;

    // Cek apakah ini produk user sendiri
    final currentUsername = request.jsonData['username'] as String?;
    final isOwnProduct = currentUsername != null &&
        widget.product.sellerUsername != null &&
        currentUsername == widget.product.sellerUsername;

    final canEditDelete = isAdmin || isOwnProduct;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              InkWell(
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailPage(product: widget.product),
                    ),
                  );

                  // Refresh wishlist status jika ada perubahan
                  if (result == true && mounted && !widget.isMine) {
                    _checkWishlistStatus();
                  }
                },
                child: ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl != null
                      ? Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    headers: kIsWeb ? null : cookieHeader,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 180,
                      color: Colors.blue[50],
                      alignment: Alignment.center,
                      child: Icon(Icons.image,
                          size: 64, color: Colors.blue[200]),
                    ),
                  )
                      : Container(
                    width: double.infinity,
                    height: 180,
                    color: Colors.blue[50],
                    alignment: Alignment.center,
                    child: Icon(Icons.image,
                        size: 64, color: Colors.blue[200]),
                  ),
                ),
              ),
              if (canEditDelete)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 18,
                        child: IconButton(
                          onPressed: () => _editProduct(context),
                          icon: const Icon(Icons.edit,
                              color: Colors.blue, size: 18),
                          padding: EdgeInsets.zero,
                          tooltip: 'Edit Product',
                        ),
                      ),
                      const SizedBox(width: 4),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 18,
                        child: IconButton(
                          onPressed: () => _deleteProduct(context),
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 18),
                          padding: EdgeInsets.zero,
                          tooltip: 'Delete Product',
                        ),
                      ),
                    ],
                  ),
                ),
              // Admin button overlay - hanya muncul jika user admin dan bukan produk sendiri
              // Edit/Delete buttons untuk produk sendiri
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.label_outline,
                          size: 10, color: Colors.blue[700]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          widget.product.categoryLabel,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.blue[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.inventory_2_outlined,
                          size: 10, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.product.stock}',
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.currencyFormatter.format(widget.product.price),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  if (widget.product.sellerUsername != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 10, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            widget.product.sellerUsername!,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  if (!widget.isMine) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 26,
                      child: ElevatedButton(
                        onPressed: () => _addToCart(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 26,
                      child: _isLoadingWishlistState
                          ? OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                          : _isInWishlist
                          ? ElevatedButton.icon(
                        onPressed: _isTogglingWishlist
                            ? null
                            : _toggleWishlist,
                        icon: const Icon(Icons.favorite, size: 12),
                        label: const Text(
                          'In Wishlist',
                          style: TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                          : OutlinedButton.icon(
                        onPressed: _isTogglingWishlist
                            ? null
                            : _toggleWishlist,
                        icon: const Icon(Icons.favorite_border,
                            size: 12),
                        label: const Text(
                          'Wishlist',
                          style: TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.pink[600],
                          side: BorderSide(color: Colors.pink[600]!),
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      )
    );
  }
}

class _EditProductDialog extends StatefulWidget {
  const _EditProductDialog({required this.product});
  final Product product;

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _description;
  late TextEditingController _price;
  late TextEditingController _stock;
  String? _category;
  bool _loading = false;

  static const List<Map<String, String>> _categories = [
    {'key': 'running', 'label': 'Running'},
    {'key': 'cycling', 'label': 'Cycling'},
    {'key': 'swimming', 'label': 'Swimming'},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p.name);
    _description = TextEditingController(text: p.description);
    _price = TextEditingController(text: p.price.toString());
    _stock = TextEditingController(text: p.stock.toString());
    _category = p.category;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final request = context.read<CookieRequest>();
    final url = '$baseUrl/shop/api/products/${widget.product.id}/edit/';

    try {
      final resp = await request.post(url, {
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'price': _price.text.trim(),
        'stock': _stock.text.trim(),
        'category': _category ?? '',
      });

      final status =
      resp is Map<String, dynamic> ? (resp['status']?.toString() ?? '') : '';
      final message = resp is Map<String, dynamic>
          ? (resp['message']?.toString() ?? 'Updated')
          : 'Updated';

      if (status == 'success') {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      } else {
        throw Exception(message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Edit Product',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || int.tryParse(v) == null
                        ? 'Invalid number'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stock,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || int.tryParse(v) == null
                        ? 'Invalid number'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                      value: c['key'],
                      child: Text(c['label']!),
                    ))
                        .toList(),
                    onChanged: (val) => setState(() => _category = val),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                          _loading ? null : () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                            CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}