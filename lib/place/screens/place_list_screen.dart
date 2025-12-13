import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart'; // Import untuk Auth
import 'package:provider/provider.dart'; // Import untuk Provider
import 'package:triathlon_mobile/place/models/place.dart';
import 'package:triathlon_mobile/place/services/place_service.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:triathlon_mobile/place/screens/place_detail_screen.dart';
import 'package:triathlon_mobile/screens/login.dart'; // Sesuaikan path login kamu
import 'package:triathlon_mobile/place/screens/place_form_screen.dart'; // Sesuaikan path form kamu
import 'package:triathlon_mobile/constants.dart';

class PlaceListScreen extends StatefulWidget {
  const PlaceListScreen({super.key});

  @override
  State<PlaceListScreen> createState() => _PlaceListScreenState();
}

class _PlaceListScreenState extends State<PlaceListScreen> {
  final PlaceService _placeService = PlaceService();

  List<Place> _allPlaces = [];
  List<Place> _filteredPlaces = [];
  List<Place> _featuredPlaces = [];

  String _searchQuery = "";
  String _selectedGenre = "Semua";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await _placeService.fetchPlaces();
      setState(() {
        _allPlaces = places;
        _filteredPlaces = places;
        _featuredPlaces = places.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _runFilter() {
    setState(() {
      _filteredPlaces = _allPlaces.where((place) {
        final matchesSearch = place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (place.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        final matchesGenre = _selectedGenre == "Semua" || place.genre == _selectedGenre;
        return matchesSearch && matchesGenre;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>(); // Ambil status login

    return Scaffold(
      backgroundColor: Colors.white,
      
      // Agar gambar background bisa naik ke belakang AppBar
      extendBodyBehindAppBar: true, 
      
      // APP BAR TRANSPARAN (Untuk Tombol Login/Logout)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (request.loggedIn)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                final response = await request.logout(
                  "$baseUrl/auth/logout/"
                );
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response["message"])),
                  );
                  setState(() {}); // Refresh UI
                }
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.login, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
        ],
      ),

      // TOMBOL ADD PLACE (Hanya muncul jika Login)
      floatingActionButton: request.loggedIn
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlaceFormScreen()),
                );
                _loadPlaces(); // Refresh data setelah tambah tempat
              },
              backgroundColor: Colors.blue[900],
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // 1. BACKGROUND IMAGE (Layer Paling Bawah)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 300,
                  child: Stack(
                    children: [
                      Image.asset(
                        "assets/images/hero-background2.png",
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 300,
                      ),
                      // Overlay Gelap
                      Container(
                        color: Colors.black.withOpacity(0.4),
                      ),
                      // Teks Judul
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Triathlon Venues",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Discover amazing locations for your next triathlon adventure.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. SCROLLABLE CONTENT (Layer Atas)
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // Spacer Transparan (Supaya gambar terlihat)
                      const SizedBox(height: 260),

                      // KOTAK PUTIH DENGAN UJUNG MELENGKUNG
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- FEATURED SECTION ---
                              if (_featuredPlaces.isNotEmpty) ...[
                                const Row(
                                  children: [
                                    Text("✨ Featured Venues",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text("Hand-picked recommendations",
                                    style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 16),

                                SizedBox(
                                  height: 220,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _featuredPlaces.length,
                                    itemBuilder: (context, index) {
                                      return _buildFeaturedCard(
                                          _featuredPlaces[index]);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // --- SEARCH BAR ---
                              TextField(
                                decoration: InputDecoration(
                                  hintText: "Search venues...",
                                  prefixIcon: const Icon(Icons.search),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 20),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                onChanged: (val) {
                                  _searchQuery = val;
                                  _runFilter();
                                },
                              ),
                              const SizedBox(height: 16),

                              // --- FILTERS ---
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip("Semua"),
                                    _buildFilterChip("Bicycle Tracking"),
                                    _buildFilterChip("Running Track"),
                                    _buildFilterChip("Swimming Pool"),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // --- ALL PLACES GRID ---
                              const Text("Explore Venues",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),

                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.75,
                                ),
                                itemCount: _filteredPlaces.length,
                                itemBuilder: (context, index) {
                                  return _buildPlaceCard(
                                      _filteredPlaces[index]);
                                },
                              ),
                              
                              const SizedBox(height: 80), // Extra space untuk FAB
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // WIDGET: Featured Card
  Widget _buildFeaturedCard(Place place) {
    String? imageUrl;
    if (place.image != null && place.image!.isNotEmpty) {
      imageUrl = "$baseUrl${place.image}";
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlaceDetailScreen(place: place)),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: Colors.black26,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(color: Colors.grey, child: const Icon(Icons.place)),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(place.city ?? "Unknown",
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text("Rp ${place.price}",
                          style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const Positioned(
                top: 12, right: 12,
                child: Chip(
                  label: Text("🏆 Featured", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET: Tombol Filter
  Widget _buildFilterChip(String label) {
    final isSelected = _selectedGenre == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedGenre = label;
            _runFilter();
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.blue[100],
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue[900] : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Colors.blue[900],
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // WIDGET: Kartu Grid Biasa
  Widget _buildPlaceCard(Place place) {
    String? imageUrl;
    if (place.image != null && place.image!.isNotEmpty) {
      imageUrl = "$baseUrl${place.image}";
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlaceDetailScreen(place: place)),
        );
      },
      child: Card(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: imageUrl != null
                  ? Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)))
                  : Container(color: Colors.blue[50], child: const Icon(Icons.place, color: Colors.blue)),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(place.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(place.city ?? "-", style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                    ]),
                    Text("Rp ${place.price}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[700])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}