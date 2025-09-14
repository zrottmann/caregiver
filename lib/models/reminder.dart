import 'package:appwrite/models.dart' as models;

enum ReminderStatus {
  scheduled,
  sent,
  cancelled,
  failed
}

enum ReminderType {
  appointment,
  medication,
  follow_up,
  custom
}

class Reminder {
  final String id;
  final String title;
  final String message;
  final DateTime scheduledTime;
  final ReminderType type;
  final ReminderStatus status;
  final String userId;
  final String? appointmentId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reminder({
    required this.id,
    required this.title,
    required this.message,
    required this.scheduledTime,
    required this.type,
    required this.status,
    required this.userId,
    this.appointmentId,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'scheduledTime': scheduledTime.toIso8601String(),
      'type': type.name,
      'status': status.name,
      'userId': userId,
      'appointmentId': appointmentId,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] ?? json['\$id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      scheduledTime: DateTime.parse(json['scheduledTime']),
      type: ReminderType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ReminderType.custom,
      ),
      status: ReminderStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ReminderStatus.scheduled,
      ),
      userId: json['userId'] ?? '',
      appointmentId: json['appointmentId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  factory Reminder.fromAppwriteDocument(models.Document doc) {
    return Reminder.fromJson({
      ...doc.data,
      'id': doc.$id,
      'createdAt': doc.$createdAt,
      'updatedAt': doc.$updatedAt,
    });
  }

  static Reminder createAppointmentReminder({
    required String appointmentId,
    required String userId,
    required DateTime appointmentTime,
    required String patientName,
    required String caregiverName,
    required Duration beforeAppointment,
  }) {
    final scheduledTime = appointmentTime.subtract(beforeAppointment);
    final hoursBeforeText = beforeAppointment.inHours > 0
        ? '${beforeAppointment.inHours} hour${beforeAppointment.inHours > 1 ? 's' : ''}'
        : '${beforeAppointment.inMinutes} minute${beforeAppointment.inMinutes > 1 ? 's' : ''}';

    return Reminder(
      id: 'reminder_${appointmentId}_${beforeAppointment.inMinutes}',
      title: 'Upcoming Appointment',
      message: 'You have an appointment with $caregiverName in $hoursBeforeText',
      scheduledTime: scheduledTime,
      type: ReminderType.appointment,
      status: ReminderStatus.scheduled,
      userId: userId,
      appointmentId: appointmentId,
      metadata: {
        'patientName': patientName,
        'caregiverName': caregiverName,
        'appointmentTime': appointmentTime.toIso8601String(),
        'beforeMinutes': beforeAppointment.inMinutes,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? scheduledTime,
    ReminderType? type,
    ReminderStatus? status,
    String? userId,
    String? appointmentId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      type: type ?? this.type,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      appointmentId: appointmentId ?? this.appointmentId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}