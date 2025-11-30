import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'screens/onboarding_page.dart';

void main() {
  // Bootstraps the app with the shared CookieRequest client so every screen can hit Django.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
  return Provider<CookieRequest>(
      // Provide one CookieRequest globally for authentication + API state.
      create: (_) => CookieRequest(),
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
        home: const OnboardingPage(),
      ),
    );
  }
}