// lib/shop/services/wishlist_service.dart
import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/shop/models/product.dart';

class WishlistService {
  final CookieRequest request;

  WishlistService(this.request);

  Future<List<Product>> getWishlist() async {
    final url = '$baseUrl/shop/api/wishlist/';
    final response = await request.get(url);

    if (response is Map<String, dynamic> && response['status'] == 'success') {
      final products = (response['products'] as List?) ?? [];
      return products
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> toggleWishlist(String productId) async {
    final url = '$baseUrl/shop/api/wishlist/toggle/$productId/';
    final response = await request.post(url, {});

    if (response is Map<String, dynamic>) {
      return {
        'success': response['status'] == 'success',
        'message': response['message'] ?? '',
        'inWishlist': response['in_wishlist'] ?? false,
        'count': response['count'] ?? 0,
      };
    }
    return {'success': false, 'message': 'Failed to toggle wishlist'};
  }

  Future<bool> isInWishlist(String productId) async {
    try {
      final url = '$baseUrl/shop/api/wishlist/check/$productId/';
      final response = await request.get(url);

      if (response is Map<String, dynamic>) {
        return response['in_wishlist'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

}
