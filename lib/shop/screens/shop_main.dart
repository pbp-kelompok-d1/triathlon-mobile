// dart
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isMine = widget.mode == ProductListMode.mine;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'My Cart',
            onPressed: () {
              final request = context.read<CookieRequest>();
              if (!request.loggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login first')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'My Wishlist',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WishlistPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(isMine ? Icons.store : Icons.person),
            tooltip: isMine ? 'Show all gear' : 'Show my gear',
            onPressed: () {
              if (isMine) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ShopPage()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MyGearPage()),
                );
              }
            },
          ),
        ],
      ),
      drawer: const LeftDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormPage()),
          ).then((_) => _refresh());
        },
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _CategoryFilter(
            selectedCategory: _selectedCategory,
            onCategoryChanged: (value) {
              setState(() {
                _selectedCategory = value;
                _productsFuture = _fetchProducts();
              });
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Failed to load products:\n${snapshot.error}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  }

                  final products = snapshot.data ?? const <Product>[];
                  if (products.isEmpty) {
                    final msg = isMine
                        ? 'You have not listed any gear yet.'
                        : 'No gear available.';
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            msg,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _ProductListTile(
                      product: products[i],
                      currencyFormatter: _currencyFormatter,
                      isMine: isMine,
                      onDeleted: _refresh,
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

class _ProductListTile extends StatefulWidget {
  const _ProductListTile({
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
  State<_ProductListTile> createState() => _ProductListTileState();
}

class _ProductListTileState extends State<_ProductListTile> {
  bool _isInWishlist = false;
  bool _isTogglingWishlist = false;

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

    final leadingWidget = imageUrl != null
        ? ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        headers: kIsWeb ? null : cookieHeader,
        errorBuilder: (_, __, ___) => Container(
          width: 60,
          height: 60,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported),
        ),
      ),
    )
        : Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, color: Colors.grey),
    );

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(product: widget.product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leadingWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.currencyFormatter.format(widget.product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text(widget.product.categoryLabel),
                          backgroundColor: Colors.blue.shade50,
                          labelStyle: const TextStyle(fontSize: 12),
                          materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                        ),
                        if (widget.product.sellerUsername != null)
                          Chip(
                            label:
                            Text('Seller: ${widget.product.sellerUsername}'),
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: const TextStyle(fontSize: 12),
                            materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Stock: ${widget.product.stock}'),
                        const Spacer(),
                        if (!widget.isMine) ...[
                          IconButton(
                            onPressed:
                            _isTogglingWishlist ? null : _toggleWishlist,
                            icon: _isTogglingWishlist
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                                : Icon(
                              _isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                              _isInWishlist ? Colors.red : Colors.grey,
                            ),
                            tooltip: 'Wishlist',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                                width: 36, height: 36),
                          ),
                          IconButton(
                            onPressed: () => _addToCart(context),
                            icon: const Icon(Icons.shopping_cart_outlined),
                            tooltip: 'Add to Cart',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                          ),
                        ],
                        if (widget.isMine) ...[
                          IconButton(
                            onPressed: () => _editProduct(context),
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Edit',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                                width: 36, height: 36),
                          ),
                          IconButton(
                            onPressed: () => _deleteProduct(context),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                                width: 36, height: 36),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selectedCategory == null,
            onSelected: (_) => onCategoryChanged(null),
          ),
          const SizedBox(width: 8),
          ..._categories.map(
                (c) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(c['label']!),
                selected: selectedCategory == c['key'],
                onSelected: (_) => onCategoryChanged(c['key']),
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
                    (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _stock,
                    decoration: const InputDecoration(labelText: 'Stock'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories
                        .map((c) => DropdownMenuItem<String>(
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
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
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