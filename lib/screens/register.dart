import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import 'login.dart';

const Color primaryBlue = Color(0xFF433BFF);
const Color darkBlue = Color(0xFF282399);
const Color accentRed = Color(0xFFFF4136);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>(); 
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled; 
  
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool agreeToTerms = false;
  String? selectedRole;
  final List<Map<String, String>> roles = [
    {"label": "User", "value": "USER"},
    {"label": "Seller", "value": "SELLER"},
    {"label": "Admin", "value": "ADMIN"},
    {"label": "Facility Administrator", "value": "FACILITY_ADMIN"},
  ];

  // Helper function untuk InputDecoration yang konsisten
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: primaryBlue),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: accentRed),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Gambar/Background Header
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            height: size.height * 0.40,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30.0),
                  bottomRight: Radius.circular(30.0),
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/images/onboarding_bg.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  opacity: 0.7, 
                ),
                gradient: const LinearGradient(
                  colors: [primaryBlue, darkBlue], 
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // 2. Card Form Register
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.75, 
              padding: const EdgeInsets.all(0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidateMode,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 30.0),

                      // 1. Username Field
                      TextFormField(
                        controller: _usernameController,
                        decoration: _inputDecoration('Username'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),

                      // 2. Role Dropdown 
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Role'),
                        value: selectedRole,
                        items: roles.map((role) {
                          return DropdownMenuItem(
                            value: role["value"],
                            child: Text(role["label"]!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() { selectedRole = value; });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a role.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),

                      // 3. Email Field 
                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration('Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email.';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),

                      // 4. Phone Number Field 
                      TextFormField(
                        controller: _phoneController,
                        decoration: _inputDecoration('Phone Number'),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number.';
                          }
                          if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value)) {
                            return 'Enter a valid phone number.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),

                      // 5. Password Field 
                      TextFormField(
                        controller: _passwordController,
                        decoration: _inputDecoration('Password'),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password.';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),

                      // 6. Confirm Password Field 
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: _inputDecoration('Confirm Password'),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password.';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Checkbox Agreement
                      Row(
                        children: [
                          Checkbox(
                            value: agreeToTerms,
                            onChanged: (value) {
                              setState(() { agreeToTerms = value ?? false; });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "I hereby declare that all data and information provided is correct.",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24.0),
                      
                      // Register Button
                      ElevatedButton(
                        onPressed: () async {                            
                            // Cek validasi form
                            if (!_formKey.currentState!.validate()) {
                                // Tampilkan pesan jika validasi field gagal
                                setState(() {
                                  _autovalidateMode = AutovalidateMode.always;
                                });
                                return;
                            }

                            if (!agreeToTerms) {
                                // Tampilkan pesan jika checkbox tidak dicentang
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please agree to the terms.')),
                                );
                                return;
                            }
                          
                            // Lanjutkan jika valid
                            String username = _usernameController.text;
                            String password1 = _passwordController.text;
                            String password2 = _confirmPasswordController.text;
                            String email = _emailController.text;
                            String phone = _phoneController.text;
                            String? role = selectedRole;
                  
                            final response = await request.postJson(
                                '$baseUrl/auth/register/',
                                jsonEncode({
                                  "username": username,
                                  if (password1 == password2) "password": password1,
                                  "email": email,
                                  "phone_number": phone,
                                  "role": role,
                                }));

                            if (context.mounted) {
                              if (response['status'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Successfully registered!')),
                                );
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginPage()),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to register! ${response['message']}')),
                                );
                              }
                            }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: const Text('Register', style: TextStyle(fontSize: 18)),
                      ),
                      
                      // Link to Login Page
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterPage()),
                              );
                            },
                            child: const Text(
                              'Sign In Here',
                              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}