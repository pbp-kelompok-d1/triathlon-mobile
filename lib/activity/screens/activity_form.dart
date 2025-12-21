import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/activity/models/activity_model.dart';
import 'package:triathlon_mobile/activity/screens/activity_menu.dart';
import 'package:triathlon_mobile/constants.dart';

class ActivityFormPage extends StatefulWidget {
  final Activity? activity;

  const ActivityFormPage({super.key, this.activity});

  @override
  State<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<ActivityFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _titleController = TextEditingController();
  final _distanceController = TextEditingController();
  final _notesController = TextEditingController();
  final _durationHoursController = TextEditingController();
  final _durationMinutesController = TextEditingController();
  final _dateController = TextEditingController();

  String _sportCategory = 'running';
  DateTime? _selectedDate;

  final List<Map<String, String>> _sportOptions = [
    {'value': 'running', 'label': 'Running'},
    {'value': 'cycling', 'label': 'Cycling'},
    {'value': 'swimming', 'label': 'Swimming'},
  ];


  @override
  void initState() {
    super.initState();
    if (widget.activity != null) {
      _titleController.text = widget.activity!.title;
      _distanceController.text = widget.activity!.distance.toString();
      _notesController.text = widget.activity!.notesFull;
      _sportCategory = widget.activity!.sportCategory;
      
      // Parse duration
      //"HH:MM:SS" 
      try {
          final parts = widget.activity!.duration.split(':');
          if (parts.length >= 2) {
              // For format "D days, H:MM:SS" (WIP)
              // Simple regex or split
              final timePart = widget.activity!.duration.split(' ').last; 
              final timeParts = timePart.split(':');
              if (timeParts.length == 3) {
                  int h = int.parse(timeParts[0]);
                  int m = int.parse(timeParts[1]);
                  // Add days to hours if present
                  if (widget.activity!.duration.contains('day')) {
                      final dayPart = widget.activity!.duration.split(' day')[0];
                      h += int.parse(dayPart) * 24;
                  }
                  _durationHoursController.text = h.toString();
                  _durationMinutesController.text = m.toString();
              }
          }
      } catch (e) {
          // ignore lol
      }

      // Date
      // doneAtIso is "YYYY-MM-DD"
      try {
        _selectedDate = DateTime.parse(widget.activity!.doneAtIso);
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      } catch (e) {
        // ignore lol
      }
    } else {
        // Default date to today
        _selectedDate = DateTime.now();
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }
  }

  Future<void> _submitPost(bool editing) async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final request = context.read<CookieRequest>();

    try {
      final h = _durationHoursController.text;
      final m = _durationMinutesController.text.padLeft(2, '0');
      final duration = "$h:$m"; 

      final body = {
        'title': _titleController.text,
        'sport_category': _sportCategory,
        'distance': _distanceController.text,
        'duration': duration,
        'done_at': _dateController.text,
        'notes': _notesController.text,
        'place_id': '', // Optional
      };

      final url = editing ? "$baseUrl/activities/edit/${widget.activity!.id}" : "$baseUrl/activities/create/";

      // Send POST request to correct endpoint
      final response = await request.post(
        url,
        body,
      );

      if (!mounted) return;

      // Handle response
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Return true to indicate successful creation
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to activate'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _distanceController.dispose();
    _notesController.dispose();
    _durationHoursController.dispose();
    _durationMinutesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final isEdit = widget.activity != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Activity" : "Add Activity"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a title";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _sportCategory,
                decoration: const InputDecoration(
                  labelText: "Sport",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_run),
                ),
                items: _sportOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option['value'],
                    child: Text(option['label']!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _sportCategory = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _distanceController,
                decoration: const InputDecoration(
                  labelText: "Distance (meters)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter distance";
                  }
                  if (int.tryParse(value) == null) {
                    return "Distance must be a number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationHoursController,
                      decoration: const InputDecoration(
                        labelText: "Hours",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Required";
                         if (int.tryParse(value) == null) return "Invalid";
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _durationMinutesController,
                      decoration: const InputDecoration(
                        labelText: "Minutes",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                         if (value == null || value.isEmpty) return "Required";
                         final n = int.tryParse(value);
                         if (n == null || n < 0 || n > 59) return "0-59";
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: "Date",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please select a date";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: "Notes",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {_submitPost(isEdit);},
                  child: Text(isEdit ? "Save Changes" : "Create Activity"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
