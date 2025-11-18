import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../widgets/left_drawer.dart';
import 'product_list.dart';

class ProductFormPage extends StatefulWidget {
    const ProductFormPage({super.key});

    @override
    State<ProductFormPage> createState() => _ProductFormPageState();
}

  class _ProductFormPageState extends State<ProductFormPage> {
    final _formKey = GlobalKey<FormState>();
    String _name = "";
    String _price = "";
    String _description = "";
    String _thumbnail = "";
    String _category = "";
    bool _isFeatured = false;
    int _stock = 0;

    @override
    Widget build(BuildContext context) {
        final request = context.watch<CookieRequest>();

        return Scaffold(
          appBar: AppBar(
            title: const Center(
              child: Text(
                'Add Product Form',
              ),
            ),
            backgroundColor: const Color(0xFFCE1126),
            foregroundColor: Colors.white,
          ),
          drawer: const LeftDrawer(),
          body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        // Name field
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                              hintText: "Enter product name",
                              labelText: "Name",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                            onChanged: (String? value) {
                              setState(() {
                                _name = value!;
                              });
                            },
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return "Product name cannot be empty!";
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        // Price field
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                              hintText: "Enter product price",
                              labelText: "Price",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                            onChanged: (String? value) {
                              setState(() {
                                _price = value!;
                              });
                            },
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return "Price cannot be empty!";
                              }
                              final price = double.tryParse(value);
                              if (price == null) {
                                return "Price must be a valid number!";
                              }
                              if (price < 0) {
                                return "Price cannot be negative!";
                              }
                              if (price == 0) {
                                return "Price must be greater than 0!";
                              }
                              return null;
                            },
                          ),
                        ),
                          
                        // Description field
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: "Enter product description",
                              labelText: "Description",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                          onChanged: (String? value) {
                            setState(() {
                              _description = value!;
                            });
                          },
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return "Description cannot be empty!";
                            }
                            return null;
                          },
                        ),
                      ),

                      // Thumbnail field
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: "https://example.com/image.jpg",
                            labelText: "Thumbnail",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          onChanged: (String? value) {
                            setState(() {
                              _thumbnail = value!;
                            });
                          },
                          validator: (String? value) {
                            if (value != null && value.isNotEmpty) {
                              final urlPattern = RegExp(r'^https?://.*\.(jpg|jpeg|png|gif|bmp|webp)$', caseSensitive: false);
                              if (!urlPattern.hasMatch(value)) {
                                return "Please enter a valid image URL (jpg, png, gif, etc.)";
                              }
                            }
                            return null;
                          },
                        ),
                      ),

                      // Category field
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: "Enter product category",
                            labelText: "Category",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          onChanged: (String? value) {
                            setState(() {
                              _category = value!;
                            });
                          },
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return "Category cannot be empty!";
                            }
                            return null;
                          },
                        ),
                      ),

                      // Feature toggle
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SwitchListTile(
                          title: const Text("Is featured"),
                          value: _isFeatured,
                          onChanged: (bool value) {
                            setState(() {
                              _isFeatured = value;
                            });
                          },
                        ),
                      ),

                      // Stock field
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: "Enter product stock",
                            labelText: "Stock",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          onChanged: (String? value) {
                            setState(() {
                              if (value == null) {
                                _stock = 0;
                                return;
                              }

                              final parsedStock = int.tryParse(value);
                              if (parsedStock == null) {
                                _stock = 0;
                              } else {
                                _stock = parsedStock;
                              }
                            });
                          },
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return "Stock cannot be empty!";
                            }
                            final stock = int.tryParse(value);
                            if (stock == null) {
                              return "Stock must be a valid integer!";
                            }
                            if (stock < 0) {
                              return "Stock cannot be negative!";
                            }
                            return null;
                          },
                        ),
                      ),
                      // Submit button
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCE1126),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // Send the form data to the Django create endpoint.
                              final response = await request.postJson(
                                '$baseUrl/create-flutter/',
                                jsonEncode({
                                  'name': _name,
                                  'price': () {
                                    final parsedPrice = int.tryParse(_price);
                                    if (parsedPrice == null) {
                                      return 0;
                                    }
                                    return parsedPrice;
                                  }(),
                                  'description': _description,
                                  'thumbnail': _thumbnail,
                                  'category': _category,
                                  'is_featured': _isFeatured,
                                  'stock': _stock,
                                }),
                              );

                              if (!context.mounted) return;

                              if (response['status'] == 'success') {
                                final createdName = _name;

                                // Clear the form so another product can be added right away.
                                _formKey.currentState!.reset();
                                setState(() {
                                  _name = '';
                                  _price = '';
                                  _description = '';
                                  _thumbnail = '';
                                  _category = '';
                                  _isFeatured = false;
                                  _stock = 0;
                                });

                                // Ask whether to stay on the form or jump to the product list.
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

                                if (!context.mounted) return;

                                if (shouldNavigate == true) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProductListPage(mode: ProductListMode.mine),
                                    ),
                                  );
                                }
                              } else {
                                String errorMessage = 'Failed to save product';
                                if (response['message'] != null) {
                                  errorMessage = response['message'];
                                }

                                // Show backend errors through a SnackBar.
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(errorMessage),
                                    ),
                                  );
                              }
                            }
                          },
                          child: const Text(
                            "Save",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ),
                      ),
                    ],
              ),
            ),
          ),
        );
    }

}

