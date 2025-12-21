import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';
import '../../place/models/place.dart';
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
  final TextEditingController _ticketQuantityController = TextEditingController(text: '1');

  List<Place> _places = [];
  Place? _selectedPlace;
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isLoadingPlaces = false;
  bool _hasFetchedPlaces = false;

  // Getter untuk menghitung total harga secara real-time
  double get totalPrice {
    if (_selectedPlace == null) return 0.0;
    final quantity = int.tryParse(_ticketQuantityController.text) ?? 1;
    final price = double.tryParse(_selectedPlace!.price) ?? 0.0;
    return price * quantity;
  }

  @override
  void initState() {
    super.initState();
    // Inisialisasi data jika dalam mode EDIT
    if (widget.ticket != null) {
      _customerNameController.text = widget.ticket!.customerName;
      _ticketQuantityController.text = widget.ticket!.ticketQuantity.toString();
      _selectedDate = widget.ticket!.bookingDate;
      _selectedPlace = widget.ticket!.place;
    }

    // Listener agar harga terupdate otomatis saat mengetik jumlah tiket
    _ticketQuantityController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _ticketQuantityController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    int current = int.tryParse(_ticketQuantityController.text) ?? 0;
    if (current < 100) {
      current++;
      _ticketQuantityController.text = current.toString();
      _ticketQuantityController.selection = TextSelection.fromPosition(
          TextPosition(offset: _ticketQuantityController.text.length));
    }
  }

  void _decrementQuantity() {
    int current = int.tryParse(_ticketQuantityController.text) ?? 1;
    if (current > 1) {
      current--;
      _ticketQuantityController.text = current.toString();
      _ticketQuantityController.selection = TextSelection.fromPosition(
          TextPosition(offset: _ticketQuantityController.text.length));
    }
  }

  Future<void> _loadPlaces(CookieRequest request) async {
    setState(() => _isLoadingPlaces = true);
    try {
      final response = await request.get('$baseUrl/ticket/api/places/');
      if (response != null) {
        List<dynamic> jsonList = (response is List) ? response : (response['data'] ?? []);
        final places = jsonList.map((json) => Place.fromJson(json)).toList();

        setState(() {
          _places = places;
          _isLoadingPlaces = false;
          // Sync ulang selectedPlace dengan objek dari list API agar referensinya sama
          if (widget.ticket != null && _places.isNotEmpty) {
            try {
              _selectedPlace = _places.firstWhere((p) => p.id == widget.ticket!.place.id);
            } catch (e) {
              _selectedPlace = widget.ticket!.place;
            }
          }
        });
      }
    } catch (e) {
      setState(() => _isLoadingPlaces = false);
      _showErrorSnackBar('Failed to load places: $e');
    }
  }

  Future<void> _submitForm(CookieRequest request) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlace == null) {
      _showErrorSnackBar('Please select a valid place from the list');
      return;
    }
    if (_selectedDate == null) {
      _showErrorSnackBar('Please select a booking date');
      return;
    }

    setState(() => _isLoading = true);
    final payload = {
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

      if (response['success'] == true || response['status'] == 'success') {
        _showSuccessSnackBar(response['message'] ?? 'Ticket saved successfully');
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to save ticket');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    if (!_hasFetchedPlaces) {
      _hasFetchedPlaces = true;
      Future.microtask(() => _loadPlaces(request));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket != null ? 'Edit Ticket' : 'Book New Ticket'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
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
                    _buildLabel('Customer Name'),
                    TextFormField(
                      controller: _customerNameController,
                      decoration: _buildInputDecoration('Enter customer name'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Place Name (Search or Select)'),
                    
                    // Autocomplete untuk memilih Place
                    Autocomplete<Place>(
                      displayStringForOption: (Place option) => option.name,
                      initialValue: TextEditingValue(text: _selectedPlace?.name ?? ''),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _places; // Menampilkan semua jika kolom kosong (seperti dropdown)
                        }
                        return _places.where((Place option) => option.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (Place selection) {
                        setState(() {
                          _selectedPlace = selection;
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: _buildInputDecoration('Select place...').copyWith(
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (controller.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      controller.clear();
                                      setState(() => _selectedPlace = null);
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onPressed: () {
                                    if (!focusNode.hasFocus) {
                                      focusNode.requestFocus();
                                    }
                                    // Trigger agar list muncul semua
                                    controller.text = ''; 
                                  },
                                ),
                              ],
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please select a place';
                            if (_selectedPlace == null || _selectedPlace!.name != v) {
                              return 'Please select a valid place from the list';
                            }
                            return null;
                          },
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 8.0,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: MediaQuery.of(context).size.width - 40,
                              constraints: const BoxConstraints(maxHeight: 250),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final Place option = options.elementAt(index);
                                  return ListTile(
                                    leading: const Icon(Icons.location_on, color: Colors.blue),
                                    title: Text(option.name),
                                    subtitle: Text('Rp ${NumberFormat('#,##0', 'id_ID').format(double.tryParse(option.price) ?? 0)}'),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    _buildLabel('Booking Date'),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: _buildInputDecoration('').copyWith(suffixIcon: const Icon(Icons.calendar_today)),
                        child: Text(_selectedDate == null ? 'Select date' : DateFormat('dd MMM yyyy').format(_selectedDate!)),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _buildLabel('Ticket Quantity'),
                    TextFormField(
                      controller: _ticketQuantityController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration('1').copyWith(
                        suffixIcon: _buildQuantityActions(),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _buildTotalPriceDisplay(),
                    const SizedBox(height: 32),

                    _buildActionButtons(request),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildQuantityActions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(onTap: () => setState(() => _incrementQuantity()), child: const Icon(Icons.arrow_drop_up)),
        InkWell(onTap: () => setState(() => _decrementQuantity()), child: const Icon(Icons.arrow_drop_down)),
      ],
    );
  }

  Widget _buildTotalPriceDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Estimated Total Price'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Rp ${NumberFormat('#,##0', 'id_ID').format(totalPrice)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(CookieRequest request) {
    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _submitForm(request),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : Text(widget.ticket != null ? 'Update Ticket' : 'Submit Booking'),
          ),
        ),
      ],
    );
  }
}