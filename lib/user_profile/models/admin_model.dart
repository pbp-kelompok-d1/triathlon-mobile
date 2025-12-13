class AdminUserListItemModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String roleValue; 
  final String roleDisplay; 
  final String? phoneNumber;
  final String? bio;
  final String joinedDateString; // Disimpan sebagai string karena format dari Django
  
  // Catatan: Jika Anda ingin menyimpan foto profil user lain, Anda perlu menambahkan 'profilePictureUrl' di sini
  // dan pastikan Django Admin API mengirimkan data tersebut.

  AdminUserListItemModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    required this.roleValue,
    required this.roleDisplay,
    this.phoneNumber,
    this.bio,
    required this.joinedDateString,
  });

  // Digunakan untuk parsing list dari endpoint /admin/api/get-user-list/
  factory AdminUserListItemModel.fromJson(Map<String, dynamic> json) {
    // Helper untuk menangani string kosong/null
    String safeString(dynamic v) => (v ?? '').toString();

    return AdminUserListItemModel(
      id: json['id'] as int,
      username: safeString(json['username']),
      email: safeString(json['email']),
      
      firstName: safeString(json['first_name']),
      lastName: safeString(json['last_name']),
      
      // Keys dari admin_update_user_view atau get_admin_user_list_api
      roleValue: safeString(json['role_value'] ?? json['role']), // Ambil role dari salah satu kunci
      roleDisplay: safeString(json['role_display']),
      
      phoneNumber: safeString(json['phone_number']),
      bio: safeString(json['bio']),
      
      // Menggunakan created_at/date_joined yang sudah diformat di Django
      joinedDateString: safeString(json['created_at'] ?? json['date_joined']), 
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}