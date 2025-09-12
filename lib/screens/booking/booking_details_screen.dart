import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/booking.dart';

class BookingDetailsScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'chat',
                child: Row(
                  children: [
                    Icon(Icons.chat),
                    SizedBox(width: 8),
                    Text('Start Chat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cancel Booking'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Booking?>(
        future: ref.read(bookingProvider.notifier).getBooking(bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Booking not found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('This booking may have been deleted or does not exist.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final booking = snapshot.data!;
          final currentProfile = ref.watch(currentUserProfileProvider);
          final isPatient = currentProfile?.id == booking.patientId;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Card(
                  color: _getStatusColor(context, booking.status),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(booking.status),
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          booking.statusText,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'ID: ${booking.id.substring(0, 8)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withAlpha((255 * 0.8).round()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Participants
                Text(
                  'Participants',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(booking.patientName),
                        subtitle: const Text('Patient/Family'),
                        trailing: isPatient ? const Text('You') : null,
                      ),
                      const Divider(),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          child: const Icon(Icons.medical_services, color: Colors.white),
                        ),
                        title: Text(booking.caregiverName),
                        subtitle: const Text('Caregiver'),
                        trailing: !isPatient ? const Text('You') : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Schedule Information
                Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Date'),
                        subtitle: Text(
                          DateFormat('EEEE, MMMM d, y').format(booking.scheduledDate),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Time'),
                        subtitle: Text(booking.timeSlot),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Services
                if (booking.services.isNotEmpty) ...[
                  Text(
                    'Services',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: booking.services.map((service) {
                          return Chip(
                            label: Text(service),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Description
                Text(
                  'Care Description',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(booking.description),
                  ),
                ),

                // Notes (if any)
                if (booking.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Additional Notes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(booking.notes!),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Payment Information
                Text(
                  'Payment',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: Icon(
                      booking.paymentIntentId != null ? Icons.check_circle : Icons.payment,
                      color: booking.paymentIntentId != null ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      '\$${booking.totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      booking.paymentIntentId != null ? 'Payment Completed' : 'Payment Pending',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Booking Timeline
                Text(
                  'Timeline',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.add_circle, color: Colors.blue),
                        title: const Text('Booking Created'),
                        subtitle: Text(
                          DateFormat('MMM d, y \'at\' h:mm a').format(booking.createdAt),
                        ),
                      ),
                      if (booking.paymentIntentId != null) ...[
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.payment, color: Colors.green),
                          title: const Text('Payment Processed'),
                          subtitle: Text(
                            DateFormat('MMM d, y \'at\' h:mm a').format(booking.updatedAt),
                          ),
                        ),
                      ],
                      if (booking.status == BookingStatus.confirmed) ...[
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: const Text('Booking Confirmed'),
                          subtitle: Text(
                            DateFormat('MMM d, y \'at\' h:mm a').format(booking.updatedAt),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                if (booking.status == BookingStatus.confirmed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startChat(context, booking),
                      icon: const Icon(Icons.chat),
                      label: const Text('Start Chat'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                if (booking.status == BookingStatus.pending) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelBooking(context, ref, booking),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel Booking'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(BuildContext context, BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'chat':
        _startChat(context, null);
        break;
      case 'cancel':
        _cancelBooking(context, ref, null);
        break;
    }
  }

  void _startChat(BuildContext context, Booking? booking) {
    if (booking != null) {
      context.push('/chat/${booking.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat feature coming soon!')),
      );
    }
  }

  void _cancelBooking(BuildContext context, WidgetRef ref, Booking? booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(bookingProvider.notifier).updateBookingStatus(
                  bookingId,
                  BookingStatus.cancelled,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking cancelled successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel booking: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }
}