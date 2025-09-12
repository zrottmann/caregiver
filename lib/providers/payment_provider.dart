import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';

class PaymentState {
  final List<Payment> payments;
  final List<PaymentMethod> paymentMethods;
  final List<Invoice> invoices;
  final Payment? currentPayment;
  final PaymentMethod? defaultPaymentMethod;
  final bool isLoading;
  final bool isProcessingPayment;
  final bool isLoadingPaymentMethods;
  final String? error;

  PaymentState({
    this.payments = const [],
    this.paymentMethods = const [],
    this.invoices = const [],
    this.currentPayment,
    this.defaultPaymentMethod,
    this.isLoading = false,
    this.isProcessingPayment = false,
    this.isLoadingPaymentMethods = false,
    this.error,
  });

  PaymentState copyWith({
    List<Payment>? payments,
    List<PaymentMethod>? paymentMethods,
    List<Invoice>? invoices,
    Payment? currentPayment,
    PaymentMethod? defaultPaymentMethod,
    bool? isLoading,
    bool? isProcessingPayment,
    bool? isLoadingPaymentMethods,
    String? error,
  }) {
    return PaymentState(
      payments: payments ?? this.payments,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      invoices: invoices ?? this.invoices,
      currentPayment: currentPayment ?? this.currentPayment,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      isLoading: isLoading ?? this.isLoading,
      isProcessingPayment: isProcessingPayment ?? this.isProcessingPayment,
      isLoadingPaymentMethods: isLoadingPaymentMethods ?? this.isLoadingPaymentMethods,
      error: error,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentService _paymentService;

  PaymentNotifier(this._paymentService) : super(PaymentState());

  // Payment Management
  Future<Payment> createPayment({
    required String bookingId,
    required String userId,
    required double amount,
    String currency = 'USD',
    String? paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      state = state.copyWith(isProcessingPayment: true, error: null);

      final payment = await _paymentService.createPayment(
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        currency: currency,
        paymentMethodId: paymentMethodId,
        metadata: metadata,
      );

      // Add to local state
      state = state.copyWith(
        payments: [...state.payments, payment],
        currentPayment: payment,
        isProcessingPayment: false,
      );

      return payment;
    } catch (e) {
      state = state.copyWith(
        isProcessingPayment: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? failureReason,
  }) async {
    try {
      final updatedPayment = await _paymentService.updatePaymentStatus(
        paymentId,
        status,
        failureReason: failureReason,
      );

      // Update in local state
      final updatedPayments = state.payments.map((payment) {
        return payment.id == paymentId ? updatedPayment : payment;
      }).toList();

      state = state.copyWith(
        payments: updatedPayments,
        currentPayment: state.currentPayment?.id == paymentId ? updatedPayment : state.currentPayment,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> loadUserPayments(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final payments = await _paymentService.getUserPayments(userId);

      state = state.copyWith(
        payments: payments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<Payment?> getPayment(String paymentId) async {
    try {
      // Check if already in state
      final existingPayment = state.payments.where((payment) => payment.id == paymentId).firstOrNull;
      if (existingPayment != null) {
        return existingPayment;
      }

      // Fetch from service
      return await _paymentService.getPayment(paymentId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<Payment?> getPaymentByBooking(String bookingId) async {
    try {
      // Check if already in state
      final existingPayment = state.payments.where((payment) => payment.bookingId == bookingId).firstOrNull;
      if (existingPayment != null) {
        return existingPayment;
      }

      // Fetch from service
      return await _paymentService.getPaymentByBooking(bookingId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Payment Method Management
  Future<void> loadUserPaymentMethods(String userId) async {
    try {
      state = state.copyWith(isLoadingPaymentMethods: true, error: null);

      final paymentMethods = await _paymentService.getUserPaymentMethods(userId);

      final defaultMethod = paymentMethods.where((method) => method.isDefault).firstOrNull;

      state = state.copyWith(
        paymentMethods: paymentMethods,
        defaultPaymentMethod: defaultMethod,
        isLoadingPaymentMethods: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPaymentMethods: false,
        error: e.toString(),
      );
    }
  }

  Future<PaymentMethod> savePaymentMethod({
    required String userId,
    required String stripePaymentMethodId,
    bool setAsDefault = false,
  }) async {
    try {
      state = state.copyWith(isLoadingPaymentMethods: true, error: null);

      final paymentMethod = await _paymentService.savePaymentMethod(
        userId: userId,
        stripePaymentMethodId: stripePaymentMethodId,
        setAsDefault: setAsDefault,
      );

      // Update local state
      final updatedPaymentMethods = [...state.paymentMethods, paymentMethod];
      
      state = state.copyWith(
        paymentMethods: updatedPaymentMethods,
        defaultPaymentMethod: setAsDefault ? paymentMethod : state.defaultPaymentMethod,
        isLoadingPaymentMethods: false,
      );

      return paymentMethod;
    } catch (e) {
      state = state.copyWith(
        isLoadingPaymentMethods: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<PaymentMethod> setDefaultPaymentMethod(String paymentMethodId, String userId) async {
    try {
      final updatedPaymentMethod = await _paymentService.setDefaultPaymentMethod(paymentMethodId, userId);

      // Update local state - set all others to not default
      final updatedPaymentMethods = state.paymentMethods.map((method) {
        return method.copyWith(isDefault: method.id == paymentMethodId);
      }).toList();

      state = state.copyWith(
        paymentMethods: updatedPaymentMethods,
        defaultPaymentMethod: updatedPaymentMethod,
      );

      return updatedPaymentMethod;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      state = state.copyWith(isLoadingPaymentMethods: true, error: null);

      await _paymentService.deletePaymentMethod(paymentMethodId);

      // Remove from local state
      final updatedPaymentMethods = state.paymentMethods.where((method) => method.id != paymentMethodId).toList();
      
      // Update default if deleted method was default
      PaymentMethod? newDefaultMethod = state.defaultPaymentMethod;
      if (state.defaultPaymentMethod?.id == paymentMethodId) {
        newDefaultMethod = updatedPaymentMethods.where((method) => method.isDefault).firstOrNull;
      }

      state = state.copyWith(
        paymentMethods: updatedPaymentMethods,
        defaultPaymentMethod: newDefaultMethod,
        isLoadingPaymentMethods: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPaymentMethods: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Stripe Customer Management
  Future<String> createStripeCustomer(String userId, String email, String name) async {
    try {
      return await _paymentService.createStripeCustomer(userId, email, name);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Refund Management
  Future<Payment> processRefund({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      state = state.copyWith(isProcessingPayment: true, error: null);

      final refundedPayment = await _paymentService.processRefund(
        paymentId: paymentId,
        amount: amount,
        reason: reason,
      );

      // Update in local state
      final updatedPayments = state.payments.map((payment) {
        return payment.id == paymentId ? refundedPayment : payment;
      }).toList();

      state = state.copyWith(
        payments: updatedPayments,
        currentPayment: state.currentPayment?.id == paymentId ? refundedPayment : state.currentPayment,
        isProcessingPayment: false,
      );

      return refundedPayment;
    } catch (e) {
      state = state.copyWith(
        isProcessingPayment: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Invoice Management
  Future<Invoice> generateInvoice({
    required String bookingId,
    required String paymentId,
    required String userId,
    required List<InvoiceLineItem> lineItems,
    Map<String, dynamic>? billingAddress,
    String? notes,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final invoice = await _paymentService.generateInvoice(
        bookingId: bookingId,
        paymentId: paymentId,
        userId: userId,
        lineItems: lineItems,
        billingAddress: billingAddress,
        notes: notes,
      );

      // Add to local state
      state = state.copyWith(
        invoices: [...state.invoices, invoice],
        isLoading: false,
      );

      return invoice;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> loadUserInvoices(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final invoices = await _paymentService.getUserInvoices(userId);

      state = state.copyWith(
        invoices: invoices,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<Invoice?> getInvoice(String invoiceId) async {
    try {
      // Check if already in state
      final existingInvoice = state.invoices.where((invoice) => invoice.id == invoiceId).firstOrNull;
      if (existingInvoice != null) {
        return existingInvoice;
      }

      // Fetch from service
      return await _paymentService.getInvoice(invoiceId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<Invoice?> getInvoiceByBooking(String bookingId) async {
    try {
      // Check if already in state
      final existingInvoice = state.invoices.where((invoice) => invoice.bookingId == bookingId).firstOrNull;
      if (existingInvoice != null) {
        return existingInvoice;
      }

      // Fetch from service
      return await _paymentService.getInvoiceByBooking(bookingId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Utility methods
  void setCurrentPayment(Payment? payment) {
    state = state.copyWith(currentPayment: payment);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearCurrentPayment() {
    state = state.copyWith(currentPayment: null);
  }
}

// Service Providers
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(ref.read(paymentServiceProvider));
});

// Convenience providers for specific data
final userPaymentsProvider = Provider<List<Payment>>((ref) {
  return ref.watch(paymentProvider).payments;
});

final userPaymentMethodsProvider = Provider<List<PaymentMethod>>((ref) {
  return ref.watch(paymentProvider).paymentMethods;
});

final defaultPaymentMethodProvider = Provider<PaymentMethod?>((ref) {
  return ref.watch(paymentProvider).defaultPaymentMethod;
});

final userInvoicesProvider = Provider<List<Invoice>>((ref) {
  return ref.watch(paymentProvider).invoices;
});

final currentPaymentProvider = Provider<Payment?>((ref) {
  return ref.watch(paymentProvider).currentPayment;
});