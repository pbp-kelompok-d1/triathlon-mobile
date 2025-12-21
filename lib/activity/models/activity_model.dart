import 'dart:convert';

class Activity {
  String id;
  String title;
  String duration; // "HH:MM:SS"
  int distance;
  String notesShort;
  String notesFull;
  String sportCategory;
  String sportLabel;
  double caloriesBurned;
  String doneAtIso;
  String doneAtDisplay;
  int? placeId;
  String? placeName;
  String creatorUsername;

  Activity({
    required this.id,
    required this.title,
    required this.duration,
    required this.distance,
    required this.notesShort,
    required this.notesFull,
    required this.sportCategory,
    required this.sportLabel,
    required this.caloriesBurned,
    required this.doneAtIso,
    required this.doneAtDisplay,
    this.placeId,
    this.placeName,
    required this.creatorUsername,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: json["id"],
        title: json["title"],
        duration: json["duration"],
        distance: json["distance"],
        notesShort: json["notes_short"],
        notesFull: json["notes_full"],
        sportCategory: json["sport_category"],
        sportLabel: json["sport_label"],
        caloriesBurned: json["calories_burned"]?.toDouble(),
        doneAtIso: json["done_at_iso"],
        doneAtDisplay: json["done_at_display"],
        placeId: json["place_id"],
        placeName: json["place_name"],
        creatorUsername: json["creator_username"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "duration": duration,
        "distance": distance,
        "notes_short": notesShort,
        "notes_full": notesFull,
        "sport_category": sportCategory,
        "sport_label": sportLabel,
        "calories_burned": caloriesBurned,
        "done_at_iso": doneAtIso,
        "done_at_display": doneAtDisplay,
        "place_id": placeId,
        "place_name": placeName,
        "creator_username": creatorUsername,
      };
}

List<Activity> activityFromJson(String str) =>
    List<Activity>.from(json.decode(str).map((x) => Activity.fromJson(x)));

String activityToJson(List<Activity> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
