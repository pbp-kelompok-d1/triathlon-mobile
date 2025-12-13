// =============================================================================
// ForumUserProfilePage - Public User Profile Screen
// =============================================================================
// This screen displays a public view of a user's forum activity including:
// - User header with avatar, username, role badge
// - Stats section (join date, total posts, total replies)
// - Tabbed view for Posts and Replies by this user
// - Clickable cards to navigate to original posts
//
// Navigation: Reached by clicking on usernames in forum posts/replies
// Data source: GET /forum/user/<username>/?format=json
// =============================================================================

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import 'forum_detail.dart';

/// Screen for displaying a user's public forum profile
class ForumUserProfilePage extends StatefulWidget {
  // The username of the user whose profile to display
  final String username;

  const ForumUserProfilePage({super.key, required this.username});

  @override
  State<ForumUserProfilePage> createState() => _ForumUserProfilePageState();
}

class _ForumUserProfilePageState extends State<ForumUserProfilePage>
    with SingleTickerProviderStateMixin {
  // ===========================================================================
  // State Variables
  // ===========================================================================
  
  // Tab controller for switching between Posts and Replies tabs
  late TabController _tabController;
  
  // Loading state while fetching data from API
  bool _isLoading = true;
  
  // Error message if API call fails
  String? _error;
  
  // ---------------------------------------------------------------------------
  // User Data from API
  // ---------------------------------------------------------------------------
  Map<String, dynamic>? _userData;    // User info (username, role, join date)
  Map<String, dynamic>? _statsData;   // Stats (total posts, total replies)
  List<dynamic> _posts = [];          // List of user's forum posts
  List<dynamic> _replies = [];        // List of user's replies

  // ===========================================================================
  // Lifecycle Methods
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    // Initialize tab controller with 2 tabs (Posts, Replies)
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Data Loading
  // ===========================================================================

  /// Load user profile data from Django API
  /// Endpoint: GET /forum/user/<username>/?format=json
  Future<void> _loadUserProfile() async {
    final request = context.read<CookieRequest>();
    
    try {
      final response = await request.get(
        '$baseUrl/forum/user/${widget.username}/?format=json',
      );
      
      setState(() {
        _userData = response['user'];
        _statsData = response['stats'];
        _posts = response['posts'] ?? [];
        _replies = response['replies'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load user profile: $e';
        _isLoading = false;
      });
    }
  }

  // ===========================================================================
  // Build Methods
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('@${widget.username}'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  /// Build main body content based on loading/error state
  Widget _buildBody() {
    // Show loading indicator while fetching data
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1D4ED8)),
            SizedBox(height: 16),
            Text('Loading profile...'),
          ],
        ),
      );
    }

    // Show error message if API call failed
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadUserProfile();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show profile content
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        // =====================================================================
        // Profile Header Section
        // =====================================================================
        SliverToBoxAdapter(
          child: _buildProfileHeader(),
        ),
        // =====================================================================
        // Tab Bar for Posts/Replies
        // =====================================================================
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverTabBarDelegate(
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1D4ED8),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF1D4ED8),
              tabs: [
                Tab(
                  icon: const Icon(Icons.article_outlined),
                  text: 'Posts (${_posts.length})',
                ),
                Tab(
                  icon: const Icon(Icons.reply_outlined),
                  text: 'Replies (${_replies.length})',
                ),
              ],
            ),
          ),
        ),
      ],
      // =======================================================================
      // Tab Content
      // =======================================================================
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsTab(),
          _buildRepliesTab(),
        ],
      ),
    );
  }

  /// Build the profile header with avatar, name, role, and stats
  Widget _buildProfileHeader() {
    final role = _userData?['role'] ?? 'USER';
    final username = _userData?['username'] ?? widget.username;
    final initial = _userData?['initial'] ?? username[0].toUpperCase();
    final dateJoined = _userData?['date_joined'] ?? 'Unknown';
    final totalPosts = _statsData?['total_posts'] ?? 0;
    final totalReplies = _statsData?['total_replies'] ?? 0;

    return Container(
      color: const Color(0xFF1D4ED8),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // -------------------------------------------------------------------
          // Avatar
          // -------------------------------------------------------------------
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 46,
              backgroundColor: _getAvatarColor(role),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // -------------------------------------------------------------------
          // Username
          // -------------------------------------------------------------------
          Text(
            '@$username',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // -------------------------------------------------------------------
          // Role Badge
          // -------------------------------------------------------------------
          _buildRoleBadge(role),
          const SizedBox(height: 16),
          
          // -------------------------------------------------------------------
          // Join Date
          // -------------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 8),
              Text(
                'Member since $dateJoined',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // -------------------------------------------------------------------
          // Stats Cards
          // -------------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatCard('Posts', totalPosts.toString(), Icons.article),
              const SizedBox(width: 24),
              _buildStatCard('Replies', totalReplies.toString(), Icons.reply),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a stat card widget (for posts count, replies count)
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the Posts tab content
  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.username} hasn\'t created any forum posts.',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildPostCard(post);
      },
    );
  }

  /// Build the Replies tab content
  Widget _buildRepliesTab() {
    if (_replies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reply_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No replies yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.username} hasn\'t replied to any posts.',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _replies.length,
      itemBuilder: (context, index) {
        final reply = _replies[index];
        return _buildReplyCard(reply);
      },
    );
  }

  /// Build a post card for the Posts tab
  /// Tapping navigates to the full post detail page
  Widget _buildPostCard(Map<String, dynamic> post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to the post detail page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForumDetailPage(postId: post['id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -----------------------------------------------------------------
              // Post Title and Pinned Status
              // -----------------------------------------------------------------
              Row(
                children: [
                  // Pinned indicator
                  if (post['is_pinned'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, size: 12, color: Colors.orange[800]),
                          const SizedBox(width: 4),
                          Text(
                            'Pinned',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Text(
                      post['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // -----------------------------------------------------------------
              // Post Content Preview
              // -----------------------------------------------------------------
              Text(
                post['content'] ?? '',
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // -----------------------------------------------------------------
              // Category Chips
              // -----------------------------------------------------------------
              Wrap(
                spacing: 8,
                children: [
                  if (post['category_display'] != null)
                    _buildCategoryChip(post['category_display']),
                  if (post['sport_category_display'] != null)
                    _buildCategoryChip(post['sport_category_display']),
                ],
              ),
              const SizedBox(height: 12),
              
              // -----------------------------------------------------------------
              // Post Stats (views, likes, replies, date)
              // -----------------------------------------------------------------
              Row(
                children: [
                  Icon(Icons.visibility, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${post['post_views'] ?? 0}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.favorite, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${post['like_count'] ?? 0}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.reply, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${post['reply_count'] ?? 0}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  Text(
                    post['created_at'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a reply card for the Replies tab
  /// Tapping navigates to the original post
  Widget _buildReplyCard(Map<String, dynamic> reply) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to the original post
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForumDetailPage(postId: reply['post_id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -----------------------------------------------------------------
              // Original Post Title
              // -----------------------------------------------------------------
              Row(
                children: [
                  Icon(Icons.reply, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    'Reply to:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                reply['post_title'] ?? 'Unknown Post',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D4ED8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // -----------------------------------------------------------------
              // Reply Content Preview
              // -----------------------------------------------------------------
              Text(
                reply['content'] ?? '',
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // -----------------------------------------------------------------
              // Reply Date
              // -----------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    reply['created_at'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a small category chip
  Widget _buildCategoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  // ===========================================================================
  // Helper Methods
  // ===========================================================================

  /// Build a role badge widget
  Widget _buildRoleBadge(String role) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (role) {
      case 'ADMIN':
        bgColor = Colors.red[400]!;
        textColor = Colors.white;
        label = 'Administrator';
        icon = Icons.admin_panel_settings;
        break;
      case 'SELLER':
        bgColor = Colors.green[400]!;
        textColor = Colors.white;
        label = 'Seller';
        icon = Icons.storefront;
        break;
      case 'FACILITY_ADMIN':
        bgColor = Colors.blue[400]!;
        textColor = Colors.white;
        label = 'Facility Admin';
        icon = Icons.business;
        break;
      default:
        bgColor = Colors.grey[400]!;
        textColor = Colors.white;
        label = 'Member';
        icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Get avatar background color based on role
  Color _getAvatarColor(String role) {
    switch (role) {
      case 'ADMIN':
        return Colors.red[600]!;
      case 'SELLER':
        return Colors.green[600]!;
      case 'FACILITY_ADMIN':
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

// =============================================================================
// Helper Delegate for Sticky Tab Bar
// =============================================================================
// This delegate keeps the tab bar pinned at the top when scrolling
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
