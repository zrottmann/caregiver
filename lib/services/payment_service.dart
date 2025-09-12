import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../models/payment.dart' as AppPayment;
import '../models/booking.dart';

class PaymentService {
  final Client _client;
  final Databases _databases;
  static const String _databaseId = 'caregiver_platform';
  static const String _paymentsCollectionId = 'payments';
  static const String _paymentMethodsCollectionId = 'payment_methods';
  static const String _invoicesCollectionId = 'invoices';

  // This should be configured from environment variables or secure config
  static const String _stripePublishableKey = 'pk_test_your_stripe_publishable_key';
  static const String _stripeSecretKey = 'sk_test_your_stripe_secret_key';

  PaymentService({Client? client})
      : _client = client ?? Client(),
        _databases = Databases(client ?? Client()) {
    _client
        .setEndpoint(AppConfig.appwriteEndpoint)
        .setProject(AppConfig.appwriteProjectId);
    
    // Initialize Stripe
    Stripe.publishableKey = _stripePublishableKey;
  }

  // Payment Intent Management
  Future<String> createPaymentIntent({
    required double amount,
    required String currency,
    required String customerId,
    String? paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).round().toString(), // Convert to cents
          'currency': currency.toLowerCase(),
          'customer': customerId,
          if (paymentMethodId != null) 'payment_method': paymentMethodId,
          'confirmation_method': 'manual',
          'confirm': 'true',
          'return_url': 'https://your-app.com/return',
          if (metadata != null) ...metadata.map((key, value) => MapEntry('metadata[$key]', value.toString())),
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['id'];
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  Future<Map<String, dynamic>> confirmPaymentIntent(String paymentIntentId) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents/$paymentIntentId/confirm'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to confirm payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to confirm payment intent: $e');
    }
  }

  // Payment Management
  Future<AppPayment.Payment> createPayment({
    required String bookingId,
    required String userId,
    required double amount,
    String currency = 'USD',
    String? paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final paymentId = const Uuid().v4();
      final now = DateTime.now();

      // Create payment intent with Stripe
      final paymentIntentId = await createPaymentIntent(
        amount: amount,
        currency: currency,
        customerId: userId, // In a real app, this should be the Stripe customer ID
        paymentMethodId: paymentMethodId,
        metadata: {
          'booking_id': bookingId,
          'payment_id': paymentId,
          ...?metadata,
        },
      );

      final payment = Payment(
        id: paymentId,
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        currency: currency,
        status: PaymentStatus.processing,
        paymentIntentId: paymentIntentId,
        paymentMethodId: paymentMethodId,
        metadata: metadata,
        createdAt: now,
        updatedAt: now,
      );

      final response = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _paymentsCollectionId,
        documentId: paymentId,
        data: payment.toJson(),
      );

      return Payment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  Future<AppPayment.Payment> updatePaymentStatus(
    String paymentId,
    AppPayment.PaymentStatus status, {
    String? failureReason,
  }) async {
    try {
      final payment = await getPayment(paymentId);
      final updatedPayment = payment.copyWith(
        status: status,
        failureReason: failureReason,
        updatedAt: DateTime.now(),
      );

      final response = await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _paymentsCollectionId,
        documentId: paymentId,
        data: updatedPayment.toJson(),
      );

      return Payment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  Future<AppPayment.Payment> getPayment(String paymentId) async {
    try {
      final response = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _paymentsCollectionId,
        documentId: paymentId,
      );

      return Payment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch payment: $e');
    }
  }

  Future<List<AppPayment.Payment>> getUserPayments(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _paymentsCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('\$createdAt'),
        ],
      );

      return response.documents.map((doc) => Payment.fromJson(doc.data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user payments: $e');
    }
  }

  Future<AppPayment.Payment?> getPaymentByBooking(String bookingId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _paymentsCollectionId,
        queries: [
          Query.equal('bookingId', bookingId),
          Query.orderDesc('\$createdAt'),
        ],
      );

      if (response.documents.isNotEmpty) {
        return Payment.fromJson(response.documents.first.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch payment by booking: $e');
    }
  }

  // Payment Method Management
  Future<String> createStripeCustomer(String userId, String email, String name) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/customers'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': email,
          'name': name,
          'metadata[user_id]': userId,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['id'];
      } else {
        throw Exception('Failed to create Stripe customer: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create Stripe customer: $e');
    }
  }

  Future<PaymentMethod> savePaymentMethod({
    required String userId,
    required String stripePaymentMethodId,
    bool setAsDefault = false,
  }) async {
    try {
      // Get payment method details from Stripe
      final response = await http.get(
        Uri.parse('https://api.stripe.com/v1/payment_methods/$stripePaymentMethodId'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to retrieve payment method from Stripe: ${response.body}');
      }

      final stripePaymentMethod = jsonDecode(response.body);
      final card = stripePaymentMethod['card'];

      final paymentMethodId = const Uuid().v4();
      final now = DateTime.now();

      // If setting as default, update other payment methods
      if (setAsDefault) {
        await _updatePaymentMethodsDefault(userId, false);
      }

      final paymentMethod = PaymentMethod(
        id: paymentMethodId,
        userId: userId,
        type: PaymentMethodType.card,
        last4: card['last4'],
        brand: card['brand'],
        expiryMonth: card['exp_month'].toString().padLeft(2, '0'),
        expiryYear: card['exp_year'].toString(),
        isDefault: setAsDefault,
        stripePaymentMethodId: stripePaymentMethodId,
        createdAt: now,
        updatedAt: now,
      );

      final dbResponse = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _paymentMethodsCollectionId,
        documentId: paymentMethodId,
        data: paymentMethod.toJson(),
      );

      return PaymentMethod.fromJson(dbResponse.data);
    } catch (e) {
      throw Exception('Failed to save payment method: $e');
    }
  }

  Future<List<PaymentMethod>> getUserPaymentMethods(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _paymentMethodsCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('isDefault'),
          Query.orderDesc('\$createdAt'),
        ],
      );

      return response.documents.map((doc) => PaymentMethod.fromJson(doc.data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user payment methods: $e');
    }
  }

  Future<PaymentMethod> setDefaultPaymentMethod(String paymentMethodId, String userId) async {
    try {
      // Update other payment methods to not be default
      await _updatePaymentMethodsDefault(userId, false);

      // Set the selected payment method as default
      final paymentMethod = await _getPaymentMethod(paymentMethodId);
      final updatedPaymentMethod = paymentMethod.copyWith(
        isDefault: true,
        updatedAt: DateTime.now(),
      );

      final response = await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _paymentMethodsCollectionId,
        documentId: paymentMethodId,
        data: updatedPaymentMethod.toJson(),
      );

      return PaymentMethod.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to set default payment method: $e');
    }
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      // First detach from Stripe
      final paymentMethod = await _getPaymentMethod(paymentMethodId);
      
      await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_methods/${paymentMethod.stripePaymentMethodId}/detach'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      // Then delete from database
      await _databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _paymentMethodsCollectionId,
        documentId: paymentMethodId,
      );
    } catch (e) {
      throw Exception('Failed to delete payment method: $e');
    }
  }

  // Refund Management
  Future<AppPayment.Payment> processRefund({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      final payment = await getPayment(paymentId);
      
      if (payment.paymentIntentId == null) {
        throw Exception('Payment intent not found');
      }

      // Create refund with Stripe
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/refunds'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_intent': payment.paymentIntentId!,
          'amount': (amount * 100).round().toString(), // Convert to cents
          if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        final refundData = jsonDecode(response.body);
        
        final refundStatus = amount >= payment.amount 
            ? AppPayment.PaymentStatus.refunded 
            : AppPayment.PaymentStatus.partiallyRefunded;

        final updatedPayment = payment.copyWith(
          status: refundStatus,
          refundedAmount: (payment.refundedAmount ?? 0) + amount,
          refundReason: reason,
          updatedAt: DateTime.now(),
        );

        final dbResponse = await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _paymentsCollectionId,
          documentId: paymentId,
          data: updatedPayment.toJson(),
        );

        return AppPayment.Payment.fromJson(dbResponse.data);
      } else {
        throw Exception('Failed to process refund: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  // Invoice Management
  Future<AppPayment.Invoice> generateInvoice({
    required String bookingId,
    required String paymentId,
    required String userId,
    required List<AppPayment.InvoiceLineItem> lineItems,
    Map<String, dynamic>? billingAddress,
    String? notes,
  }) async {
    try {
      final invoiceId = const Uuid().v4();
      final now = DateTime.now();
      
      // Generate invoice number
      final invoiceNumber = 'INV-${now.year}-${now.millisecondsSinceEpoch.toString().substring(8)}';

      final subtotal = lineItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
      final taxRate = 0.08; // 8% tax rate - should be configurable
      final taxAmount = subtotal * taxRate;
      final totalAmount = subtotal + taxAmount;

      final invoice = Invoice(
        id: invoiceId,
        bookingId: bookingId,
        paymentId: paymentId,
        userId: userId,
        invoiceNumber: invoiceNumber,
        subtotal: subtotal,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        issueDate: now,
        dueDate: now.add(const Duration(days: 30)),
        billingAddress: billingAddress,
        lineItems: lineItems,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      final response = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _invoicesCollectionId,
        documentId: invoiceId,
        data: invoice.toJson(),
      );

      return Invoice.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to generate invoice: $e');
    }
  }

  Future<AppPayment.Invoice> getInvoice(String invoiceId) async {
    try {
      final response = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _invoicesCollectionId,
        documentId: invoiceId,
      );

      return Invoice.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch invoice: $e');
    }
  }

  Future<List<AppPayment.Invoice>> getUserInvoices(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _invoicesCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('\$createdAt'),
        ],
      );

      return response.documents.map((doc) => Invoice.fromJson(doc.data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user invoices: $e');
    }
  }

  Future<AppPayment.Invoice?> getInvoiceByBooking(String bookingId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _invoicesCollectionId,
        queries: [
          Query.equal('bookingId', bookingId),
        ],
      );

      if (response.documents.isNotEmpty) {
        return Invoice.fromJson(response.documents.first.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch invoice by booking: $e');
    }
  }

  // Helper Methods
  Future<PaymentMethod> _getPaymentMethod(String paymentMethodId) async {
    try {
      final response = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _paymentMethodsCollectionId,
        documentId: paymentMethodId,
      );

      return PaymentMethod.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch payment method: $e');
    }
  }

  Future<void> _updatePaymentMethodsDefault(String userId, bool isDefault) async {
    try {
      final paymentMethods = await getUserPaymentMethods(userId);
      
      for (final paymentMethod in paymentMethods) {
        if (paymentMethod.isDefault != isDefault) {
          final updatedPaymentMethod = paymentMethod.copyWith(
            isDefault: isDefault,
            updatedAt: DateTime.now(),
          );

          await _databases.updateDocument(
            databaseId: _databaseId,
            collectionId: _paymentMethodsCollectionId,
            documentId: paymentMethod.id,
            data: updatedPaymentMethod.toJson(),
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to update payment methods default: $e');
    }
  }
}