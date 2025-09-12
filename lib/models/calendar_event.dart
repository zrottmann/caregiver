import 'appointment.dart';

enum EventType {
  appointment,
  availability,
  blocked,
  reminder,
  holiday,
}

enum EventPriority {
  low,
  medium,
  high,
  urgent,
}

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final EventType type;
  final EventPriority priority;
  final String? appointmentId;
  final String? caregiverId;
  final String? patientId;
  final bool isAllDay;
  final String? color;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.priority = EventPriority.medium,
    this.appointmentId,
    this.caregiverId,
    this.patientId,
    this.isAllDay = false,
    this.color,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration get duration => endTime.difference(startTime);

  String get timeRange {
    if (isAllDay) return 'All Day';
    
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  String get typeText {
    switch (type) {
      case EventType.appointment:
        return 'Appointment';
      case EventType.availability:
        return 'Available';
      case EventType.blocked:
        return 'Blocked';
      case EventType.reminder:
        return 'Reminder';
      case EventType.holiday:
        return 'Holiday';
    }
  }

  String get priorityText {
    switch (priority) {
      case EventPriority.low:
        return 'Low';
      case EventPriority.medium:
        return 'Medium';
      case EventPriority.high:
        return 'High';
      case EventPriority.urgent:
        return 'Urgent';
    }
  }

  bool get isAppointment => type == EventType.appointment;
  bool get isAvailability => type == EventType.availability;
  bool get isBlocked => type == EventType.blocked;
  bool get isReminder => type == EventType.reminder;

  bool overlaps(CalendarEvent other) {
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  }

  bool isOnDate(DateTime date) {
    final eventDate = DateTime(startTime.year, startTime.month, startTime.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return eventDate.isAtSameMomentAs(checkDate) ||
           (startTime.isBefore(date.add(const Duration(days: 1))) && 
            endTime.isAfter(date));
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type.name,
      'priority': priority.name,
      'appointmentId': appointmentId,
      'caregiverId': caregiverId,
      'patientId': patientId,
      'isAllDay': isAllDay,
      'color': color,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['\$id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      type: EventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EventType.appointment,
      ),
      priority: EventPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => EventPriority.medium,
      ),
      appointmentId: json['appointmentId'],
      caregiverId: json['caregiverId'],
      patientId: json['patientId'],
      isAllDay: json['isAllDay'] ?? false,
      color: json['color'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  factory CalendarEvent.fromAppointment(Appointment appointment) {
    return CalendarEvent(
      id: appointment.id,
      title: appointment.services.join(', '),
      description: appointment.description,
      startTime: appointment.startTime,
      endTime: appointment.endTime,
      type: EventType.appointment,
      priority: EventPriority.medium,
      appointmentId: appointment.id,
      caregiverId: appointment.caregiverId,
      patientId: appointment.patientId,
      metadata: {
        'patientName': appointment.patientName,
        'caregiverName': appointment.caregiverName,
        'status': appointment.status.name,
        'totalAmount': appointment.totalAmount,
      },
      createdAt: appointment.createdAt,
      updatedAt: appointment.updatedAt,
    );
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    EventType? type,
    EventPriority? priority,
    String? appointmentId,
    String? caregiverId,
    String? patientId,
    bool? isAllDay,
    String? color,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      appointmentId: appointmentId ?? this.appointmentId,
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      isAllDay: isAllDay ?? this.isAllDay,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}