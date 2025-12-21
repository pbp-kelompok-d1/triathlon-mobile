import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/place/models/place.dart';

class PlaceEditScreen extends StatefulWidget {
  final Place place;

  const PlaceEditScreen({super.key, required this.place});

  @override
  State<PlaceEditScreen> createState() => _PlaceEditScreenState();
}

class _PlaceEditScreenState extends State<PlaceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _cityController;
  late TextEditingController _provinceController;
  late TextEditingController _imageUrlController;

  String? _selectedGenre;
  final List<String> _genres = [
    'Swimming Pool',
    'Running Track',
    'Bicycle Tracking',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing place data
    _nameController = TextEditingController(text: widget.place.name);
    _priceController = TextEditingController(text: widget.place.price);
    _descriptionController = TextEditingController(text: widget.place.description ?? '');
    _cityController = TextEditingController(text: widget.place.city ?? '');
    _provinceController = TextEditingController(text: widget.place.province ?? '');
    _imageUrlController = TextEditingController(text: widget.place.image ?? '');
    _selectedGenre = widget.place.genre;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitForm(CookieRequest request) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGenre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih genre terlebih dahulu")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final url = "$baseUrl/place/api/edit-place/${widget.place.id}/";

    final payload = {
      'name': _nameController.text.trim(),
      'price': _priceController.text.trim(),
      'description': _descriptionController.text.trim(),
      'city': _cityController.text.trim(),
      'province': _provinceController.text.trim(),
      'genre': _selectedGenre!,
      'image_url': _imageUrlController.text.trim(),
    };

    try {
      debugPrint('Editing place ID: ${widget.place.id}');
      debugPrint('Sending to: $url');

      // Use postJson to prevent base64 conversion
      final response = await request.postJson(
        url,
        jsonEncode(payload),
      );

      debugPrint('Response: $response');

      setState(() => _isLoading = false);

      if (context.mounted) {
        if (response['success'] == true || response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tempat berhasil diperbarui!")),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          final errorMsg = response['message'] ?? response['error'] ?? 'Gagal memperbarui tempat';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: $errorMsg")),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Tempat"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image URL field
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: "URL Gambar (opsional)",
                hintText: "https://...",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            
            // Image preview
            if (_imageUrlController.text.trim().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    _imageUrlController.text.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(child: Text("Gagal memuat gambar")),
                      );
                    },
                  ),
                ),
              ),
            if (_imageUrlController.text.trim().isNotEmpty)
              const SizedBox(height: 20),
            
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nama Tempat *",
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? "Nama tidak boleh kosong" : null,
            ),
            const SizedBox(height: 12),
            
            // Price field
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: "Harga (Rp) *",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? "Harga tidak boleh kosong" : null,
            ),
            const SizedBox(height: 12),
            
            // Genre dropdown
            DropdownButtonFormField<String>(
              value: _genres.contains(_selectedGenre) ? _selectedGenre : null,
              hint: const Text("Pilih Genre *"),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _genres.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (val) => setState(() => _selectedGenre = val),
              validator: (value) => value == null ? "Pilih genre" : null,
            ),
            const SizedBox(height: 12),
            
            // City field
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: "Kota",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Province field
            TextFormField(
              controller: _provinceController,
              decoration: const InputDecoration(
                labelText: "Provinsi",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : () => _submitForm(request),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("Simpan Perubahan", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
