import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../models/payment.dart';
import '../../providers/booking_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends ConsumerState<BookingConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  Booking? _booking;
  Payment? _payment;
  Invoice? _invoice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBookingData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  Future<void> _loadBookingData() async {
    try {
      // Load booking details
      final booking = await ref.read(bookingProvider.notifier).getBooking(widget.bookingId);
      
      if (booking != null) {
        setState(() {
          _booking = booking;
        });

        // Load payment information
        final payment = await ref.read(paymentProvider.notifier).getPaymentByBooking(widget.bookingId);
        if (payment != null) {
          setState(() {
            _payment = payment;
          });

          // Load invoice if available
          final invoice = await ref.read(paymentProvider.notifier).getInvoiceByBooking(widget.bookingId);
          if (invoice != null) {
            setState(() {
              _invoice = invoice;
            });
          }
        }
      }
    } catch (e) {
      _showError('Failed to load booking details: ${e.toString()}');
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
        backgroundColor: Colors.red,
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
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
        return Icons.task_alt;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Confirmation'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Confirmation'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking not found',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Animation and Status
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildSuccessHeader(),
              ),
            ),
            
            const SizedBox(height: 32),

            // Booking Details Card
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildBookingDetailsCard(),
            ),
            
            const SizedBox(height: 16),

            // Payment Information
            if (_payment != null) ...[
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildPaymentInfoCard(),
              ),
              const SizedBox(height: 16),
            ],

            // Next Steps Card
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildNextStepsCard(),
            ),
            
            const SizedBox(height: 24),

            // Action Buttons
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    final statusColor = _getStatusColor(_booking!.status);
    final statusIcon = _getStatusIcon(_booking!.status);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: statusColor.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withAlpha((255 * 0.3).round())),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getSuccessTitle(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getSuccessSubtitle(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getSuccessTitle() {
    switch (_booking!.status) {
      case BookingStatus.pending:
        return 'Booking Submitted!';
      case BookingStatus.confirmed:
        return 'Booking Confirmed!';
      case BookingStatus.completed:
        return 'Service Completed!';
      case BookingStatus.cancelled:
        return 'Booking Cancelled';
    }
  }

  String _getSuccessSubtitle() {
    switch (_booking!.status) {
      case BookingStatus.pending:
        return 'Your booking is being processed. You will be notified once confirmed.';
      case BookingStatus.confirmed:
        return 'Your care session has been confirmed. The caregiver will contact you soon.';
      case BookingStatus.completed:
        return 'Thank you for using our service. Hope you had a great experience!';
      case BookingStatus.cancelled:
        return 'Your booking has been cancelled. Any payments will be refunded shortly.';
    }
  }

  Widget _buildBookingDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_booking!.status).withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(_booking!.status).withAlpha((255 * 0.3).round())),
                  ),
                  child: Text(
                    _booking!.statusText,
                    style: TextStyle(
                      color: _getStatusColor(_booking!.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Booking ID
            _buildDetailRow(
              'Booking ID',
              '${_booking!.id.substring(0, 8).toUpperCase()}...',
              Icons.confirmation_number,
            ),

            // Caregiver
            _buildDetailRow(
              'Caregiver',
              _booking!.caregiverName,
              Icons.person,
            ),

            // Date & Time
            _buildDetailRow(
              'Date',
              DateFormat('EEEE, MMMM d, y').format(_booking!.scheduledDate),
              Icons.calendar_today,
            ),

            _buildDetailRow(
              'Time',
              _booking!.timeSlot,
              Icons.access_time,
            ),

            // Services
            if (_booking!.services.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.medical_services,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Services',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _booking!.services.map((service) {
                            return Chip(
                              label: Text(
                                service,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer.withAlpha((255 * 0.5).round()),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Total Amount
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '\$${_booking!.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            _buildDetailRow(
              'Payment Status',
              _payment!.statusText,
              Icons.payment,
            ),

            _buildDetailRow(
              'Amount',
              _payment!.formattedAmount,
              Icons.attach_money,
            ),

            if (_payment!.paymentIntentId != null)
              _buildDetailRow(
                'Transaction ID',
                _payment!.paymentIntentId!.substring(0, 12).toUpperCase(),
                Icons.receipt,
              ),

            if (_invoice != null) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice Available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to invoice screen or download
                      context.push('/invoice/${_invoice!.id}');
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNextStepsCard() {
    final nextSteps = _getNextSteps();
    
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'What\'s Next?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            ...nextSteps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.blue[700],
                          ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  List<String> _getNextSteps() {
    switch (_booking!.status) {
      case BookingStatus.pending:
        return [
          'Wait for booking confirmation (usually within 2 hours)',
          'You will receive a notification once confirmed',
          'The caregiver will contact you to discuss details',
        ];
      case BookingStatus.confirmed:
        return [
          'The caregiver will contact you 24 hours before the appointment',
          'Prepare any necessary items or medications',
          'Be available at the scheduled time and location',
          'You can message the caregiver through the app',
        ];
      case BookingStatus.completed:
        return [
          'Leave a review for your caregiver',
          'Download your invoice for records',
          'Book future appointments if needed',
        ];
      case BookingStatus.cancelled:
        return [
          'Refund will be processed within 3-5 business days',
          'You will receive an email confirmation of the refund',
          'Feel free to book a new appointment when ready',
        ];
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary Actions
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push('/booking-details/${widget.bookingId}');
            },
            icon: const Icon(Icons.visibility),
            label: const Text('View Full Details'),
          ),
        ),
        
        const SizedBox(height: 12),

        // Secondary Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push('/chat/booking-${widget.bookingId}');
                },
                icon: const Icon(Icons.message),
                label: const Text('Message Caregiver'),
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.go('/home');
                },
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Help Section
        Card(
          color: Colors.grey[50],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Need help? Contact our support team.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to support or show contact options
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Contact Support'),
                        content: const Text(
                          'Email: support@careconnect.com\nPhone: 1-800-CARE-123\n\nOur support team is available 24/7 to help you.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Contact'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}