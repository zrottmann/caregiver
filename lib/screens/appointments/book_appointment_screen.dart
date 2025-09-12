import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/appointment.dart';
import '../../models/availability_slot.dart';
import '../../models/user_profile.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caregiver_provider.dart';
import '../../widgets/calendar/custom_calendar.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final String? caregiverId;

  const BookAppointmentScreen({super.key, this.caregiverId});

  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Booking data
  UserProfile? _selectedCaregiver;
  DateTime? _selectedDate;
  AvailabilitySlot? _selectedTimeSlot;
  List<String> _selectedServices = [];
  String _description = '';
  String _notes = '';
  double _estimatedCost = 0.0;

  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.caregiverId != null) {
      _loadCaregiver();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadCaregiver() async {
    try {
      final caregiverAsync = ref.read(caregiverProvider(widget.caregiverId!));
      caregiverAsync.when(
        data: (caregiver) {
          setState(() {
            _selectedCaregiver = caregiver;
          });
        },
        loading: () {},
        error: (_, __) {},
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: const Text('Back'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCaregiverSelectionStep(),
                _buildDateSelectionStep(),
                _buildTimeSlotSelectionStep(),
                _buildServiceSelectionStep(),
                _buildDetailsStep(),
                _buildConfirmationStep(),
              ],
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          for (int i = 0; i < 6; i++) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= _currentStep
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: i <= _currentStep ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (i < 5) ...[
              Expanded(
                child: Container(
                  height: 2,
                  color: i < _currentStep
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCaregiverSelectionStep() {
    if (widget.caregiverId != null && _selectedCaregiver != null) {
      return _buildSelectedCaregiverView();
    }

    final caregiversAsync = ref.watch(caregiversProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a Caregiver',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: caregiversAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : caregiversAsync.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: ${caregiversAsync.error}'),
                            ElevatedButton(
                              onPressed: () => ref.read(caregiversProvider.notifier).loadCaregivers(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: caregiversAsync.caregivers.length,
                        itemBuilder: (context, index) {
                          final caregiver = caregiversAsync.caregivers[index];
                          return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: caregiver.profilePictureUrl != null
                            ? NetworkImage(caregiver.profilePictureUrl!)
                            : null,
                        child: caregiver.profilePictureUrl == null
                            ? Text(caregiver.fullName[0])
                            : null,
                      ),
                      title: Text(caregiver.fullName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (caregiver.specializations != null)
                            Text(caregiver.specializations!.join(', ')),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text('${caregiver.rating ?? 0.0}'),
                              const SizedBox(width: 16),
                              Text('\$${caregiver.hourlyRate ?? 0}/hr'),
                            ],
                          ),
                        ],
                      ),
                      trailing: Radio<UserProfile>(
                        value: caregiver,
                        groupValue: _selectedCaregiver,
                        onChanged: (value) {
                          setState(() {
                            _selectedCaregiver = value;
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCaregiver = caregiver;
                        });
                      },
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCaregiverView() {
    final caregiver = _selectedCaregiver!;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Caregiver',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: caregiver.profilePictureUrl != null
                            ? NetworkImage(caregiver.profilePictureUrl!)
                            : null,
                        child: caregiver.profilePictureUrl == null
                            ? Text(caregiver.fullName[0], style: const TextStyle(fontSize: 24))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              caregiver.fullName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (caregiver.specializations != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                caregiver.specializations!.join(', '),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text('${caregiver.rating ?? 0.0}'),
                                const SizedBox(width: 16),
                                Text(
                                  '\$${caregiver.hourlyRate ?? 0}/hr',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (caregiver.bio != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      caregiver.bio!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CustomCalendar(
                    showEvents: false,
                    onDateSelected: (date) {
                      if (date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
                        setState(() {
                          _selectedDate = date;
                          _selectedTimeSlot = null; // Reset time slot when date changes
                        });
                      }
                    },
                  ),
                  
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Selected: ${_formatDate(_selectedDate!)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotSelectionStep() {
    if (_selectedDate == null || _selectedCaregiver == null) {
      return const Center(child: Text('Please select a caregiver and date first'));
    }

    final availableSlotsAsync = ref.watch(availableSlotsProvider(
      AvailableSlotFilters(
        caregiverId: _selectedCaregiver!.id,
        date: _selectedDate!,
        minimumDuration: const Duration(hours: 1),
      ),
    ));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Time Slot',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Available slots for ${_formatDate(_selectedDate!)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: availableSlotsAsync.when(
              data: (slots) {
                if (slots.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No available time slots',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          'Please select a different date',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final isSelected = _selectedTimeSlot?.id == slot.id;
                    
                    return Card(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTimeSlot = slot;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                slot.timeSlot.timeRange,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error loading slots: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelectionStep() {
    final services = [
      'Senior Care',
      'Child Care',
      'Medical Care',
      'Companionship',
      'Housekeeping',
      'Medication Management',
      'Physical Therapy',
      'Meal Preparation',
      'Transportation',
      'Overnight Care',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Services',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the services you need',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                final isSelected = _selectedServices.contains(service);
                
                return Card(
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedServices.add(service);
                        } else {
                          _selectedServices.remove(service);
                        }
                        _calculateEstimatedCost();
                      });
                    },
                    title: Text(service),
                    secondary: Icon(_getServiceIcon(service)),
                  ),
                );
              },
            ),
          ),
          
          if (_selectedServices.isNotEmpty) ...[
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.list_alt,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Services (${_selectedServices.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          Text(
                            _selectedServices.join(', '),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Describe what you need help with...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _description = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes',
                      hintText: 'Any special instructions or requirements...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _notes = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Summary Card
                  Card(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appointment Summary',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildSummaryRow('Caregiver', _selectedCaregiver?.fullName ?? ''),
                          _buildSummaryRow('Date', _selectedDate != null ? _formatDate(_selectedDate!) : ''),
                          _buildSummaryRow('Time', _selectedTimeSlot?.timeSlot.timeRange ?? ''),
                          _buildSummaryRow('Services', _selectedServices.join(', ')),
                          _buildSummaryRow('Duration', _selectedTimeSlot?.timeSlot.duration.inHours.toString() ?? '' + ' hours'),
                          
                          const Divider(),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Estimated Cost',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${_estimatedCost.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm Appointment',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appointment Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildConfirmationRow(Icons.person, 'Caregiver', _selectedCaregiver?.fullName ?? ''),
                          _buildConfirmationRow(Icons.calendar_today, 'Date', _selectedDate != null ? _formatDate(_selectedDate!) : ''),
                          _buildConfirmationRow(Icons.access_time, 'Time', _selectedTimeSlot?.timeSlot.timeRange ?? ''),
                          _buildConfirmationRow(Icons.medical_services, 'Services', _selectedServices.join(', ')),
                          _buildConfirmationRow(Icons.schedule, 'Duration', '${_selectedTimeSlot?.timeSlot.duration.inHours ?? 0} hours'),
                          _buildConfirmationRow(Icons.attach_money, 'Total Cost', '\$${_estimatedCost.toStringAsFixed(2)}'),
                          
                          if (_description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Description:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_description),
                          ],
                          
                          if (_notes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Notes:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_notes),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Important Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Payment will be processed after the appointment is confirmed\n'
                            '• You can cancel or reschedule up to 24 hours before the appointment\n'
                            '• You will receive reminders 24 hours and 1 hour before the appointment',
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha((255 * 0.2).round()),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextStep : null,
              child: Text(_currentStep == 5 ? 'Book Appointment' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: // Caregiver selection
        return _selectedCaregiver != null;
      case 1: // Date selection
        return _selectedDate != null;
      case 2: // Time slot selection
        return _selectedTimeSlot != null;
      case 3: // Service selection
        return _selectedServices.isNotEmpty;
      case 4: // Details
        return _description.isNotEmpty;
      case 5: // Confirmation
        return true;
      default:
        return false;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _bookAppointment();
    }
  }

  void _bookAppointment() async {
    if (!_canProceed()) return;

    final currentUser = ref.read(currentUserProfileProvider);
    if (currentUser == null) return;

    try {
      final appointment = Appointment(
        id: '',
        patientId: currentUser.id,
        caregiverId: _selectedCaregiver!.id,
        patientName: currentUser.fullName,
        caregiverName: _selectedCaregiver!.fullName,
        startTime: DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTimeSlot!.timeSlot.startTime.hour,
          _selectedTimeSlot!.timeSlot.startTime.minute,
        ),
        endTime: DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTimeSlot!.timeSlot.endTime.hour,
          _selectedTimeSlot!.timeSlot.endTime.minute,
        ),
        status: AppointmentStatus.scheduled,
        type: AppointmentType.oneTime,
        description: _description,
        notes: _notes.isNotEmpty ? _notes : null,
        services: _selectedServices,
        totalAmount: _estimatedCost,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(appointmentNotifierProvider.notifier).createAppointment(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/calendar');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _calculateEstimatedCost() {
    if (_selectedCaregiver == null || _selectedTimeSlot == null) {
      _estimatedCost = 0.0;
      return;
    }

    final hourlyRate = _selectedCaregiver!.hourlyRate ?? 0.0;
    final duration = _selectedTimeSlot!.timeSlot.duration.inHours;
    final baseAmount = hourlyRate * duration;
    
    // Add service-specific costs
    double serviceMultiplier = 1.0;
    if (_selectedServices.contains('Medical Care')) serviceMultiplier += 0.2;
    if (_selectedServices.contains('Overnight Care')) serviceMultiplier += 0.5;
    if (_selectedServices.contains('Physical Therapy')) serviceMultiplier += 0.3;
    
    _estimatedCost = baseAmount * serviceMultiplier;
  }

  IconData _getServiceIcon(String service) {
    switch (service) {
      case 'Senior Care':
        return Icons.elderly;
      case 'Child Care':
        return Icons.child_care;
      case 'Medical Care':
        return Icons.medical_services;
      case 'Companionship':
        return Icons.people;
      case 'Housekeeping':
        return Icons.cleaning_services;
      case 'Medication Management':
        return Icons.medication;
      case 'Physical Therapy':
        return Icons.accessibility;
      case 'Meal Preparation':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Overnight Care':
        return Icons.bedtime;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}