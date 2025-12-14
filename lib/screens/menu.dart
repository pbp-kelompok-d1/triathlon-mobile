import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/widgets/left_drawer.dart';
import 'package:triathlon_mobile/user_profile/widgets/profile_drawer.dart';
import 'package:triathlon_mobile/shop/screens/shop_main.dart';
import 'package:triathlon_mobile/place/screens/place_list_screen.dart';
import 'package:triathlon_mobile/place/models/place.dart';
import 'package:triathlon_mobile/place/services/place_service.dart';
import 'package:triathlon_mobile/place/screens/place_detail_screen.dart';
import 'package:triathlon_mobile/forum/screens/forum_list.dart';
import 'package:triathlon_mobile/ticket/screens/ticket_list_page.dart';
import 'package:triathlon_mobile/activity/screens/activity_menu.dart';
import 'package:triathlon_mobile/activity/screens/activity_form.dart';
import 'package:triathlon_mobile/constants.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PlaceService _placeService = PlaceService();
  List<Place> _recommendedPlaces = [];
  bool _isLoadingPlaces = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendedPlaces();
  }

  Future<void> _loadRecommendedPlaces() async {
    try {
      final places = await _placeService.fetchPlaces();
      setState(() {
        _recommendedPlaces = places.take(3).toList();
        _isLoadingPlaces = false;
      });
    } catch (e) {
      setState(() => _isLoadingPlaces = false);
    }
  }

  String? _resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    final parsed = Uri.tryParse(rawUrl);
    if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) return rawUrl;
    return "$baseUrl$rawUrl";
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    String username = 'Explorer';
    if (request.jsonData['username'] != null) {
      username = request.jsonData['username'].toString();
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.grey[800]),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openEndDrawer(),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: const CircleAvatar(
                  backgroundColor: Color(0xFF6366F1),
                  child: Icon(Icons.person, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: LeftDrawer(),
      endDrawer: const CustomRightDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              // GREETING SECTION
              Text(
                "Hello,",
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                "$username!",
                style: const TextStyle(
                  fontSize: 32,
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You're on track to achieve your triathlon goals.\nKeep pushing and stay motivated!",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // START TRAINING BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActivityFormPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    "Start Training",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // TRAINING SUMMARY CARD
              _buildSectionCard(
                title: "Your Training Summary",
                subtitle: "Track your progress and stay motivated",
                icon: Icons.fitness_center,
                iconColor: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ActivityMenu()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("🏊", "Swim", "0 km"),
                      _buildStatItem("🚴", "Bike", "0 km"),
                      _buildStatItem("🏃", "Run", "0 km"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // RECENT ACTIVITIES CARD
              _buildSectionCard(
                title: "Recent Activities",
                subtitle: "Your latest training sessions",
                icon: Icons.directions_run,
                iconColor: Colors.amber,
                trailing: _buildViewAllButton(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ActivityMenu()),
                  );
                }),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ActivityMenu()),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      "No recent activities.\nStart training now!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // QUICK ACCESS GRID
              const Text(
                "Quick Access",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildQuickAccessCard(
                    icon: Icons.shopping_bag,
                    label: "Shop",
                    color: const Color(0xFF10B981),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopPage())),
                  ),
                  _buildQuickAccessCard(
                    icon: Icons.forum,
                    label: "Forum",
                    color: const Color(0xFF8B5CF6),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForumListPage())),
                  ),
                  _buildQuickAccessCard(
                    icon: Icons.confirmation_number,
                    label: "Tickets",
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketListPage())),
                  ),
                  _buildQuickAccessCard(
                    icon: Icons.place,
                    label: "Places",
                    color: const Color(0xFF3B82F6),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceListScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // RECOMMENDED PLACES SECTION
              const Center(
                child: Text(
                  "Recommended Places",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  "Great training locations and venues for your\ntriathlon journey!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // PLACES HORIZONTAL LIST
              _isLoadingPlaces
                  ? const Center(child: CircularProgressIndicator())
                  : _recommendedPlaces.isEmpty
                      ? const Center(child: Text("No places available"))
                      : SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _recommendedPlaces.length,
                            itemBuilder: (context, index) {
                              return _buildPlaceCard(_recommendedPlaces[index]);
                            },
                          ),
                        ),
              const SizedBox(height: 16),

              // VIEW ALL PLACES BUTTON
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlaceListScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2937),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "View All Places",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // HELPER: Section Card Widget
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Widget? trailing,
    Widget? child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (trailing != null) trailing,
              ],
            ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  // HELPER: Stat Item for Training Summary
  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // HELPER: View All Button
  Widget _buildViewAllButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "View All",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // HELPER: Quick Access Card
  Widget _buildQuickAccessCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HELPER: Place Card for Recommended Places
  Widget _buildPlaceCard(Place place) {
    final imageUrl = _resolveImageUrl(place.image);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.place, size: 40, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.place, size: 40, color: Colors.grey),
                      ),
              ),
              // Gradient Overlay
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
              // Genre Badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag, size: 10, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        place.genre ?? "Venue",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Place Info
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.city ?? "-",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}