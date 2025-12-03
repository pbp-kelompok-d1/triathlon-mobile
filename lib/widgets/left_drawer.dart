import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/screens/login.dart';
import 'package:triathlon_mobile/screens/menu.dart';
import '../forum/screens/forum_list.dart';
import '../ticket/screens/ticket_list_page.dart';
import 'package:triathlon_mobile/shop/screens/shop_main.dart';
import 'package:triathlon_mobile/activity/screens/activity_menu.dart';
import 'package:triathlon_mobile/shop/screens/admin_dashboard.dart'; // ← Import admin dashboard

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  Future<bool> _checkIsAdmin(CookieRequest request) async {
    try {
      final response = await request.get('$baseUrl/auth/check-admin/');
      if (response is Map<String, dynamic>) {
        return response['is_admin'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'Triathlon',
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
                  builder: (context) => MyHomePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.nordic_walking_sharp),
            title: const Text('Activity'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActivityMenu(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopify_sharp),
            title: const Text('Shop'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShopPage(),
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
          ListTile(
            leading: const Icon(Icons.confirmation_num),
            title: const Text('My Tickets'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TicketListPage(),
                ),
              );
            },
          ),
          // ✅ ADMIN MENU - Tambahkan ini
          FutureBuilder<bool>(
            future: _checkIsAdmin(request),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink(); // Hide sementara saat loading
              }

              if (snapshot.data == true) {
                return ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.deepPurple,
                  ),
                  title: const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboardPage(),
                      ),
                    );
                  },
                );
              }

              return const SizedBox.shrink(); // Hide jika bukan admin
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
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