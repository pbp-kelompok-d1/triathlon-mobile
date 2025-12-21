import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Import intl for date & currency formatting

import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/user_profile/screens/edit_profile_screen.dart';
import 'package:triathlon_mobile/forum/models/forum_post.dart';
import 'package:triathlon_mobile/forum/models/forum_reply.dart';
import 'package:triathlon_mobile/shop/models/product.dart';
import 'package:triathlon_mobile/forum/screens/forum_detail.dart';
import 'package:triathlon_mobile/forum/screens/forum_form.dart';
import 'package:triathlon_mobile/forum/screens/forum_list.dart';
import 'package:triathlon_mobile/shop/screens/shop_main.dart';
import 'package:triathlon_mobile/shop/screens/product_detail.dart'; // Tambahkan ini untuk navigasi detail produk

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  static const primaryColor = Color(0xFF433BFF);
  
  String _selectedView = 'all';
  String _selectedCategory = '';
  bool _isLoading = true;
  
  List<ForumPost> _posts = [];
  List<ForumReply> _replies = [];
  List<Product> _wishlistProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // --- HELPER FORMATTERS ---
  
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown Date';
    try {
      final DateTime date = DateTime.parse(dateString).toLocal();
      return DateFormat('d MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Helper untuk format Rupiah (Rp 15.000)
  String _formatCurrency(double price) {
    return NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp ', 
      decimalDigits: 0
    ).format(price);
  }

  // --- NAVIGATION HELPERS ---
  
  void _navigateToPostDetail(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForumDetailPage(postId: postId),
      ),
    ).then((_) => _fetchDashboardData());
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(product: product),
      ),
    ).then((_) => _fetchDashboardData());
  }

  void _navigateToForum() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForumListPage()),
    ).then((_) => _fetchDashboardData());
  }

  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForumFormPage(),
      ),
    ).then((_) => _fetchDashboardData());
  }

  void _navigateToShop() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShopPage()),
    ).then((_) => _fetchDashboardData());
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    
    final request = context.read<CookieRequest>();
    
    try {
      final url = '$baseUrl/profile/api/dashboard/?view=$_selectedView&category=$_selectedCategory';
      final response = await request.get(url);
      
      if (response != null && response['data'] != null && mounted) {
        final data = response['data'];
        setState(() {
          _posts = (data['posts'] as List?)
              ?.map((p) => ForumPost.fromJson(p))
              .toList() ?? [];
          
          _replies = (data['replies'] as List?)
              ?.map((r) => ForumReply.fromJson(r))
              .toList() ?? [];
          
          _wishlistProducts = (data['wishlist_products'] as List?)
              ?.map((p) => Product.fromJson(p))
              .toList() ?? [];
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'User Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  ).then((_) => _fetchDashboardData());
                },
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildFilterSection(),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : _buildDashboardContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _animateTask(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)), // Delay bertahap
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)), // Efek slide up
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Activities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildViewChip('All Activities', 'all'),
                const SizedBox(width: 8),
                _buildViewChip('My Posts', 'posts'),
                const SizedBox(width: 8),
                _buildViewChip('My Replies', 'replies'),
                const SizedBox(width: 8),
                _buildViewChip('My Wishlist', 'wishlist'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          DropdownButtonFormField<String>(
            value: _selectedCategory.isEmpty ? null : _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Filter by Sport Category',
              prefixIcon: const Icon(Icons.filter_list_rounded, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(value: '', child: Text('All Categories')),
              DropdownMenuItem(value: 'swimming', child: Text('Swimming')),
              DropdownMenuItem(value: 'running', child: Text('Running')),
              DropdownMenuItem(value: 'cycling', child: Text('Cycling')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value ?? '';
              });
              _fetchDashboardData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewChip(String label, String value) {
    final isSelected = _selectedView == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedView = value;
        });
        _fetchDashboardData();
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? primaryColor : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 500),
    switchInCurve: Curves.easeOut,
    switchOutCurve: Curves.easeIn,
    // Menambahkan animasi scale dan fade saat filter berubah
    transitionBuilder: (Widget child, Animation<double> animation) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(animation), child: child),
      );
    },
    child: Padding(padding:   const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      key: ValueKey<String>(_selectedView), // Kunci penting agar animasi terpicu
      children: [
        if (_selectedView == 'all' || _selectedView == 'posts') _buildPostsSection(),
        if (_selectedView == 'all' || _selectedView == 'replies') _buildRepliesSection(),
        if (_selectedView == 'all' || _selectedView == 'wishlist') _buildWishlistSection(),
        const SizedBox(height: 40),
      ],
    ),
    )
  );
}

  Widget _buildPostsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.article_rounded, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'My Forum Posts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_posts.isEmpty)
          _buildEmptyState(
            icon: Icons.article_outlined,
            title: 'No Posts Found',
            subtitle: 'You haven\'t created any forum posts yet.',
            actionLabel: 'Create a Post',
            onActionPressed: _navigateToCreatePost,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _posts.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) => _animateTask(idx, _buildPostCard(_posts[idx])),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPostCard(ForumPost post) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToPostDetail(post.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag(post.categoryDisplay, primaryColor),
                  _buildTag(post.sportCategoryDisplay, Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.visibility_rounded, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${post.postViews} views',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time_rounded, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(post.createdAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRepliesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.reply_rounded, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'My Replies',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_replies.isEmpty)
          _buildEmptyState(
            icon: Icons.reply_outlined,
            title: 'No Replies Found',
            subtitle: 'You haven\'t replied to any posts yet.',
            actionLabel: 'Browse Forum',
            onActionPressed: _navigateToForum,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _replies.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) => _animateTask(idx, _buildReplyCard(_replies[idx])),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildReplyCard(ForumReply reply) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (reply.postId.isNotEmpty) {
            _navigateToPostDetail(reply.postId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot find original post')),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.reply, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Replied to: ${reply.postTitle}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: primaryColor, width: 4),
                  ),
                ),
                child: Text(
                  '"${reply.content}"',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(reply.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite_rounded, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'My Wishlist',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_wishlistProducts.isEmpty)
          _buildEmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'Wishlist is Empty',
            subtitle: 'You haven\'t added any products to your wishlist yet.',
            actionLabel: 'Browse Shop',
            onActionPressed: _navigateToShop,
          )
        else
          // RESPONSIF GRID LAYOUT
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.75, // Disesuaikan agar card tidak terlalu panjang
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _wishlistProducts.length,
                itemBuilder: (context, index) {
                  return _animateTask(index, _buildWishlistCard(_wishlistProducts[index]));
                },
              );
            },
          ),
      ],
    );
  }

  // --- UPDATED WISHLIST CARD WITH IMAGE AND FORMATTED PRICE ---
  Widget _buildWishlistCard(Product product) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToProductDetail(product), // Redirect ke Product Detail
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IMAGE SECTION ---
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.thumbnail.isNotEmpty
                    ? Image.network(
                        product.thumbnail,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback jika gambar error/gagal load
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          );
                        },
                      )
                    : Container(
                        // Fallback jika thumbnail kosong
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.shopping_bag_rounded,
                            size: 48,
                            color: primaryColor,
                          ),
                        ),
                      ),
              ),
            ),
            
            // --- DETAILS SECTION ---
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.categoryLabel,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // --- FORMATTED PRICE ---
                  Text(
                    _formatCurrency(product.price), // Pakai helper baru
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      width: double.infinity,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onActionPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}