import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/product_entry.dart';
import '../widgets/left_drawer.dart';
import 'product_detail.dart';

// product list doubles as "all items" feed and "my submissions" view.
enum ProductListMode { all, mine }

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key, required this.mode});

  final ProductListMode mode;

  String get title {
    if (mode == ProductListMode.all) {
      return 'All Gear';
    }
    return 'My Gear';
  }

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late Future<List<ProductEntry>> _productsFuture;
  String? _selectedCategory;
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  // Pull the matching JSON endpoint depending on which tab is open.
  Future<List<ProductEntry>> _fetchProducts() async {
    final request = context.read<CookieRequest>();
    final baseEndpoint = widget.mode == ProductListMode.all
        ? '$baseUrl/shop/api/products/'
        : '$baseUrl/shop/api/products/mine/';

    final uri = Uri.parse(baseEndpoint).replace(
      queryParameters:
          _selectedCategory == null ? null : {'category': _selectedCategory!},
    );

    final response = await request.get(uri.toString());

    if (response is List) {
      return productEntryFromJson(jsonEncode(response));
    }

    return [];
  }

  // Helper function so both pull-to-refresh and the AppBar button reuse the same logic.
  Future<void> _refresh() async {
    setState(() {
      _productsFuture = _fetchProducts();
    });
    await _productsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const LeftDrawer(),
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
              child: FutureBuilder<List<ProductEntry>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(32.0),
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
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Failed to load products: ${snapshot.error}'),
                        ),
                      ],
                    );
                  }

                  final products = snapshot.data ?? <ProductEntry>[];

                  if (products.isEmpty) {
                    final emptyMessage = widget.mode == ProductListMode.mine
                        ? "You haven't listed any gear yet."
                        : 'No gear available yet.';

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            emptyMessage,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    );
                  }

                  // Render catalog with spacing between cards.
                  return ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductListTile(
                        product: product,
                        currencyFormatter: _currencyFormatter,
                      );
                    },
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

// Small reusable tile so both list variants share identical styling.
class _ProductListTile extends StatelessWidget {
  const _ProductListTile({required this.product, required this.currencyFormatter});

  final ProductEntry product;
  final NumberFormat currencyFormatter;

  String? get _imageUrl {
    if (product.thumbnail.isEmpty) return null;
    if (product.thumbnail.startsWith('http')) {
      return buildProxyImageUrl(product.thumbnail);
    }
    return product.thumbnail;
  }

  @override
  Widget build(BuildContext context) {
  // Build either the thumbnail image or the placeholder box before wiring it into ListTile.leading.
  Widget leadingWidget;
    if (_imageUrl != null) {
      leadingWidget = Image.network(
        _imageUrl!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
      );
    } else {
      leadingWidget = Container(
        width: 60,
        height: 60,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12.0),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: leadingWidget,
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(product.categoryLabel),
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: const TextStyle(fontSize: 12.0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (product.sellerUsername != null)
                    Chip(
                      label: Text('Seller: ${product.sellerUsername}'),
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: const TextStyle(fontSize: 12.0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(currencyFormatter.format(product.price)),
            const SizedBox(height: 4.0),
            Text('Stock: ${product.stock}')
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(product: product),
            ),
          );
        },
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
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selectedCategory == null,
            onSelected: (_) => onCategoryChanged(null),
          ),
          const SizedBox(width: 8),
          ..._categories.map(
            (category) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(category['label']!),
                selected: selectedCategory == category['key'],
                onSelected: (_) => onCategoryChanged(category['key']),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
