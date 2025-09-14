enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}

enum AppointmentType {
  oneTime,
  recurring,
}

enum RecurrenceType {
  daily,
  weekly,
  monthly,
}

class Appointment {
  final String id;
  final String patientId;
  final String caregiverId;
  final String patientName;
  final String caregiverName;
  final DateTime startTime;
  final DateTime endTime;
  final AppointmentStatus status;
  final AppointmentType type;
  final String? description;
  final String? notes;
  final List<String> services;
  final double? duration; // in hours
  final double? totalAmount;
  final String? location;
  final RecurrenceType? recurrenceType;
  final DateTime? recurrenceEndDate;
  final int? recurrenceInterval;
  final List<String>? reminders; // reminder IDs
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentAppointmentId; // for recurring appointments

  Appointment({
    required this.id,
    required this.patientId,
    required this.caregiverId,
    required this.patientName,
    required this.caregiverName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.type,
    this.description,
    this.notes,
    required this.services,
    this.duration,
    this.totalAmount,
    this.location,
    this.recurrenceType,
    this.recurrenceEndDate,
    this.recurrenceInterval,
    this.reminders,
    required this.createdAt,
    required this.updatedAt,
    this.parentAppointmentId,
  });

  String get statusText {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }

  bool get isActive => status == AppointmentStatus.scheduled || 
                       status == AppointmentStatus.confirmed ||
                       status == AppointmentStatus.inProgress;

  bool get canReschedule => status == AppointmentStatus.scheduled || 
                           status == AppointmentStatus.confirmed;

  bool get canCancel => status == AppointmentStatus.scheduled || 
                       status == AppointmentStatus.confirmed;

  bool get isRecurring => type == AppointmentType.recurring;

  Duration get appointmentDuration => endTime.difference(startTime);

  String get timeSlot {
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'caregiverId': caregiverId,
      'patientName': patientName,
      'caregiverName': caregiverName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status.name,
      'type': type.name,
      'description': description,
      'notes': notes,
      'services': services,
      'duration': duration,
      'totalAmount': totalAmount,
      'location': location,
      'recurrenceType': recurrenceType?.name,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'recurrenceInterval': recurrenceInterval,
      'reminders': reminders,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'parentAppointmentId': parentAppointmentId,
    };
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['\$id'] ?? json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      caregiverId: json['caregiverId'] ?? '',
      patientName: json['patientName'] ?? '',
      caregiverName: json['caregiverName'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AppointmentStatus.scheduled,
      ),
      type: AppointmentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AppointmentType.oneTime,
      ),
      description: json['description'],
      notes: json['notes'],
      services: List<String>.from(json['services'] ?? []),
      duration: json['duration']?.toDouble(),
      totalAmount: json['totalAmount']?.toDouble(),
      location: json['location'],
      recurrenceType: json['recurrenceType'] != null
          ? RecurrenceType.values.firstWhere(
              (e) => e.name == json['recurrenceType'],
              orElse: () => RecurrenceType.weekly,
            )
          : null,
      recurrenceEndDate: json['recurrenceEndDate'] != null
          ? DateTime.parse(json['recurrenceEndDate'])
          : null,
      recurrenceInterval: json['recurrenceInterval'],
      reminders: json['reminders'] != null
          ? List<String>.from(json['reminders'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String()),
      parentAppointmentId: json['parentAppointmentId'],
    );
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? caregiverId,
    String? patientName,
    String? caregiverName,
    DateTime? startTime,
    DateTime? endTime,
    AppointmentStatus? status,
    AppointmentType? type,
    String? description,
    String? notes,
    List<String>? services,
    double? duration,
    double? totalAmount,
    String? location,
    RecurrenceType? recurrenceType,
    DateTime? recurrenceEndDate,
    int? recurrenceInterval,
    List<String>? reminders,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentAppointmentId,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      patientName: patientName ?? this.patientName,
      caregiverName: caregiverName ?? this.caregiverName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      type: type ?? this.type,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      services: services ?? this.services,
      duration: duration ?? this.duration,
      totalAmount: totalAmount ?? this.totalAmount,
      location: location ?? this.location,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      reminders: reminders ?? this.reminders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentAppointmentId: parentAppointmentId ?? this.parentAppointmentId,
    );
  }
}