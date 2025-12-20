import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/place/screens/place_list_screen.dart';
import 'screens/login.dart';
import 'package:triathlon_mobile/place/screens/place_list_screen.dart';

import 'screens/onboarding_page.dart';

void main() {
  // Bootstraps the app with the shared CookieRequest client so every screen can hit Django.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
  return Provider(
      // Provide one CookieRequest globally for authentication + API state.
      create: (_) {
        CookieRequest request = CookieRequest();
        // Enable credentials for web to send cookies (including CSRF token)
        request.init();
        return request;
      },
      child: MaterialApp(
        title: 'Triathlon App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF433BFF),
            primary: const Color(0xFF433BFF),
            secondary: const Color(0xFFFDB913),
            surface: Colors.white,
            onPrimary: Colors.white,
            onSecondary: Colors.black,
          ),
          useMaterial3: true,
        ),
        home: const LoginPage(),
      ),
    );
  }
}