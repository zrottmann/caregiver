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

class EnhancedBookingFormScreen extends ConsumerStatefulWidget {
  final String caregiverId;
  final List<BookingService>? preSelectedServices;

  const EnhancedBookingFormScreen({
    super.key,
    required this.caregiverId,
    this.preSelectedServices,
  });

  @override
  ConsumerState<EnhancedBookingFormScreen> createState() => _EnhancedBookingFormScreenState();
}

class _EnhancedBookingFormScreenState extends ConsumerState<EnhancedBookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final PageController _pageController = PageController();

  // Booking details
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  List<BookingService> _selectedServices = [];
  
  // UI state
  int _currentStep = 0;
  bool _isLoading = false;
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize with pre-selected services if provided
    if (widget.preSelectedServices != null) {
      _selectedServices = List.from(widget.preSelectedServices!);
    }
    
    // Load availability data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedDate != null) {
        ref.read(bookingProvider.notifier).loadAvailableTimeSlots(widget.caregiverId, _selectedDate!);
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  UserProfile? get caregiver {
    return ref.read(caregiverProvider.notifier).getCaregiverById(widget.caregiverId);
  }

  double get totalAmount {
    return _selectedServices.fold(0.0, (sum, service) => sum + service.totalPrice);
  }

  int get totalDuration {
    return _selectedServices.fold(0, (sum, service) => sum + service.totalDuration);
  }

  String get formattedDuration {
    final hours = totalDuration ~/ 60;
    final minutes = totalDuration % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  Future<void> _selectDate(DateTime selectedDay) async {
    if (isSameDay(_selectedDate, selectedDay)) return;

    setState(() {
      _selectedDate = selectedDay;
      _focusedDay = selectedDay;
      _selectedTimeSlot = null; // Reset time slot when date changes
    });

    // Load available time slots for the selected date
    ref.read(bookingProvider.notifier).loadAvailableTimeSlots(widget.caregiverId, selectedDay);
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedFromCurrentStep() {
    switch (_currentStep) {
      case 0: // Services selection
        return _selectedServices.isNotEmpty;
      case 1: // Date and time selection
        return _selectedDate != null && _selectedTimeSlot != null;
      case 2: // Details
        return _formKey.currentState?.validate() ?? false;
      default:
        return false;
    }
  }

  Future<void> _submitBooking() async {
    if (!_canProceedFromCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      final currentProfile = ref.read(currentUserProfileProvider);
      
      if (currentUser == null || currentProfile == null) {
        throw 'User not authenticated';
      }

      if (caregiver == null) {
        throw 'Caregiver not found';
      }

      final booking = Booking(
        id: '',
        patientId: currentUser.$id,
        caregiverId: widget.caregiverId,
        patientName: currentProfile.name,
        caregiverName: caregiver!.name,
        scheduledDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
        description: _descriptionController.text.trim(),
        services: _selectedServices.map((s) => s.serviceName).toList(),
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildServicesStep(),
                _buildDateTimeStep(),
                _buildDetailsStep(),
              ],
            ),
          ),

          // Bottom Navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            _buildStepIndicator(
              step: i + 1,
              isActive: i <= _currentStep,
              isCompleted: i < _currentStep,
            ),
            if (i < 2) Expanded(child: _buildStepConnector(i < _currentStep)),
          ],
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, {required bool isActive, required bool isCompleted}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? Theme.of(context).primaryColor
            : isActive
                ? Theme.of(context).primaryColor.withAlpha((255 * 0.2).round())
                : Colors.grey[300],
        border: isActive && !isCompleted
            ? Border.all(color: Theme.of(context).primaryColor, width: 2)
            : null,
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                step.toString(),
                style: TextStyle(
                  color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildStepConnector(bool isCompleted) {
    return Container(
      height: 2,
      color: isCompleted ? Theme.of(context).primaryColor : Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildServicesStep() {
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
            'Choose the care services you need',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          // Service Selection Button
          if (_selectedServices.isEmpty) ...[
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to service selection screen
                  context.pushNamed(
                    'service-selection',
                    pathParameters: {'caregiverId': widget.caregiverId},
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Services'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ),
          ] else ...[
            // Selected Services List
            Expanded(
              child: ListView.builder(
                itemCount: _selectedServices.length,
                itemBuilder: (context, index) {
                  final service = _selectedServices[index];
                  return _buildSelectedServiceCard(service, index);
                },
              ),
            ),

            // Add More Services Button
            TextButton.icon(
              onPressed: () {
                // Navigate to service selection screen to add more
                context.pushNamed(
                  'service-selection',
                  pathParameters: {'caregiverId': widget.caregiverId},
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add More Services'),
            ),

            // Services Summary
            _buildServicesSummary(),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedServiceCard(BookingService service, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.serviceName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${service.formattedPrice} × ${service.quantity}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  Text(
                    'Duration: ${service.durationMinutes}m × ${service.quantity}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${service.totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedServices.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Cost:'),
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Duration:'),
              Text(
                formattedDuration,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeStep() {
    final bookingState = ref.watch(bookingProvider);
    final availableSlots = bookingState.availableTimeSlots;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date & Time',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred date and time slot',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          // Calendar
          Card(
            child: TableCalendar<String>(
              firstDay: DateTime.now().add(const Duration(days: 1)),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              availableGestures: AvailableGestures.all,
              onDaySelected: (selectedDay, focusedDay) {
                if (selectedDay.isAfter(DateTime.now())) {
                  _selectDate(selectedDay);
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red[400]),
                holidayTextStyle: TextStyle(color: Colors.red[400]),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha((255 * 0.5).round()),
                  shape: BoxShape.circle,
                ),
                disabledTextStyle: TextStyle(color: Colors.grey[400]),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Time Slots
          if (_selectedDate != null) ...[
            Text(
              'Available Time Slots',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            if (bookingState.isLoadingAvailability) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (availableSlots.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[600]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('No available time slots for this date. Please select another date.'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: availableSlots.length,
                itemBuilder: (context, index) {
                  final timeSlot = availableSlots[index];
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
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Provide additional information about your booking',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Care Description
            Text(
              'Care Description *',
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
            const SizedBox(height: 24),

            // Booking Summary
            _buildBookingSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            
            _buildSummaryRow('Caregiver', caregiver!.name),
            if (_selectedDate != null)
              _buildSummaryRow('Date', DateFormat('EEEE, MMMM d, y').format(_selectedDate!)),
            if (_selectedTimeSlot != null)
              _buildSummaryRow('Time', _selectedTimeSlot!),
            _buildSummaryRow('Duration', formattedDuration),
            _buildSummaryRow('Services', '${_selectedServices.length} service${_selectedServices.length != 1 ? 's' : ''}'),
            
            const Divider(),
            _buildSummaryRow(
              'Total Amount',
              '\$${totalAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isTotal ? FontWeight.bold : null,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isTotal ? FontWeight.bold : null,
                  color: isTotal ? Theme.of(context).primaryColor : null,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
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
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _canProceedFromCurrentStep()
                  ? (_currentStep == 2 ? (_isLoading ? null : _submitBooking) : _nextStep)
                  : null,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep == 2 ? 'Proceed to Payment' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}