enum BookingStatus {
  pending,
  confirmed,
  completed,
  cancelled,
}

class Booking {
  final String id;
  final String patientId;
  final String caregiverId;
  final String patientName;
  final String caregiverName;
  final DateTime scheduledDate;
  final String timeSlot;
  final String description;
  final List<String> services;
  final double totalAmount;
  final BookingStatus status;
  final String? notes;
  final String? paymentIntentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.patientId,
    required this.caregiverId,
    required this.patientName,
    required this.caregiverName,
    required this.scheduledDate,
    required this.timeSlot,
    required this.description,
    required this.services,
    required this.totalAmount,
    required this.status,
    this.notes,
    this.paymentIntentId,
    required this.createdAt,
    required this.updatedAt,
  });

  String get statusText {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isPending => status == BookingStatus.pending;
  bool get isConfirmed => status == BookingStatus.confirmed;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isCancelled => status == BookingStatus.cancelled;

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'caregiverId': caregiverId,
      'patientName': patientName,
      'caregiverName': caregiverName,
      'scheduledDate': scheduledDate.toIso8601String(),
      'timeSlot': timeSlot,
      'description': description,
      'services': services,
      'totalAmount': totalAmount,
      'status': status.name,
      'notes': notes,
      'paymentIntentId': paymentIntentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['\$id'] ?? json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      caregiverId: json['caregiverId'] ?? '',
      patientName: json['patientName'] ?? '',
      caregiverName: json['caregiverName'] ?? '',
      scheduledDate: DateTime.parse(json['scheduledDate']),
      timeSlot: json['timeSlot'] ?? '',
      description: json['description'] ?? '',
      services: List<String>.from(json['services'] ?? []),
      totalAmount: json['totalAmount']?.toDouble() ?? 0.0,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      notes: json['notes'],
      paymentIntentId: json['paymentIntentId'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Booking copyWith({
    String? id,
    String? patientId,
    String? caregiverId,
    String? patientName,
    String? caregiverName,
    DateTime? scheduledDate,
    String? timeSlot,
    String? description,
    List<String>? services,
    double? totalAmount,
    BookingStatus? status,
    String? notes,
    String? paymentIntentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      patientName: patientName ?? this.patientName,
      caregiverName: caregiverName ?? this.caregiverName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeSlot: timeSlot ?? this.timeSlot,
      description: description ?? this.description,
      services: services ?? this.services,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}