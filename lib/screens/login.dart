import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triathlon_mobile/user_profile/models/user_profile_model.dart';

import '../constants.dart';
import 'menu.dart';
import 'register.dart';

const Color primaryBlue = Color(0xFF433BFF);
const Color accentRed = Color(0xFFFF4136);
const String roleKey = 'user_role'; 
const String isLoggedInKey = 'is_logged_in';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool rememberMe = false;
  bool _isLoading = false;

  Future<void> _saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(roleKey, role);
    await prefs.setBool(isLoggedInKey, true);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    );
  }

  Widget _buildSocialIcon(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Image.asset(assetPath, height: 30, width: 30), 
    );
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter username and password'),
          backgroundColor: accentRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final request = context.read<CookieRequest>();
    String username = _usernameController.text;
    String password = _passwordController.text;

    try {
      // 1. Login ke Django
      final response = await request.login(
        '$baseUrl/auth/login/',
        {"username": username, "password": password},
      );
    
      if (request.loggedIn) {
        // 2. Setelah login berhasil, LANGSUNG fetch profile data
        try {
          final profileResponse = await request.get('$baseUrl/profile/api/current-user/');
          
          if (profileResponse != null && mounted) {
            // 3. Parse dan simpan ke UserProfileData
            final userData = profileResponse['user'];
            
            // 4. Simpan role ke SharedPreferences
            if (userData != null) {
            // Parse data dari dalam 'user'
            final profile = UserProfileBaseModel.fromJson(userData);
            
            // Simpan ke Global State
            UserProfileData.setFromModel(profile);
            
            // Simpan role ke SharedPreferences
            await _saveUserRole(profile.role);

              if (mounted) {
                String message = response['message'] ?? 'Login successful';
                
                // 5. Navigate ke home
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
                
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('$message Welcome, ${profile.username}!'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
              }
            } else {
              print("Key 'user' tidak ditemukan dalam response");
            }
          }
        } catch (profileError) {
          // Jika fetch profile gagal, tetap arahkan ke home tapi dengan data minimal
          print('Error fetching profile: $profileError');
          
          // Fallback: gunakan data dari login response
          String uname = response['username'] ?? username;
          String role = response['role'] ?? 'USER';
          String email = response['email'] ?? '';

          await _saveUserRole(role);
          UserProfileData.setUserData(
            newUsername: uname,
            newRole: role,
            newEmail: email,
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MyHomePage()),
            );
            
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Welcome, $uname!'),
                  backgroundColor: Colors.green,
                ),
              );
          }
        }
      } else {
        // Login gagal
        if (mounted) {
          setState(() => _isLoading = false);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: const [
                  Icon(Icons.error_outline, color: accentRed, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Login Failed',
                    style: TextStyle(
                      color: accentRed,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                response['message'] ?? 'Invalid username or password',
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Header
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            height: size.height * 0.50, 
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
                  colors: [primaryBlue, Color(0xFF282399)], 
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // Form Login Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 30.0),

                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      decoration: _inputDecoration('Username'),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 15.0),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecoration('Password'),
                      obscureText: true,
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 10.0),

                    // Remember Me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: _isLoading
                                  ? null
                                  : (val) {
                                      setState(() {
                                        rememberMe = val!;
                                      });
                                    },
                              activeColor: primaryBlue,
                            ),
                            const Text('Remember Me'),
                          ],
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : () {},
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: primaryBlue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),

                    // Sign In Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: primaryBlue,
                        disabledBackgroundColor: primaryBlue.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: _isLoading ? 0 : 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20.0),

                    // Sign in with
                    const Text(
                      'Sign in with',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 15.0),

                    // Social Media Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialIcon('assets/images/google_icon.png'),
                        const SizedBox(width: 15),
                        _buildSocialIcon('assets/images/x_icon.png'),
                        const SizedBox(width: 15),
                        _buildSocialIcon('assets/images/facebook_icon.png'),
                        const SizedBox(width: 15),
                        _buildSocialIcon('assets/images/apple_icon.png'),
                      ],
                    ),
                    const SizedBox(height: 30.0),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have account?"),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterPage(),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Register here',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}