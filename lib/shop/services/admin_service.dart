// lib/shop/services/admin_service.dart
import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class AdminService {
  final CookieRequest request;
  final String baseUrl;

  AdminService(this.request, this.baseUrl);

  /// Load dataset cycling
  Future<Map<String, dynamic>> loadDatasetCycling() async {
    try {
      final response = await request.get('$baseUrl/shop/load-dataset-cycling/');
      return {
        'success': true,
        'message': response['message'] ?? 'Dataset loaded',
        'count': (response['products'] as List?)?.length ?? 0,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to load cycling dataset: $e'};
    }
  }

  /// Load dataset running
  Future<Map<String, dynamic>> loadDatasetRunning() async {
    try {
      final response = await request.get('$baseUrl/shop/load-dataset-running/');
      return {
        'success': true,
        'message': response['message'] ?? 'Dataset loaded',
        'count': (response['products'] as List?)?.length ?? 0,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to load running dataset: $e'};
    }
  }

  /// Load dataset swimming
  Future<Map<String, dynamic>> loadDatasetSwimming() async {
    try {
      final response = await request.get('$baseUrl/shop/load-dataset-swimming/');
      return {
        'success': true,
        'message': response['message'] ?? 'Dataset loaded',
        'count': (response['products'] as List?)?.length ?? 0,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to load swimming dataset: $e'};
    }
  }

  /// Delete all products
  Future<Map<String, dynamic>> deleteAllProducts() async {
    try {
      final response = await request.post('$baseUrl/shop/delete-all-products/', {});
      return {
        'success': response['status'] == 'success',
        'message': response['message'] ?? 'Products deleted',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete products: $e'};
    }
  }

  /// Admin delete specific product
  Future<Map<String, dynamic>> adminDeleteProduct(String productId) async {
    try {
      final response = await request.post(
        '$baseUrl/shop/api/products/$productId/delete/',
        {},
      );
      return {
        'success': response['status'] == 'success',
        'message': response['message'] ?? 'Product deleted',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete product: $e'};
    }
  }

  /// Admin edit product
  Future<Map<String, dynamic>> adminEditProduct(
      String productId,
      Map<String, dynamic> data,
      ) async {
    try {
      final response = await request.post(
        '$baseUrl/shop/api/products/$productId/edit/',
        data,
      );
      return {
        'success': response['status'] == 'success',
        'message': response['message'] ?? 'Product updated',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to update product: $e'};
    }
  }
}