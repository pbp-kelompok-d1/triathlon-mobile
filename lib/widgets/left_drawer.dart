import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../screens/login.dart';
import '../screens/menu.dart';
import '../screens/product_form.dart';
import '../screens/product_list.dart';
import '../forum/screens/forum_list.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
  // Reuse the same CookieRequest that login.dart seeded so logout works consistently.
  final request = context.read<CookieRequest>();

    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF1D4ED8),
            ),
            child: Column(
              children: [
                Text(
                  'Triathlon Gear Hub',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Padding(padding: EdgeInsets.all(8)),
                Text(
                  "Curate, list, and track your endurance gear in one place.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyHomePage(),
                  ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('All Gear'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListPage(mode: ProductListMode.all),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('My Gear'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListPage(mode: ProductListMode.mine),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle),
            title: const Text('List New Gear'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductFormPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.forum),
            title: const Text('Forum'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ForumListPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              // Calling the Django logout endpoint clears both session + cookies in one go.
              final response = await request.logout('$baseUrl/auth/logout/');

              if (!context.mounted) return;

              String logoutMessage = 'Logged out';
              if (response['message'] != null) {
                logoutMessage = response['message'];
              }

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(logoutMessage),
                  ),
                );

              // Drop the entire navigation stack so the login screen is the only page left.
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}