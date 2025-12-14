import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/place/models/place.dart';
import 'package:triathlon_mobile/place/models/province_stat.dart';
import 'package:triathlon_mobile/place/services/place_service.dart';
import 'package:triathlon_mobile/place/screens/place_detail_screen.dart';
import 'package:triathlon_mobile/screens/login.dart';
import 'package:triathlon_mobile/place/screens/place_form_screen.dart';
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
  List<ProvinceStat> _provinceStats = [];

  String? _provinceError;

  String _searchQuery = "";
  String _selectedGenre = "Semua";
  bool _isLoading = true;
  bool _isProvinceLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    _loadProvinceStats();
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

  Future<void> _loadProvinceStats() async {
    try {
      final stats = await _placeService.fetchProvinceStats();
      setState(() {
        _provinceStats = stats;
        _isProvinceLoading = false;
        _provinceError = null;
      });
    } catch (e) {
      setState(() {
        _isProvinceLoading = false;
        _provinceError = e.toString();
      });
    }
  }

  String? _resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    final parsed = Uri.tryParse(rawUrl);
    // Jika sudah absolute (https://example.com/img), pakai langsung. Jika relative, prefix dengan baseUrl.
    if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) return rawUrl;
    return "$baseUrl$rawUrl";
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

  Widget _buildBadge({required String label, Color? color, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
                    SnackBar(content: Text(response['message'] ?? 'Logged out')),
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
                        'assets/images/hero-background.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        height: 300,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.blue[900],
                            height: 300,
                          );
                        },
                      ),
                      Container(color: Colors.black.withOpacity(0.4)),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 40),
                              Text(
                                "Triathlon Venues",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Discover amazing locations for your next triathlon adventure",
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                                textAlign: TextAlign.center,
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
                                  height: 280, // Increased height
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
                                      borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
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

                              if (_provinceStats.isNotEmpty || _isProvinceLoading || _provinceError != null) ...[
                                _buildProvinceSection(),
                                const SizedBox(height: 24),
                              ],

                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.55, // Smaller ratio = taller cards
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

  // FIXED: Featured Card - removed nested duplicate Card
  Widget _buildFeaturedCard(Place place) {
    final imageUrl = _resolveImageUrl(place.image);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlaceDetailScreen(place: place)),
        );
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: 6,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        : Container(color: Colors.grey[200], child: const Icon(Icons.place, size: 48)),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _buildBadge(label: place.genre ?? "Venue", icon: Icons.directions_bike),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _buildBadge(label: "Featured", color: Colors.amber[700], icon: Icons.star),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place.city ?? "Unknown",
                              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Rp ${place.price}",
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            (place.averageRating ?? 0).toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            " (${place.reviewCount ?? 0})",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
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

  // FIXED: Place Card - constrained content to prevent overflow
  Widget _buildPlaceCard(Place place) {
    final imageUrl = _resolveImageUrl(place.image);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlaceDetailScreen(place: place)),
        );
      },
      child: Card(
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                      : Container(color: Colors.blue[50], child: const Icon(Icons.place, color: Colors.blue)),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: _buildBadge(label: place.genre ?? "Venue", icon: Icons.flag),
                      ),
                      if (place.isFeatured == true)
                        _buildBadge(label: "⭐", color: Colors.amber[700]),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.city ?? "-",
                            style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Rp ${place.price}",
                        style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          (place.averageRating ?? 0).toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        Text(
                          " (${place.reviewCount ?? 0})",
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvinceSection() {
    if (_isProvinceLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_provinceError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Explore by Province", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              "Gagal memuat statistik provinsi",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_provinceStats.isEmpty) {
      return const SizedBox.shrink(); // Hide if empty
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Explore by Province", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _provinceStats.length,
            itemBuilder: (context, index) {
              final stat = _provinceStats[index];
              final imageUrl = _resolveImageUrl(stat.image);
              return Container(
                width: 160,
                margin: EdgeInsets.only(right: index == _provinceStats.length - 1 ? 0 : 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: imageUrl != null
                            ? Image.network(imageUrl, fit: BoxFit.cover)
                            : Container(color: Colors.blueGrey[300]),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.6)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              stat.province,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${stat.venueCount} venues",
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}