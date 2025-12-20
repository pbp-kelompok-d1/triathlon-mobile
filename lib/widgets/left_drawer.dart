import 'package:flutter/material.dart';
import 'package:triathlon_mobile/screens/menu.dart';
import 'package:triathlon_mobile/shop/screens/shop_main.dart';
import 'package:triathlon_mobile/activity/screens/activity_menu.dart';
import 'package:triathlon_mobile/place/screens/place_list_screen.dart';
import 'package:triathlon_mobile/forum/screens/forum_list.dart';
import 'package:triathlon_mobile/ticket/screens/ticket_list_page.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  // Warna utama yang konsisten dengan Right Drawer
  static const primaryColor = Color(0xFF433BFF);
  static const secondaryColor = Color(0xFF2D27A8);

  // Helper untuk animasi masuk (Staggered Entrance)
  Widget _animateEntrance(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 450 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-30 * (1 - value), 0), // Muncul dari kiri (berlawanan dengan Right Drawer)
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // 1. Header dengan Logo dan Slogan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, secondaryColor],
              ),
            ),
            child: _animateEntrance(0, Column(
              children: [
                Image(image:  const AssetImage('assets/images/logo_triathlon.png'),
                  width: 100,
                  height: 100,
                ),
                SizedBox(height: 10),
                Text(
                  'Triathlon',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "We Achieve, We Persevere, We Triumph",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            )),
          ),

          // 2. List Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: [
                _animateEntrance(1, _buildDrawerItem(
                  icon: Icons.home_outlined,
                  title: 'Home',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => MyHomePage())),
                )),
                _animateEntrance(2, _buildDrawerItem(
                  icon: Icons.nordic_walking_sharp,
                  title: 'Activity',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ActivityMenu())),
                )),
                _animateEntrance(3, _buildDrawerItem(
                  icon: Icons.shopify_sharp,
                  title: 'Shop',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ShopPage())),
                )),
                _animateEntrance(4, _buildDrawerItem(
                  icon: Icons.forum_outlined,
                  title: 'Forum',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ForumListPage())),
                )),
                _animateEntrance(5, _buildDrawerItem(
                  icon: Icons.confirmation_number_outlined,
                  title: 'My Tickets',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const TicketListPage())),
                )),
                _animateEntrance(6, _buildDrawerItem(
                  icon: Icons.place_outlined,
                  title: 'Places',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const PlaceListScreen())),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      hoverColor: primaryColor.withOpacity(0.1),
    );
  }
}