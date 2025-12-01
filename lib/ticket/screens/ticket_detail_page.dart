// lib/ticket/screens/ticket_detail_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/ticket_model.dart';

class TicketDetailPage extends StatefulWidget {
  final int ticketId;

  const TicketDetailPage({Key? key, required this.ticketId}) : super(key: key);

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  Ticket? _ticket;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTicketDetail();
  }

  Future<void> _loadTicketDetail() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/ticket/${widget.ticketId}/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _ticket = Ticket.fromJson(jsonData);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load ticket detail');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load ticket detail: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${widget.ticketId}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ticket == null
              ? const Center(child: Text('Ticket not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ticket ID Card
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
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '#${_ticket!.id}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Details Card
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
                            _buildDetailRow(
                              'Customer Name',
                              _ticket!.customerName,
                              Icons.person,
                            ),
                            const Divider(height: 32),
                            _buildDetailRow(
                              'Place',
                              _ticket!.place.name,
                              Icons.location_on,
                            ),
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

                      // Status Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_ticket!.getStatus()).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(_ticket!.getStatus()),
                              width: 2,
                            ),
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
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue.shade600, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? Colors.black87,
                  fontWeight: valueBold ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'past':
        return Colors.grey;
      case 'today':
        return Colors.orange;
      case 'upcoming':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'past':
        return 'PAST EVENT';
      case 'today':
        return 'TODAY';
      case 'upcoming':
        return 'UPCOMING';
      default:
        return 'UNKNOWN';
    }
  }
}