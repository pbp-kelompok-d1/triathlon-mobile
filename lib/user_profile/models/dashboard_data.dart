// Import model dari folder /models lain (sesuai struktur teman Anda)
import '../../forum/models/forum_post.dart';
import '../../forum/models/forum_reply.dart';
import '../../shop/models/product.dart';
import '../../ticket/models/ticket_model.dart' show Place, Ticket; // Ambil Place dan Ticket

class DashboardData {
  final String role;
  final String view;
  
  // Data for USER & SELLER
  final List<ForumPost> posts;

  // Data for USER
  final List<ForumReply> replies;
  final List<Product> wishlistProducts; 

  // Data for SELLER
  final List<Product> sellerProducts; // Note: Di Django kita sebut 'products'

  // Data for FACILITY_ADMIN
  final List<Place> facilities;
  final List<Ticket> tickets;
  final double totalRevenueAmount;
  final int totalTicketQuantity;

  DashboardData({
    required this.role,
    required this.view,
    this.posts = const [],
    this.replies = const [],
    this.wishlistProducts = const [],
    this.sellerProducts = const [],
    this.facilities = const [],
    this.tickets = const [],
    this.totalRevenueAmount = 0.0,
    this.totalTicketQuantity = 0,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // Pastikan kita mengambil dari key 'data' dari respons Django
    final data = json['data'] as Map<String, dynamic>; 

    // --- Perhatian Parsing Content ---
    // Di API Django kita: content_snippet
    // Di model ForumPost teman Anda: content
    // Kita perlu mapping, atau asumsikan backend mengirim data yang benar
    
    // --- Parsing Helper ---
    List<T> parseList<T>(List? rawList, T Function(Map<String, dynamic>) fromJsonConverter) {
      return rawList
          ?.whereType<Map<String, dynamic>>()
          .map(fromJsonConverter)
          .toList() ?? [];
    }

    return DashboardData(
      role: data['role'] ?? 'USER',
      view: data['view'] ?? 'all',
      
      // 1. Posts (USER & SELLER)
      posts: parseList<ForumPost>(data['posts'] as List?, ForumPost.fromJson),

      // 2. Replies (USER)
      replies: parseList<ForumReply>(data['replies'] as List?, ForumReply.fromJson),

      // 3. Wishlist Products (USER)
      wishlistProducts: parseList<Product>(data['wishlist_products'] as List?, Product.fromJson),
          
      // 4. Seller Products (SELLER)
      sellerProducts: parseList<Product>(data['products'] as List?, Product.fromJson),
          
      // 5. Facilities (FACILITY_ADMIN)
      facilities: parseList<Place>(data['facilities'] as List?, Place.fromJson),
          
      // 6. Tickets (FACILITY_ADMIN)
      tickets: parseList<Ticket>(data['tickets'] as List?, Ticket.fromJson),

      // 7. Stats (FACILITY_ADMIN)
      totalRevenueAmount: (data['total_revenue_amount'] as num?)?.toDouble() ?? 0.0,
      totalTicketQuantity: data['total_ticket_quantity'] ?? 0,
    );
  }
}