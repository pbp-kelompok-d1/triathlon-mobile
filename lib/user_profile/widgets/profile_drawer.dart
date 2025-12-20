import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/screens/login.dart';
import 'package:triathlon_mobile/user_profile/models/user_profile_model.dart';
import 'package:triathlon_mobile/user_profile/screens/user_dashboard_screen.dart';
import 'package:triathlon_mobile/user_profile/screens/seller_dashboard_screen.dart';
import 'package:triathlon_mobile/user_profile/screens/facility_admin_dashboard_screen.dart';
import 'package:triathlon_mobile/user_profile/screens/admin_dashboard_screen.dart';
import 'package:triathlon_mobile/user_profile/screens/edit_profile_screen.dart';

class CustomRightDrawer extends StatefulWidget {
  const CustomRightDrawer({super.key});

  @override
  State<CustomRightDrawer> createState() => _CustomRightDrawerState();
}

class _CustomRightDrawerState extends State<CustomRightDrawer> {
  static const primaryColor = Color(0xFF433BFF);

  @override
  void initState() {
    super.initState();
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return const Color.fromARGB(255, 197, 12, 12);
      case 'SELLER':
        return Colors.green;
      case 'FACILITY_ADMIN':
        return const Color.fromARGB(255, 255, 132, 9);
      default:
        return primaryColor;
    }
  }

  String _getRoleDisplay(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Admin';
      case 'SELLER':
        return 'Seller';
      case 'FACILITY_ADMIN':
        return 'Facility Admin';
      default:
        return 'User';
    }
  }

  Widget _animateEntrance(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 450 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0), // Muncul dari kanan
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildDashboardButton() {
    final role = UserProfileData.role.toUpperCase();
    
    if (role.isEmpty || role == 'GUEST') return const SizedBox.shrink();

    return _animateEntrance(1, Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getRoleColor(UserProfileData.role), Color(0xFF2D27A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getRoleColor(UserProfileData.role).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            
            Widget dashboardScreen;
            switch (role) {
              case 'ADMIN':
                dashboardScreen = const AdminDashboardScreen();
                break;
              case 'SELLER':
                dashboardScreen = const SellerDashboardScreen();
                break;
              case 'FACILITY_ADMIN':
                dashboardScreen = const FacilityAdminDashboardScreen();
                break;
              default:
                dashboardScreen = const UserDashboardScreen();
            }
            
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => dashboardScreen),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.dashboard_rounded, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Text(
                  'My Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final isLoggedIn = request.loggedIn;

    final username = UserProfileData.username;
    final fullName = UserProfileData.fullName;
    final email = UserProfileData.email;
    final role = UserProfileData.role;
    final bio = UserProfileData.bio;
    final profilePictureUrl = UserProfileData.profilePictureUrl;

    return Drawer(
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ _getRoleColor(role),
                  Color(0xFF2D27A8),
                ],
              ),
            ),
            child: isLoggedIn
                ? Column(
                    children: [
                      // Profile Picture
                      _animateEntrance(0, Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          backgroundImage: profilePictureUrl.isNotEmpty &&
                                  !profilePictureUrl.contains('default_profile.png')
                              ? NetworkImage(profilePictureUrl)
                              : null,
                          child: profilePictureUrl.isEmpty ||
                                  profilePictureUrl.contains('default_profile.png')
                              ? Text(
                                  username.isNotEmpty
                                      ? username[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Full Name
                      _animateEntrance(0, Text(
                        fullName.isNotEmpty ? fullName : username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      )
                      ),
                      
                      // Username
                      if (fullName.isNotEmpty)
                        _animateEntrance(0, Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '@$username',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Email
                      _animateEntrance(0, Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                        ),
                      ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Role Badge
                      _animateEntrance(0, Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _getRoleDisplay(role),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ),
                      
                      // Bio
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _animateEntrance(0, Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            bio,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        )
                      ],
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person_rounded,
                            size: 45,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Guest',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Please login to continue',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),

          // Action Buttons
          if (isLoggedIn) ...[
            const SizedBox(height: 20),
            
            // Dashboard Button
            _buildDashboardButton(),
            
            // Edit Profile Button
            _animateEntrance(1, Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor, width: 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    ).then((result) {
                      if (mounted) {
                      setState(() {});
                    }
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.edit_rounded, color: primaryColor, size: 22),
                        SizedBox(width: 12),
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Divider(height: 1),
            ),
          ],

          // Menu Items or Login Button
          Expanded(
            child: !isLoggedIn
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryColor, Color(0xFF2D27A8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.login_rounded, color: Colors.white, size: 22),
                                  SizedBox(width: 12),
                                  Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _buildDrawerItem(
                        icon: Icons.info_outline_rounded,
                        title: 'About',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.settings_rounded,
                        title: 'Settings',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
          ),

          // Logout Button
          if (isLoggedIn)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.red, Color(0xFFD32F2F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      try {
                        final response = await request.logout('$baseUrl/auth/logout/');
                        
                        UserProfileData.clearUserData();

                        if (!context.mounted) return;

                        String message = response['message'] ?? 'Logged out successfully';

                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(message)),
                          );

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
    return _animateEntrance(1, Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: primaryColor, size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
    );
  }
}