import 'package:triathlon_mobile/widgets/left_drawer.dart';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/shop/screens/shop_main.dart';
import '../widgets/product_card.dart';

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

    final String nama = "Randuichi Touya"; // Name
    final String npm = "2406350021"; // NPM
    final String kelas = "D"; // Class

    final List<ItemHomepage> items = [
      ItemHomepage("Forum", Icons.forum, Color(0xFF7C3AED)),
    ];

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    // Grab the username from CookieRequest state so the greeting reflects whoever logged in.
    String username = 'Explorer';
    if (request.jsonData['username'] != null) {
      username = request.jsonData['username'].toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Triathlon - Home',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      drawer: LeftDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InfoCard(title: 'NPM', content: npm),
                InfoCard(title: 'Name', content: nama),
                InfoCard(title: 'Class', content: kelas),
              ],
            ),
            const SizedBox(height: 16.0),
            Center(
              child: Column(

                children: [
                  // Menampilkan teks sambutan dengan gaya tebal dan ukuran 18.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1D4ED8),
                          const Color(0xFF0EA5E9).withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.sports_motorsports,
                            color: Color(0xFF0EA5E9),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selamat datang di',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 4.0),
                            const Text(
                              'Triathlon',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Logged in as $username',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Go to Shop'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShopPage()),
                      );
                    },
                  ),

                  const SizedBox(height: 24.0),

                  // Grid untuk menampilkan ItemCard dalam bentuk grid 3 kolom.
                  GridView.count(
                    primary: true,
                    padding: const EdgeInsets.all(20),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    crossAxisCount: 3,

                    shrinkWrap: true,


                    children: items.map((ItemHomepage item) {
                      return ItemCard(item);
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {


  final String title; 
  final String content;  

  const InfoCard({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(

      elevation: 2.0,
      child: Container(

        width: MediaQuery.of(context).size.width / 3.5, 
        padding: const EdgeInsets.all(16.0),

        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(content),
          ],
        ),
      ),
    );
  }
}

class ItemHomepage {
 final String name;
 final IconData icon;
 final Color color;
 ItemHomepage(this.name, this.icon, this.color);
}