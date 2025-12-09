// lib/ticket/screens/ticket_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';
import 'ticket_form_page.dart';
import '../../constants.dart';

class TicketDetailPage extends StatefulWidget {
  final int ticketId;

  const TicketDetailPage({Key? key, required this.ticketId}) : super(key: key);

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  Ticket? _ticket;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  bool _hasFetched = false;
  bool _isDataChanged = false;

  Future<void> _loadTicketDetail(CookieRequest request) async {
    setState(() => _isLoading = true);

    try {
      final response = await request.get('$baseUrl/ticket/api/${widget.ticketId}/');

      if (response != null) {
        setState(() {
          if (response.containsKey('data') && response['data'] != null) {
            _ticket = Ticket.fromJson(response['data']);
          } else if (response.containsKey('ticket') && response['ticket'] != null) {
            _ticket = Ticket.fromJson(response['ticket']);
          } else if (response.containsKey('id')) {
            _ticket = Ticket.fromJson(response);
          } else {
            throw Exception("Format respon API tidak dikenali.");
          }
          
          _isLoading = false;
          _isError = false;
        });
      } else {
        throw Exception('Respon API kosong (null)');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _deleteTicket() async {
    final request = context.read<CookieRequest>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Ticket', style: TextStyle(color: Colors.black)),
        content: const Text(
          'Are you sure you want to delete this ticket? This action cannot be undone.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await request.post(
          '$baseUrl/ticket/api/${widget.ticketId}/delete/',
          {},
        );

        if (response['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? 'Ticket deleted successfully'), backgroundColor: Colors.green),
            );
            Navigator.pop(context, true); 
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? 'Failed to delete ticket'), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting ticket: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    if (!_hasFetched) {
      _hasFetched = true;
      Future.microtask(() => _loadTicketDetail(request));
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, _isDataChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Ticket #${widget.ticketId}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _isDataChanged),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Gagal memuat tiket.\n$_errorMessage', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() { _isLoading = true; _hasFetched = false; });
                          },
                          child: const Text('Coba Lagi'),
                        )
                      ],
                    ),
                  )
                : _ticket == null
                    ? const Center(child: Text("Data tiket tidak ditemukan"))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- HEADER BIRU ---
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // KIRI: ID
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'TICKET ID',
                                            style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1.2),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '#${_ticket!.id}',
                                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      
                                      // KANAN: Status Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          // PERUBAHAN PENTING DI SINI:
                                          // Kita HAPUS .withOpacity(0.8) di sini karena opacity sudah diatur di fungsi _getStatusColor di bawah.
                                          color: _getStatusColor(_ticket!.getStatus()), 
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                        child: Text(
                                          _getStatusText(_ticket!.getStatus()),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // DETAILS CARD
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow('Customer Name', _ticket!.customerName, Icons.person),
                                  const Divider(height: 32),
                                  _buildDetailRow('Place', _ticket!.place.name, Icons.location_on),
                                  const Divider(height: 32),
                                  _buildDetailRow(
                                    'Booking Date',
                                    DateFormat('EEEE, dd MMMM yyyy').format(_ticket!.bookingDate),
                                    Icons.calendar_today,
                                  ),
                                  const Divider(height: 32),
                                  _buildDetailRow(
                                    'Quantity',
                                    '${_ticket!.ticketQuantity} ticket(s)',
                                    Icons.confirmation_number,
                                  ),
                                  const Divider(height: 32),
                                  _buildDetailRow(
                                    'Total Price',
                                    'Rp ${NumberFormat('#,##0', 'id_ID').format(_ticket!.totalPrice)}',
                                    Icons.attach_money,
                                    valueColor: Colors.green.shade700,
                                    valueBold: true,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // ACTION BUTTONS
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TicketFormPage(ticket: _ticket),
                                        ),
                                      );
                                      if (result == true) {
                                        setState(() {
                                          _isLoading = true;
                                          _hasFetched = false;
                                          _isDataChanged = true;
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _deleteTicket,
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Delete'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor, bool valueBold = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 16, color: valueColor ?? Colors.black87, fontWeight: valueBold ? FontWeight.bold : FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }


  Color _getStatusColor(String status) {
    switch (status) {
      case 'past':
        return Colors.grey.withOpacity(03); 
      case 'today':
        return Colors.orange.withOpacity(0.6);
      case 'upcoming':
        return Colors.green.withOpacity(0.6); 
      default:
        return Colors.blue.withOpacity(0.6);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'past': return 'PAST EVENT';
      case 'today': return 'TODAY';
      case 'upcoming': return 'UPCOMING';
      default: return 'UNKNOWN';
    }
  }
}