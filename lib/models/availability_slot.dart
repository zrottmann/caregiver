import 'package:appwrite/models.dart' as models;

enum SlotStatus {
  available,
  booked,
  unavailable,
  blocked
}

enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday
}

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;

  TimeSlot({
    required this.startTime,
    required this.endTime,
  }) : duration = endTime.difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
  }
}

class AvailabilitySlot {
  final String id;
  final String caregiverId;
  final DateTime date;
  final TimeSlot timeSlot;
  final SlotStatus status;
  final String? appointmentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  AvailabilitySlot({
    required this.id,
    required this.caregiverId,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.appointmentId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caregiverId': caregiverId,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot.toJson(),
      'status': status.name,
      'appointmentId': appointmentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      id: json['id'] ?? json['\$id'] ?? '',
      caregiverId: json['caregiverId'] ?? '',
      date: DateTime.parse(json['date']),
      timeSlot: TimeSlot.fromJson(json['timeSlot']),
      status: SlotStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SlotStatus.available,
      ),
      appointmentId: json['appointmentId'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  factory AvailabilitySlot.fromAppwriteDocument(models.Document doc) {
    return AvailabilitySlot.fromJson({
      ...doc.data,
      'id': doc.$id,
      'createdAt': doc.$createdAt,
      'updatedAt': doc.$updatedAt,
    });
  }

  AvailabilitySlot copyWith({
    String? id,
    String? caregiverId,
    DateTime? date,
    TimeSlot? timeSlot,
    SlotStatus? status,
    String? appointmentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AvailabilitySlot(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      appointmentId: appointmentId ?? this.appointmentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}