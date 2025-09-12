enum ReminderType {
  appointment,
  medication,
  checkup,
  custom,
}

enum ReminderMethod {
  notification,
  email,
  sms,
  call,
}

enum ReminderStatus {
  scheduled,
  sent,
  delivered,
  failed,
  cancelled,
}

class Reminder {
  final String id;
  final String title;
  final String? message;
  final DateTime scheduledTime;
  final ReminderType type;
  final List<ReminderMethod> methods;
  final ReminderStatus status;
  final String? appointmentId;
  final String? patientId;
  final String? caregiverId;
  final Duration? advanceTime; // How far in advance to remind
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentAt;
  final String? failureReason;

  Reminder({
    required this.id,
    required this.title,
    this.message,
    required this.scheduledTime,
    required this.type,
    required this.methods,
    this.status = ReminderStatus.scheduled,
    this.appointmentId,
    this.patientId,
    this.caregiverId,
    this.advanceTime,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.sentAt,
    this.failureReason,
  });

  bool get isPending => status == ReminderStatus.scheduled;
  bool get isSent => status == ReminderStatus.sent;
  bool get isDelivered => status == ReminderStatus.delivered;
  bool get isFailed => status == ReminderStatus.failed;
  bool get isCancelled => status == ReminderStatus.cancelled;

  bool get isDue => DateTime.now().isAfter(scheduledTime) && isPending;

  String get statusText {
    switch (status) {
      case ReminderStatus.scheduled:
        return 'Scheduled';
      case ReminderStatus.sent:
        return 'Sent';
      case ReminderStatus.delivered:
        return 'Delivered';
      case ReminderStatus.failed:
        return 'Failed';
      case ReminderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get typeText {
    switch (type) {
      case ReminderType.appointment:
        return 'Appointment Reminder';
      case ReminderType.medication:
        return 'Medication Reminder';
      case ReminderType.checkup:
        return 'Checkup Reminder';
      case ReminderType.custom:
        return 'Custom Reminder';
    }
  }

  List<String> get methodTexts {
    return methods.map((method) {
      switch (method) {
        case ReminderMethod.notification:
          return 'Push Notification';
        case ReminderMethod.email:
          return 'Email';
        case ReminderMethod.sms:
          return 'SMS';
        case ReminderMethod.call:
          return 'Phone Call';
      }
    }).toList();
  }

  bool hasMethod(ReminderMethod method) => methods.contains(method);

  Duration get timeUntilDue => scheduledTime.difference(DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'scheduledTime': scheduledTime.toIso8601String(),
      'type': type.name,
      'methods': methods.map((e) => e.name).toList(),
      'status': status.name,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'caregiverId': caregiverId,
      'advanceTime': advanceTime?.inMinutes,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'failureReason': failureReason,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['\$id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      type: ReminderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReminderType.custom,
      ),
      methods: List<String>.from(json['methods'] ?? [])
          .map((e) => ReminderMethod.values.firstWhere(
                (m) => m.name == e,
                orElse: () => ReminderMethod.notification,
              ))
          .toList(),
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReminderStatus.scheduled,
      ),
      appointmentId: json['appointmentId'],
      patientId: json['patientId'],
      caregiverId: json['caregiverId'],
      advanceTime: json['advanceTime'] != null 
          ? Duration(minutes: json['advanceTime'])
          : null,
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String()),
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      failureReason: json['failureReason'],
    );
  }

  factory Reminder.createAppointmentReminder({
    required String appointmentId,
    required String patientId,
    required String caregiverId,
    required DateTime appointmentTime,
    required String appointmentDescription,
    Duration advanceTime = const Duration(hours: 24),
    List<ReminderMethod> methods = const [ReminderMethod.notification],
  }) {
    final reminderTime = appointmentTime.subtract(advanceTime);
    final now = DateTime.now();

    return Reminder(
      id: '', // Will be set by the service
      title: 'Upcoming Appointment',
      message: 'You have an appointment scheduled: $appointmentDescription',
      scheduledTime: reminderTime,
      type: ReminderType.appointment,
      methods: methods,
      appointmentId: appointmentId,
      patientId: patientId,
      caregiverId: caregiverId,
      advanceTime: advanceTime,
      metadata: {
        'appointmentTime': appointmentTime.toIso8601String(),
        'appointmentDescription': appointmentDescription,
      },
      createdAt: now,
      updatedAt: now,
    );
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? scheduledTime,
    ReminderType? type,
    List<ReminderMethod>? methods,
    ReminderStatus? status,
    String? appointmentId,
    String? patientId,
    String? caregiverId,
    Duration? advanceTime,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? sentAt,
    String? failureReason,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      type: type ?? this.type,
      methods: methods ?? this.methods,
      status: status ?? this.status,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      advanceTime: advanceTime ?? this.advanceTime,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sentAt: sentAt ?? this.sentAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}