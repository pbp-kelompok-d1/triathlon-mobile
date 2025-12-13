import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/user_profile/models/dashboard_data.dart';
import 'package:triathlon_mobile/user_profile/screens/edit_profile_screen.dart';
import '../../ticket/models/ticket_model.dart' show Ticket;
import '../../place/models/place.dart';

class FacilityAdminDashboardScreen extends StatefulWidget {
  const FacilityAdminDashboardScreen({super.key});

  @override
  State<FacilityAdminDashboardScreen> createState() => _FacilityAdminDashboardScreenState();
}

class _FacilityAdminDashboardScreenState extends State<FacilityAdminDashboardScreen> {
  // Warna Utama Orange
  static const Color primaryOrange = Color.fromARGB(255, 255, 132, 9);
  
  String _selectedView = 'all';
  String _selectedCategory = '';
  bool _isLoading = true;
  DashboardData? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    
    final request = context.read<CookieRequest>();
    
    try {
      final url = '$baseUrl/profile/api/dashboard/?view=$_selectedView&category=$_selectedCategory';
      final response = await request.get(url);
      
      if (response != null) {
        setState(() {
          _dashboardData = DashboardData.fromJson(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: primaryOrange,
        child: CustomScrollView(
          slivers: [
            // 1. SLIVER APP BAR (Header Keren)
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: primaryOrange,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Facility Admin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryOrange,
                        primaryOrange.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Lingkaran Dekoratif
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  tooltip: 'Edit Profile',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    ).then((_) => _fetchDashboardData());
                  },
                ),
              ],
            ),

            // 2. CONTENT BODY
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildFilterSection(),
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: primaryOrange),
                        )
                      : _buildDashboardContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Dashboard',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // Filter Chips Scrollable
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildViewChip('All', 'all'),
                const SizedBox(width: 8),
                _buildViewChip('My Facilities', 'facilities'),
                const SizedBox(width: 8),
                _buildViewChip('Ticket Orders', 'tickets'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Dropdown Filter
          DropdownButtonFormField<String>(
            value: _selectedCategory.isEmpty ? null : _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Filter by Facility Type',
              labelStyle: TextStyle(color: Colors.grey.shade700),
              prefixIcon: const Icon(Icons.filter_list_rounded, color: primaryOrange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryOrange, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(value: '', child: Text('All Types')),
              DropdownMenuItem(value: 'swimming', child: Text('Swimming Pool')),
              DropdownMenuItem(value: 'running', child: Text('Running Track')),
              DropdownMenuItem(value: 'cycling', child: Text('Bicycle Tracking')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value ?? '';
              });
              _fetchDashboardData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewChip(String label, String value) {
    final isSelected = _selectedView == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedView = value;
        });
        _fetchDashboardData();
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: primaryOrange,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? primaryOrange : Colors.grey.shade300,
        ),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_dashboardData == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No data available')),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (_selectedView == 'all' || _selectedView == 'tickets')
            _buildStatsSection(),
          
          if (_selectedView == 'all' || _selectedView == 'facilities')
            _buildFacilitiesSection(),
          
          if (_selectedView == 'all' || _selectedView == 'tickets')
            _buildTicketsSection(),
            
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- STATS SECTION (RESPONSIVE) ---
  Widget _buildStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Orders',
                    value: '${_dashboardData?.tickets.length ?? 0}',
                    icon: Icons.confirmation_number_rounded,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Tickets Sold',
                    value: '${_dashboardData?.totalTicketQuantity ?? 0}',
                    icon: Icons.receipt_long_rounded,
                    color: Colors.green,
                  ),
                ),
                if (isWide) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Revenue',
                      value: 'Rp ${(_dashboardData?.totalRevenueAmount ?? 0).toStringAsFixed(0)}',
                      icon: Icons.monetization_on_rounded,
                      color: Colors.purple,
                    ),
                  ),
                ]
              ],
            ),
            if (!isWide) ...[
              const SizedBox(height: 12),
              _buildStatCard(
                title: 'Total Revenue',
                value: 'Rp ${(_dashboardData?.totalRevenueAmount ?? 0).toStringAsFixed(0)}',
                icon: Icons.monetization_on_rounded,
                color: Colors.purple,
                fullWidth: true,
              ),
            ],
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required MaterialColor color,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color.shade700, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color.shade800,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FACILITIES SECTION ---
  Widget _buildFacilitiesSection() {
    final facilities = _dashboardData?.facilities ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.business_rounded, color: primaryOrange, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Managed Facilities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (facilities.isEmpty)
          _buildEmptyState(
            icon: Icons.location_city_outlined,
            title: 'No Facilities Found',
            subtitle: 'You are not managing any facilities yet.',
            buttonText: 'Add a Facility',
            onButtonPressed: () {},
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: facilities.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) => _buildFacilityCard(facilities[idx]),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFacilityCard(Place facility) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            facility.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildTag(facility.genre ?? 'General', Colors.blue),
                              if (facility.city != null && facility.city!.isNotEmpty)
                                _buildTag(facility.city!, Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  facility.description ?? 'No description available.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ticket Price:',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    Text(
                      'Rp ${facility.price}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TICKETS SECTION ---
  Widget _buildTicketsSection() {
    final tickets = _dashboardData?.tickets ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.confirmation_number_rounded, color: primaryOrange, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'User Ticket Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tickets.isEmpty)
          _buildEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No Ticket Orders',
            subtitle: 'No users have ordered tickets for your facilities yet.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tickets.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) => _buildTicketCard(tickets[idx]),
          ),
      ],
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    MaterialColor statusColor;
    IconData statusIcon;
    String statusDisplay;

    final currentStatus = ticket.getStatus(); 

    switch (currentStatus) {
      case 'upcoming':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusDisplay = "Upcoming";
        break;
      case 'today':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_rounded;
        statusDisplay = "Today";
        break;
      default: 
        statusColor = Colors.grey;
        statusIcon = Icons.history_rounded;
        statusDisplay = "Past";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ticket.place.name,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusDisplay,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTicketInfo(
                    label: 'Date',
                    value: ticket.bookingDate.toString().split(' ')[0],
                    icon: Icons.calendar_today_rounded,
                  ),
                  _buildTicketInfo(
                    label: 'Qty',
                    value: '${ticket.ticketQuantity}',
                    icon: Icons.confirmation_number_outlined,
                  ),
                  _buildTicketInfo(
                    label: 'Total',
                    value: 'Rp ${ticket.totalPrice.toStringAsFixed(0)}',
                    icon: Icons.payments_outlined,
                    isPrice: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  
  Widget _buildTicketInfo({required String label, required String value, required IconData icon, bool isPrice = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isPrice ? primaryOrange : Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color.shade700, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: primaryOrange),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}