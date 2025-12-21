import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/user_profile/models/admin_model.dart';

class AdminEditUserScreen extends StatefulWidget {
  final AdminUserListItemModel user;

  const AdminEditUserScreen({
    super.key,
    required this.user,
  });

  @override
  State<AdminEditUserScreen> createState() => _AdminEditUserScreenState();
}

class _AdminEditUserScreenState extends State<AdminEditUserScreen> {
  static const adminRed = Color(0xFFD32F2F);
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late String _selectedRole;

  final List<Map<String, String>> _roles = [
    {'value': 'USER', 'display': 'User'},
    {'value': 'SELLER', 'display': 'Seller'},
    {'value': 'FACILITY_ADMIN', 'display': 'Facility Administrator'},
    {'value': 'ADMIN', 'display': 'Admin'},
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _selectedRole = widget.user.roleValue;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // --- UI HELPERS ---

  InputDecoration _buildInputDecoration({
    required String label, 
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: adminRed.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: adminRed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN': return adminRed;
      case 'SELLER': return Colors.green.shade700;
      case 'FACILITY_ADMIN': return Colors.orange.shade800;
      default: return Colors.blue.shade700;
    }
  }

  // --- ANIMATED SECTION WRAPPER ---
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final request = context.read<CookieRequest>();
    
    try {
      final response = await request.post(
        '$baseUrl/profile/api/admin/update/',
        {
          'user_id': widget.user.id.toString(),
          'username': _usernameController.text,
          'email': _emailController.text,
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'phone_number': _phoneController.text,
          'bio': _bioController.text,
          'role': _selectedRole,
        },
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? 'Update failed'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Edit User', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: adminRed,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Decor
          Container(height: 100, color: adminRed),
          
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              children: [
                // 1. Profile Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'user-avatar-${widget.user.id}',
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: _getRoleColor(_selectedRole).withOpacity(0.1),
                          child: Text(
                            widget.user.username.substring(0, 2).toUpperCase(),
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _getRoleColor(_selectedRole)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(widget.user.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('User ID: #${widget.user.id}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // 2. Account Information Section
                _buildSection('Account Info', [
                  TextFormField(
                    controller: _usernameController,
                    decoration: _buildInputDecoration(label: 'Username', icon: Icons.person_outline),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: _buildInputDecoration(label: 'Email Address', icon: Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: _buildInputDecoration(label: 'Account Role', icon: Icons.admin_panel_settings_outlined),
                    items: _roles.map((r) => DropdownMenuItem(
                      value: r['value'], 
                      child: Text(r['display']!, style: TextStyle(color: _getRoleColor(r['value']!))),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedRole = v!),
                  ),
                ]),

                const SizedBox(height: 24),

                // 3. Personal Details Section
                _buildSection('Personal Details', [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: _buildInputDecoration(label: 'First Name', icon: Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: _buildInputDecoration(label: 'Last Name', icon: Icons.badge_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: _buildInputDecoration(label: 'Phone Number', icon: Icons.phone_android_outlined),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: _buildInputDecoration(label: 'Biography', icon: Icons.description_outlined, hint: 'Tell us something about the user...'),
                  ),
                ]),

                const SizedBox(height: 32),

                // 4. Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: adminRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('UPDATE PROFILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Discard Changes', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}