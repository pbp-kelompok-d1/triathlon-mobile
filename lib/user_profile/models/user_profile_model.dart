/// Class ini bertugas untuk mem-parsing JSON dari response API Django.
/// Digunakan sesaat setelah login atau fetch data.
class UserProfileBaseModel {
  // Data dari Django User
  final String username;
  final String email;

  // Data dari UserProfile (Extension fields)
  final String role;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? bio;
  final String? profilePictureUrl;
  final DateTime? dateJoined;

  UserProfileBaseModel({
    required this.username,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.bio,
    this.profilePictureUrl,
    this.dateJoined,
  });

  factory UserProfileBaseModel.fromJson(Map<String, dynamic> json) {
    // Helper function untuk parsing DateTime yang aman
    DateTime? parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    // Default URL jika profile_picture_url null
    const defaultPictureUrl = 'assets/images/default_profile.png';

    return UserProfileBaseModel(
      // Pastikan key JSON di sini sesuai dengan response dari views.py Django kamu
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'USER',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      bio: json['bio'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String? ?? defaultPictureUrl,
      
      // Cek 'date_joined' atau 'created_at', sesuaikan dengan API
      dateJoined: parseDate(json['date_joined']) ?? parseDate(json['created_at']),
    );
  }

  // Helper untuk mendapatkan nama lengkap (opsional, untuk display sementara)
  String get fullNameDisplay {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    if (first.isEmpty && last.isEmpty) {
      return '@$username';
    }
    return '$first $last'.trim();
  }
}

/// Class ini bertugas menyimpan State Global aplikasi secara statis.
/// Data di sini bisa diakses dari halaman manapun tanpa perlu pass parameter.
class UserProfileData {
  static String username = 'Guest';
  static String email = '';
  static String role = 'GUEST';
  static String firstName = '';
  static String lastName = '';
  static String phoneNumber = '';
  static String bio = '';
  static String profilePictureUrl = '';
  // Jika ingin menyimpan tanggal join juga di global state:
  static DateTime? dateJoined; 

  // Getter untuk Nama Lengkap
  static String get fullName {
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isEmpty && last.isEmpty) {
      return username; // Fallback ke username jika nama kosong
    }
    return '$first $last'.trim();
  }

  static void setFromModel(UserProfileBaseModel model) {
    username = model.username;
    email = model.email;
    role = model.role;
    
    // Konversi null dari model menjadi string kosong agar aman di UI
    firstName = model.firstName ?? '';
    lastName = model.lastName ?? '';
    phoneNumber = model.phoneNumber ?? '';
    bio = model.bio ?? '';
    profilePictureUrl = model.profilePictureUrl ?? '';
    dateJoined = model.dateJoined;
  }

  // Method manual (jika diperlukan update spesifik tanpa API call)
  static void setUserData({
    required String newUsername,
    required String newRole,
    required String newEmail,
    String? newFirstName,
    String? newLastName,
    String? newPhoneNumber,
    String? newBio,
    String? newProfilePictureUrl,
  }) {
    username = newUsername;
    role = newRole;
    email = newEmail;
    firstName = newFirstName ?? '';
    lastName = newLastName ?? '';
    phoneNumber = newPhoneNumber ?? '';
    bio = newBio ?? '';
    profilePictureUrl = newProfilePictureUrl ?? '';
  }

  // Update parsial (misal setelah Edit Profile berhasil)
  static void updateProfile({
    String? newFirstName,
    String? newLastName,
    String? newPhoneNumber,
    String? newBio,
  }) {
    if (newFirstName != null) firstName = newFirstName;
    if (newLastName != null) lastName = newLastName;
    if (newPhoneNumber != null) phoneNumber = newPhoneNumber;
    if (newBio != null) bio = newBio;
  }

  // Reset data saat Logout
  static void clearUserData() {
    username = 'Guest';
    email = '';
    role = 'GUEST';
    firstName = '';
    lastName = '';
    phoneNumber = '';
    bio = '';
    profilePictureUrl = '';
    dateJoined = null;
  }
}