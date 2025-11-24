import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/shop/models/product.dart';
import 'package:triathlon_mobile/widgets/left_drawer.dart';
import 'package:triathlon_mobile/shop/screens/product_detail.dart';

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

  String get title =>
      mode == ProductListMode.all ? 'All Gear' : 'My Gear';

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
    if (response is List) {
      return productFromJson(jsonEncode(response));
    }
    return const [];
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
                    final msg = widget.mode == ProductListMode.mine
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

class _ProductListTile extends StatelessWidget {
  const _ProductListTile({
    required this.product,
    required this.currencyFormatter,
  });

  final Product product;
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
    final leadingWidget = _imageUrl != null
        ? Image.network(
      _imageUrl!,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
      const Icon(Icons.image_not_supported),
    )
        : Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image, color: Colors.grey),
    );

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: leadingWidget,
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(product.categoryLabel),
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: const TextStyle(fontSize: 12),
                    materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (product.sellerUsername != null)
                    Chip(
                      label: Text('Seller: ${product.sellerUsername}'),
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: const TextStyle(fontSize: 12),
                      materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
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
              const SizedBox(height: 4),
              Text('Stock: ${product.stock}'),
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
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
