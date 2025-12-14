import 'dart:convert';

List<ProvinceStat> provinceStatFromJson(String str) =>
    List<ProvinceStat>.from(json.decode(str).map((x) => ProvinceStat.fromJson(x)));

String provinceStatToJson(List<ProvinceStat> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ProvinceStat {
  final String province;
  final int venueCount;
  final String? image;

  ProvinceStat({required this.province, required this.venueCount, this.image});

  factory ProvinceStat.fromJson(Map<String, dynamic> json) => ProvinceStat(
        province: json['province'] ?? '-',
        venueCount: int.tryParse(
              (json['count'] ?? json['total'] ?? json['venue_count'] ?? json['venues'] ?? '0').toString(),
            ) ??
            0,
        image: (json['image_url'] ?? json['image'])?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'province': province,
        'count': venueCount,
        'image_url': image,
      };
}
