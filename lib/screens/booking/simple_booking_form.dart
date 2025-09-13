import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/simple_appointment_service.dart';

class SimpleBookingForm extends StatefulWidget {
  const SimpleBookingForm({super.key});

  @override
  State<SimpleBookingForm> createState() => _SimpleBookingFormState();
}

class _SimpleBookingFormState extends State<SimpleBookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientEmailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _appointmentService = SimpleAppointmentService();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String _selectedCaregiver = 'Dr. Sarah Johnson';
  String _selectedLocation = 'Home';
  String _locationAddress = '123 Main St, Baltimore, MD 21201';
  bool _isLoading = false;

  final List<String> _caregivers = [
    'Dr. Sarah Johnson',
    'Nurse Maria Garcia',
    'Therapist John Smith',
    'Aide Jennifer Lee',
    'Specialist Robert Brown',
  ];

  final List<String> _locations = [
    'Home',
    'Clinic',
    'Hospital',
    'Senior Center',
  ];

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientEmailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
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
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final appointment = SimpleAppointment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        caregiverName: _selectedCaregiver,
        dateTime: appointmentDateTime,
        price: 150.0, // Base price
        status: 'scheduled',
        description: _descriptionController.text,
        location: _selectedLocation,
        locationAddress: _locationAddress,
        patientEmail: _patientEmailController.text.trim(),
        patientName: _patientNameController.text.trim(),
      );

      await _appointmentService.bookAppointment(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Appointment booked successfully! Confirmation email sent.'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _patientNameController.clear();
        _patientEmailController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedDate = DateTime.now().add(const Duration(days: 1));
          _selectedTime = const TimeOfDay(hour: 10, minute: 0);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to book appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: const Color(0xFF2E7D8A),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                color: const Color(0xFF2E7D8A).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.medical_services,
                        color: Color(0xFF2E7D8A),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Christy Cares',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E7D8A),
                              ),
                            ),
                            const Text('Personalized Assisted Living Services'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Patient Information
              Text(
                'Patient Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _patientNameController,
                decoration: const InputDecoration(
                  labelText: 'Patient Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter patient name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _patientEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Appointment Details
              Text(
                'Appointment Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Caregiver Selection
              DropdownButtonFormField<String>(
                value: _selectedCaregiver,
                decoration: const InputDecoration(
                  labelText: 'Select Caregiver',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_add),
                ),
                items: _caregivers.map((caregiver) {
                  return DropdownMenuItem(
                    value: caregiver,
                    child: Text(caregiver),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCaregiver = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date Selection
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Appointment Date'),
                  subtitle: Text(DateFormat('EEEE, MMMM d, y').format(_selectedDate)),
                  trailing: const Icon(Icons.edit),
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(height: 8),

              // Time Selection
              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Appointment Time'),
                  subtitle: Text(_selectedTime.format(context)),
                  trailing: const Icon(Icons.edit),
                  onTap: _selectTime,
                ),
              ),
              const SizedBox(height: 16),

              // Location Selection
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: _locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLocation = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Service Description *',
                  hintText: 'Describe the care needed...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the care needed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Summary Card
              Card(
                color: const Color(0xFF8B5A96).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('📅 ${DateFormat('EEEE, MMMM d, y').format(_selectedDate)}'),
                      Text('🕐 ${_selectedTime.format(context)}'),
                      Text('👩‍⚕️ $_selectedCaregiver'),
                      Text('📍 $_selectedLocation'),
                      const SizedBox(height: 8),
                      Text(
                        'Estimated Cost: \$150.00',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D8A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D8A),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Book Appointment & Send Confirmation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(height: 8),
                      Text(
                        'You will receive a confirmation email with all appointment details, including cancellation policy and contact information.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}