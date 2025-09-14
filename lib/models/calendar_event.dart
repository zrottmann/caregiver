import 'package:appwrite/models.dart' as models;
import 'appointment.dart';

enum EventType {
  appointment,
  availability,
  reminder,
  break,
  personal
}

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final EventType type;
  final String? appointmentId;
  final String? userId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.appointmentId,
    this.userId,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type.name,
      'appointmentId': appointmentId,
      'userId': userId,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] ?? json['\$id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      type: EventType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => EventType.appointment,
      ),
      appointmentId: json['appointmentId'],
      userId: json['userId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  factory CalendarEvent.fromAppwriteDocument(models.Document doc) {
    return CalendarEvent.fromJson({
      ...doc.data,
      'id': doc.$id,
      'createdAt': doc.$createdAt,
      'updatedAt': doc.$updatedAt,
    });
  }

  factory CalendarEvent.fromAppointment(Appointment appointment) {
    return CalendarEvent(
      id: 'event_${appointment.id}',
      title: 'Appointment with ${appointment.caregiverName}',
      description: appointment.description,
      startTime: appointment.startTime,
      endTime: appointment.endTime,
      type: EventType.appointment,
      appointmentId: appointment.id,
      userId: appointment.patientId,
      metadata: {
        'appointmentStatus': appointment.status.name,
        'services': appointment.services,
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
    String? appointmentId,
    String? userId,
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
      appointmentId: appointmentId ?? this.appointmentId,
      userId: userId ?? this.userId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}