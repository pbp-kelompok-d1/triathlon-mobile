import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:triathlon_mobile/place/models/place.dart';
import 'package:triathlon_mobile/place/models/review.dart';
import 'package:triathlon_mobile/place/models/province_stat.dart';
import 'package:triathlon_mobile/constants.dart';

class PlaceService {
  Future<List<Place>> fetchPlaces() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/place/api/places/'));

      if (response.statusCode != 200) {
        throw Exception('Gagal memuat data. Error: ${response.statusCode}');
      }

      final body = response.body.trim();
      if (body.startsWith('<')) {
        throw Exception('Server tidak mengirim JSON places');
      }

      try {
        return placeFromJson(body);
      } catch (e) {
        throw Exception('Gagal parse places: $e');
      }
    } catch (e) {
      throw Exception('Error koneksi: $e');
    }
  }
  
  Future<List<Review>> fetchReviews(int placeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/place/api/places/$placeId/reviews/'));

      if (response.statusCode != 200) {
        throw Exception('Gagal load review: ${response.statusCode}');
      }

      final body = response.body.trim();
      if (body.startsWith('<')) {
        throw Exception('Server tidak mengirim JSON review');
      }

      return reviewFromJson(body);
    } catch (e) {
      throw Exception('Gagal parse review: $e');
    }
  }

  Future<List<ProvinceStat>> fetchProvinceStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/place/api/province-stats/'));

      if (response.statusCode == 404) {
        // Endpoint doesn't exist - return empty list instead of throwing
        return [];
      }

      if (response.statusCode != 200) {
        throw Exception('Gagal memuat statistik provinsi: ${response.statusCode}');
      }

      final body = response.body.trim();
      if (body.startsWith('<')) {
        // HTML response means endpoint not available
        return [];
      }

      return provinceStatFromJson(body);
    } catch (e) {
      // Return empty list on error to prevent UI crash
      return [];
    }
  }
}