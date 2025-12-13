// lib/ticket/screens/ticket_form_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';
import '../../models/place.dart';
import '../../constants.dart';

class TicketFormPage extends StatefulWidget {
  final Ticket? ticket;

  const TicketFormPage({Key? key, this.ticket}) : super(key: key);

  @override
  State<TicketFormPage> createState() => _TicketFormPageState();
}

class _TicketFormPageState extends State<TicketFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _ticketQuantityController =
      TextEditingController(text: '1');

  List<Place> _places = [];
  Place? _selectedPlace;
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isLoadingPlaces = false;
  bool _hasFetchedPlaces = false;

  double get totalPrice {
    if (_selectedPlace == null) return 0.0;
    final quantity = int.tryParse(_ticketQuantityController.text) ?? 1;
    final price = double.tryParse(_selectedPlace!.price) ?? 0.0;
    return price * quantity;
  }

  @override
  void initState() {
    super.initState();
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

  // --- FUNGSI INCREMENT (DIPERBAIKI) ---
  void _incrementQuantity() {
    int current = int.tryParse(_ticketQuantityController.text) ?? 0;
    if (current < 100) {
      setState(() {
        current++;
        _ticketQuantityController.text = current.toString();
        // Menjaga kursor tetap di akhir angka
        _ticketQuantityController.selection = TextSelection.fromPosition(
            TextPosition(offset: _ticketQuantityController.text.length));
      });
    }
  }

  // --- FUNGSI DECREMENT (DIPERBAIKI) ---
  void _decrementQuantity() {
    int current = int.tryParse(_ticketQuantityController.text) ?? 1;
    if (current > 1) {
      setState(() {
        current--;
        _ticketQuantityController.text = current.toString();
        // Menjaga kursor tetap di akhir angka
        _ticketQuantityController.selection = TextSelection.fromPosition(
            TextPosition(offset: _ticketQuantityController.text.length));
      });
    }
  }

  Future<void> _loadPlaces(CookieRequest request) async {
    setState(() => _isLoadingPlaces = true);

    try {
      final response = await request.get('$baseUrl/ticket/api/places/');

      if (response != null) {
        List<dynamic> jsonList;

        if (response is List) {
          jsonList = response;
        } else if (response is Map && response.containsKey('data')) {
          jsonList = response['data'];
        } else {
          jsonList = [];
        }

        final places = jsonList.map((json) => Place.fromJson(json)).toList();

        setState(() {
          _places = places;
          _isLoadingPlaces = false;

          if (widget.ticket != null && _places.isNotEmpty) {
            try {
              _selectedPlace = _places.firstWhere(
                  (p) => p.id == widget.ticket!.place.id);
            } catch (e) {
              _selectedPlace = null;
            }
          }
        });
      } else {
        throw Exception('Response is null');
      }
    } catch (e) {
      setState(() => _isLoadingPlaces = false);
      if (mounted) {
        _showErrorSnackBar('Failed to load places: $e');
      }
    }
  }

  Future<void> _submitForm(CookieRequest request) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlace == null) {
      _showErrorSnackBar('Please select a place');
      return;
    }
    if (_selectedDate == null) {
      _showErrorSnackBar('Please select a booking date');
      return;
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDateOnly =
        DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);

    if (selectedDateOnly.isBefore(todayDate)) {
      _showErrorSnackBar('Booking date cannot be in the past');
      return;
    }

    setState(() => _isLoading = true);

    final Map<String, dynamic> payload = {
      'customer_name': _customerNameController.text,
      'place': _selectedPlace!.id.toString(),
      'booking_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      'ticket_quantity': _ticketQuantityController.text,
    };

    try {
      final isEdit = widget.ticket != null;
      final url = isEdit
          ? '$baseUrl/ticket/api/${widget.ticket!.id}/update/'
          : '$baseUrl/ticket/api/tickets/create/';

      final response = await request.post(url, payload);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (response['success'] == true) {
        _showSuccessSnackBar(response['message'] ?? 'Ticket saved successfully');
        Navigator.pop(context, true);
      } else {
        if (response['errors'] != null) {
          String errorMessage = '';
          if (response['errors'] is Map) {
            (response['errors'] as Map).forEach((field, errors) {
              if (errors is List && errors.isNotEmpty) {
                errorMessage += '$field: ${errors[0]}\n';
              } else {
                errorMessage += '$field: $errors\n';
              }
            });
          } else {
            errorMessage = response['errors'].toString();
          }
          _showErrorSnackBar(errorMessage.trim());
        } else {
          _showErrorSnackBar(response['message'] ?? 'Failed to save ticket');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('An error occurred: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    if (!_hasFetchedPlaces) {
      _hasFetchedPlaces = true;
      Future.microtask(() => _loadPlaces(request));
    }

    final isEdit = widget.ticket != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Ticket' : 'Book New Ticket'),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
                        if (value.length < 3) {
                          return 'Customer name must be at least 3 characters';
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
                        final priceValue = double.tryParse(place.price) ?? 0.0;
                        return DropdownMenuItem<Place>(
                          value: place,
                          child: Text(
                            '${place.name} - Rp ${NumberFormat('#,##0', 'id_ID').format(priceValue)}',
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
                              : DateFormat('dd MMM yyyy')
                                  .format(_selectedDate!),
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
                        hintText: '1',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        suffixIcon: Container(
                          width: 40,
                          height: 45,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _incrementQuantity,
                                  child: const Icon(
                                    Icons.arrow_drop_up,
                                    size: 24,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: _decrementQuantity,
                                  child: const Icon(
                                    Icons.arrow_drop_down,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity < 1) {
                          return 'Min 1';
                        }
                        if (quantity > 100) {
                          return 'Max 100';
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
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
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
                            onPressed: _isLoading
                                ? null
                                : () => _submitForm(request),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
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