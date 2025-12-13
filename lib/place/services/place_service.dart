import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:triathlon_mobile/place/models/place.dart';
import 'package:triathlon_mobile/place/models/review.dart';
import 'package:flutter/foundation.dart'; 

class PlaceService {
  static const String baseUrl = 'http://127.0.0.1:8000/place/api/places/';

  Future<List<Place>> fetchPlaces() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

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

    String domain = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
    final response = await http.get(Uri.parse('$domain/place/api/places/$placeId/reviews/'));

    if (response.statusCode == 200) {
      return reviewFromJson(response.body);
    } else {
      throw Exception('Gagal load review');
    }
  }
}