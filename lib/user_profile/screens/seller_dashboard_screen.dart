import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Import intl

import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/user_profile/models/dashboard_data.dart';
import 'package:triathlon_mobile/user_profile/screens/edit_profile_screen.dart';
import 'package:triathlon_mobile/shop/models/product.dart';
import 'package:triathlon_mobile/forum/models/forum_post.dart';

// --- IMPORT NAVIGASI ---
import 'package:triathlon_mobile/forum/screens/forum_detail.dart';
import 'package:triathlon_mobile/forum/screens/forum_form.dart';
import 'package:triathlon_mobile/shop/screens/product_detail.dart';
import 'package:triathlon_mobile/shop/screens/product_form.dart'; // Pastikan file ini ada

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  
  String _selectedView = 'all';
  String _selectedCategory = '';
  bool _isLoading = true;
  DashboardData? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // --- HELPERS FORMATTER ---
  
  String _formatCurrency(double price) {
    return NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp ', 
      decimalDigits: 0
    ).format(price);
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown Date';
    try {
      final DateTime date = DateTime.parse(dateString).toLocal();
      return DateFormat('d MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // --- NAVIGATION ---

  void _navigateToPostDetail(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForumDetailPage(postId: postId)),
    ).then((_) => _fetchDashboardData());
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductDetailPage(product: product)),
    ).then((_) => _fetchDashboardData());
  }

  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForumFormPage()),
    ).then((_) => _fetchDashboardData());
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductFormPage()),
    ).then((_) => _fetchDashboardData());
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    final request = context.read<CookieRequest>();
    
    try {
      final url = '$baseUrl/profile/api/dashboard/?view=$_selectedView&category=$_selectedCategory';
      final response = await request.get(url);
      
      if (response != null) {
        setState(() {
          _dashboardData = DashboardData.fromJson(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: primaryGreen,
        child: CustomScrollView(
          slivers: [
            // SLIVER APP BAR
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: primaryGreen,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Seller Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryGreen,
                        const Color(0xFF66BB6A),
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
                  tooltip: 'Edit Profile',
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

            // CONTENT
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildFilterSection(),
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: primaryGreen),
                        )
                      : _buildDashboardContent(),
                ],
              ),
            ),
          ],
        ),
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
            'Manage Products & Posts',
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
                _buildViewChip('All', 'all'),
                const SizedBox(width: 8),
                _buildViewChip('My Products', 'products'),
                const SizedBox(width: 8),
                _buildViewChip('My Posts', 'posts'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          DropdownButtonFormField<String>(
            value: _selectedCategory.isEmpty ? null : _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Filter by Sport Category',
              prefixIcon: const Icon(Icons.filter_list_rounded, color: primaryGreen),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryGreen, width: 2),
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
      selectedColor: primaryGreen,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? primaryGreen : Colors.grey.shade300,
        ),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_dashboardData == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No data available')),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (_selectedView == 'all' || _selectedView == 'products')
            _buildProductsSection(),
            
          if (_selectedView == 'all' || _selectedView == 'posts')
            _buildPostsSection(),
            
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- POSTS SECTION ---
  Widget _buildPostsSection() {
    final posts = _dashboardData?.posts ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.article_rounded, color: primaryGreen, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'My Forum Posts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (posts.isEmpty)
          _buildEmptyState(
            icon: Icons.article_outlined,
            title: 'No Posts Found',
            subtitle: 'You haven\'t created any forum posts yet.',
            buttonText: 'Create a Post',
            onButtonPressed: _navigateToCreatePost, 
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) => _animateTask(idx, _buildPostCard(posts[idx])),
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
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag(post.categoryDisplay, primaryGreen),
                  _buildTag(post.sportCategoryDisplay, Colors.blue),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 12),
              // --- DETAIL VIEWS & DATE (ADDED) ---
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

  // --- PRODUCTS SECTION ---
  Widget _buildProductsSection() {
    final products = _dashboardData?.sellerProducts ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag_rounded, color: primaryGreen, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'My Products',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          _buildEmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'No Products Found',
            subtitle: 'You haven\'t added any products yet.',
            buttonText: 'Add a Product', 
            onButtonPressed: _navigateToAddProduct, 
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _animateTask(index, _buildProductCard(products[index]));
                },
              );
            },
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToProductDetail(product),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Hero(
                  tag: 'product-image-${product.id}', 
                  child: product.thumbnail.isNotEmpty
                      ? Image.network(
                          product.thumbnail,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.1),
                          ),
                          child: const Center(
                            child: Icon(Icons.shopping_bag, size: 48, color: primaryGreen),
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatCurrency(product.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
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

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: primaryGreen),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}