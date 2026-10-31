import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:follow_up_planner/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/core/utils/ist_date_time.dart';
import 'package:follow_up_planner/features/follow_up/presentation/providers/follow_up_provider.dart';

class AddCallScreen extends StatefulWidget {
  const AddCallScreen({super.key, this.existingCall});

  // If null, the screen works in Add mode.
  // If a call is provided, the screen works in Edit mode.
  final FollowUpCall? existingCall;

  @override
  State<AddCallScreen> createState() => _AddCallScreenState();
}

class _AddCallScreenState extends State<AddCallScreen> {
  final _formKey = GlobalKey<FormState>();

  final _leadNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _dealValueController = TextEditingController();

  CallPriority _selectedPriority = CallPriority.cold;

  DateTime _selectedDate = DateTime.now();

  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 30);

  bool get _isEditing => widget.existingCall != null;

  @override
  void initState() {
    super.initState();

    // Fill the form when editing an existing call.
    final call = widget.existingCall;

    if (call != null) {
      _leadNameController.text = call.leadName;
      _phoneNumberController.text = call.phoneNumber;

      _dealValueController.text = (call.dealValuePaise / 100).toStringAsFixed(
        2,
      );

      _selectedPriority = call.priority;

      _selectedDate = DateTime(
        call.requestedAt.year,
        call.requestedAt.month,
        call.requestedAt.day,
      );

      _selectedTime = TimeOfDay(
        hour: call.requestedAt.hour,
        minute: call.requestedAt.minute,
      );
    }
  }

  @override
  void dispose() {
    _leadNameController.dispose();
    _phoneNumberController.dispose();
    _dealValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FollowUpProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Follow-Up Call' : 'Add Follow-Up Call'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _buildTextField(
                controller: _leadNameController,
                label: 'Lead Name',
                hint: 'Enter lead name',
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneNumberController,
                label: 'Phone Number',
                hint: 'Enter 10-digit phone number',
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _dealValueController,
                label: 'Deal Value (₹)',
                hint: 'Enter deal value',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              const Text(
                'Call Priority',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<CallPriority>(
                initialValue: _selectedPriority,

                decoration: const InputDecoration(border: OutlineInputBorder()),

                items: CallPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.name.toUpperCase()),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Requested Date',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),

                label: Text(
                  '${_selectedDate.day}/'
                  '${_selectedDate.month}/'
                  '${_selectedDate.year}',
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Requested Time',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: _selectTime,
                icon: const Icon(Icons.access_time),
                label: Text(_selectedTime.format(context)),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: provider.isSaving ? null : _saveCall,

                  child: Text(
                    _isEditing ? 'Update Follow-Up' : 'Save Follow-Up',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }

        if (label == 'Phone Number') {
          final phoneRegex = RegExp(r'^[6-9]\d{9}$');

          if (!phoneRegex.hasMatch(value.trim())) {
            return 'Enter a valid 10-digit phone number';
          }
        }

        if (label == 'Deal Value (₹)') {
          final dealValue = double.tryParse(value.trim());

          if (dealValue == null || dealValue <= 0) {
            return 'Enter a valid deal value greater than zero';
          }
        }

        return null;
      },
    );
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2026),
      lastDate: DateTime(2030),
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (selectedTime != null) {
      setState(() {
        _selectedTime = selectedTime;
      });
    }
  }

  Future<void> _saveCall() async {
    // Step 1: Validate the form.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Step 2: Read the entered values.
    final leadName = _leadNameController.text.trim();

    final phoneNumber = _phoneNumberController.text.trim();

    final dealValue = double.parse(_dealValueController.text.trim());

    // Step 3: Create requested date and time in IST.
    final requestedAt = DateTime.utc(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Step 4: Get the existing call, if editing.
    final existingCall = widget.existingCall;

    // Step 5: Create the updated or new call.
    final call = FollowUpCall(
      id: existingCall?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),

      leadName: leadName,

      phoneNumber: phoneNumber,

      priority: _selectedPriority,

      dealValuePaise: (dealValue * 100).round(),

      requestedAt: requestedAt,

      scheduledAt: requestedAt,

      createdAt: existingCall?.createdAt ?? IstDateTime.nowIst(),
    );

    // Step 6: Call the appropriate provider method.
    final provider = context.read<FollowUpProvider>();

    final result = _isEditing
        ? await provider.editCall(call)
        : await provider.addCall(call);

    if (!mounted) return;

    // Step 7: Show the result.
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Follow-up call updated successfully!'
                : 'Follow-up call scheduled successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Unable to save the follow-up call.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
