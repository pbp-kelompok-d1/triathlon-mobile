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
import '../../user_profile/models/user_profile_model.dart';
import '../services/wishlist_service.dart';

enum ProductListMode { all, mine }
enum SortOption { none, priceAsc, priceDesc }

final role = UserProfileData.role.toUpperCase();

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
  SortOption _sortOption = SortOption.none;
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
    var products = productFromJson(jsonEncode(listData));
    return _applySorting(products);
  }

  List<Product> _applySorting(List<Product> products) {
    switch (_sortOption) {
      case SortOption.priceAsc:
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceDesc:
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.none:
        break;
    }
    return products;
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.none:
        return 'Default';
      case SortOption.priceAsc:
        return 'Price: Low to High';
      case SortOption.priceDesc:
        return 'Price: High to Low';
    }
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

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _SortBottomSheet(
        selectedSort: _sortOption,
        onSortChanged: (sort) {
          setState(() {
            _sortOption = sort;
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showSortSheet(context),
                              icon: const Icon(Icons.sort, size: 18),
                              label: Text(
                                _getSortLabel(_sortOption),
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
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
                          gridDelegate:
                          SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            childAspectRatio: 0.52,
                            crossAxisSpacing: isDesktop ? 20 : 12,
                            mainAxisSpacing: isDesktop ? 20 : 12,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, i) => _ProductCard(
                            key: ValueKey(products[i].id),
                            product: products[i],
                            currencyFormatter: _currencyFormatter,
                            isMine: _isProductMine(products[i]),
                            onDeleted: _refresh,
                            index: i,
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

class _SortBottomSheet extends StatelessWidget {
  const _SortBottomSheet({
    required this.selectedSort,
    required this.onSortChanged,
  });

  final SortOption selectedSort;
  final ValueChanged<SortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sort By',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Default'),
            leading: Radio<SortOption>(
              value: SortOption.none,
              groupValue: selectedSort,
              onChanged: (_) => onSortChanged(SortOption.none),
            ),
            onTap: () => onSortChanged(SortOption.none),
          ),
          ListTile(
            title: const Text('Price: Low to High'),
            leading: Radio<SortOption>(
              value: SortOption.priceAsc,
              groupValue: selectedSort,
              onChanged: (_) => onSortChanged(SortOption.priceAsc),
            ),
            onTap: () => onSortChanged(SortOption.priceAsc),
          ),
          ListTile(
            title: const Text('Price: High to Low'),
            leading: Radio<SortOption>(
              value: SortOption.priceDesc,
              groupValue: selectedSort,
              onChanged: (_) => onSortChanged(SortOption.priceDesc),
            ),
            onTap: () => onSortChanged(SortOption.priceDesc),
          ),
        ],
      ),
    );
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    super.key,
    required this.product,
    required this.currencyFormatter,
    this.isMine = false,
    this.onDeleted,
    required this.index,
  });

  final Product product;
  final NumberFormat currencyFormatter;
  final bool isMine;
  final VoidCallback? onDeleted;
  final int index;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  bool _isInWishlist = false;
  bool _isTogglingWishlist = false;
  bool _isLoadingWishlistState = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _animationController.forward();
      }
    });

    _checkWishlistStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        if (mounted) {
          setState(() {
            _isInWishlist = !_isInWishlist;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ??
                  (_isInWishlist ? 'Added to wishlist' : 'Removed from wishlist')),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update wishlist'),
              backgroundColor: Colors.red,
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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
          ? (resp['message']?.toString() ?? 'Product deleted successfully')
          : 'Product deleted successfully';

      if (status == 'success') {
        widget.onDeleted?.call();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(message);
      }
    } catch (e) {
      if (context.mounted) {
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
              duration: const Duration(seconds: 2),
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
    final imageUrl = _imageUrl;

    final isAdmin = role == 'ADMIN';

    final currentUsername = request.jsonData['username'] as String?;
    final isOwnProduct = currentUsername != null &&
        widget.product.sellerUsername != null &&
        currentUsername == widget.product.sellerUsername;

    final canEditDelete = isAdmin || isOwnProduct;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(product: widget.product),
                  ),
                );

                if (result != null && mounted) {
                  final hasChanged = result['hasChanged'] as bool? ?? false;
                  final isInWishlist = result['isInWishlist'] as bool? ?? false;

                  if (hasChanged) {
                    setState(() {
                      _isInWishlist = isInWishlist;
                    });
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'product_image_${widget.product.id}',
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: imageUrl != null
                                ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.broken_image, size: 50, color: Colors.grey[400]),
                              ),
                            )
                                : Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
                            ),
                          ),
                        ),
                        if (canEditDelete)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, size: 16),
                                    padding: const EdgeInsets.all(6),
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _editProduct(context),
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, size: 16),
                                    padding: const EdgeInsets.all(6),
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _deleteProduct(context),
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
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
                              Icon(Icons.label_outline, size: 10, color: Colors.blue[700]),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  widget.product.category,
                                  style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.inventory_2_outlined, size: 10, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text('${widget.product.stock}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.currencyFormatter.format(widget.product.price),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                          ),
                          if (widget.product.sellerUsername != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 10, color: Colors.grey),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    widget.product.sellerUsername!,
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _addToCart(context),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 40),
                              ),
                              child: const Text('Add to Cart', style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: _isLoadingWishlistState
                                ? OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: BorderSide(color: Colors.pink[600]!),
                                foregroundColor: Colors.pink[600],
                                minimumSize: const Size(double.infinity, 40),
                              ),
                              child: const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                                : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                              child: _isInWishlist
                                  ? ElevatedButton.icon(
                                key: const ValueKey('in_wishlist'),
                                onPressed: _isTogglingWishlist ? null : _toggleWishlist,
                                icon: const Icon(Icons.favorite, size: 14),
                                label: const Text('In Wishlist', style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: Colors.pink[600],
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 40),
                                ),
                              )
                                  : OutlinedButton.icon(
                                key: const ValueKey('add_wishlist'),
                                onPressed: _isTogglingWishlist ? null : _toggleWishlist,
                                icon: const Icon(Icons.favorite_border, size: 14),
                                label: const Text('Wishlist', style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  side: BorderSide(color: Colors.pink[600]!),
                                  foregroundColor: Colors.pink[600],
                                  minimumSize: const Size(double.infinity, 40),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
  late TextEditingController _thumbnail;
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
    _price = TextEditingController(text: p.price.toInt().toString());
    _stock = TextEditingController(text: p.stock.toInt().toString());
    _thumbnail = TextEditingController(text: p.thumbnail);
    _category = p.category;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _thumbnail.dispose();
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
        'thumbnail': _thumbnail.text.trim(),
        'category': _category ?? '',
      });

      final status = resp is Map<String, dynamic>
          ? (resp['status']?.toString() ?? '')
          : '';
      final message = resp is Map<String, dynamic>
          ? (resp['message']?.toString() ?? 'Product updated successfully')
          : 'Product updated successfully';

      if (status == 'success') {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(message);
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid number' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stock,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid number' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _thumbnail,
                    decoration: const InputDecoration(
                      labelText: 'Thumbnail URL',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'Enter image URL',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          onPressed: _loading ? null : () => Navigator.pop(context, false),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
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

