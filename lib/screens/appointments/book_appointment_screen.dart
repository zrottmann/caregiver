import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final String? caregiverId;

  const BookAppointmentScreen({super.key, this.caregiverId});

  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedCaregiver = 'Sarah Johnson';
  String _description = '';

  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: const Color(0xFF2E7D8A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caregiver Selection
            _buildSection(
              'Select Caregiver',
              DropdownButtonFormField<String>(
                value: _selectedCaregiver,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Choose a caregiver',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Sarah Johnson',
                    child: Text('Sarah Johnson - Personal Care'),
                  ),
                  DropdownMenuItem(
                    value: 'Mike Wilson',
                    child: Text('Mike Wilson - Medical Care'),
                  ),
                  DropdownMenuItem(
                    value: 'Emma Davis',
                    child: Text('Emma Davis - Companionship'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCaregiver = value!;
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // Date Selection
            _buildSection(
              'Select Date',
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(_selectedDate != null
                    ? 'Date: ${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'
                    : 'Choose a date'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectDate,
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Time Selection
            _buildSection(
              'Select Time',
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(_selectedTime != null
                    ? 'Time: ${_selectedTime!.format(context)}'
                    : 'Choose a time'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectTime,
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Description
            _buildSection(
              'Description (Optional)',
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Describe any specific needs or requirements...',
                ),
                onChanged: (value) {
                  _description = value;
                },
              ),
            ),

            const Spacer(),

            // Book Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canBookAppointment() ? _bookAppointment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D8A),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Book Appointment',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  bool _canBookAppointment() {
    return _selectedDate != null && _selectedTime != null;
  }

  Future<void> _bookAppointment() async {
    if (!_canBookAppointment()) return;

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not logged in');
      }

      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final appointment = Appointment(
        id: 'apt_${DateTime.now().millisecondsSinceEpoch}',
        patientId: user.$id,
        caregiverId: 'caregiver_${_selectedCaregiver.replaceAll(' ', '_').toLowerCase()}',
        patientName: user.name,
        caregiverName: _selectedCaregiver,
        startTime: startDateTime,
        endTime: startDateTime.add(const Duration(hours: 1)),
        status: AppointmentStatus.scheduled,
        type: AppointmentType.oneTime,
        services: ['General Care'],
        description: _description.isNotEmpty ? _description : null,
        totalAmount: 50.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create the appointment
      await ref.read(appointmentServiceProvider).createAppointment(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}