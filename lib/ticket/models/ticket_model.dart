// lib/ticket/models/ticket_model.dart
import '../../models/place.dart'; 

// Utility class for parsing
class ParseUtils {
  static int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

// User & Profile Model
class User {
  final int id;
  final String username;
  final String email;
  final Profile? profile;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: ParseUtils.toInt(json['id']),
      username: json['username']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
      profile: json['profile'] != null ? Profile.fromJson(json['profile']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile': profile?.toJson(),
    };
  }
}

class Profile {
  final int id;
  final String? role;
  final String? phoneNumber;

  Profile({
    required this.id,
    this.role,
    this.phoneNumber,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: ParseUtils.toInt(json['id']),
      role: json['role']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'phone_number': phoneNumber,
    };
  }

  bool isAdmin() {
    return role?.toLowerCase() == 'admin';
  }
}

// Ticket Model
class Ticket {
  final int id;
  final String customerName;
  final Place place;
  final DateTime bookingDate;
  final int ticketQuantity;
  final double totalPrice;
  final User? user;

  Ticket({
    required this.id,
    required this.customerName,
    required this.place,
    required this.bookingDate,
    required this.ticketQuantity,
    required this.totalPrice,
    this.user,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    // Handling jika Place berbentuk Map (Object) atau Null
    // Jika API error dan place null, kita buat dummy place agar aplikasi tidak crash
    Place parsedPlace;
    if (json['place'] != null && json['place'] is Map<String, dynamic>) {
       parsedPlace = Place.fromJson(json['place']);
    } else {
       // Placeholder jika data place rusak/hanya ID
       parsedPlace = Place(
         id: 0, 
         name: 'Unknown Place', 
         price: '0', 
         description: '', 
         city: '', 
         genre: ''
       );
    }

    return Ticket(
      id: ParseUtils.toInt(json['id']),
      customerName: json['customer_name']?.toString() ?? 'No Name',
      place: parsedPlace,
      bookingDate: DateTime.tryParse(json['booking_date'].toString()) ?? DateTime.now(),
      ticketQuantity: ParseUtils.toInt(json['ticket_quantity']),
      totalPrice: ParseUtils.toDouble(json['total_price']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_name': customerName,
      'place': place.toJson(),
      'booking_date': bookingDate.toIso8601String().split('T')[0],
      'ticket_quantity': ticketQuantity,
      'total_price': totalPrice,
      'user': user?.toJson(),
    };
  }

  String getStatus() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final ticketDate = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);

    if (ticketDate.isBefore(todayDate)) {
      return 'past';
    } else if (ticketDate.isAtSameMomentAs(todayDate)) {
      return 'today';
    } else {
      return 'upcoming';
    }
  }
}

// Ticket Request untuk membuat/mengedit tiket
class TicketRequest {
  final String customerName;
  final int placeId;
  final String bookingDate;
  final int ticketQuantity;

  TicketRequest({
    required this.customerName,
    required this.placeId,
    required this.bookingDate,
    required this.ticketQuantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_name': customerName,
      'place': placeId, 
      'booking_date': bookingDate,
      'ticket_quantity': ticketQuantity,
    };
  }
}