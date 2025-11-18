import 'package:flutter/material.dart';

import '../models/product_entry.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});

  final ProductEntry product;

  // Proxy http thumbnails through Django so every platform can load them safely.
  String? get _imageUrl {
    if (product.thumbnail.isEmpty) return null;
    if (product.thumbnail.startsWith('http')) {
      const proxyPath = '/proxy-image/?url=';
      if (product.thumbnail.contains('proxy-image')) {
        return product.thumbnail;
      }
      return 'http://10.0.2.2:8000$proxyPath${Uri.encodeComponent(product.thumbnail)}';
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
            Builder(
              builder: (context) {
                // Force the title to stay bold even when headlineSmall is null.
                TextStyle? nameStyle = Theme.of(context).textTheme.headlineSmall;
                if (nameStyle != null) {
                  nameStyle = nameStyle.copyWith(fontWeight: FontWeight.bold);
                }
                return Text(
                  product.name,
                  style: nameStyle,
                );
              },
            ),
            const SizedBox(height: 8.0),
            Builder(
              builder: (context) {
                // Tint the price with the primary red the app uses elsewhere.
                TextStyle? priceStyle = Theme.of(context).textTheme.titleLarge;
                if (priceStyle != null) {
                  priceStyle = priceStyle.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  );
                }
                return Text(
                  'Rp${product.price}',
                  style: priceStyle,
                );
              },
            ),
            const Divider(height: 32.0),
            Builder(
              builder: (_) {
                // Show a dash whenever the backend omits the category field.
                String categoryValue = product.category;
                if (categoryValue.isEmpty) {
                  categoryValue = '-';
                }
                return _DetailRow(label: 'Category', value: categoryValue);
              },
            ),
            _DetailRow(label: 'Stock', value: product.stock.toString()),
            Builder(
              builder: (_) {
                // Convert the boolean flag into "Yes"/"No" text.
                String featuredValue = 'No';
                if (product.isFeatured) {
                  featuredValue = 'Yes';
                }
                return _DetailRow(label: 'Featured', value: featuredValue);
              },
            ),
            Builder(
              builder: (_) {
                // Owner ID can be null, so display a dash when it is missing.
                final int? ownerId = product.userId;
                String ownerIdValue;
                if (ownerId == null) {
                  ownerIdValue = '-';
                } else {
                  ownerIdValue = ownerId.toString();
                }
                return _DetailRow(label: 'Owner ID', value: ownerIdValue);
              },
            ),
            const SizedBox(height: 16.0),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Builder(
              builder: (_) {
                // Swap in a default sentence when no description was provided.
                String descriptionText = product.description;
                if (descriptionText.isEmpty) {
                  descriptionText = 'No description available.';
                }
                return Text(descriptionText);
              },
            ),
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
