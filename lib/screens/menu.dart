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
import 'package:triathlon_mobile/activity/models/activity_model.dart';
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

  // Activities state
  bool _isLoadingActivities = true;
  String? _activitiesError;
  List<Activity> _myActivities = [];
  Activity? _mostRecentActivity;

  int _swimCount = 0;
  int _bikeCount = 0;
  int _runCount = 0;

  // Consistent Coloring
  static const primaryBlue = Color(0xFF433BFF);
  static const secondaryBlue = Color(0xFF2D27A8);

  @override
  void initState() {
    super.initState();
    _loadRecommendedPlaces();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyActivities();
    });
  }

  // Animation Helper
  Widget _animateEntrance(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Logic
  Future<void> _loadRecommendedPlaces() async {
    try {
      final places = await _placeService.fetchPlaces();
      if (mounted) {
        setState(() {
          _recommendedPlaces = places.take(3).toList();
          _isLoadingPlaces = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPlaces = false);
    }
  }

  Future<void> _loadMyActivities() async {
    final request = context.read<CookieRequest>();
    final username = request.jsonData['username']?.toString();
    setState(() {
      _isLoadingActivities = true;
      _activitiesError = null;
    });
    try {
      final all = await _fetchActivities(request);
      final mine = (username == null || username.trim().isEmpty)
          ? <Activity>[]
          : all.where((a) => a.creatorUsername == username).toList();

      int swim = 0, bike = 0, run = 0;
      for (final a in mine) {
        final cat = a.sportCategory.trim().toLowerCase();
        if (cat == 'swimming') swim++;
        if (cat == 'cycling') bike++;
        if (cat == 'running') run++;
      }

      Activity? mostRecent;
      if (mine.isNotEmpty) {
        mine.sort((a, b) => _parseActivityDate(b).compareTo(_parseActivityDate(a)));
        mostRecent = mine.first;
      }

      if (mounted) {
        setState(() {
          _myActivities = mine;
          _swimCount = swim;
          _bikeCount = bike;
          _runCount = run;
          _mostRecentActivity = mostRecent;
          _isLoadingActivities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activitiesError = e.toString();
          _isLoadingActivities = false;
        });
      }
    }
  }

  // Helper fetch internal
  Future<List<Activity>> _fetchActivities(CookieRequest request) async {
    final response = await request.get('$baseUrl/activities/jsonning');
    if (response is Map<String, dynamic> && response.containsKey('results')) {
      return (response['results'] as List).map((d) => Activity.fromJson(d)).toList();
    } else if (response is List) {
      return response.map((d) => Activity.fromJson(d)).toList();
    }
    throw Exception("Unexpected response format");
  }

  DateTime _parseActivityDate(Activity a) {
    final iso = a.doneAtIso.trim();
    if (iso.isNotEmpty) return DateTime.tryParse(iso) ?? DateTime(0);
    return DateTime.tryParse(a.doneAtDisplay.trim()) ?? DateTime(0);
  }

  String _resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return "";
    if (rawUrl.startsWith('http')) return rawUrl;
    return "$baseUrl$rawUrl";
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    String username = request.jsonData['username']?.toString() ?? 'Explorer';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: primaryBlue),
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
                  backgroundColor: primaryBlue,
                  radius: 18,
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const LeftDrawer(),
      endDrawer: const CustomRightDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadMyActivities();
          await _loadRecommendedPlaces();
        },
        color: primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // 1. GREETING (Animated)
                _animateEntrance(0, Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hello,", style: TextStyle(fontSize: 24, color: Colors.grey[600], fontWeight: FontWeight.w400)),
                    Text("$username!", style: const TextStyle(fontSize: 32, color: primaryBlue, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("You're on track to achieve your triathlon goals.", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                )),

                const SizedBox(height: 24),

                // Start Training
                _animateEntrance(1, Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryBlue, secondaryBlue], 
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityFormPage()));
                      _loadMyActivities();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Start Training", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )),

                const SizedBox(height: 30),

                // Summary Card
                _animateEntrance(2, _buildSectionCard(
                  title: "Your Training Summary",
                  subtitle: "Track your progress",
                  icon: Icons.fitness_center_rounded,
                  iconColor: const Color(0xFFFF8409),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityMenu())),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: _isLoadingActivities
                        ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem("🏊", "Swim", "$_swimCount"),
                              _buildStatItem("🚴", "Bike", "$_bikeCount"),
                              _buildStatItem("🏃", "Run", "$_runCount"),
                            ],
                          ),
                  ),
                )),

                const SizedBox(height: 20),

                // Recent Activity
                _animateEntrance(3, _buildSectionCard(
                  title: "Recent Activity",
                  subtitle: "Latest session",
                  icon: Icons.history_rounded,
                  iconColor: primaryBlue,
                  trailing: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityMenu())),
                    child: const Text("View All", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                  child: _isLoadingActivities
                      ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                      : (_mostRecentActivity == null)
                          ? const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: Text("No activities yet")))
                          : _buildRecentPreview(_mostRecentActivity!),
                )),

                const SizedBox(height: 30),

                // Quick Access
                _animateEntrance(4, const Text("Quick Access", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                _animateEntrance(5, GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildQuickAccessCard(icon: Icons.shopping_bag_rounded, label: "Shop", color: const Color(0xFF10B981), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopPage()))),
                    _buildQuickAccessCard(icon: Icons.forum_rounded, label: "Forum", color: const Color(0xFF8B5CF6), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForumListPage()))),
                    _buildQuickAccessCard(icon: Icons.confirmation_num_rounded, label: "Tickets", color: const Color(0xFFF59E0B), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketListPage()))),
                    _buildQuickAccessCard(icon: Icons.place_rounded, label: "Places", color: const Color(0xFF3B82F6), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceListScreen()))),
                  ],
                )),

                const SizedBox(height: 30),

                // Places Section
                _animateEntrance(6, const Center(child: Text("Recommended Places", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue)))),
                const SizedBox(height: 20),
                _animateEntrance(7, _isLoadingPlaces 
                  ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                  : SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recommendedPlaces.length,
                        itemBuilder: (ctx, idx) => _buildPlaceCard(_recommendedPlaces[idx]),
                      ),
                    )),
                
                const SizedBox(height: 20),
                _animateEntrance(8, Center(
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceListScreen())),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: const Text("View All Places", style: TextStyle(
                      color: primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                )),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widgets

  Widget _buildSectionCard({required String title, required String subtitle, required IconData icon, required Color iconColor, Widget? trailing, required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryBlue.withOpacity(0.1), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)
            )],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(subtitle, style: TextStyle(
                          color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                if (trailing != null) trailing,
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 18, color: primaryBlue)),
        Text(label, style: TextStyle(
          color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }

  Widget _buildRecentPreview(Activity a) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.directions_run_rounded, color: primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.title, style: const TextStyle(
                fontWeight: FontWeight.bold), 
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text("${a.distance}m • ${a.sportCategory}", style: TextStyle(
                fontSize: 12, color: Colors.grey[600])),
            ],
          )),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)
            )],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(Place place) {
    final imageUrl = _resolveImageUrl(place.image);
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(child: imageUrl.isNotEmpty 
              ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.place))
              : const Icon(Icons.place)),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, 
                    end: Alignment.bottomCenter, 
                    colors: [
                      Colors.transparent, 
                      Colors.black.withOpacity(0.8)])
                    )
                  )
                ),
            Positioned(
              bottom: 10, 
              left: 10, 
              right: 10, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(place.name, style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 12), 
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(place.city ?? "-", style: const TextStyle(
                    color: Colors.white70, fontSize: 10)),
                ])),
          ],
        ),
      ),
    );
  }
}