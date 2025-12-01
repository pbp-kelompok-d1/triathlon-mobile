import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:triathlon_mobile/models/place.dart'; // <-- SUDAH DIPERBAIKI
import 'package:triathlon_mobile/models/review.dart'; // <-- SUDAH DIPERBAIKI
import 'package:triathlon_mobile/services/place_service.dart'; // <-- SUDAH DIPERBAIKI

class PlaceDetailScreen extends StatefulWidget {
  final Place place; // Menerima data tempat dari halaman sebelumnya

  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late Future<List<Review>> _reviewsFuture;
  final PlaceService _placeService = PlaceService();

  @override
  void initState() {
    super.initState();
    // Ambil review saat halaman dibuka
    _reviewsFuture = _placeService.fetchReviews(widget.place.id);
  }

  @override
  Widget build(BuildContext context) {
    // Logika URL Gambar (Adaptive Web/Mobile)
    String baseUrl = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
    String? imageUrl;
    if (widget.place.image != null && widget.place.image!.isNotEmpty) {
      imageUrl = "$baseUrl${widget.place.image}";
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. APP BAR DENGAN GAMBAR
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: Colors.blue[900],
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(color: Colors.grey, child: const Icon(Icons.place, size: 50)),
            ),
          ),

          // 2. KONTEN DETAIL
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul
                    Text(
                      widget.place.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    // Lokasi & Harga
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        Text(" ${widget.place.city}, ${widget.place.province}"),
                        const Spacer(),
                        Text(
                          "Rp ${widget.place.price}",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                      ],
                    ),
                    const Divider(height: 30),

                    // Deskripsi
                    const Text("About this place", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      widget.place.description ?? "Tidak ada deskripsi.",
                      style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // --- BAGIAN REVIEW ---
                    const Text("Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    FutureBuilder<List<Review>>(
                      future: _reviewsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text("Error loading reviews: ${snapshot.error}");
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text("Belum ada ulasan. Jadilah yang pertama mereview!");
                        }

                        // List Review
                        return ListView.builder(
                          shrinkWrap: true, // Agar bisa masuk dalam ScrollView utama
                          physics: const NeverScrollableScrollPhysics(), // Scroll ikut parent
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final review = snapshot.data![index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : "?"),
                                ),
                                title: Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(review.comment),
                                    const SizedBox(height: 4),
                                    Text(review.createdAt.substring(0, 10), style: const TextStyle(fontSize: 10, color: Colors.grey)), 
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, size: 14, color: Colors.orange),
                                      Text(" ${review.rating}"),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}