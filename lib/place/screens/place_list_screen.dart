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
import 'package:triathlon_mobile/user_profile/models/user_profile_model.dart';
import 'package:triathlon_mobile/place/widgets/shimmer_loading.dart';

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

  // Mapping province names to image URLs (using reliable Unsplash CDN)
  static const Map<String, String> _provinceImages = {
    'Jawa Barat':
        'https://images.unsplash.com/photo-1555899434-94d1368aa7af?w=400&h=300&fit=crop',
    'DKI Jakarta':
        'https://images.unsplash.com/photo-1555899434-94d1368aa7af?w=400&h=300&fit=crop',
    'Jawa Timur':
        'https://images.unsplash.com/photo-1588668214407-6ea9a6d8c272?w=400&h=300&fit=crop',
    'Jawa Tengah':
        'https://images.unsplash.com/photo-1596402184320-417e7178b2cd?w=400&h=300&fit=crop',
    'DI Yogyakarta':
        'https://images.unsplash.com/photo-1584810359583-96fc3448beaa?w=400&h=300&fit=crop',
    'Bali':
        'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=400&h=300&fit=crop',
    'Sumatera Utara':
        'https://images.unsplash.com/photo-1571366343168-631c5bcca7a4?w=400&h=300&fit=crop',
    'Nusa Tenggara Barat':
        'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=400&h=300&fit=crop',
    'Sumatera Barat':
        'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400&h=300&fit=crop',
    'Sulawesi Utara':
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400&h=300&fit=crop',
    'Sulawesi Selatan':
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&h=300&fit=crop',
    'Papua':
        'https://images.unsplash.com/photo-1559128010-7c1ad6e1b6a5?w=400&h=300&fit=crop',
    'Kalimantan Timur':
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop',
  };

  // Selected province for filtering
  String? _selectedProvince;

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty)
      return rawUrl;
    return "$baseUrl$rawUrl";
  }

  void _runFilter() {
    setState(() {
      _filteredPlaces = _allPlaces.where((place) {
        final matchesSearch =
            place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (place.description?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
        final matchesGenre =
            _selectedGenre == "Semua" || place.genre == _selectedGenre;
        // Filter by province if selected
        final matchesProvince =
            _selectedProvince == null ||
            (place.province?.toLowerCase() == _selectedProvince?.toLowerCase());
        return matchesSearch && matchesGenre && matchesProvince;
      }).toList();
    });
  }

  // Get province image URL from mapping or fallback
  String? _getProvinceImageUrl(String provinceName) {
    // Return the image URL directly (external URLs don't need baseUrl prefix)
    return _provinceImages[provinceName];
  }

  // Check if user can add places (admin or facility_admin only)
  bool _canAddPlace() {
    final role = UserProfileData.role.toUpperCase();
    return role == 'ADMIN' || role == 'FACILITY_ADMIN';
  }

  Widget _buildBadge({required String label, Color? color, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),

      // TOMBOL ADD PLACE (Hanya muncul jika Login dan role admin/facility_admin)
      floatingActionButton: (request.loggedIn && _canAddPlace())
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlaceFormScreen(),
                  ),
                );
                _loadPlaces(); // Refresh data setelah tambah tempat
              },
              backgroundColor: Colors.blue[900],
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,

      body: _isLoading
          ? const PlaceShimmerLoading() // Shimmer loading effect
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
                        'assets/images/hero-background2.png',
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
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
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
                                    Text(
                                      "✨ Featured Venues",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Hand-picked recommendations",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),

                                SizedBox(
                                  height: 280, // Increased height
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _featuredPlaces.length,
                                    itemBuilder: (context, index) {
                                      return _buildFeaturedCard(
                                        _featuredPlaces[index],
                                      );
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
                                    vertical: 0,
                                    horizontal: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
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

                              if (_provinceStats.isNotEmpty ||
                                  _isProvinceLoading ||
                                  _provinceError != null) ...[
                                _buildProvinceSection(),
                                const SizedBox(height: 24),
                              ],

                              // --- ALL PLACES GRID ---
                              const Text(
                                "Explore Venues",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),

                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio:
                                          0.48, // Even taller to fit description
                                    ),
                                itemCount: _filteredPlaces.length,
                                itemBuilder: (context, index) {
                                  return _buildPlaceCard(
                                    _filteredPlaces[index],
                                  );
                                },
                              ),

                              const SizedBox(
                                height: 80,
                              ), // Extra space untuk FAB
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
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetailScreen(place: place),
          ),
        );
        // Refresh list if place was edited/deleted/reviewed
        if (result == true) {
          _loadPlaces();
        }
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: 6,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
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
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.place, size: 48),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _buildBadge(
                      label: place.genre ?? "Venue",
                      icon: Icons.directions_bike,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _buildBadge(
                      label: "Featured",
                      color: Colors.amber[700],
                      icon: Icons.star,
                    ),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place.city ?? "Unknown",
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            " (${place.reviewCount ?? 0})",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
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

  // FIXED: Place Card - match Django design with description, full location, and price/ticket
  Widget _buildPlaceCard(Place place) {
    final imageUrl = _resolveImageUrl(place.image);
    // Build full location string: "City, Province"
    String locationText = '';
    if (place.city != null && place.city!.isNotEmpty) {
      locationText = place.city!;
    }
    if (place.province != null && place.province!.isNotEmpty) {
      if (locationText.isNotEmpty) {
        locationText += ', ${place.province}';
      } else {
        locationText = place.province!;
      }
    }
    if (locationText.isEmpty) locationText = '-';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetailScreen(place: place),
          ),
        );
        // Refresh list if place was edited/deleted/reviewed
        if (result == true) {
          _loadPlaces();
        }
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
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.blue[50],
                          child: const Icon(Icons.place, color: Colors.blue),
                        ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: _buildBadge(
                          label: place.genre ?? "Venue",
                          icon: Icons.flag,
                        ),
                      ),
                      if (place.isFeatured == true)
                        _buildBadge(label: "New", color: Colors.orange),
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
                    // Title
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Location: City, Province
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.teal[400],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationText,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.teal[400],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price with /ticket
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Rp ${place.price}',
                            style: TextStyle(
                              color: Colors.teal[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: ' / ticket',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Description
                    Expanded(
                      child: Text(
                        place.description ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Rating row
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          (place.averageRating ?? 0).toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          " (${place.reviewCount ?? 0})",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
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
            const Text(
              "Explore by Province",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
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
        const Text(
          "Explore by Province",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          "Discover venues across Indonesia",
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(), // Enable smooth scrolling
            clipBehavior: Clip.none, // Allow shadow to show
            itemCount: _provinceStats.length,
            itemBuilder: (context, index) {
              final stat = _provinceStats[index];
              // Build province image URL from mapping (since API returns null)
              final imageUrl = _getProvinceImageUrl(stat.province);
              final isSelected = _selectedProvince == stat.province;

              return GestureDetector(
                onTap: () {
                  // Filter by province when tapped
                  setState(() {
                    // Toggle filter: if same province is tapped again, clear filter
                    if (_selectedProvince == stat.province) {
                      _selectedProvince = null;
                    } else {
                      _selectedProvince = stat.province;
                    }
                    _runFilter();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _selectedProvince == null
                            ? 'Showing all venues'
                            : 'Showing venues in ${stat.province}',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  width: 160,
                  margin: EdgeInsets.only(
                    right: index == _provinceStats.length - 1 ? 0 : 12,
                    bottom: 4, // Space for shadow
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: Colors.blue[700]!, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.4)
                            : Colors.black26,
                        blurRadius: isSelected ? 10 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Background image or fallback color
                        Positioned.fill(
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback gradient if image fails
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blueGrey[700]!,
                                            Colors.blueGrey[900]!,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          color: Colors.blueGrey[400],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blueGrey[600]!,
                                        Colors.blueGrey[800]!,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                        ),
                        // Gradient overlay for text readability
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // Content: Province name, venue count, and arrow
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Province flag icon at top (optional)
                              const Align(
                                alignment: Alignment.topRight,
                                child: Icon(
                                  Icons.flag,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                              ),
                              // Bottom content
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
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
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Arrow indicator
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
