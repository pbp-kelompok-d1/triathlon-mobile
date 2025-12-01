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

  String get title => mode == ProductListMode.all ? 'All Gear' : 'My Gear';

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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
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
    // Di halaman My Gear, semua produk adalah milik user
    if (widget.mode == ProductListMode.mine) return true;

    // Di halaman All Gear, cek apakah sellerUsername sama dengan username login
    final request = context.read<CookieRequest>();
    final currentUsername = request.jsonData['username'] as String?;

    return currentUsername != null &&
        product.sellerUsername != null &&
        currentUsername == product.sellerUsername;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.store, color: Colors.grey[800]),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WishlistPage()),
              );
            },
            icon: const Icon(Icons.favorite, size: 18),
            label: const Text('Wishlist'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[600],
              foregroundColor: Colors.white,
              elevation: 0,
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
            icon: const Icon(Icons.shopping_cart, size: 18),
            label: const Text('Cart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
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
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: const LeftDrawer(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refresh,
                            child: const Text('Retry'),
                          ),
                        ],
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
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 350,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, i) => InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailPage(product: products[i]),
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
          SnackBar(content: Text('Error: $e')),
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
            SnackBar(content: Text(response['message'] ?? 'Added to cart')),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to add to cart');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl != null
                    ? Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  headers: kIsWeb ? null : cookieHeader,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.blue[50],
                    alignment: Alignment.center,
                    child: Icon(Icons.image, size: 64, color: Colors.blue[200]),
                  ),
                )
                    : Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.blue[50],
                  alignment: Alignment.center,
                  child: Icon(Icons.image, size: 64, color: Colors.blue[200]),
                ),
              ),
              if (widget.isMine)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 18,
                        child: IconButton(
                          onPressed: () => _editProduct(context),
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 4),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 18,
                        child: IconButton(
                          onPressed: () => _deleteProduct(context),
                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.label_outline, size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.product.categoryLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${widget.product.stock}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    widget.currencyFormatter.format(widget.product.price),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.product.sellerUsername != null)
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Seller: ${widget.product.sellerUsername}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  if (!widget.isMine) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _addToCart(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Add to Cart', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: _isLoadingWishlistState
                          ? OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                          : _isInWishlist
                          ? ElevatedButton.icon(
                        onPressed: _isTogglingWishlist ? null : _toggleWishlist,
                        icon: const Icon(Icons.favorite, size: 16),
                        label: const Text('In Wishlist', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                          : OutlinedButton.icon(
                        onPressed: _isTogglingWishlist ? null : _toggleWishlist,
                        icon: const Icon(Icons.favorite_border, size: 16),
                        label: const Text('Add to Wishlist', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.pink[600],
                          side: BorderSide(color: Colors.pink[600]!),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                    v == null || int.tryParse(v) == null ? 'Invalid number' : null,
                  ),
                  TextFormField(
                    controller: _stock,
                    decoration: const InputDecoration(labelText: 'Stock'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                    v == null || int.tryParse(v) == null ? 'Invalid number' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
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
                          onPressed: _loading
                              ? null
                              : () => Navigator.pop(context, false),
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
