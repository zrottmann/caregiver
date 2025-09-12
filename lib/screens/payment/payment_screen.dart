import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/booking.dart';
import '../../models/payment.dart' as PaymentModels;
import '../../config/app_config.dart';
import '../../services/payment_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const PaymentScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isProcessingPayment = false;
  Booking? _booking;
  String? _paymentIntentId;

  @override
  void initState() {
    super.initState();
    _loadBooking();
    _initializeForm();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    try {
      final booking = await ref.read(bookingProvider.notifier).getBooking(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load booking details: ${e.toString()}');
      }
    }
  }

  void _initializeForm() {
    final currentProfile = ref.read(currentUserProfileProvider);
    if (currentProfile != null) {
      _nameController.text = currentProfile.name;
      _emailController.text = currentProfile.email;
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate() || _booking == null) return;

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final paymentService = PaymentService();

      // Create payment intent
      final paymentIntentResponse = await paymentService.createPaymentIntent(
        amount: _booking!.totalAmount,
        currency: AppConfig.currency,
        bookingId: widget.bookingId,
        metadata: {
          'patient_id': _booking!.patientId,
          'caregiver_id': _booking!.caregiverId,
          'scheduled_date': _booking!.scheduledDate.toIso8601String(),
        },
      );

      final clientSecret = paymentIntentResponse['client_secret'] as String;
      _paymentIntentId = paymentIntentResponse['id'] as String;

      // Update booking with payment intent ID
      await ref.read(bookingProvider.notifier).updatePaymentIntent(
        widget.bookingId,
        _paymentIntentId!,
      );

      // Process payment using Stripe Payment Sheet
      final billingDetails = BillingDetails(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      final result = await paymentService.processPayment(
        clientSecret: clientSecret,
        billingDetails: billingDetails,
      );

      if (result.status == PaymentIntentStatus.succeeded) {
        // Update booking status to confirmed
        await ref.read(bookingProvider.notifier).updateBookingStatus(
          widget.bookingId,
          BookingStatus.confirmed,
        );

        if (mounted) {
          _showSuccessDialog();
        }
      } else if (result.status == PaymentIntentStatus.canceled) {
        if (mounted) {
          _showError('Payment was cancelled');
        }
      } else {
        if (mounted) {
          _showError('Payment failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 64,
        ),
        title: const Text('Payment Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your booking has been confirmed.'),
            const SizedBox(height: 16),
            Text(
              'Booking ID: ${widget.bookingId.substring(0, 8)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/booking-details/${widget.bookingId}');
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                    // Booking Summary Card
                    Container(
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
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  child: const Icon(Icons.medical_services, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _booking!.caregiverName,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      Text(
                                        DateFormat('EEEE, MMMM d, y').format(_booking!.scheduledDate),
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        _booking!.timeSlot,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_booking!.services.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: _booking!.services.map((service) {
                                  return Chip(
                                    label: Text(service),
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer.withAlpha((255 * 0.5).round()),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Details
                    Text(
                      'Payment Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Billing Information
                    Container(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Billing Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Method Info Card
                    Container(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Secure Payment',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your payment is secured by Stripe. We never store your card details.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/stripe-logo.png',
                                  height: 20,
                                  errorBuilder: (context, error, stackTrace) => 
                                      const Text('Stripe', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.security, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'SSL Encrypted',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
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

            // Bottom Section with Price and Pay Button
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Service Fee'),
                      Text('\$${(_booking!.totalAmount - AppConfig.bookingFee).toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Platform Fee'),
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
                        '\$${_booking!.totalAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Pay Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessingPayment ? null : _processPayment,
                      icon: _isProcessingPayment 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.payment),
                      label: Text(
                        _isProcessingPayment 
                            ? 'Processing...' 
                            : 'Pay \$${_booking!.totalAmount.toStringAsFixed(2)}',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
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