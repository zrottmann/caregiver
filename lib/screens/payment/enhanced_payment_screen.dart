import 'package:flutter/material.dart' hide Card;
import 'package:flutter/material.dart' as FlutterMaterial show Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/booking.dart';
import '../../models/payment.dart' as AppPayment;
import '../../config/app_config.dart';
import '../../services/payment_service.dart';

class EnhancedPaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const EnhancedPaymentScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<EnhancedPaymentScreen> createState() => _EnhancedPaymentScreenState();
}

class _EnhancedPaymentScreenState extends ConsumerState<EnhancedPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isProcessingPayment = false;
  bool _savePaymentMethod = false;
  Booking? _booking;
  AppPayment.PaymentMethod? _selectedPaymentMethod;
  CardFieldInputDetails? _cardDetails;

  @override
  void initState() {
    super.initState();
    _loadBooking();
    _loadPaymentMethods();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    try {
      final booking = await ref.read(bookingProvider.notifier).getBooking(widget.bookingId);
      if (mounted && booking != null) {
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

  Future<void> _loadPaymentMethods() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        await ref.read(paymentProvider.notifier).loadUserPaymentMethods(currentUser.$id);
        final paymentMethods = ref.read(userPaymentMethodsProvider);
        if (paymentMethods.isNotEmpty) {
          setState(() {
            _selectedPaymentMethod = paymentMethods.firstWhere(
              (method) => method.isDefault,
              orElse: () => paymentMethods.first,
            );
          });
        }
      }
    } catch (e) {
      // Payment methods are optional, so we don't show an error if they fail to load
      debugPrint('Failed to load payment methods: $e');
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
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Create payment record
      final payment = await ref.read(paymentProvider.notifier).createPayment(
        bookingId: widget.bookingId,
        userId: currentUser.$id,
        amount: _booking!.totalAmount,
        currency: 'USD',
        paymentMethodId: _selectedPaymentMethod?.id,
        metadata: {
          'booking_id': widget.bookingId,
          'patient_id': _booking!.patientId,
          'caregiver_id': _booking!.caregiverId,
          'scheduled_date': _booking!.scheduledDate.toIso8601String(),
          'time_slot': _booking!.timeSlot,
        },
      );

      // Process payment with Stripe
      if (_selectedPaymentMethod != null) {
        // Use existing payment method
        await _processWithExistingPaymentMethod(payment);
      } else {
        // Process with new payment method using payment sheet
        await _processWithPaymentSheet(payment);
      }

    } catch (e) {
      if (mounted) {
        _showError('Payment failed: ${e.toString()}');
        // Update payment status to failed
        if (ref.read(currentPaymentProvider) != null) {
          await ref.read(paymentProvider.notifier).updatePaymentStatus(
            ref.read(currentPaymentProvider)!.id,
            AppPayment.PaymentStatus.failed,
            failureReason: e.toString(),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  Future<void> _processWithExistingPaymentMethod(AppPayment.Payment payment) async {
    try {
      // In a real implementation, you would confirm the payment intent with Stripe
      // using the selected payment method. For this demo, we'll simulate success.
      
      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Update payment status to succeeded
      await ref.read(paymentProvider.notifier).updatePaymentStatus(
        payment.id,
        AppPayment.PaymentStatus.succeeded,
      );

      // Update booking status to confirmed
      await ref.read(bookingProvider.notifier).updateBookingStatus(
        widget.bookingId,
        BookingStatus.confirmed,
      );

      // Generate invoice
      await ref.read(paymentProvider.notifier).generateInvoice(
        bookingId: widget.bookingId,
        paymentId: payment.id,
        userId: payment.userId,
        lineItems: [
          AppPayment.InvoiceLineItem(
            description: 'Care Services - ${_booking!.caregiverName}',
            quantity: 1,
            unitPrice: _booking!.totalAmount,
            totalPrice: _booking!.totalAmount,
          ),
        ],
        notes: 'Thank you for booking with CareConnect.',
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      throw 'Failed to process payment with existing method: $e';
    }
  }

  Future<void> _processWithPaymentSheet(AppPayment.Payment payment) async {
    try {
      // Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: payment.paymentIntentId, // This would be the client secret
          merchantDisplayName: 'CareConnect',
          billingDetails: BillingDetails(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
          ),
          style: ThemeMode.system,
          allowsDelayedPaymentMethods: false,
        ),
      );

      // Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // Update payment status to succeeded
      await ref.read(paymentProvider.notifier).updatePaymentStatus(
        payment.id,
        AppPayment.PaymentStatus.succeeded,
      );

      // Update booking status to confirmed
      await ref.read(bookingProvider.notifier).updateBookingStatus(
        widget.bookingId,
        BookingStatus.confirmed,
      );

      // Save payment method if requested and card details are available
      if (_savePaymentMethod && _cardDetails != null) {
        // In a real implementation, you would extract the payment method ID from Stripe
        // and save it using the payment provider
      }

      // Generate invoice
      await ref.read(paymentProvider.notifier).generateInvoice(
        bookingId: widget.bookingId,
        paymentId: payment.id,
        userId: payment.userId,
        lineItems: [
          AppPayment.InvoiceLineItem(
            description: 'Care Services - ${_booking!.caregiverName}',
            quantity: 1,
            unitPrice: _booking!.totalAmount,
            totalPrice: _booking!.totalAmount,
          ),
        ],
        notes: 'Thank you for booking with CareConnect.',
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // User canceled the payment
        await ref.read(paymentProvider.notifier).updatePaymentStatus(
          payment.id,
          AppPayment.PaymentStatus.cancelled,
        );
        if (mounted) {
          _showError('Payment was cancelled');
        }
      } else {
        throw 'Stripe error: ${e.error.message}';
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
            const Text('Your booking has been confirmed and an invoice has been generated.'),
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/booking-details/${widget.bookingId}');
            },
            child: const Text('View Details'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('Done'),
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
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showAddPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Payment Method'),
        content: const Text('You can add and manage payment methods in your profile settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/profile/payment-methods');
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final paymentMethods = paymentState.paymentMethods;

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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                    _buildBookingSummaryCard(),
                    const SizedBox(height: 24),

                    // Payment Method Selection
                    _buildPaymentMethodSection(paymentMethods),
                    const SizedBox(height: 24),

                    // Billing Information
                    _buildBillingInformationCard(),
                    const SizedBox(height: 16),

                    // Payment Security Info
                    _buildSecurityInfoCard(),
                  ],
                ),
              ),
            ),

            // Bottom Section with Price and Pay Button
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummaryCard() {
    return FlutterMaterial.Card(
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(_booking!.scheduledDate),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        _booking!.timeSlot,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${_booking!.totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      _booking!.statusText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _booking!.status == BookingStatus.pending
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_booking!.services.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Services:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(List<PaymentMethod> paymentMethods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (paymentMethods.isNotEmpty)
              TextButton.icon(
                onPressed: _showAddPaymentMethodDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add New'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (paymentMethods.isEmpty) ...[
          // No saved payment methods - show card form
          FlutterMaterial.Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter Card Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  CardField(
                    onCardChanged: (card) {
                      setState(() {
                        _cardDetails = card;
                      });
                    },
                    style: CardFieldStyle(
                      borderColor: Colors.grey[300],
                      borderRadius: 8,
                      borderWidth: 1,
                    ),
                  ),
                  const SizedBox(height: 16),

                  CheckboxListTile(
                    value: _savePaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _savePaymentMethod = value ?? false;
                      });
                    },
                    title: const Text('Save payment method for future use'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Show saved payment methods
          Column(
            children: paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod?.id == method.id;
              return FlutterMaterial.Card(
                color: isSelected ? Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()) : null,
                child: RadioListTile<PaymentMethod>(
                  value: method,
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                  title: Row(
                    children: [
                      Icon(
                        method.type == AppPayment.PaymentMethodType.card
                            ? Icons.credit_card
                            : Icons.account_balance,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(method.displayName)),
                      if (method.isDefault) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text('Expires ${method.expiryDisplay}'),
                ),
              );
            }).toList(),
          ),

          // Add new payment method option
          FlutterMaterial.Card(
            color: _selectedPaymentMethod == null 
                ? Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()) 
                : null,
            child: RadioListTile<PaymentMethod?>(
              value: null,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = null;
                });
              },
              title: const Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Use a different payment method'),
                ],
              ),
            ),
          ),

          // Show card form if "different payment method" is selected
          if (_selectedPaymentMethod == null) ...[
            const SizedBox(height: 16),
            FlutterMaterial.Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Card Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    CardField(
                      onCardChanged: (card) {
                        setState(() {
                          _cardDetails = card;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    CheckboxListTile(
                      value: _savePaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _savePaymentMethod = value ?? false;
                        });
                      },
                      title: const Text('Save payment method for future use'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildBillingInformationCard() {
    return FlutterMaterial.Card(
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
                border: OutlineInputBorder(),
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
                border: OutlineInputBorder(),
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
    );
  }

  Widget _buildSecurityInfoCard() {
    return FlutterMaterial.Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Secure Payment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment is secured by Stripe. We never store your card details on our servers.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.lock, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Text(
                  'SSL Encrypted',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.verified_user, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Text(
                  'PCI Compliant',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
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
      child: Column(
        children: [
          // Price Breakdown
          if (_booking!.totalAmount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('\$${(_booking!.totalAmount * 0.9).toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Service Fee (10%)'),
                Text('\$${(_booking!.totalAmount * 0.1).toStringAsFixed(2)}'),
              ],
            ),
            const Divider(),
          ],
          
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
              onPressed: (_isProcessingPayment || 
                         (_selectedPaymentMethod == null && (_cardDetails == null || !_cardDetails!.complete)))
                  ? null 
                  : _processPayment,
              icon: _isProcessingPayment 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.payment),
              label: Text(
                _isProcessingPayment 
                    ? 'Processing Payment...' 
                    : 'Pay \$${_booking!.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
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
    );
  }
}