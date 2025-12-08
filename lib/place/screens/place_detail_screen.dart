import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/place/models/place.dart';
import 'package:triathlon_mobile/place/models/review.dart';
import 'package:triathlon_mobile/place/services/place_service.dart';

class PlaceDetailScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late Future<List<Review>> _reviewsFuture;
  final PlaceService _placeService = PlaceService();

  // Variabel untuk Form Review
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshReviews();
  }

  void _refreshReviews() {
    setState(() {
      _reviewsFuture = _placeService.fetchReviews(widget.place.id);
    });
  }

  // LOGIKA URL (Adaptive)
  String get baseUrl => kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";

  // --- FUNGSI 1: KIRIM REVIEW (POST) ---
  Future<void> _submitReview(CookieRequest request) async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tolong berikan rating bintang!")),
      );
      return;
    }

    // URL Backend: Sesuaikan dengan place/urls.py
    final url = '$baseUrl/place/api/places/${widget.place.id}/reviews/add/';

    try {
      final response = await request.postJson(
        url,
        jsonEncode({
          'rating': _rating,
          'comment': _commentController.text,
        }),
      );

      if (context.mounted) {
        if (response['success'] == true) {
          Navigator.pop(context); // Tutup Modal
          _commentController.clear();
          setState(() {
             _rating = 0;
          });
          _refreshReviews(); // Refresh List Review
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Review berhasil ditambahkan!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? "Gagal kirim review")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  // --- FUNGSI 2: HAPUS REVIEW (DELETE) ---
  Future<void> _deleteReview(CookieRequest request, int reviewId) async {
    // URL Backend: Sesuaikan dengan place/urls.py
    final url = '$baseUrl/place/api/reviews/$reviewId/delete/';

    try {
      final response = await request.postJson(url, jsonEncode({}));

      if (context.mounted) {
        if (response['success'] == true) {
          _refreshReviews();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Review berhasil dihapus!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? "Gagal hapus review")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // --- FUNGSI 3: TAMPILKAN MODAL FORM ---
  void _showAddReviewModal(BuildContext context, CookieRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return StatefulBuilder( // Agar bintang bisa berubah warna saat diklik
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tulis Ulasan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // BINTANG RATING INPUT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setStateModal(() {
                            _rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      labelText: "Komentar kamu...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _submitReview(request),
                      child: const Text("Kirim Review"),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>(); // Ambil Cookie User Login
    String? imageUrl;
    if (widget.place.image != null && widget.place.image!.isNotEmpty) {
      imageUrl = "$baseUrl${widget.place.image}";
    }

    return Scaffold(
      // TOMBOL FAB UNTUK ADD REVIEW
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!request.loggedIn) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Silakan login terlebih dahulu.")),
            );
          } else {
            _showAddReviewModal(context, request);
          }
        },
        label: const Text("Review"),
        icon: const Icon(Icons.rate_review),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      
      body: CustomScrollView(
        slivers: [
          // 1. GAMBAR HERO
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
                    Text(
                      widget.place.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
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
                    const Text("About this place", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      widget.place.description ?? "Tidak ada deskripsi.",
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    const Text("Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    // DAFTAR REVIEW
                    FutureBuilder<List<Review>>(
                      future: _reviewsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text("Belum ada ulasan. Jadilah yang pertama!");
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Bintang Rating
                                    const Icon(Icons.star, size: 16, color: Colors.amber),
                                    Text(" ${review.rating}  "),
                                    
                                    // TOMBOL DELETE (Hanya muncul jika bisa delete)
                                    // Kita coba tampilkan ke semua, backend yang akan tolak kalau bukan miliknya
                                    if (request.loggedIn)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _deleteReview(request, review.id),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 80), // Space untuk FAB
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