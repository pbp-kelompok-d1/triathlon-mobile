import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../widgets/left_drawer.dart';
import 'shop_main.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _price = '';
  String _description = '';
  String _thumbnail = '';
  String _category = 'running';
  int _stock = 0;

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      drawer: const LeftDrawer(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                label: 'Product Name',
                hint: 'Enter product name',
                onChanged: (value) => _name = value,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: 'Description',
                hint: 'Describe your product...',
                maxLines: 5,
                onChanged: (value) => _description = value,
                validator: null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  hintText: 'Select a category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'running', child: Text('Running')),
                  DropdownMenuItem(value: 'cycling', child: Text('Cycling')),
                  DropdownMenuItem(value: 'swimming', child: Text('Swimming')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              _buildTextField(
                label: 'Price (Rp)',
                hint: '0',
                keyboardType: TextInputType.number,
                onChanged: (value) => _price = value,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price is required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Price must be a valid number';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: 'Stock Quantity',
                hint: 'Enter stock quantity',
                keyboardType: TextInputType.number,
                onChanged: (value) => _stock = int.tryParse(value) ?? 0,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Stock quantity is required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Stock must be a valid number';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: 'Thumbnail URL',
                hint: 'https://example.com/image.jpg',
                onChanged: (value) => _thumbnail = value,
                validator: null,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const ShopPage()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submitForm(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add Product',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    required void Function(String value) onChanged,
    String? Function(String? value)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            validator: validator,
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm(CookieRequest request) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final response = await request.postJson(
      '$baseUrl/shop/api/products/create/',
      jsonEncode({
        'name': _name,
        'price': double.tryParse(_price)?.round() ?? 0,
        'description': _description,
        'thumbnail': _thumbnail,
        'category': _category,
        'stock': _stock,
      }),
    );

    if (!mounted) return;

    if (response['status'] == 'success') {
      final createdName = _name;
      _formKey.currentState!.reset();
      setState(() {
        _name = '';
        _price = '';
        _description = '';
        _thumbnail = '';
        _category = 'running';
        _stock = 0;
      });

      final shouldNavigate = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Product Created'),
            content: Text(
              '"$createdName" has been saved successfully.\n\nDo you want to review your product list now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Go to Products'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (shouldNavigate == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ShopPage()),
        );
      }
    } else {
      final errorMessage = response['message'] ?? 'Failed to save product';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }
}
