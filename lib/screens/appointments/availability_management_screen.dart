import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/availability_slot.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/calendar/custom_calendar.dart';

class AvailabilityManagementScreen extends ConsumerStatefulWidget {
  const AvailabilityManagementScreen({super.key});

  @override
  ConsumerState<AvailabilityManagementScreen> createState() => _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState extends ConsumerState<AvailabilityManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  Set<DayOfWeek> _selectedDays = {};
  List<TimeSlot> _timeSlots = [];
  DateTime _recurringStartDate = DateTime.now();
  DateTime _recurringEndDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProfileProvider);

    if (currentUser?.isCaregiver != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Availability Management')),
        body: const Center(
          child: Text('This feature is only available for caregivers'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        actions: [
          IconButton(
            onPressed: _showQuickActions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily Availability', icon: Icon(Icons.today)),
            Tab(text: 'Recurring Schedule', icon: Icon(Icons.repeat)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyAvailabilityTab(currentUser!.id),
          _buildRecurringScheduleTab(currentUser.id),
        ],
      ),
    );
  }

  Widget _buildDailyAvailabilityTab(String caregiverId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Date',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomCalendar(
                    onDateSelected: (date) {
                      if (date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Current Availability for Selected Date
          _buildDailyAvailabilityList(caregiverId),

          const SizedBox(height: 24),

          // Add Availability Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddAvailabilityDialog(caregiverId, _selectedDate),
              icon: const Icon(Icons.add),
              label: const Text('Add Availability Slot'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringScheduleTab(String caregiverId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Days Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Days of Week',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDaySelector(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Time Slots
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Time Slots',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addTimeSlot,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Slot'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTimeSlotsList(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Date Range
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule Period',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Start Date',
                          date: _recurringStartDate,
                          onTap: () => _selectStartDate(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          label: 'End Date',
                          date: _recurringEndDate,
                          onTap: () => _selectEndDate(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Create Recurring Schedule Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canCreateRecurringSchedule()
                  ? () => _createRecurringSchedule(caregiverId)
                  : null,
              icon: const Icon(Icons.repeat),
              label: const Text('Create Recurring Schedule'),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Schedule Templates
          _buildQuickTemplates(caregiverId),
        ],
      ),
    );
  }

  Widget _buildDailyAvailabilityList(String caregiverId) {
    final availabilitySlotsAsync = ref.watch(availabilitySlotsProvider(
      AvailabilityFilters(
        caregiverId: caregiverId,
        date: _selectedDate,
      ),
    ));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Availability for ${_formatDate(_selectedDate)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            availabilitySlotsAsync.when(
              data: (slots) {
                if (slots.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.schedule_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No availability set for this date'),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: slots.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    return _buildAvailabilitySlotCard(slot);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySlotCard(AvailabilitySlot slot) {
    return Card(
      color: _getSlotStatusColor(slot.status).withAlpha((255 * 0.1).round()),
      child: ListTile(
        leading: Icon(
          _getSlotStatusIcon(slot.status),
          color: _getSlotStatusColor(slot.status),
        ),
        title: Text(slot.timeSlot.timeRange),
        subtitle: Text(slot.statusText),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onSlotMenuSelected(value, slot),
          itemBuilder: (context) => [
            if (slot.isAvailable) ...[
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 16),
                    SizedBox(width: 8),
                    Text('Block'),
                  ],
                ),
              ),
            ] else if (slot.isBlocked) ...[
              const PopupMenuItem(
                value: 'unblock',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16),
                    SizedBox(width: 8),
                    Text('Make Available'),
                  ],
                ),
              ),
            ],
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = [
      (DayOfWeek.monday, 'Mon'),
      (DayOfWeek.tuesday, 'Tue'),
      (DayOfWeek.wednesday, 'Wed'),
      (DayOfWeek.thursday, 'Thu'),
      (DayOfWeek.friday, 'Fri'),
      (DayOfWeek.saturday, 'Sat'),
      (DayOfWeek.sunday, 'Sun'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: days.map((day) {
        final isSelected = _selectedDays.contains(day.$1);
        return FilterChip(
          label: Text(day.$2),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(day.$1);
              } else {
                _selectedDays.remove(day.$1);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTimeSlotsList() {
    if (_timeSlots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No time slots added yet'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _timeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = _timeSlots[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(timeSlot.timeRange),
            trailing: IconButton(
              onPressed: () => _removeTimeSlot(index),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(_formatDate(date)),
      ),
    );
  }

  Widget _buildQuickTemplates(String caregiverId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Templates',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTemplateChip(
                  'Full Week (9-5)',
                  () => _applyTemplate(_getFullWeekTemplate()),
                ),
                _buildTemplateChip(
                  'Weekdays Only',
                  () => _applyTemplate(_getWeekdaysTemplate()),
                ),
                _buildTemplateChip(
                  'Weekends Only',
                  () => _applyTemplate(_getWeekendsTemplate()),
                ),
                _buildTemplateChip(
                  'Evening Hours',
                  () => _applyTemplate(_getEveningTemplate()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block Time Range'),
              onTap: () {
                Navigator.pop(context);
                _showBlockTimeDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Previous Week'),
              onTap: () {
                Navigator.pop(context);
                _copyPreviousWeek();
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Clear All Availability'),
              onTap: () {
                Navigator.pop(context);
                _showClearAllDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAvailabilityDialog(String caregiverId, DateTime date) {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Availability for ${_formatDate(date)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text(startTime?.format(context) ?? 'Select time'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (time != null) {
                          setDialogState(() {
                            startTime = time;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Time'),
                      subtitle: Text(endTime?.format(context) ?? 'Select time'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: endTime ?? const TimeOfDay(hour: 17, minute: 0),
                        );
                        if (time != null) {
                          setDialogState(() {
                            endTime = time;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: startTime != null && endTime != null
                  ? () {
                      Navigator.of(context).pop();
                      _createSingleAvailabilitySlot(caregiverId, date, startTime!, endTime!);
                    }
                  : null,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockTimeDialog() {
    // Implementation for blocking time ranges
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Block time functionality coming soon')),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Availability'),
        content: const Text('Are you sure you want to clear all your availability? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllAvailability();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _addTimeSlot() {
    showDialog(
      context: context,
      builder: (context) {
        TimeOfDay? startTime;
        TimeOfDay? endTime;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add Time Slot'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(startTime?.format(context) ?? 'Select time'),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (time != null) {
                      setDialogState(() {
                        startTime = time;
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('End Time'),
                  subtitle: Text(endTime?.format(context) ?? 'Select time'),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 17, minute: 0),
                    );
                    if (time != null) {
                      setDialogState(() {
                        endTime = time;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: startTime != null && endTime != null
                    ? () {
                        final timeSlot = TimeSlot(
                          startTime: DateTime(2024, 1, 1, startTime!.hour, startTime!.minute),
                          endTime: DateTime(2024, 1, 1, endTime!.hour, endTime!.minute),
                        );
                        setState(() {
                          _timeSlots.add(timeSlot);
                        });
                        Navigator.of(context).pop();
                      }
                    : null,
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _timeSlots.removeAt(index);
    });
  }

  void _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recurringStartDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _recurringStartDate = date;
        if (_recurringEndDate.isBefore(date)) {
          _recurringEndDate = date.add(const Duration(days: 30));
        }
      });
    }
  }

  void _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recurringEndDate,
      firstDate: _recurringStartDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _recurringEndDate = date;
      });
    }
  }

  void _createSingleAvailabilitySlot(
    String caregiverId,
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    try {
      final timeSlot = TimeSlot(
        startTime: DateTime(2024, 1, 1, startTime.hour, startTime.minute),
        endTime: DateTime(2024, 1, 1, endTime.hour, endTime.minute),
      );

      final availabilitySlot = AvailabilitySlot(
        id: '',
        caregiverId: caregiverId,
        date: date,
        timeSlot: timeSlot,
        status: SlotStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(appointmentServiceProvider).createAvailabilitySlot(availabilitySlot);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability slot added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(availabilitySlotsProvider);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add availability: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createRecurringSchedule(String caregiverId) async {
    if (!_canCreateRecurringSchedule()) return;

    try {
      await ref.read(appointmentServiceProvider).createRecurringAvailability(
        caregiverId: caregiverId,
        days: _selectedDays.toList(),
        timeSlots: _timeSlots,
        startDate: _recurringStartDate,
        endDate: _recurringEndDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring schedule created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form
        setState(() {
          _selectedDays.clear();
          _timeSlots.clear();
          _recurringStartDate = DateTime.now();
          _recurringEndDate = DateTime.now().add(const Duration(days: 30));
        });
        
        ref.invalidate(availabilitySlotsProvider);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create recurring schedule: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSlotMenuSelected(String value, AvailabilitySlot slot) {
    switch (value) {
      case 'block':
        // Block the slot
        break;
      case 'unblock':
        // Unblock the slot
        break;
      case 'delete':
        // Delete the slot
        break;
    }
  }

  void _copyPreviousWeek() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copy previous week functionality coming soon')),
    );
  }

  void _clearAllAvailability() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clear all functionality coming soon')),
    );
  }

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _selectedDays = Set<DayOfWeek>.from(template['days']);
      _timeSlots = List<TimeSlot>.from(template['timeSlots']);
    });
  }

  Map<String, dynamic> _getFullWeekTemplate() {
    return {
      'days': [
        DayOfWeek.monday,
        DayOfWeek.tuesday,
        DayOfWeek.wednesday,
        DayOfWeek.thursday,
        DayOfWeek.friday,
        DayOfWeek.saturday,
        DayOfWeek.sunday,
      ],
      'timeSlots': [
        TimeSlot(
          startTime: DateTime(2024, 1, 1, 9, 0),
          endTime: DateTime(2024, 1, 1, 17, 0),
        ),
      ],
    };
  }

  Map<String, dynamic> _getWeekdaysTemplate() {
    return {
      'days': [
        DayOfWeek.monday,
        DayOfWeek.tuesday,
        DayOfWeek.wednesday,
        DayOfWeek.thursday,
        DayOfWeek.friday,
      ],
      'timeSlots': [
        TimeSlot(
          startTime: DateTime(2024, 1, 1, 9, 0),
          endTime: DateTime(2024, 1, 1, 17, 0),
        ),
      ],
    };
  }

  Map<String, dynamic> _getWeekendsTemplate() {
    return {
      'days': [DayOfWeek.saturday, DayOfWeek.sunday],
      'timeSlots': [
        TimeSlot(
          startTime: DateTime(2024, 1, 1, 10, 0),
          endTime: DateTime(2024, 1, 1, 16, 0),
        ),
      ],
    };
  }

  Map<String, dynamic> _getEveningTemplate() {
    return {
      'days': [
        DayOfWeek.monday,
        DayOfWeek.tuesday,
        DayOfWeek.wednesday,
        DayOfWeek.thursday,
        DayOfWeek.friday,
      ],
      'timeSlots': [
        TimeSlot(
          startTime: DateTime(2024, 1, 1, 17, 0),
          endTime: DateTime(2024, 1, 1, 21, 0),
        ),
      ],
    };
  }

  bool _canCreateRecurringSchedule() {
    return _selectedDays.isNotEmpty &&
           _timeSlots.isNotEmpty &&
           _recurringStartDate.isBefore(_recurringEndDate);
  }

  Color _getSlotStatusColor(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return Colors.green;
      case SlotStatus.booked:
        return Colors.blue;
      case SlotStatus.unavailable:
        return Colors.grey;
      case SlotStatus.blocked:
        return Colors.red;
      case SlotStatus.tentative:
        return Colors.orange;
    }
  }

  IconData _getSlotStatusIcon(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return Icons.check_circle;
      case SlotStatus.booked:
        return Icons.event_busy;
      case SlotStatus.unavailable:
        return Icons.cancel;
      case SlotStatus.blocked:
        return Icons.block;
      case SlotStatus.tentative:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}