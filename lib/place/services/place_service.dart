import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:triathlon_mobile/place/models/place.dart';
import 'package:triathlon_mobile/place/models/review.dart';
import 'package:triathlon_mobile/constants.dart';

class PlaceService {
  Future<List<Place>> fetchPlaces() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/place/api/places/'));

      if (response.statusCode == 200) {
        return placeFromJson(response.body);
      } else {
        throw Exception('Gagal memuat data. Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error koneksi: $e');
    }
  }
  
  Future<List<Review>> fetchReviews(int placeId) async {
    final response = await http.get(Uri.parse('$baseUrl/place/api/places/$placeId/reviews/'));

    if (response.statusCode == 200) {
      return reviewFromJson(response.body);
    } else {
      throw Exception('Gagal load review');
    }
  }
}