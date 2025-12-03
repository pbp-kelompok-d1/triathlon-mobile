import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../widgets/left_drawer.dart';


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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                label: 'Name',
                hint: 'Enter product name',
                onChanged: (value) => _name = value,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Name cannot be empty!' : null,
              ),
              _buildTextField(
                label: 'Price',
                hint: 'Enter price in Rupiah',
                keyboardType: TextInputType.number,
                onChanged: (value) => _price = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Price cannot be empty!';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Price must be greater than 0!';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: 'Description',
                hint: 'Write what makes this product special',
                maxLines: 4,
                onChanged: (value) => _description = value,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Description cannot be empty!'
                    : null,
              ),
              _buildTextField(
                label: 'Thumbnail URL',
                hint: 'https://example.com/image.jpg',
                onChanged: (value) => _thumbnail = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  }
                  final pattern = RegExp(
                    r'^https?://.*\.(jpg|jpeg|png|gif|bmp|webp)$',
                    caseSensitive: false,
                  );
                  if (!pattern.hasMatch(value)) {
                    return 'Enter a valid image URL';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'running', child: Text('Running')),
                    DropdownMenuItem(value: 'cycling', child: Text('Cycling')),
                    DropdownMenuItem(value: 'swimming', child: Text('Swimming')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _category = value);
                  },
                ),
              ),
              _buildTextField(
                label: 'Stock',
                hint: 'Enter stock quantity',
                keyboardType: TextInputType.number,
                onChanged: (value) => _stock = int.tryParse(value) ?? 0,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stock cannot be empty!';
                  }
                  final parsed = int.tryParse(value);
                  if (parsed == null || parsed < 0) {
                    return 'Stock must be zero or more.';
                  }
                  return null;
                },
              ),
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      'Add Product',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => _submitForm(request),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Padding _buildTextField({
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    required void Function(String value) onChanged,
    required String? Function(String? value) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        onChanged: onChanged,
        validator: validator,
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
    } else {
      final errorMessage = response['message'] ?? 'Failed to save product';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
    }
  }
}

