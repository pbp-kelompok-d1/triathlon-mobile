import 'package:flutter/material.dart';

import '../models/product_entry.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});

  final ProductEntry product;

  String? get _imageUrl {
    if (product.thumbnail.isEmpty) return null;
    if (product.thumbnail.startsWith('http')) {
      const proxyPath = '/proxy-image/?url=';
      return product.thumbnail.contains('proxy-image')
          ? product.thumbnail
          : 'http://10.0.2.2:8000$proxyPath${Uri.encodeComponent(product.thumbnail)}';
    }
    return product.thumbnail;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Center(child: Icon(Icons.image, size: 48)),
              ),
            const SizedBox(height: 16.0),
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Rp${product.price}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 32.0),
            _DetailRow(label: 'Category', value: product.category.isEmpty ? '-' : product.category),
            _DetailRow(label: 'Stock', value: product.stock.toString()),
            _DetailRow(label: 'Featured', value: product.isFeatured ? 'Yes' : 'No'),
            _DetailRow(label: 'Owner ID', value: product.userId?.toString() ?? '-'),
            const SizedBox(height: 16.0),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Text(product.description.isEmpty ? 'No description available.' : product.description),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
