import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/appointment.dart';
import '../../models/availability_slot.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/calendar/custom_calendar.dart';

class AppointmentDetailsScreen extends ConsumerStatefulWidget {
  final String appointmentId;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  ConsumerState<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends ConsumerState<AppointmentDetailsScreen> {
  bool _isRescheduling = false;
  DateTime? _newDate;
  AvailabilitySlot? _newTimeSlot;

  @override
  Widget build(BuildContext context) {
    final appointmentAsync = ref.watch(appointmentProvider(widget.appointmentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        actions: [
          appointmentAsync.when(
            data: (appointment) => PopupMenuButton<String>(
              onSelected: (value) => _onMenuSelected(value, appointment),
              itemBuilder: (context) => [
                if (appointment.canReschedule)
                  const PopupMenuItem(
                    value: 'reschedule',
                    child: Row(
                      children: [
                        Icon(Icons.schedule),
                        SizedBox(width: 8),
                        Text('Reschedule'),
                      ],
                    ),
                  ),
                if (appointment.canCancel)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cancel', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Share'),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: appointmentAsync.when(
        data: (appointment) => _isRescheduling
            ? _buildRescheduleView(appointment)
            : _buildDetailsView(appointment),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load appointment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('$error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsView(Appointment appointment) {
    final currentUser = ref.watch(currentUserProfileProvider);
    final isPatient = currentUser?.id == appointment.patientId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _buildStatusCard(appointment),
          
          const SizedBox(height: 16),
          
          // Main Details Card
          _buildMainDetailsCard(appointment),
          
          const SizedBox(height: 16),
          
          // Participants Card
          _buildParticipantsCard(appointment, isPatient),
          
          const SizedBox(height: 16),
          
          // Services Card
          _buildServicesCard(appointment),
          
          if (appointment.description != null || appointment.notes != null) ...[
            const SizedBox(height: 16),
            _buildNotesCard(appointment),
          ],
          
          const SizedBox(height: 16),
          
          // Cost Card
          _buildCostCard(appointment),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          _buildActionButtons(appointment),
        ],
      ),
    );
  }

  Widget _buildRescheduleView(Appointment appointment) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isRescheduling = false;
                    _newDate = null;
                    _newTimeSlot = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
              ),
              Text(
                'Reschedule Appointment',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Current appointment info
          Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Appointment',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${_formatDate(appointment.startTime)} at ${appointment.timeSlot}'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Date Selection
          Text(
            'Select New Date',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          CustomCalendar(
            showEvents: false,
            onDateSelected: (date) {
              if (date.isAfter(DateTime.now())) {
                setState(() {
                  _newDate = date;
                  _newTimeSlot = null; // Reset time slot
                });
              }
            },
          ),
          
          if (_newDate != null) ...[
            const SizedBox(height: 24),
            
            Text(
              'Select New Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTimeSlotSelection(appointment.caregiverId),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isRescheduling = false;
                        _newDate = null;
                        _newTimeSlot = null;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _newTimeSlot != null ? () => _confirmReschedule(appointment) : null,
                    child: const Text('Confirm Reschedule'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(Appointment appointment) {
    Color statusColor;
    IconData statusIcon;
    
    switch (appointment.status) {
      case AppointmentStatus.scheduled:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case AppointmentStatus.confirmed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case AppointmentStatus.inProgress:
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle;
        break;
      case AppointmentStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case AppointmentStatus.noShow:
        statusColor = Colors.grey;
        statusIcon = Icons.person_off;
        break;
    }

    return Card(
      color: statusColor.withAlpha((255 * 0.1).round()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.statusText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    _getStatusDescription(appointment.status),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainDetailsCard(Appointment appointment) {
    return Card(
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
            
            _buildDetailRow(
              Icons.calendar_today,
              'Date',
              _formatDate(appointment.startTime),
            ),
            
            _buildDetailRow(
              Icons.access_time,
              'Time',
              appointment.timeSlot,
            ),
            
            _buildDetailRow(
              Icons.schedule,
              'Duration',
              '${appointment.appointmentDuration.inHours}h ${appointment.appointmentDuration.inMinutes % 60}m',
            ),
            
            _buildDetailRow(
              Icons.repeat,
              'Type',
              appointment.isRecurring ? 'Recurring' : 'One-time',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsCard(Appointment appointment, bool isPatient) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(appointment.patientName),
              subtitle: const Text('Patient'),
              trailing: isPatient ? const Chip(label: Text('You')) : null,
              contentPadding: EdgeInsets.zero,
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: Text(appointment.caregiverName),
              subtitle: const Text('Caregiver'),
              trailing: !isPatient ? const Chip(label: Text('You')) : null,
              contentPadding: EdgeInsets.zero,
              onTap: () {
                // Navigate to caregiver profile
                context.push('/caregiver-profile/${appointment.caregiverId}');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesCard(Appointment appointment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Services',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: appointment.services.map((service) => Chip(
                label: Text(service),
                avatar: Icon(_getServiceIcon(service), size: 16),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(Appointment appointment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes & Description',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (appointment.description != null) ...[
              Text(
                'Description:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(appointment.description!),
              const SizedBox(height: 16),
            ],
            
            if (appointment.notes != null) ...[
              Text(
                'Additional Notes:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(appointment.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostCard(Appointment appointment) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.attach_money,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Cost',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${appointment.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
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

  Widget _buildActionButtons(Appointment appointment) {
    final currentUser = ref.watch(currentUserProfileProvider);
    final isPatient = currentUser?.id == appointment.patientId;

    return Column(
      children: [
        if (appointment.canReschedule || appointment.canCancel) ...[
          Row(
            children: [
              if (appointment.canReschedule) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isRescheduling = true;
                      });
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Reschedule'),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (appointment.canCancel) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(appointment),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        if (isPatient) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/chat/${appointment.caregiverId}'),
              icon: const Icon(Icons.chat),
              label: const Text('Message Caregiver'),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/chat/${appointment.patientId}'),
              icon: const Icon(Icons.chat),
              label: const Text('Message Patient'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeSlotSelection(String caregiverId) {
    if (_newDate == null) return const SizedBox();

    final availableSlotsAsync = ref.watch(availableSlotsProvider(
      AvailableSlotFilters(
        caregiverId: caregiverId,
        date: _newDate!,
        minimumDuration: const Duration(hours: 1),
      ),
    ));

    return availableSlotsAsync.when(
      data: (slots) {
        if (slots.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No available time slots for this date'),
            ),
          );
        }

        return SizedBox(
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final isSelected = _newTimeSlot?.id == slot.id;
              
              return Card(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _newTimeSlot = slot;
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
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading time slots: $error'),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
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

  void _onMenuSelected(String value, Appointment appointment) {
    switch (value) {
      case 'reschedule':
        setState(() {
          _isRescheduling = true;
        });
        break;
      case 'cancel':
        _showCancelDialog(appointment);
        break;
      case 'share':
        _shareAppointment(appointment);
        break;
    }
  }

  void _showCancelDialog(Appointment appointment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this appointment?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                hintText: 'Please provide a reason for cancellation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelAppointment(appointment, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }

  void _cancelAppointment(Appointment appointment, String reason) async {
    try {
      await ref.read(appointmentNotifierProvider.notifier).cancelAppointment(
        appointment.id,
        reason.isEmpty ? 'No reason provided' : reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel appointment: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmReschedule(Appointment appointment) async {
    if (_newDate == null || _newTimeSlot == null) return;

    try {
      final newStartTime = DateTime(
        _newDate!.year,
        _newDate!.month,
        _newDate!.day,
        _newTimeSlot!.timeSlot.startTime.hour,
        _newTimeSlot!.timeSlot.startTime.minute,
      );

      final newEndTime = DateTime(
        _newDate!.year,
        _newDate!.month,
        _newDate!.day,
        _newTimeSlot!.timeSlot.endTime.hour,
        _newTimeSlot!.timeSlot.endTime.minute,
      );

      await ref.read(appointmentNotifierProvider.notifier).rescheduleAppointment(
        appointment.id,
        newStartTime,
        newEndTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment rescheduled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isRescheduling = false;
          _newDate = null;
          _newTimeSlot = null;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reschedule appointment: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareAppointment(Appointment appointment) {
    // In a real app, you would implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality not implemented yet'),
      ),
    );
  }

  String _getStatusDescription(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Appointment is scheduled and awaiting confirmation';
      case AppointmentStatus.confirmed:
        return 'Appointment has been confirmed by the caregiver';
      case AppointmentStatus.inProgress:
        return 'Appointment is currently in progress';
      case AppointmentStatus.completed:
        return 'Appointment has been completed successfully';
      case AppointmentStatus.cancelled:
        return 'Appointment has been cancelled';
      case AppointmentStatus.noShow:
        return 'Patient did not show up for the appointment';
    }
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
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}