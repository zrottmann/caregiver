enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

enum SlotStatus {
  available,
  booked,
  blocked,
  tentative,
}

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;

  TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);

  String get timeRange {
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  bool overlaps(TimeSlot other) {
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  }

  bool contains(DateTime time) {
    return time.isAtSameMomentAs(startTime) || 
           time.isAtSameMomentAs(endTime) ||
           (time.isAfter(startTime) && time.isBefore(endTime));
  }

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;
}

class AvailabilitySlot {
  final String id;
  final String caregiverId;
  final DateTime date;
  final TimeSlot timeSlot;
  final SlotStatus status;
  final String? appointmentId;
  final bool isRecurring;
  final List<DayOfWeek>? recurringDays;
  final DateTime? recurringEndDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AvailabilitySlot({
    required this.id,
    required this.caregiverId,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.appointmentId,
    this.isRecurring = false,
    this.recurringDays,
    this.recurringEndDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAvailable => status == SlotStatus.available;
  bool get isBooked => status == SlotStatus.booked;
  bool get isBlocked => status == SlotStatus.blocked;
  bool get isTentative => status == SlotStatus.tentative;

  String get statusText {
    switch (status) {
      case SlotStatus.available:
        return 'Available';
      case SlotStatus.booked:
        return 'Booked';
      case SlotStatus.blocked:
        return 'Blocked';
      case SlotStatus.tentative:
        return 'Tentative';
    }
  }

  DateTime get startDateTime => DateTime(
        date.year,
        date.month,
        date.day,
        timeSlot.startTime.hour,
        timeSlot.startTime.minute,
      );

  DateTime get endDateTime => DateTime(
        date.year,
        date.month,
        date.day,
        timeSlot.endTime.hour,
        timeSlot.endTime.minute,
      );

  bool conflictsWith(AvailabilitySlot other) {
    if (date.day != other.date.day ||
        date.month != other.date.month ||
        date.year != other.date.year) {
      return false;
    }
    return timeSlot.overlaps(other.timeSlot);
  }

  Map<String, dynamic> toJson() {
    return {
      'caregiverId': caregiverId,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot.toJson(),
      'status': status.name,
      'appointmentId': appointmentId,
      'isRecurring': isRecurring,
      'recurringDays': recurringDays?.map((e) => e.name).toList(),
      'recurringEndDate': recurringEndDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      id: json['\$id'] ?? json['id'] ?? '',
      caregiverId: json['caregiverId'] ?? '',
      date: DateTime.parse(json['date']),
      timeSlot: TimeSlot.fromJson(json['timeSlot']),
      status: SlotStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SlotStatus.available,
      ),
      appointmentId: json['appointmentId'],
      isRecurring: json['isRecurring'] ?? false,
      recurringDays: json['recurringDays'] != null
          ? List<String>.from(json['recurringDays'])
              .map((e) => DayOfWeek.values.firstWhere((d) => d.name == e))
              .toList()
          : null,
      recurringEndDate: json['recurringEndDate'] != null
          ? DateTime.parse(json['recurringEndDate'])
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  AvailabilitySlot copyWith({
    String? id,
    String? caregiverId,
    DateTime? date,
    TimeSlot? timeSlot,
    SlotStatus? status,
    String? appointmentId,
    bool? isRecurring,
    List<DayOfWeek>? recurringDays,
    DateTime? recurringEndDate,
    String? notes,
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
      isRecurring: isRecurring ?? this.isRecurring,
      recurringDays: recurringDays ?? this.recurringDays,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Helper class for caregiver availability preferences
class CaregiverAvailability {
  final String caregiverId;
  final Map<DayOfWeek, List<TimeSlot>> weeklySchedule;
  final List<DateTime> blockedDates;
  final List<AvailabilitySlot> customSlots;
  final Duration minimumBookingNotice;
  final Duration maximumBookingAdvance;
  final DateTime updatedAt;

  CaregiverAvailability({
    required this.caregiverId,
    required this.weeklySchedule,
    this.blockedDates = const [],
    this.customSlots = const [],
    this.minimumBookingNotice = const Duration(hours: 24),
    this.maximumBookingAdvance = const Duration(days: 30),
    required this.updatedAt,
  });

  List<TimeSlot> getAvailableSlotsForDay(DayOfWeek dayOfWeek) {
    return weeklySchedule[dayOfWeek] ?? [];
  }

  bool isDateBlocked(DateTime date) {
    return blockedDates.any((blockedDate) =>
        blockedDate.day == date.day &&
        blockedDate.month == date.month &&
        blockedDate.year == date.year);
  }

  Map<String, dynamic> toJson() {
    return {
      'caregiverId': caregiverId,
      'weeklySchedule': weeklySchedule.map((key, value) => MapEntry(
            key.name,
            value.map((slot) => slot.toJson()).toList(),
          )),
      'blockedDates': blockedDates.map((e) => e.toIso8601String()).toList(),
      'customSlots': customSlots.map((e) => e.toJson()).toList(),
      'minimumBookingNotice': minimumBookingNotice.inMinutes,
      'maximumBookingAdvance': maximumBookingAdvance.inDays,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CaregiverAvailability.fromJson(Map<String, dynamic> json) {
    final weeklyScheduleJson = json['weeklySchedule'] as Map<String, dynamic>? ?? {};
    final weeklySchedule = <DayOfWeek, List<TimeSlot>>{};

    for (final entry in weeklyScheduleJson.entries) {
      final dayOfWeek = DayOfWeek.values.firstWhere((e) => e.name == entry.key);
      final slots = (entry.value as List)
          .map((slotJson) => TimeSlot.fromJson(slotJson))
          .toList();
      weeklySchedule[dayOfWeek] = slots;
    }

    return CaregiverAvailability(
      caregiverId: json['caregiverId'] ?? '',
      weeklySchedule: weeklySchedule,
      blockedDates: json['blockedDates'] != null
          ? List<String>.from(json['blockedDates'])
              .map((e) => DateTime.parse(e))
              .toList()
          : [],
      customSlots: json['customSlots'] != null
          ? List<Map<String, dynamic>>.from(json['customSlots'])
              .map((e) => AvailabilitySlot.fromJson(e))
              .toList()
          : [],
      minimumBookingNotice: Duration(minutes: json['minimumBookingNotice'] ?? 1440),
      maximumBookingAdvance: Duration(days: json['maximumBookingAdvance'] ?? 30),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}