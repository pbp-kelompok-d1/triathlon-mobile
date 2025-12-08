import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';
import 'ticket_form_page.dart'; // IMPORT WAJIB: Untuk navigasi ke halaman edit
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

  // --- LOGIKA FETCH DATA ---
  Future<void> _loadTicketDetail(CookieRequest request) async {
    try {
      final response = await request.get('$baseUrl/ticket/api/${widget.ticketId}/');

      if (response['success'] == true) {
        setState(() {
          _ticket = Ticket.fromJson(response['data']);
          _isLoading = false;
          _isError = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Gagal memuat tiket');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $_errorMessage'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- LOGIKA DELETE (Diadaptasi dari referensi) ---
  Future<void> _deleteTicket() async {
    final request = context.read<CookieRequest>();

    // 1. Tampilkan Dialog Konfirmasi
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

    // 2. Eksekusi Hapus jika dikonfirmasi
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
            // Kembali ke halaman list dengan membawa nilai 'true' agar list direfresh
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${widget.ticketId}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Gagal memuat tiket.\n$_errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _hasFetched = false;
                          });
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
                          // --- COMPONENT: TICKET ID CARD ---
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade600, Colors.blue.shade800],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade200,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'TICKET ID',
                                  style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1.2),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '#${_ticket!.id}',
                                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // --- COMPONENT: DETAILS CARD ---
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

                          const SizedBox(height: 24),

                          // --- COMPONENT: STATUS BADGE ---
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_ticket!.getStatus()).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _getStatusColor(_ticket!.getStatus()), width: 2),
                              ),
                              child: Text(
                                _getStatusText(_ticket!.getStatus()),
                                style: TextStyle(
                                  color: _getStatusColor(_ticket!.getStatus()),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // --- COMPONENT: ACTION BUTTONS (EDIT & DELETE) ---
                          Row(
                            children: [
                              // Tombol Edit
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    // Navigasi ke Form Edit
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TicketFormPage(ticket: _ticket),
                                      ),
                                    );
                                    // Jika form berhasil disimpan (result == true), refresh halaman detail
                                    if (result == true) {
                                      setState(() {
                                        _isLoading = true;
                                        _hasFetched = false; // Trigger fetch ulang
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Tombol Delete
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
                          // Tambahan padding bawah agar tombol tidak mepet layar
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor, bool valueBold = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.blue.shade600, size: 24),
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
      case 'past': return Colors.grey;
      case 'today': return Colors.orange;
      case 'upcoming': return Colors.green;
      default: return Colors.blue;
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