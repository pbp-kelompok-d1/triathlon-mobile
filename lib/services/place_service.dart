import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:triathlon_mobile/models/place.dart';
import 'package:triathlon_mobile/models/review.dart';
import 'package:flutter/foundation.dart'; // GANTI 'your_app_name' dengan nama project fluttermu

class PlaceService {
  // Gunakan 10.0.2.2 untuk Emulator Android
  // Gunakan 127.0.0.1 jika lewat Web Browser
  static const String baseUrl = 'http://127.0.0.1:8000/place/api/places/';

  Future<List<Place>> fetchPlaces() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        // Jika server menjawab OK (200), ubah JSON jadi List<Place>
        // Kita pakai fungsi placeFromJson yang ada di model tadi
        return placeFromJson(response.body);
      } else {
        throw Exception('Gagal memuat data. Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error koneksi: $e');
    }
  }
  Future<List<Review>> fetchReviews(int placeId) async {
    // Sesuaikan URL dengan API Django kamu: /api/places/<id>/reviews/
    // Pakai logika IP Address yang sama (10.0.2.2 untuk Emulator, 127.0.0.1 untuk Web)
    // Supaya gampang, kita hardcode cek platform atau oper URL base dari UI.
    // Tapi untuk sekarang, kita asumsi pakai base url yang sama.
    
    // NOTE: Ganti ip sesuai environment (Web/Android) seperti sebelumnya
    // String baseUrl = "http://10.0.2.2:8000"; 
    // String url = "$baseUrl/place/api/places/$placeId/reviews/";
    
    // Biar konsisten dengan Screen List, kita pakai logika IP di screen saja, 
    // tapi karena Service terpisah, kita pakai pendekatan 'kIsWeb' di sini juga bisa.
    // Atau masukkan logic switch IP di sini.
    
    // SEMENTARA KITA PAKAI LOGIKA SEDERHANA:
    // Pastikan import: import 'package:flutter/foundation.dart';
    
    String domain = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
    final response = await http.get(Uri.parse('$domain/place/api/places/$placeId/reviews/'));

    if (response.statusCode == 200) {
      return reviewFromJson(response.body);
    } else {
      throw Exception('Gagal load review');
    }
  }
}