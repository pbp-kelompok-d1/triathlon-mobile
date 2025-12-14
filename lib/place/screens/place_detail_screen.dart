import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/place/models/place.dart';
import 'package:triathlon_mobile/place/models/review.dart';
import 'package:triathlon_mobile/place/services/place_service.dart';
import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/ticket/screens/ticket_list_page.dart';

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

  String? _resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    final parsed = Uri.tryParse(rawUrl);
    if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) return rawUrl;
    return "$baseUrl$rawUrl";
  }

  double _computeAverage(List<Review> reviews) {
    if (reviews.isEmpty) return 0;
    final total = reviews.fold<int>(0, (sum, r) => sum + r.rating);
    return total / reviews.length;
  }

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
    final imageUrl = _resolveImageUrl(widget.place.image);

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
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.blue[900],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned.fill(
                    child: imageUrl != null
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : Container(color: Colors.grey[200], child: const Icon(Icons.place, size: 48)),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 16,
                    child: _buildTag(widget.place.genre ?? "Venue", Icons.flag),
                  ),
                  if (widget.place.isFeatured == true)
                    Positioned(
                      top: 40,
                      right: 16,
                      child: _buildTag("Featured", Icons.star, color: Colors.amber[700]),
                    ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.place.name,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.location_on, size: 16, color: Colors.blueGrey),
                                            const SizedBox(width: 6),
                                            Text(
                                              "${widget.place.city ?? "-"}, ${widget.place.province ?? "-"}",
                                              style: const TextStyle(color: Colors.blueGrey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      _buildTag(widget.place.genre ?? "Venue", Icons.flag),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    widget.place.description ?? "Tidak ada deskripsi.",
                                    style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text("Price per session", style: TextStyle(color: Colors.green)),
                                  Text(
                                    "Rp ${widget.place.price}",
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, size: 18, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(
                                        (widget.place.averageRating ?? 0).toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(" (${widget.place.reviewCount ?? 0})", style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => TicketListPage(),
                              ));
                            },
                            icon: const Icon(Icons.airplane_ticket),
                            label: const Text("Pesan Tiket"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.blue[800]!),
                              foregroundColor: Colors.blue[800],
                            ),
                            onPressed: () => _showAddReviewModal(context, request),
                            icon: const Icon(Icons.rate_review),
                            label: const Text("Tambah Review"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Ulasan Pengunjung", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    FutureBuilder<List<Review>>(
                      future: _reviewsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gagal memuat ulasan: ${snapshot.error}',
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _refreshReviews,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          );
                        }
                        final reviews = snapshot.data ?? [];
                        final average = _computeAverage(reviews);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.yellow[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Text(average.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(" (${reviews.length})", style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (reviews.isEmpty)
                              const Text("Belum ada ulasan. Jadilah yang pertama!"),
                            if (reviews.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: reviews.length,
                                itemBuilder: (context, index) {
                                  final review = reviews[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.blue[100],
                                            child: Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : "?"),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green[50],
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(Icons.star, size: 14, color: Colors.amber),
                                                          const SizedBox(width: 4),
                                                          Text(review.rating.toString()),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(review.comment),
                                                const SizedBox(height: 6),
                                                Text(
                                                  review.createdAt.substring(0, 10),
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (request.loggedIn)
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                              onPressed: () => _deleteReview(request, review.id),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 80),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}