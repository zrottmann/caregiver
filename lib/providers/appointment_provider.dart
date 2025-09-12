import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment.dart';
import '../models/availability_slot.dart';
import '../models/calendar_event.dart';
import '../models/reminder.dart';
import '../services/appointment_service.dart';
import 'auth_provider.dart';

// Service provider
final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService();
});

// Appointment providers
final appointmentsProvider = FutureProvider.autoDispose.family<List<Appointment>, AppointmentFilters?>((ref, filters) async {
  final service = ref.read(appointmentServiceProvider);
  final currentUser = ref.read(currentUserProfileProvider);
  
  return service.getAppointments(
    userId: filters?.userId ?? currentUser?.id,
    caregiverId: filters?.caregiverId,
    patientId: filters?.patientId,
    startDate: filters?.startDate,
    endDate: filters?.endDate,
    statuses: filters?.statuses,
  );
});

final appointmentProvider = FutureProvider.autoDispose.family<Appointment, String>((ref, appointmentId) async {
  final service = ref.read(appointmentServiceProvider);
  return service.getAppointment(appointmentId);
});

final upcomingAppointmentsProvider = FutureProvider.autoDispose<List<Appointment>>((ref) async {
  final service = ref.read(appointmentServiceProvider);
  final currentUser = ref.read(currentUserProfileProvider);
  
  if (currentUser == null) return [];
  
  final now = DateTime.now();
  final nextWeek = now.add(const Duration(days: 7));
  
  return service.getAppointments(
    userId: currentUser.id,
    startDate: now,
    endDate: nextWeek,
    statuses: [AppointmentStatus.scheduled, AppointmentStatus.confirmed],
  );
});

final todayAppointmentsProvider = FutureProvider.autoDispose<List<Appointment>>((ref) async {
  final service = ref.read(appointmentServiceProvider);
  final currentUser = ref.read(currentUserProfileProvider);
  
  if (currentUser == null) return [];
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  
  return service.getAppointments(
    userId: currentUser.id,
    startDate: today,
    endDate: tomorrow,
  );
});

// Appointment management notifier
class AppointmentNotifier extends StateNotifier<AsyncValue<void>> {
  AppointmentNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  final AppointmentService _service;
  final Ref _ref;

  Future<Appointment> createAppointment(Appointment appointment) async {
    state = const AsyncValue.loading();
    try {
      final createdAppointment = await _service.createAppointment(appointment);
      
      // Invalidate related providers
      _ref.invalidate(appointmentsProvider);
      _ref.invalidate(upcomingAppointmentsProvider);
      _ref.invalidate(todayAppointmentsProvider);
      _ref.invalidate(availabilitySlotsProvider);
      _ref.invalidate(calendarEventsProvider);
      
      state = const AsyncValue.data(null);
      return createdAppointment;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<Appointment> updateAppointment(String appointmentId, Appointment appointment) async {
    state = const AsyncValue.loading();
    try {
      final updatedAppointment = await _service.updateAppointment(appointmentId, appointment);
      
      // Invalidate related providers
      _ref.invalidate(appointmentsProvider);
      _ref.invalidate(appointmentProvider(appointmentId));
      _ref.invalidate(upcomingAppointmentsProvider);
      _ref.invalidate(todayAppointmentsProvider);
      _ref.invalidate(calendarEventsProvider);
      
      state = const AsyncValue.data(null);
      return updatedAppointment;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> cancelAppointment(String appointmentId, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _service.cancelAppointment(appointmentId, reason);
      
      // Invalidate related providers
      _ref.invalidate(appointmentsProvider);
      _ref.invalidate(appointmentProvider(appointmentId));
      _ref.invalidate(upcomingAppointmentsProvider);
      _ref.invalidate(todayAppointmentsProvider);
      _ref.invalidate(availabilitySlotsProvider);
      _ref.invalidate(calendarEventsProvider);
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<Appointment> rescheduleAppointment(
    String appointmentId,
    DateTime newStartTime,
    DateTime newEndTime,
  ) async {
    state = const AsyncValue.loading();
    try {
      final rescheduledAppointment = await _service.rescheduleAppointment(
        appointmentId,
        newStartTime,
        newEndTime,
      );
      
      // Invalidate related providers
      _ref.invalidate(appointmentsProvider);
      _ref.invalidate(appointmentProvider(appointmentId));
      _ref.invalidate(upcomingAppointmentsProvider);
      _ref.invalidate(todayAppointmentsProvider);
      _ref.invalidate(availabilitySlotsProvider);
      _ref.invalidate(calendarEventsProvider);
      
      state = const AsyncValue.data(null);
      return rescheduledAppointment;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final appointmentNotifierProvider = StateNotifierProvider<AppointmentNotifier, AsyncValue<void>>((ref) {
  final service = ref.read(appointmentServiceProvider);
  return AppointmentNotifier(service, ref);
});

// Availability providers
final availabilitySlotsProvider = FutureProvider.autoDispose.family<List<AvailabilitySlot>, AvailabilityFilters?>((ref, filters) async {
  final service = ref.read(appointmentServiceProvider);
  
  return service.getAvailabilitySlots(
    caregiverId: filters?.caregiverId,
    date: filters?.date,
    startDate: filters?.startDate,
    endDate: filters?.endDate,
    status: filters?.status,
  );
});

final availableSlotsProvider = FutureProvider.autoDispose.family<List<AvailabilitySlot>, AvailableSlotFilters>((ref, filters) async {
  final service = ref.read(appointmentServiceProvider);
  
  return service.getAvailableSlots(
    caregiverId: filters.caregiverId,
    date: filters.date,
    minimumDuration: filters.minimumDuration,
  );
});

// Calendar providers
final calendarEventsProvider = FutureProvider.autoDispose.family<List<CalendarEvent>, CalendarFilters?>((ref, filters) async {
  final service = ref.read(appointmentServiceProvider);
  final currentUser = ref.read(currentUserProfileProvider);
  
  return service.getCalendarEvents(
    userId: filters?.userId ?? currentUser?.id,
    startDate: filters?.startDate,
    endDate: filters?.endDate,
    types: filters?.types,
  );
});

final monthCalendarEventsProvider = FutureProvider.autoDispose.family<List<CalendarEvent>, DateTime>((ref, month) async {
  final startOfMonth = DateTime(month.year, month.month, 1);
  final endOfMonth = DateTime(month.year, month.month + 1, 0);
  
  final filters = CalendarFilters(
    startDate: startOfMonth,
    endDate: endOfMonth,
  );
  
  return ref.read(calendarEventsProvider(filters).future);
});

final dayCalendarEventsProvider = FutureProvider.autoDispose.family<List<CalendarEvent>, DateTime>((ref, date) async {
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  final filters = CalendarFilters(
    startDate: startOfDay,
    endDate: endOfDay,
  );
  
  return ref.read(calendarEventsProvider(filters).future);
});

// Reminder providers
final remindersProvider = FutureProvider.autoDispose.family<List<Reminder>, ReminderFilters?>((ref, filters) async {
  final service = ref.read(appointmentServiceProvider);
  final currentUser = ref.read(currentUserProfileProvider);
  
  return service.getReminders(
    userId: filters?.userId ?? currentUser?.id,
    appointmentId: filters?.appointmentId,
    status: filters?.status,
  );
});

final pendingRemindersProvider = FutureProvider.autoDispose<List<Reminder>>((ref) async {
  final filters = ReminderFilters(status: ReminderStatus.scheduled);
  return ref.read(remindersProvider(filters).future);
});

// Filter classes
class AppointmentFilters {
  final String? userId;
  final String? caregiverId;
  final String? patientId;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<AppointmentStatus>? statuses;

  const AppointmentFilters({
    this.userId,
    this.caregiverId,
    this.patientId,
    this.startDate,
    this.endDate,
    this.statuses,
  });
}

class AvailabilityFilters {
  final String? caregiverId;
  final DateTime? date;
  final DateTime? startDate;
  final DateTime? endDate;
  final SlotStatus? status;

  const AvailabilityFilters({
    this.caregiverId,
    this.date,
    this.startDate,
    this.endDate,
    this.status,
  });
}

class AvailableSlotFilters {
  final String caregiverId;
  final DateTime date;
  final Duration? minimumDuration;

  const AvailableSlotFilters({
    required this.caregiverId,
    required this.date,
    this.minimumDuration,
  });
}

class CalendarFilters {
  final String? userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<EventType>? types;

  const CalendarFilters({
    this.userId,
    this.startDate,
    this.endDate,
    this.types,
  });
}

class ReminderFilters {
  final String? userId;
  final String? appointmentId;
  final ReminderStatus? status;

  const ReminderFilters({
    this.userId,
    this.appointmentId,
    this.status,
  });
}

// Current selected appointment provider for navigation
final selectedAppointmentProvider = StateProvider<String?>((ref) => null);

// Calendar view state
class CalendarViewState {
  final DateTime currentMonth;
  final DateTime? selectedDate;
  final CalendarViewType viewType;

  const CalendarViewState({
    required this.currentMonth,
    this.selectedDate,
    this.viewType = CalendarViewType.month,
  });

  CalendarViewState copyWith({
    DateTime? currentMonth,
    DateTime? selectedDate,
    CalendarViewType? viewType,
  }) {
    return CalendarViewState(
      currentMonth: currentMonth ?? this.currentMonth,
      selectedDate: selectedDate ?? this.selectedDate,
      viewType: viewType ?? this.viewType,
    );
  }
}

enum CalendarViewType {
  month,
  week,
  day,
}

class CalendarViewNotifier extends StateNotifier<CalendarViewState> {
  CalendarViewNotifier() : super(CalendarViewState(currentMonth: DateTime.now()));

  void changeMonth(DateTime newMonth) {
    state = state.copyWith(currentMonth: newMonth);
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void changeViewType(CalendarViewType viewType) {
    state = state.copyWith(viewType: viewType);
  }

  void goToToday() {
    final now = DateTime.now();
    state = state.copyWith(
      currentMonth: now,
      selectedDate: now,
    );
  }
}

final calendarViewProvider = StateNotifierProvider<CalendarViewNotifier, CalendarViewState>((ref) {
  return CalendarViewNotifier();
});