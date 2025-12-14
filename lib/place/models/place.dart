// To parse this JSON data, do
//
//     final place = placeFromJson(jsonString);

import 'dart:convert';

List<Place> placeFromJson(String str) => List<Place>.from(json.decode(str).map((x) => Place.fromJson(x)));

String placeToJson(List<Place> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Place {
    int id;
    String name;
    String? description; // Pakai tanda tanya (?) artinya boleh null
    String? city;
    String? province;
    String? genre; // Ubah jadi String biasa biar aman
    String price; // Harga tetap String (dari JSON)
    String? image; // Image bisa null
    double? averageRating;
    int? reviewCount;
    bool? isFeatured;

    Place({
        required this.id,
        required this.name,
        this.description, // Hapus 'required' untuk yang boleh null
        this.city,
        this.province,
        this.genre,
        required this.price,
        this.image,
        this.averageRating,
        this.reviewCount,
        this.isFeatured,
    });

    factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json["id"],
        name: json["name"],
        // Logika: Jika datanya null, biarkan null. Jika ada, ambil stringnya.
        description: json["description"],
        city: json["city"],
        province: json["province"],
        genre: json["genre"],
        price: json["price"].toString(), // .toString() untuk jaga-jaga kalau backend kirim angka/decimal
        // Backend baru mengirim URL langsung (image_url). Jaga kompatibilitas dengan key lama "image".
        image: (json["image_url"] ?? json["image"])?.toString(),
        averageRating: json["average_rating"] != null
            ? double.tryParse(json["average_rating"].toString())
            : null,
        reviewCount: json["review_count"] != null
            ? int.tryParse(json["review_count"].toString())
            : null,
        isFeatured: json["is_featured"] == null ? null : json["is_featured"] as bool,
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "city": city,
        "province": province,
        "genre": genre,
        "price": price,
        // Kirim dua-duanya untuk kompatibilitas dengan backend lama/baru.
        "image": image,
        "image_url": image,
        "average_rating": averageRating,
        "review_count": reviewCount,
        "is_featured": isFeatured,
    };
}