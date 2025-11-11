import 'package:flutter/material.dart';
import '../widgets/left_drawer.dart';

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
        return Scaffold(
          appBar: AppBar(
            title: const Center(
              child: Text(
                'Add Product Form',
              ),
            ),
            backgroundColor: Color(0xFFCE1126),
            foregroundColor: Colors.white,
          ),
          drawer: const LeftDrawer(),
          body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        // === Name ===
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
                        
                        // === Price ===
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
                          
                        // === Description ===
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

                      // === Thumbnail ===
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

                      // === Category ===
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

                      // === Is Featured ===
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

                      // === Stock ===
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
                              _stock = int.tryParse(value!) ?? 0;
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
                      // === Tombol Simpan ===
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all(Color(0xFFCE1126)),
                                  ),
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      await showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Product Successfully Saved'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildInfoRow('Name', _name),
                                                  _buildInfoRow('Price', _price),
                                                  _buildInfoRow('Description', _description),
                                                  _buildInfoRow('Thumbnail', _thumbnail.isEmpty ? 'Not provided' : _thumbnail),
                                                  _buildInfoRow('Category', _category),
                                                  _buildInfoRow('Is Featured', _isFeatured ? 'Yes' : 'No'),
                                                  _buildInfoRow('Stock', _stock.toString()),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                child: const Text('OK'),
                                                onPressed: () {
                                                  Navigator.pop(context); // Close dialog
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      // Reset form after dialog is closed
                                      _formKey.currentState!.reset();
                                      setState(() {
                                        _name = "";
                                        _price = "";
                                        _description = "";
                                        _thumbnail = "";
                                        _category = "";
                                        _isFeatured = false;
                                        _stock = 0;
                                      });
                                      // Navigate back to previous page (main page)
                                      Navigator.pop(context);
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

    Widget _buildInfoRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }
}

