import 'package:appwrite/appwrite.dart';
import '../config/app_config.dart';
import '../models/appointment.dart';
import '../models/availability_slot.dart';
import '../models/calendar_event.dart';
import '../models/reminder.dart';

class AppointmentService {
  static const String appointmentsCollectionId = 'appointments';
  static const String availabilitySlotsCollectionId = 'availability_slots';
  static const String calendarEventsCollectionId = 'calendar_events';
  static const String remindersCollectionId = 'reminders';
  static const String caregiverAvailabilityCollectionId = 'caregiver_availability';

  final Databases _databases;

  AppointmentService() : _databases = Databases(AppConfig.client);

  // Appointment Management
  Future<List<Appointment>> getAppointments({
    String? userId,
    String? caregiverId,
    String? patientId,
    DateTime? startDate,
    DateTime? endDate,
    List<AppointmentStatus>? statuses,
  }) async {
    try {
      final queries = <String>[];
      
      if (userId != null) {
        queries.add(Query.or([
          Query.equal('patientId', userId),
          Query.equal('caregiverId', userId),
        ]));
      }
      
      if (caregiverId != null) {
        queries.add(Query.equal('caregiverId', caregiverId));
      }
      
      if (patientId != null) {
        queries.add(Query.equal('patientId', patientId));
      }
      
      if (startDate != null) {
        queries.add(Query.greaterThanEqual('startTime', startDate.toIso8601String()));
      }
      
      if (endDate != null) {
        queries.add(Query.lessThanEqual('startTime', endDate.toIso8601String()));
      }
      
      if (statuses != null && statuses.isNotEmpty) {
        queries.add(Query.equal('status', statuses.map((s) => s.name).toList()));
      }
      
      queries.add(Query.orderDesc('startTime'));
      
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: appointmentsCollectionId,
        queries: queries,
      );
      
      return response.documents
          .map((doc) => Appointment.fromJson(doc.data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch appointments: $e');
    }
  }

  Future<Appointment> createAppointment(Appointment appointment) async {
    try {
      // Check for conflicts
      await _checkAppointmentConflicts(appointment);
      
      final response = await _databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: appointmentsCollectionId,
        documentId: ID.unique(),
        data: appointment.toJson(),
      );
      
      final createdAppointment = Appointment.fromJson(response.data);
      
      // Create calendar event
      await _createCalendarEventForAppointment(createdAppointment);
      
      // Create reminders if needed
      await _createAppointmentReminders(createdAppointment);
      
      // Update availability slot to booked
      await _updateAvailabilityForAppointment(createdAppointment, SlotStatus.booked);
      
      return createdAppointment;
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  Future<Appointment> updateAppointment(String appointmentId, Appointment updatedAppointment) async {
    try {
      // Check for conflicts if time changed
      await _checkAppointmentConflicts(updatedAppointment, excludeAppointmentId: appointmentId);
      
      final response = await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: appointmentsCollectionId,
        documentId: appointmentId,
        data: updatedAppointment.copyWith(
          id: appointmentId,
          updatedAt: DateTime.now(),
        ).toJson(),
      );
      
      final appointment = Appointment.fromJson(response.data);
      
      // Update calendar event
      await _updateCalendarEventForAppointment(appointment);
      
      return appointment;
    } catch (e) {
      throw Exception('Failed to update appointment: $e');
    }
  }

  Future<void> cancelAppointment(String appointmentId, String reason) async {
    try {
      final appointment = await getAppointment(appointmentId);
      
      final cancelledAppointment = appointment.copyWith(
        status: AppointmentStatus.cancelled,
        notes: '${appointment.notes ?? ''}\nCancellation reason: $reason'.trim(),
        updatedAt: DateTime.now(),
      );
      
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: appointmentsCollectionId,
        documentId: appointmentId,
        data: cancelledAppointment.toJson(),
      );
      
      // Update availability slot back to available
      await _updateAvailabilityForAppointment(appointment, SlotStatus.available);
      
      // Cancel reminders
      await _cancelAppointmentReminders(appointmentId);
      
      // Update calendar event
      await _updateCalendarEventForAppointment(cancelledAppointment);
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  Future<Appointment> rescheduleAppointment(
    String appointmentId,
    DateTime newStartTime,
    DateTime newEndTime,
  ) async {
    try {
      final appointment = await getAppointment(appointmentId);
      
      final rescheduledAppointment = appointment.copyWith(
        startTime: newStartTime,
        endTime: newEndTime,
        status: AppointmentStatus.scheduled,
        updatedAt: DateTime.now(),
      );
      
      // Check for conflicts
      await _checkAppointmentConflicts(rescheduledAppointment, excludeAppointmentId: appointmentId);
      
      // Update old availability slot
      await _updateAvailabilityForAppointment(appointment, SlotStatus.available);
      
      // Update appointment
      final response = await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: appointmentsCollectionId,
        documentId: appointmentId,
        data: rescheduledAppointment.toJson(),
      );
      
      final updatedAppointment = Appointment.fromJson(response.data);
      
      // Update new availability slot
      await _updateAvailabilityForAppointment(updatedAppointment, SlotStatus.booked);
      
      // Update calendar event
      await _updateCalendarEventForAppointment(updatedAppointment);
      
      // Update reminders
      await _updateAppointmentReminders(updatedAppointment);
      
      return updatedAppointment;
    } catch (e) {
      throw Exception('Failed to reschedule appointment: $e');
    }
  }

  Future<Appointment> getAppointment(String appointmentId) async {
    try {
      final response = await _databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: appointmentsCollectionId,
        documentId: appointmentId,
      );
      
      return Appointment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get appointment: $e');
    }
  }

  // Availability Management
  Future<List<AvailabilitySlot>> getAvailabilitySlots({
    String? caregiverId,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    SlotStatus? status,
  }) async {
    try {
      final queries = <String>[];
      
      if (caregiverId != null) {
        queries.add(Query.equal('caregiverId', caregiverId));
      }
      
      if (date != null) {
        final dateStr = date.toIso8601String().split('T')[0];
        queries.add(Query.equal('date', dateStr));
      }
      
      if (startDate != null) {
        queries.add(Query.greaterThanEqual('date', startDate.toIso8601String().split('T')[0]));
      }
      
      if (endDate != null) {
        queries.add(Query.lessThanEqual('date', endDate.toIso8601String().split('T')[0]));
      }
      
      if (status != null) {
        queries.add(Query.equal('status', status.name));
      }
      
      queries.add(Query.orderAsc('date'));
      
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: availabilitySlotsCollectionId,
        queries: queries,
      );
      
      return response.documents
          .map((doc) => AvailabilitySlot.fromJson(doc.data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch availability slots: $e');
    }
  }

  Future<List<AvailabilitySlot>> getAvailableSlots({
    required String caregiverId,
    required DateTime date,
    Duration? minimumDuration,
  }) async {
    try {
      final slots = await getAvailabilitySlots(
        caregiverId: caregiverId,
        date: date,
        status: SlotStatus.available,
      );
      
      if (minimumDuration != null) {
        return slots.where((slot) => 
          slot.timeSlot.duration.inMinutes >= minimumDuration.inMinutes
        ).toList();
      }
      
      return slots;
    } catch (e) {
      throw Exception('Failed to get available slots: $e');
    }
  }

  Future<AvailabilitySlot> createAvailabilitySlot(AvailabilitySlot slot) async {
    try {
      final response = await _databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: availabilitySlotsCollectionId,
        documentId: ID.unique(),
        data: slot.toJson(),
      );
      
      return AvailabilitySlot.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create availability slot: $e');
    }
  }

  Future<List<AvailabilitySlot>> createRecurringAvailability({
    required String caregiverId,
    required List<DayOfWeek> days,
    required List<TimeSlot> timeSlots,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final slots = <AvailabilitySlot>[];
      final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
      final finalDate = DateTime(endDate.year, endDate.month, endDate.day);
      
      for (var date = currentDate; date.isBefore(finalDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
        final dayOfWeek = DayOfWeek.values[date.weekday - 1];
        
        if (days.contains(dayOfWeek)) {
          for (final timeSlot in timeSlots) {
            final slot = AvailabilitySlot(
              id: '',
              caregiverId: caregiverId,
              date: date,
              timeSlot: timeSlot,
              status: SlotStatus.available,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            slots.add(await createAvailabilitySlot(slot));
          }
        }
      }
      
      return slots;
    } catch (e) {
      throw Exception('Failed to create recurring availability: $e');
    }
  }

  // Calendar Events
  Future<List<CalendarEvent>> getCalendarEvents({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    List<EventType>? types,
  }) async {
    try {
      final queries = <String>[];
      
      if (userId != null) {
        queries.add(Query.or([
          Query.equal('patientId', userId),
          Query.equal('caregiverId', userId),
        ]));
      }
      
      if (startDate != null) {
        queries.add(Query.greaterThanEqual('startTime', startDate.toIso8601String()));
      }
      
      if (endDate != null) {
        queries.add(Query.lessThanEqual('startTime', endDate.toIso8601String()));
      }
      
      if (types != null && types.isNotEmpty) {
        queries.add(Query.equal('type', types.map((t) => t.name).toList()));
      }
      
      queries.add(Query.orderAsc('startTime'));
      
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: calendarEventsCollectionId,
        queries: queries,
      );
      
      return response.documents
          .map((doc) => CalendarEvent.fromJson(doc.data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch calendar events: $e');
    }
  }

  // Reminders
  Future<List<Reminder>> getReminders({
    String? userId,
    String? appointmentId,
    ReminderStatus? status,
  }) async {
    try {
      final queries = <String>[];
      
      if (userId != null) {
        queries.add(Query.or([
          Query.equal('patientId', userId),
          Query.equal('caregiverId', userId),
        ]));
      }
      
      if (appointmentId != null) {
        queries.add(Query.equal('appointmentId', appointmentId));
      }
      
      if (status != null) {
        queries.add(Query.equal('status', status.name));
      }
      
      queries.add(Query.orderAsc('scheduledTime'));
      
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: remindersCollectionId,
        queries: queries,
      );
      
      return response.documents
          .map((doc) => Reminder.fromJson(doc.data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reminders: $e');
    }
  }

  // Private helper methods
  Future<void> _checkAppointmentConflicts(Appointment appointment, {String? excludeAppointmentId}) async {
    final conflictingAppointments = await getAppointments(
      caregiverId: appointment.caregiverId,
      startDate: appointment.startTime.subtract(const Duration(hours: 1)),
      endDate: appointment.endTime.add(const Duration(hours: 1)),
      statuses: [AppointmentStatus.scheduled, AppointmentStatus.confirmed, AppointmentStatus.inProgress],
    );
    
    final conflicts = conflictingAppointments.where((existing) {
      if (excludeAppointmentId != null && existing.id == excludeAppointmentId) {
        return false;
      }
      return appointment.startTime.isBefore(existing.endTime) && 
             appointment.endTime.isAfter(existing.startTime);
    }).toList();
    
    if (conflicts.isNotEmpty) {
      throw Exception('Appointment conflicts with existing appointments');
    }
  }

  Future<void> _createCalendarEventForAppointment(Appointment appointment) async {
    try {
      final event = CalendarEvent.fromAppointment(appointment);
      
      await _databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: calendarEventsCollectionId,
        documentId: ID.unique(),
        data: event.toJson(),
      );
    } catch (e) {
      // Log error but don't fail the appointment creation
      print('Failed to create calendar event: $e');
    }
  }

  Future<void> _updateCalendarEventForAppointment(Appointment appointment) async {
    try {
      // Find existing calendar event
      final events = await getCalendarEvents(
        startDate: appointment.startTime.subtract(const Duration(days: 1)),
        endDate: appointment.endTime.add(const Duration(days: 1)),
        types: [EventType.appointment],
      );
      
      final existingEvent = events.firstWhere(
        (event) => event.appointmentId == appointment.id,
        orElse: () => throw Exception('Calendar event not found'),
      );
      
      final updatedEvent = CalendarEvent.fromAppointment(appointment);
      
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: calendarEventsCollectionId,
        documentId: existingEvent.id,
        data: updatedEvent.toJson(),
      );
    } catch (e) {
      // Log error but don't fail
      print('Failed to update calendar event: $e');
    }
  }

  Future<void> _createAppointmentReminders(Appointment appointment) async {
    try {
      // Create default reminders (24h and 1h before)
      final reminders = [
        Reminder.createAppointmentReminder(
          appointmentId: appointment.id,
          userId: appointment.patientId,
          appointmentTime: appointment.startTime,
          patientName: appointment.patientName,
          caregiverName: appointment.caregiverName,
          beforeAppointment: const Duration(hours: 24),
        ),
        Reminder.createAppointmentReminder(
          appointmentId: appointment.id,
          userId: appointment.patientId,
          appointmentTime: appointment.startTime,
          patientName: appointment.patientName,
          caregiverName: appointment.caregiverName,
          beforeAppointment: const Duration(hours: 1),
        ),
      ];
      
      for (final reminder in reminders) {
        await _databases.createDocument(
          databaseId: AppConfig.databaseId,
          collectionId: remindersCollectionId,
          documentId: ID.unique(),
          data: reminder.toJson(),
        );
      }
    } catch (e) {
      print('Failed to create reminders: $e');
    }
  }

  Future<void> _updateAppointmentReminders(Appointment appointment) async {
    try {
      final reminders = await getReminders(appointmentId: appointment.id);
      
      for (final reminder in reminders) {
        if (reminder.isPending) {
          final newScheduledTime = appointment.startTime.subtract(reminder.advanceTime.abs());
          
          await _databases.updateDocument(
            databaseId: AppConfig.databaseId,
            collectionId: remindersCollectionId,
            documentId: reminder.id,
            data: reminder.copyWith(
              scheduledTime: newScheduledTime,
              updatedAt: DateTime.now(),
            ).toJson(),
          );
        }
      }
    } catch (e) {
      print('Failed to update reminders: $e');
    }
  }

  Future<void> _cancelAppointmentReminders(String appointmentId) async {
    try {
      final reminders = await getReminders(appointmentId: appointmentId);
      
      for (final reminder in reminders) {
        if (reminder.isPending) {
          await _databases.updateDocument(
            databaseId: AppConfig.databaseId,
            collectionId: remindersCollectionId,
            documentId: reminder.id,
            data: reminder.copyWith(
              status: ReminderStatus.cancelled,
              updatedAt: DateTime.now(),
            ).toJson(),
          );
        }
      }
    } catch (e) {
      print('Failed to cancel reminders: $e');
    }
  }

  Future<void> _updateAvailabilityForAppointment(Appointment appointment, SlotStatus newStatus) async {
    try {
      final slots = await getAvailabilitySlots(
        caregiverId: appointment.caregiverId,
        date: appointment.startTime,
      );
      
      final matchingSlot = slots.firstWhere(
        (slot) => slot.timeSlot.startTime.hour == appointment.startTime.hour &&
                  slot.timeSlot.startTime.minute == appointment.startTime.minute,
        orElse: () => throw Exception('Availability slot not found'),
      );
      
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: availabilitySlotsCollectionId,
        documentId: matchingSlot.id,
        data: matchingSlot.copyWith(
          status: newStatus,
          appointmentId: newStatus == SlotStatus.booked ? appointment.id : null,
          updatedAt: DateTime.now(),
        ).toJson(),
      );
    } catch (e) {
      print('Failed to update availability: $e');
    }
  }
}