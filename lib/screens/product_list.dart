import 'dart:convert';

import 'package:flutter/material.dart';
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
      return 'All Products';
    }
    return 'My Products';
  }

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late Future<List<ProductEntry>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  // Pull the matching JSON endpoint depending on which tab is open.
  Future<List<ProductEntry>> _fetchProducts() async {
    final request = context.read<CookieRequest>();
    String endpoint;
    if (widget.mode == ProductListMode.all) {
      endpoint = '$baseUrl/json/';
    } else {
      endpoint = '$baseUrl/json/user/';
    }

  final response = await request.get(endpoint);

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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ProductEntry>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Failed to load products: ${snapshot.error}'),
                ),
              );
            }

            List<ProductEntry> products;
            if (snapshot.data == null) {
              products = <ProductEntry>[];
            } else {
              products = snapshot.data!;
            }

            if (products.isEmpty) {
              String emptyMessage;
              if (widget.mode == ProductListMode.mine) {
                emptyMessage = "You haven't created any products yet.";
              } else {
                emptyMessage = 'No products available.';
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              );
            }

            // Render catalog with spacing between cards.
            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12.0),
              itemBuilder: (context, index) {
                final product = products[index];
                return _ProductListTile(product: product);
              },
            );
          },
        ),
      ),
    );
  }
}

// Small reusable tile so both list variants share identical styling.
class _ProductListTile extends StatelessWidget {
  const _ProductListTile({required this.product});

  final ProductEntry product;

  String? get _imageUrl {
    if (product.thumbnail.isEmpty) return null;
    if (product.thumbnail.startsWith('http')) {
      return '$baseUrl/proxy-image/?url=${Uri.encodeComponent(product.thumbnail)}';
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
        subtitle: Text(
          product.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Rp${product.price}'),
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
