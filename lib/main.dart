import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'screens/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
  return Provider<CookieRequest>(
      create: (_) => CookieRequest(),
      child: MaterialApp(
        title: 'Kosinduy YNWA Shop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFCE1126),
            primary: const Color(0xFFCE1126),
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