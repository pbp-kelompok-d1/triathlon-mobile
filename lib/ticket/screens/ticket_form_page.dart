// lib/ticket/screens/ticket_form_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/ticket_model.dart';
import '/constants.dart';

class TicketFormPage extends StatefulWidget {
  final Ticket? ticket; // Null untuk create, berisi data untuk update

  const TicketFormPage({Key? key, this.ticket}) : super(key: key);

  @override
  State<TicketFormPage> createState() => _TicketFormPageState();
}

class _TicketFormPageState extends State<TicketFormPage> {
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _ticketQuantityController = TextEditingController(text: '1');
  
  List<Place> _places = [];
  Place? _selectedPlace;
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isLoadingPlaces = false;

  double get totalPrice {
    if (_selectedPlace == null) return 0;
    final quantity = int.tryParse(_ticketQuantityController.text) ?? 1;
    return _selectedPlace!.price * quantity;
  }

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    
    // Jika mode edit, isi form dengan data tiket
    if (widget.ticket != null) {
      _customerNameController.text = widget.ticket!.customerName;
      _ticketQuantityController.text = widget.ticket!.ticketQuantity.toString();
      _selectedDate = widget.ticket!.bookingDate;
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _ticketQuantityController.dispose();
    super.dispose();
  }


  Future<void> _loadPlaces() async {
    setState(() => _isLoadingPlaces = true);
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/place/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final places = jsonList.map((json) => Place.fromJson(json)).toList();
        
        setState(() {
          _places = places;
          _isLoadingPlaces = false;
          
          // Jika mode edit, set selected place
          if (widget.ticket != null && _places.isNotEmpty) {
            _selectedPlace = _places.firstWhere(
              (p) => p.id == widget.ticket!.place.id,
              orElse: () => _places.first,
            );
          }
        });
      } else {
        throw Exception('Failed to load places: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoadingPlaces = false);
      _showErrorSnackBar('Failed to load places: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlace == null) {
      _showErrorSnackBar('Please select a place');
      return;
    }
    if (_selectedDate == null) {
      _showErrorSnackBar('Please select a booking date');
      return;
    }

    setState(() => _isLoading = true);

    final ticketRequest = TicketRequest(
      customerName: _customerNameController.text,
      placeId: _selectedPlace!.id,
      bookingDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      ticketQuantity: int.parse(_ticketQuantityController.text),
    );

    try {
      final isEdit = widget.ticket != null;
      final url = isEdit 
          ? '$baseUrl/api/ticket/${widget.ticket!.id}/update/'
          : '$baseUrl/api/ticket/create/';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: json.encode(ticketRequest.toJson()),
      );

      final data = json.decode(response.body);
      setState(() => _isLoading = false);

      if (response.statusCode == 200 && data['success']) {
        _showSuccessSnackBar(data['message'] ?? 'Ticket saved successfully');
        Navigator.pop(context, true); // Return true untuk refresh list
      } else {
        // Handle errors
        if (data['errors'] != null) {
          // Tampilkan error dari form validation
          String errorMessage = '';
          data['errors'].forEach((field, errors) {
            errorMessage += '${errors[0]}\n';
          });
          _showErrorSnackBar(errorMessage.trim());
        } else {
          _showErrorSnackBar(data['message'] ?? 'Failed to save ticket');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('An error occurred: $e');
    }
  }

  // ========== UI HELPERS ==========

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
    final isEdit = widget.ticket != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Ticket' : 'Book New Ticket'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingPlaces
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Name
                    const Text(
                      'Customer Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customerNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter customer name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Customer name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Place Dropdown
                    const Text(
                      'Place Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Place>(
                      value: _selectedPlace,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      hint: const Text('-- Select Place --'),
                      isExpanded: true,
                      items: _places.map((place) {
                        return DropdownMenuItem<Place>(
                          value: place,
                          child: Text(
                            '${place.name} - Rp ${NumberFormat('#,##0', 'id_ID').format(place.price)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (Place? newValue) {
                        setState(() {
                          _selectedPlace = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a place';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Booking Date
                    const Text(
                      'Booking Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Select date'
                              : DateFormat('dd MMM yyyy').format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null
                                ? Colors.grey.shade600
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Ticket Quantity
                    const Text(
                      'Ticket Quantity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ticketQuantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (_) => setState(() {}), // Update total price
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Quantity is required';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity < 1) {
                          return 'Quantity must be at least 1';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Total Price Display
                    const Text(
                      'Estimated Total Price',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Rp ${NumberFormat('#,##0', 'id_ID').format(totalPrice)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Price will be calculated automatically',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(isEdit ? 'Update' : 'Submit Booking'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}