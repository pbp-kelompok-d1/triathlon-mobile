// lib/ticket/screens/ticket_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Tambahan wajib
import 'package:pbp_django_auth/pbp_django_auth.dart'; // Tambahan wajib
import '../models/ticket_model.dart';
import '../widgets/ticket_card.dart';
import 'ticket_form_page.dart';
import 'ticket_detail_page.dart';
import '/constants.dart';
import '../../widgets/left_drawer.dart';

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
    // Panggil load ticket setelah frame pertama dirender agar context provider aman
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTickets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========== API CALLS ==========

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);

    // Gunakan CookieRequest untuk autentikasi
    final request = context.read<CookieRequest>();

    try {
      // Konstruksi URL
      String url = '$baseUrl/ticket/api/tickets/';
      
      // Menambahkan Query Params manual karena pbp_django_auth .get menerima URL string
      List<String> queryParts = [];
      if (_selectedFilter.isNotEmpty) {
        queryParts.add('status=$_selectedFilter');
      }
      if (_searchQuery.isNotEmpty) {
        queryParts.add('search=$_searchQuery');
      }
      
      if (queryParts.isNotEmpty) {
        url += '?' + queryParts.join('&');
      }

      // Request ke Django (request.get otomatis return JSON decoded)
      final response = await request.get(url);

      // Perbaikan Parsing JSON
      // Django return: { "success": true, "data": [...] }
      if (response != null && response['data'] != null) {
        final List<dynamic> listData = response['data'];
        
        // Mapping ke model
        final tickets = listData.map((json) => Ticket.fromJson(json)).toList();

        // Hitung statistik
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

        setState(() {
          _tickets = tickets;
          _pastCount = past;
          _todayCount = todayC;
          _upcomingCount = upcoming;
          _isLoading = false;
        });
      } else {
        // Handle jika response kosong atau format salah
        setState(() => _isLoading = false);
        // Opsional: print(response) untuk debugging
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error loading tickets: $e");
      // _showErrorSnackBar('Failed to load tickets: $e'); 
      // Comment snackbar di atas agar tidak spam error saat inisialisasi awal
    }
  }

  Future<void> _deleteTicket(Ticket ticket) async {
    final request = context.read<CookieRequest>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Ticket'),
        content: const Text(
          'Are you sure you want to delete this ticket? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Menggunakan POST karena view Django kamu support ["DELETE", "POST"]
        // Ini lebih aman untuk session cookie dibanding http.delete biasa
        final response = await request.post(
          '$baseUrl/ticket/api/${ticket.id}/delete/', 
          {}, // Body kosong
        );

        if (response['success'] == true) {
          _showSuccessSnackBar(response['message'] ?? 'Ticket deleted successfully');
          _loadTickets(); // Reload list
        } else {
          _showErrorSnackBar(response['message'] ?? 'Failed to delete ticket');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting ticket: $e');
      }
    }
  }

  // ========== UI HELPERS ==========

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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const LeftDrawer(),
      appBar: AppBar(
        title: const Text('My Tickets', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF433BFF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Hero Section
          Container(
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Plan your next challenge and manage all your ticket bookings easily.',
                      style: TextStyle(
                        color: Colors.blue.shade100,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search and Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, place, or ID...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadTickets,
                  icon: const Icon(Icons.refresh),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TicketFormPage(),
                      ),
                    );
                    if (result == true) {
                      _loadTickets();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Book'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF433BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
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

          // Ticket List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tickets.isEmpty
                    ? const Center(
                        child: Text(
                          'No tickets found.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTickets,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = _tickets[index];
                            return TicketCard(
                              ticket: ticket,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TicketDetailPage(
                                      ticketId: ticket.id,
                                    ),
                                  ),
                                );
                              },
                              onEdit: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TicketFormPage(
                                      ticket: ticket,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadTickets();
                                }
                              },
                              onDelete: () => _deleteTicket(ticket),
                            );
                          },
                        ),
                      ),
          ),
        ],
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}