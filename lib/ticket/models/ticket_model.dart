// lib/ticket/models/ticket_model.dart
import 'dart:convert';

// ============ USER & PROFILE ============
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
      id: json['id'],
      username: json['username'],
      email: json['email'],
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
      id: json['id'],
      role: json['role'],
      phoneNumber: json['phone_number'],
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

// ============ PLACE ============
class Place {
  final int id;
  final String name;
  final double price;
  final String? description;
  final String? city;
  final String? genre;

  Place({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.city,
    this.genre,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      name: json['name'],
      price: (json['price'] is int) 
          ? (json['price'] as int).toDouble() 
          : double.parse(json['price'].toString()),
      description: json['description'],
      city: json['city'],
      genre: json['genre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'city': city,
      'genre': genre,
    };
  }
}

// ============ TICKET ============
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
    return Ticket(
      id: json['id'],
      customerName: json['customer_name'],
      place: Place.fromJson(json['place']),
      bookingDate: DateTime.parse(json['booking_date']),
      ticketQuantity: json['ticket_quantity'],
      totalPrice: (json['total_price'] is int)
          ? (json['total_price'] as int).toDouble()
          : double.parse(json['total_price'].toString()),
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

  // Helper untuk mendapatkan status tiket
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

// ============ TICKET REQUEST ============
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