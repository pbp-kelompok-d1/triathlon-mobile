import 'package:flutter/material.dart';
import 'package:triathlon_mobile/models/place.dart';
import 'package:triathlon_mobile/services/place_service.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:triathlon_mobile/screens/place_detail_screen.dart'; // Pastikan file ini sudah dibuat

class PlaceListScreen extends StatefulWidget {
  const PlaceListScreen({super.key});

  @override
  State<PlaceListScreen> createState() => _PlaceListScreenState();
}

class _PlaceListScreenState extends State<PlaceListScreen> {
  final PlaceService _placeService = PlaceService();

  List<Place> _allPlaces = [];
  List<Place> _filteredPlaces = [];
  List<Place> _featuredPlaces = []; // List khusus Featured

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
        // AMBIL 3 TEMPAT PERTAMA SEBAGAI FEATURED (Sementara)
        _featuredPlaces = places.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // 1. HERO SECTION (Sebagai SliverAppBar)
                SliverAppBar(
                  expandedHeight: 250.0,
                  pinned: true,
                  backgroundColor: Colors.blue[900],
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text("Triathlon Venues",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // GAMBAR BACKGROUND HERO
                        Image.asset(
                          "assets/images/hero-background2.png", // Pastikan file ada di assets
                          fit: BoxFit.cover,
                        ),
                        // OVERLAY GELAP
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                            ),
                          ),
                        ),
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text(
                              "Discover amazing locations for your next triathlon adventure.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. ISI HALAMAN (Scrollable)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- FEATURED SECTION ---
                        if (_featuredPlaces.isNotEmpty) ...[
                          const Row(
                            children: [
                              Text("✨ Featured Venues", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text("Hand-picked recommendations", style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 12),

                          // LIST HORIZONTAL
                          SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _featuredPlaces.length,
                              itemBuilder: (context, index) {
                                return _buildFeaturedCard(_featuredPlaces[index]);
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
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.grey[200],
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
                        const Text("Explore Venues", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),

                        // GRID VIEW
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _filteredPlaces.length,
                          itemBuilder: (context, index) {
                            return _buildPlaceCard(_filteredPlaces[index]);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // WIDGET: Featured Card (Horizontal)
  Widget _buildFeaturedCard(Place place) {
    String? imageUrl;
    if (place.image != null && place.image!.isNotEmpty) {
      // LOGIKA ADAPTIVE URL (Web vs Android)
      String baseUrl = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
      imageUrl = "$baseUrl${place.image}";
    }

    // Dibungkus GestureDetector untuk Navigasi
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetailScreen(place: place),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(place.city ?? "Unknown",
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text("Rp ${place.price}",
                          style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const Positioned(
                top: 8, right: 8,
                child: Chip(
                  label: Text("🏆 Featured", style: TextStyle(fontSize: 10)),
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.all(0),
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
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.blue[800],
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        onSelected: (bool selected) {
          setState(() {
            _selectedGenre = label;
            _runFilter();
          });
        },
      ),
    );
  }

  // WIDGET: Kartu Grid Biasa
  Widget _buildPlaceCard(Place place) {
    String? imageUrl;
    if (place.image != null && place.image!.isNotEmpty) {
      // LOGIKA ADAPTIVE URL (Web vs Android)
      String baseUrl = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
      imageUrl = "$baseUrl${place.image}";
    }

    // Dibungkus GestureDetector untuk Navigasi
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetailScreen(place: place),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: imageUrl != null
                  ? Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)))
                  : Container(color: Colors.blue[50], child: const Icon(Icons.place, color: Colors.blue)),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(place.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(place.city ?? "-", style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                    ]),
                    Text("Rp ${place.price}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green[700])),
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