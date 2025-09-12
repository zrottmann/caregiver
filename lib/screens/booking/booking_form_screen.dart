import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/caregiver_provider.dart';
import '../../models/user_profile.dart';
import '../../models/booking.dart';
import '../../models/service.dart';
import '../../config/app_config.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  final String caregiverId;
  final List<BookingService>? preSelectedServices;

  const BookingFormScreen({
    super.key,
    required this.caregiverId,
    this.preSelectedServices,
  });

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  List<BookingService> _selectedServices = [];
  bool _isLoading = false;
  bool _showCalendar = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  UserProfile? get caregiver {
    return ref.read(caregiverProvider.notifier).getCaregiverById(widget.caregiverId);
  }

  double get totalAmount {
    if (caregiver?.hourlyRate == null) return AppConfig.bookingFee;
    
    // Calculate based on 2-hour minimum booking + booking fee
    final serviceHours = 2.0;
    final serviceAmount = caregiver!.hourlyRate! * serviceHours;
    return serviceAmount + AppConfig.bookingFee;
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showError('Please select a date');
      return;
    }
    if (_selectedTimeSlot == null) {
      _showError('Please select a time slot');
      return;
    }
    if (_selectedServices.isEmpty) {
      _showError('Please select at least one service');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      final currentProfile = ref.read(currentUserProfileProvider);
      
      if (currentUser == null || currentProfile == null) {
        throw 'User not authenticated';
      }

      final booking = Booking(
        id: '',
        patientId: currentUser.$id,
        caregiverId: widget.caregiverId,
        patientName: currentProfile.name,
        caregiverName: caregiver?.name ?? '',
        scheduledDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
        description: _descriptionController.text.trim(),
        services: _selectedServices,
        totalAmount: totalAmount,
        status: BookingStatus.pending,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdBooking = await ref.read(bookingProvider.notifier).createBooking(booking);

      if (mounted) {
        // Navigate to payment screen
        context.pushReplacement('/payment/${createdBooking.id}');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (caregiver == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Caregiver')),
        body: const Center(
          child: Text('Caregiver not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Caregiver'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Caregiver Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              backgroundImage: caregiver!.profileImageUrl != null
                                  ? NetworkImage(caregiver!.profileImageUrl!)
                                  : null,
                              child: caregiver!.profileImageUrl == null
                                  ? Text(
                                      caregiver!.name[0].toUpperCase(),
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    caregiver!.name,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (caregiver!.location != null)
                                    Text(caregiver!.location!),
                                  if (caregiver!.rating != null)
                                    Row(
                                      children: [
                                        Icon(Icons.star, size: 16, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text('${caregiver!.rating!.toStringAsFixed(1)}'),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            if (caregiver!.hourlyRate != null)
                              Text(
                                '\$${caregiver!.hourlyRate!.toStringAsFixed(0)}/hr',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date Selection
                    Text(
                      'Select Date',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text(
                          _selectedDate != null
                              ? DateFormat('EEEE, MMMM d, y').format(_selectedDate!)
                              : 'Choose a date',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _selectDate,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Slot Selection
                    Text(
                      'Select Time Slot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _timeSlots.length,
                      itemBuilder: (context, index) {
                        final timeSlot = _timeSlots[index];
                        final isSelected = _selectedTimeSlot == timeSlot;
                        
                        return FilterChip(
                          label: Text(
                            timeSlot,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTimeSlot = selected ? timeSlot : null;
                            });
                          },
                          backgroundColor: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Services Selection
                    Text(
                      'Select Services',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: caregiver!.services.map((service) {
                        final isSelected = _selectedServices.contains(service);
                        return FilterChip(
                          label: Text(service),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedServices.add(service);
                              } else {
                                _selectedServices.remove(service);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Care Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Describe the care needed...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please describe the care needed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Additional Notes
                    Text(
                      'Additional Notes (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'Any special requirements or notes...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Section with Price and Book Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.1).round()),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Price Breakdown
                  if (caregiver!.hourlyRate != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Service (2 hours)'),
                        Text('\$${(caregiver!.hourlyRate! * 2).toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Booking Fee'),
                      Text('\$${AppConfig.bookingFee.toStringAsFixed(2)}'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Book Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitBooking,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Continue to Payment'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}