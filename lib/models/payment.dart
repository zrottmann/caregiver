enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
  refunded,
  partiallyRefunded,
}

enum PaymentMethodType {
  card,
  bankTransfer,
  digitalWallet,
}

class PaymentMethod {
  final String id;
  final String userId;
  final PaymentMethodType type;
  final String last4;
  final String brand;
  final String expiryMonth;
  final String expiryYear;
  final bool isDefault;
  final String stripePaymentMethodId;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.last4,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
    this.isDefault = false,
    required this.stripePaymentMethodId,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName {
    switch (type) {
      case PaymentMethodType.card:
        return '${brand.toUpperCase()} •••• $last4';
      case PaymentMethodType.bankTransfer:
        return 'Bank Transfer •••• $last4';
      case PaymentMethodType.digitalWallet:
        return 'Digital Wallet •••• $last4';
    }
  }

  String get expiryDisplay => '$expiryMonth/$expiryYear';

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type.name,
      'last4': last4,
      'brand': brand,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'isDefault': isDefault,
      'stripePaymentMethodId': stripePaymentMethodId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['\$id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: PaymentMethodType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PaymentMethodType.card,
      ),
      last4: json['last4'] ?? '',
      brand: json['brand'] ?? '',
      expiryMonth: json['expiryMonth'] ?? '',
      expiryYear: json['expiryYear'] ?? '',
      isDefault: json['isDefault'] ?? false,
      stripePaymentMethodId: json['stripePaymentMethodId'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  PaymentMethod copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    String? last4,
    String? brand,
    String? expiryMonth,
    String? expiryYear,
    bool? isDefault,
    String? stripePaymentMethodId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      isDefault: isDefault ?? this.isDefault,
      stripePaymentMethodId: stripePaymentMethodId ?? this.stripePaymentMethodId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Payment {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String? paymentIntentId;
  final String? paymentMethodId;
  final String? failureReason;
  final double? refundedAmount;
  final String? refundReason;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    this.paymentIntentId,
    this.paymentMethodId,
    this.failureReason,
    this.refundedAmount,
    this.refundReason,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
  String get formattedRefundedAmount => 
      refundedAmount != null ? '\$${refundedAmount!.toStringAsFixed(2)}' : '\$0.00';

  bool get isPending => status == PaymentStatus.pending;
  bool get isProcessing => status == PaymentStatus.processing;
  bool get isSucceeded => status == PaymentStatus.succeeded;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isRefunded => status == PaymentStatus.refunded;
  bool get isPartiallyRefunded => status == PaymentStatus.partiallyRefunded;

  String get statusText {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.succeeded:
        return 'Succeeded';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.partiallyRefunded:
        return 'Partially Refunded';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'paymentIntentId': paymentIntentId,
      'paymentMethodId': paymentMethodId,
      'failureReason': failureReason,
      'refundedAmount': refundedAmount,
      'refundReason': refundReason,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['\$id'] ?? json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      userId: json['userId'] ?? '',
      amount: json['amount']?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentIntentId: json['paymentIntentId'],
      paymentMethodId: json['paymentMethodId'],
      failureReason: json['failureReason'],
      refundedAmount: json['refundedAmount']?.toDouble(),
      refundReason: json['refundReason'],
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(
        json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Payment copyWith({
    String? id,
    String? bookingId,
    String? userId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    String? paymentIntentId,
    String? paymentMethodId,
    String? failureReason,
    double? refundedAmount,
    String? refundReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      failureReason: failureReason ?? this.failureReason,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      refundReason: refundReason ?? this.refundReason,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Invoice {
  final String id;
  final String bookingId;
  final String paymentId;
  final String userId;
  final String invoiceNumber;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final DateTime issueDate;
  final DateTime dueDate;
  final Map<String, dynamic>? billingAddress;
  final List<InvoiceLineItem> lineItems;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.bookingId,
    required this.paymentId,
    required this.userId,
    required this.invoiceNumber,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    this.currency = 'USD',
    required this.issueDate,
    required this.dueDate,
    this.billingAddress,
    required this.lineItems,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';
  String get formattedTaxAmount => '\$${taxAmount.toStringAsFixed(2)}';
  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'paymentId': paymentId,
      'userId': userId,
      'invoiceNumber': invoiceNumber,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'currency': currency,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'billingAddress': billingAddress,
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['\$id'] ?? json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      paymentId: json['paymentId'] ?? '',
      userId: json['userId'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      subtotal: json['subtotal']?.toDouble() ?? 0.0,
      taxAmount: json['taxAmount']?.toDouble() ?? 0.0,
      totalAmount: json['totalAmount']?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      issueDate: DateTime.parse(json['issueDate']),
      dueDate: DateTime.parse(json['dueDate']),
      billingAddress: json['billingAddress'] as Map<String, dynamic>?,
      lineItems: (json['lineItems'] as List? ?? [])
          .map((item) => InvoiceLineItem.fromJson(item))
          .toList(),
      notes: json['notes'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class InvoiceLineItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  String get formattedUnitPrice => '\$${unitPrice.toStringAsFixed(2)}';
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: json['unitPrice']?.toDouble() ?? 0.0,
      totalPrice: json['totalPrice']?.toDouble() ?? 0.0,
    );
  }
}