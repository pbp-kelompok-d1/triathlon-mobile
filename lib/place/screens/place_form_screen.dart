import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http; // Butuh ini untuk Multipart Request
import 'package:flutter/foundation.dart'; // kIsWeb

class PlaceFormScreen extends StatefulWidget {
  const PlaceFormScreen({super.key});

  @override
  State<PlaceFormScreen> createState() => _PlaceFormScreenState();
}

class _PlaceFormScreenState extends State<PlaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  
  String? _selectedGenre;
  final List<String> _genres = ['Swimming Pool', 'Running Track', 'Bicycle Tracking'];

  File? _imageFile; // Untuk menyimpan gambar yang dipilih
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm(CookieRequest request) async {
    if (!_formKey.currentState!.validate()) return;

    // URL API Django
    String baseUrl = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
    var uri = Uri.parse("$baseUrl/place/api/add-place/");

    // Siapkan Multipart Request (Bukan JSON biasa)
    var multipartRequest = http.MultipartRequest("POST", uri);

    // Tambahkan Data Teks
    multipartRequest.fields['name'] = _nameController.text;
    multipartRequest.fields['price'] = _priceController.text;
    multipartRequest.fields['description'] = _descriptionController.text;
    multipartRequest.fields['city'] = _cityController.text;
    multipartRequest.fields['province'] = _provinceController.text;
    if (_selectedGenre != null) {
      multipartRequest.fields['genre'] = _selectedGenre!;
    }

    // Tambahkan Gambar (Jika ada)
    if (_imageFile != null) {
      var stream = http.ByteStream(_imageFile!.openRead());
      var length = await _imageFile!.length();
      var multipartFile = http.MultipartFile(
        'image', stream, length,
        filename: _imageFile!.path.split("/").last
      );
      multipartRequest.files.add(multipartFile);
    }

    // PENTING: Sisipkan Headers dari CookieRequest agar dianggap Login
    // Kita ambil headers dari request library pbp_django_auth
    Map<String, String> headers = request.headers;
    multipartRequest.headers.addAll(headers);

    // Kirim Request
    try {
      var streamedResponse = await multipartRequest.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tempat berhasil ditambahkan!")),
          );
          Navigator.pop(context, true); // Kembali ke list dan refresh
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Gagal: ${response.body}")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error koneksi: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Tempat Baru"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // IMAGE PICKER
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          Text("Tap untuk upload gambar"),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // FORM FIELDS
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nama Tempat", border: OutlineInputBorder()),
              validator: (value) => value!.isEmpty ? "Nama tidak boleh kosong" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: "Harga (Rp)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? "Harga tidak boleh kosong" : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedGenre,
              hint: const Text("Pilih Genre"),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _genres.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (val) => setState(() => _selectedGenre = val),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: "Kota", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _provinceController,
              decoration: const InputDecoration(labelText: "Provinsi", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Deskripsi", border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: () => _submitForm(request),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Simpan Tempat", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}