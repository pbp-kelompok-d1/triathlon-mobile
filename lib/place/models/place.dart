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

    Place({
        required this.id,
        required this.name,
        this.description, // Hapus 'required' untuk yang boleh null
        this.city,
        this.province,
        this.genre,
        required this.price,
        this.image,
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
        image: json["image"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "city": city,
        "province": province,
        "genre": genre,
        "price": price,
        "image": image,
    };
}