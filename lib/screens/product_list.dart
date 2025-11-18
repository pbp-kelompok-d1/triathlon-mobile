import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/product_entry.dart';
import '../widgets/left_drawer.dart';
import 'product_detail.dart';

enum ProductListMode { all, mine }

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key, required this.mode});

  final ProductListMode mode;

  String get title => mode == ProductListMode.all ? 'All Products' : 'My Products';

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

  Future<List<ProductEntry>> _fetchProducts() async {
    final request = context.read<CookieRequest>();
    final endpoint = widget.mode == ProductListMode.all
        ? '$baseUrl/json/'
        : '$baseUrl/json/user/';

  final response = await request.get(endpoint);

    if (response is List) {
      return productEntryFromJson(jsonEncode(response));
    }

    return [];
  }

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

            final products = snapshot.data ?? [];

            if (products.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    widget.mode == ProductListMode.mine
                        ? "You haven't created any products yet."
                        : 'No products available.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              );
            }

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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12.0),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: _imageUrl != null
              ? Image.network(
                  _imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
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
