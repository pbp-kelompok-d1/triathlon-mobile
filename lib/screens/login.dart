import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import 'menu.dart';
import 'register.dart';

const Color primaryBlue = Color(0xFF433BFF);
const Color accentRed = Color(0xFFFF4136);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool rememberMe = false;

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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    );
  }

  // Helper widget untuk ikon sosial (asumsi path ikon sudah benar)
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

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Hapus AppBar standar
      body: Stack(
        children: [
          // 1. Gambar/Background Header (Menggunakan gaya Onboarding Halaman 2)
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            height: size.height * 0.50, 
            child: Container(
              decoration: BoxDecoration(
                // Rounded corner di bawah
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30.0),
                  bottomRight: Radius.circular(30.0),
                ),
                image: DecorationImage(
                  image: const AssetImage('assets/images/onboarding_bg.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  opacity: 0.7, // Opacity agar terlihat jelas
                ),
                // Gradient yang sama dengan Onboarding Halaman 2
                gradient: const LinearGradient(
                  colors: [primaryBlue, Color(0xFF282399)], 
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // 2. Card Form Login (Di bagian bawah)
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
                    const SizedBox(height: 30.0),

                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      decoration: _inputDecoration('Username'),
                    ),
                    const SizedBox(height: 15.0),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecoration('Password'),
                      obscureText: true,
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
                              onChanged: (val) {
                                setState(() {
                                  rememberMe = val!;
                                });
                              },
                            ),
                            const Text('Remember Me'),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
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
                      onPressed: () async {
                        String username = _usernameController.text;
                        String password = _passwordController.text;

                        final response = await request.login(
                            '$baseUrl/auth/login/',
                            ({"username": username, "password": password}));
                      
                        if (request.loggedIn) {
                          String message = response['message'];
                          String uname = response['username'];
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => MyHomePage()),
                            );
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(content: Text("$message Welcome, $uname.")),
                              );
                          }
                        } else {
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Login Failed', style: TextStyle(
                                    color: accentRed, 
                                    fontSize: 20, 
                                    fontWeight: FontWeight.bold) 
                                    ),
                                shadowColor: Color(0xFF433BFF),
                                backgroundColor: Colors.white,
                                content: Text(response['message']),
                                actions: [
                                  TextButton(
                                    child: const Text('OK', style: TextStyle(color: primaryBlue)),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
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
                      child: const Text('Sign In', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 20.0),

                    // Sign in with
                    const Text('Sign in with', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 15.0),

                    // Social Media Icons (Ganti path aset jika berbeda)
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage()),
                            );
                          },
                          child: const Text(
                            'Register here',
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
        ],
      ),
    );
  }
}