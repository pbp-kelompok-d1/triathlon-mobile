// lib/ticket/screens/ticket_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/ticket_model.dart';
import '../widgets/ticket_card.dart';
import 'ticket_form_page.dart';
import 'ticket_detail_page.dart';
import '../../constants.dart';
import '../../widgets/left_drawer.dart'; 
import 'package:triathlon_mobile/user_profile/widgets/profile_drawer.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({Key? key}) : super(key: key);

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  List<Ticket> _tickets = [];
  bool _isLoading = false;
  String _selectedFilter = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  int _pastCount = 0;
  int _todayCount = 0;
  int _upcomingCount = 0;

  @override
  void initState() {
    super.initState();
    // load data pas pertama kali buka halaman
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTickets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);

    final request = context.read<CookieRequest>();

    try {
      String url = '$baseUrl/ticket/api/tickets/';
      
      // bikin query parameter buat filter sama search
      List<String> queryParts = [];
      if (_selectedFilter.isNotEmpty) queryParts.add('status=$_selectedFilter');
      if (_searchQuery.isNotEmpty) queryParts.add('search=$_searchQuery');
      
      if (queryParts.isNotEmpty) url += '?' + queryParts.join('&');

      final response = await request.get(url);

      List<dynamic> listData = [];

      // handle berbagai format response dari backend
      if (response is List) {
        listData = response;
      } else if (response is Map && response.containsKey('data')) {
        listData = response['data'];
      } else if (response is Map && response.containsKey('results')) {
        listData = response['results'];
      }

      // parse json ke object Ticket
      final List<Ticket> tickets = [];
      for (var json in listData) {
        try {
          tickets.add(Ticket.fromJson(json));
        } catch (e) {
          print("Error parsing ticket item: $e");
        }
      }

      // itung jumlah tiket per kategori
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int past = 0, todayC = 0, upcoming = 0;
      for (var ticket in tickets) {
        final ticketDate = DateTime(
          ticket.bookingDate.year,
          ticket.bookingDate.month,
          ticket.bookingDate.day,
        );
        if (ticketDate.isBefore(today)) {
          past++;
        } else if (ticketDate.isAtSameMomentAs(today)) {
          todayC++;
        } else {
          upcoming++;
        }
      }

      if (mounted) {
        setState(() {
          _tickets = tickets;
          _pastCount = past;
          _todayCount = todayC;
          _upcomingCount = upcoming;
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'), 
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTicket(Ticket ticket) async {
    final request = context.read<CookieRequest>();

    // konfirmasi dulu sebelum hapus
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Ticket',
        style: TextStyle(color: Colors.black),
        ),
        content: const Text(
          'Are you sure you want to delete this ticket? This action cannot be undone.',
        style: TextStyle(color: Colors.black87),),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
            foregroundColor: Colors.black,
          ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await request.post(
          '$baseUrl/ticket/api/${ticket.id}/delete/',
          {},
        );

        bool success = false;
        String message = 'Failed to delete';

        if (response is Map) {
          if (response['success'] == true || response['status'] == 'success') {
            success = true;
          }
          message = response['message'] ?? message;
        }

        if (mounted) {
          if (success) {
            _showSuccessSnackBar(message);
            _loadTickets();
          } else {
            _showErrorSnackBar(message);
          }
        }
      } catch (e) {
        if (mounted) _showErrorSnackBar('Error deleting ticket: $e');
      }
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadTickets();
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _loadTickets();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const LeftDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Triathlon Tickets',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.person_rounded, size: 30, color: Colors.white,),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: const CustomRightDrawer(),
      
      body: RefreshIndicator(
        onRefresh: _loadTickets,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 20), 
          itemCount: _tickets.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // bagian header
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // hero section
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/herosectionticket.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.blue.shade900.withOpacity(0.6),
                            Colors.indigo.shade800.withOpacity(0.5),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                      child: SafeArea(
                        child: Column(
                          children: [
                            const Text(
                              'TRIATHLON TICKET',
                              style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Plan your next challenge and manage all your ticket bookings easily.',
                              style: TextStyle(color: Colors.blue.shade100, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // search bar sama tombol aksi
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            onSubmitted: (_) => _performSearch(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _loadTickets,
                          icon: const Icon(Icons.refresh),
                          style: IconButton.styleFrom(backgroundColor: Colors.grey.shade200),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TicketFormPage()),
                            );
                            if (result == true) _loadTickets();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Book'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF433BFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // filter chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', '', _tickets.length),
                          _buildFilterChip('Past', 'past', _pastCount),
                          _buildFilterChip('Today', 'today', _todayCount),
                          _buildFilterChip('Upcoming', 'upcoming', _upcomingCount),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isLoading)
                     const Padding(
                       padding: EdgeInsets.all(20.0),
                       child: Center(child: CircularProgressIndicator()),
                     ),
                  
                  if (!_isLoading && _tickets.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: Text('No tickets found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ),
                    ),
                ],
              );
            }

            // list tiket
            if (_isLoading || _tickets.isEmpty) return const SizedBox.shrink();
            
            final ticket = _tickets[index - 1];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TicketCard(
                ticket: ticket,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicketDetailPage(ticketId: ticket.id),
                    ),
                  );
                  if (result == true) {
                    _loadTickets();
                  }
                },
                onEdit: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicketFormPage(ticket: ticket),
                    ),
                  );
                  if (result == true) _loadTickets();
                },
                onDelete: () => _deleteTicket(ticket),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (_) => _applyFilter(value),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF433BFF),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}