import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:follow_up_planner/core/constants/app_constants.dart';
import 'package:follow_up_planner/core/utils/ist_date_time.dart';
import 'package:follow_up_planner/core/utils/phone_utils.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/domain/services/scheduling_slot_generator.dart';
import 'package:follow_up_planner/features/follow_up/presentation/providers/follow_up_provider.dart';

class AddCallScreen extends StatefulWidget {
  const AddCallScreen({super.key, this.existingCall, this.initialDateTime});

  final FollowUpCall? existingCall;
  final DateTime? initialDateTime;

  @override
  State<AddCallScreen> createState() => _AddCallScreenState();
}

class _AddCallScreenState extends State<AddCallScreen> {
  static const Uuid _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();

  final _leadNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _dealValueController = TextEditingController();

  CallPriority _selectedPriority = CallPriority.cold;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  bool get _isEditing => widget.existingCall != null;

  DateTime _getNextValidSlot() {
    final now = IstDateTime.nowIst();

    var currentDate = DateTime.utc(now.year, now.month, now.day);

    while (true) {
      if (IstDateTime.isWorkingDay(currentDate)) {
        final slots = SchedulingSlotGenerator.generateSlotsForDay(currentDate);

        for (final slot in slots) {
          if (slot.isAfter(now)) {
            return slot;
          }
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  @override
  void initState() {
    super.initState();

    final call = widget.existingCall;

    if (call == null) {
      final initialSlot = widget.initialDateTime ?? _getNextValidSlot();

      _selectedDate = DateTime(
        initialSlot.year,
        initialSlot.month,
        initialSlot.day,
      );

      _selectedTime = TimeOfDay(
        hour: initialSlot.hour,
        minute: initialSlot.minute,
      );
    } else {
      _leadNameController.text = call.leadName;
      _phoneNumberController.text = call.phoneNumber;

      _dealValueController.text = (call.dealValuePaise / 100).toStringAsFixed(
        2,
      );

      _selectedPriority = call.priority;

      _selectedDate = DateTime(
        call.scheduledAt.year,
        call.scheduledAt.month,
        call.scheduledAt.day,
      );

      _selectedTime = TimeOfDay(
        hour: call.scheduledAt.hour,
        minute: call.scheduledAt.minute,
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
                validator: (value) => _validateRequired(value, 'Lead name'),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneNumberController,
                label: 'Phone Number',
                hint: 'Enter 10-digit phone number',
                keyboardType: TextInputType.phone,
                validator: _validatePhoneNumber,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _dealValueController,
                label: 'Deal Value (₹)',
                hint: 'Enter deal value',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                maxLength: 15,
                validator: _validateDealValue,
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

  // CQ-01: Reusable text field with an independent validator.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        counterText: maxLength != null ? null : '',
      ),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  // CQ-02: Uses the central phone number pattern.
  String? _validatePhoneNumber(String? value) {
    final requiredError = _validateRequired(value, 'Phone number');

    if (requiredError != null) {
      return requiredError;
    }

    final normalizedPhone = PhoneUtils.normalize(value!.trim());

    final phoneRegex = RegExp(AppConstants.phoneNumberPattern);

    if (!phoneRegex.hasMatch(normalizedPhone)) {
      return 'Enter a valid 10-digit phone number';
    }

    return null;
  }

  // CQ-04: Converts rupees to paise without floating-point calculations.
  int? _parseDealValueToPaise(String value) {
    final normalizedValue = value.replaceAll(',', '').trim();

    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalizedValue)) {
      return null;
    }

    final parts = normalizedValue.split('.');

    final rupees = int.tryParse(parts[0]);

    if (rupees == null) {
      return null;
    }

    final paisePart = parts.length > 1
        ? int.parse(parts[1].padRight(2, '0'))
        : 0;

    final maxRupees = AppConstants.maxDealValuePaise ~/ 100;

    if (rupees > maxRupees) {
      return null;
    }

    final totalPaise = (rupees * 100) + paisePart;

    if (totalPaise <= 0 || totalPaise > AppConstants.maxDealValuePaise) {
      return null;
    }

    return totalPaise;
  }

  String? _validateDealValue(String? value) {
    final requiredError = _validateRequired(value, 'Deal value');

    if (requiredError != null) {
      return requiredError;
    }

    final dealValuePaise = _parseDealValueToPaise(value!);

    if (dealValuePaise == null) {
      return 'Enter a valid amount up to ₹1 crore (maximum 2 decimals)';
    }

    return null;
  }

  // CQ-05 and CQ-06: Uses IST and a rolling one-year date range.
  Future<void> _selectDate() async {
    final today = IstDateTime.nowIst();

    final firstAllowedDate = DateTime(today.year, today.month, today.day);

    final lastAllowedDate = DateTime(
      firstAllowedDate.year + 1,
      firstAllowedDate.month,
      firstAllowedDate.day,
    );

    final initialDate = _selectedDate.isBefore(firstAllowedDate)
        ? firstAllowedDate
        : _selectedDate.isAfter(lastAllowedDate)
        ? lastAllowedDate
        : _selectedDate;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowedDate,
      lastDate: lastAllowedDate,
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final leadName = _leadNameController.text.trim();

    final phoneNumber = PhoneUtils.normalize(_phoneNumberController.text);

    final dealValuePaise = _parseDealValueToPaise(_dealValueController.text);

    if (dealValuePaise == null) {
      return;
    }

    // Preserve the existing IST wall-clock scheduling convention.
    final requestedAt = DateTime.utc(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final existingCall = widget.existingCall;

    if (existingCall == null) {
      final currentTime = IstDateTime.nowIst();

      if (!requestedAt.isAfter(currentTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a future date and time.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final call = FollowUpCall(
      id: existingCall?.id ?? _uuid.v4(),
      leadName: leadName,
      phoneNumber: phoneNumber,
      priority: _selectedPriority,
      dealValuePaise: dealValuePaise,
      requestedAt: requestedAt,
      scheduledAt: requestedAt,
      createdAt: existingCall?.createdAt ?? IstDateTime.nowIst(),
    );

    final provider = context.read<FollowUpProvider>();

    final result = _isEditing
        ? await provider.editCall(call)
        : await provider.addCall(call);

    if (!mounted) return;

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
