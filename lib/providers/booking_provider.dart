import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../models/service.dart' as service_model;
import '../services/booking_service.dart' as booking_service;

class BookingState {
  final List<Booking> bookings;
  final List<service_model.CareService> services;
  final List<service_model.ServiceCategory> categories;
  final List<String> availableTimeSlots;
  final Map<String, int> bookingStats;
  final bool isLoading;
  final bool isLoadingServices;
  final bool isLoadingAvailability;
  final String? error;

  BookingState({
    this.bookings = const [],
    this.services = const [],
    this.categories = const [],
    this.availableTimeSlots = const [],
    this.bookingStats = const {},
    this.isLoading = false,
    this.isLoadingServices = false,
    this.isLoadingAvailability = false,
    this.error,
  });

  BookingState copyWith({
    List<Booking>? bookings,
    List<service_model.CareService>? services,
    List<service_model.ServiceCategory>? categories,
    List<String>? availableTimeSlots,
    Map<String, int>? bookingStats,
    bool? isLoading,
    bool? isLoadingServices,
    bool? isLoadingAvailability,
    String? error,
  }) {
    return BookingState(
      bookings: bookings ?? this.bookings,
      services: services ?? this.services,
      categories: categories ?? this.categories,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      bookingStats: bookingStats ?? this.bookingStats,
      isLoading: isLoading ?? this.isLoading,
      isLoadingServices: isLoadingServices ?? this.isLoadingServices,
      isLoadingAvailability: isLoadingAvailability ?? this.isLoadingAvailability,
      error: error,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final booking_service.BookingService _bookingService;

  BookingNotifier(this._bookingService) : super(BookingState());

  // Booking Management
  Future<Booking> createBooking(Booking booking) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final createdBooking = await _bookingService.createBooking(booking);
      
      // Add to local state
      state = state.copyWith(
        bookings: [...state.bookings, createdBooking],
        isLoading: false,
      );
      
      return createdBooking;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> loadUserBookings(String userId, {bool isCaregiver = false}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final bookings = isCaregiver
          ? await _bookingService.getCaregiverBookings(userId)
          : await _bookingService.getUserBookings(userId);
      
      state = state.copyWith(
        bookings: bookings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<Booking?> getBooking(String bookingId) async {
    try {
      // Check if already in state
      final existingBooking = state.bookings.where((booking) => booking.id == bookingId).firstOrNull;
      if (existingBooking != null) {
        return existingBooking;
      }
      
      // Fetch from service
      return await _bookingService.getBooking(bookingId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus status, {String? notes}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final updatedBooking = await _bookingService.updateBookingStatus(bookingId, status, notes: notes);
      
      // Update in local state
      final updatedBookings = state.bookings.map((booking) {
        return booking.id == bookingId ? updatedBooking : booking;
      }).toList();
      
      state = state.copyWith(
        bookings: updatedBookings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    try {
      await _bookingService.cancelBooking(bookingId, reason: reason);
      await updateBookingStatus(bookingId, BookingStatus.cancelled, notes: reason);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Service Management
  Future<void> loadServices({String? categoryId}) async {
    try {
      state = state.copyWith(isLoadingServices: true, error: null);
      
      final services = await _bookingService.getServices(categoryId: categoryId);
      
      state = state.copyWith(
        services: services,
        isLoadingServices: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingServices: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadServiceCategories() async {
    try {
      state = state.copyWith(isLoadingServices: true, error: null);
      
      final categories = await _bookingService.getServiceCategories();
      
      state = state.copyWith(
        categories: categories,
        isLoadingServices: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingServices: false,
        error: e.toString(),
      );
    }
  }

  Future<service_model.CareService?> getService(String serviceId) async {
    try {
      // Check if already in state
      final existingService = state.services.where((service) => service.id == serviceId).firstOrNull;
      if (existingService != null) {
        return existingService;
      }
      
      // Fetch from service
      return await _bookingService.getService(serviceId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Availability Management
  Future<void> loadAvailableTimeSlots(String caregiverId, DateTime date) async {
    try {
      state = state.copyWith(isLoadingAvailability: true, error: null);
      
      final availableSlots = await _bookingService.getAvailableTimeSlots(caregiverId, date);
      
      state = state.copyWith(
        availableTimeSlots: availableSlots,
        isLoadingAvailability: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingAvailability: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> isTimeSlotAvailable(String caregiverId, DateTime date, String timeSlot) async {
    try {
      return await _bookingService.isTimeSlotAvailable(caregiverId, date, timeSlot);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Statistics
  Future<void> loadBookingStats(String userId, {bool isCaregiver = false}) async {
    try {
      final stats = await _bookingService.getBookingStats(userId, isCaregiver: isCaregiver);
      
      state = state.copyWith(bookingStats: stats);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Search and Filter
  Future<void> searchBookings(String userId, {
    String? query,
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool isCaregiver = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final bookings = await _bookingService.searchBookings(
        userId,
        query: query,
        status: status,
        startDate: startDate,
        endDate: endDate,
        isCaregiver: isCaregiver,
      );
      
      state = state.copyWith(
        bookings: bookings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearAvailableTimeSlots() {
    state = state.copyWith(availableTimeSlots: []);
  }
}

// Service Providers
final bookingServiceProvider = Provider<booking_service.BookingService>((ref) {
  return booking_service.BookingService();
});

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier(ref.read(bookingServiceProvider));
});

// Convenience providers for specific data
final servicesProvider = Provider<List<service_model.CareService>>((ref) {
  return ref.watch(bookingProvider).services;
});

final serviceCategoriesProvider = Provider<List<service_model.ServiceCategory>>((ref) {
  return ref.watch(bookingProvider).categories;
});

final availableTimeSlotsProvider = Provider<List<String>>((ref) {
  return ref.watch(bookingProvider).availableTimeSlots;
});

final bookingStatsProvider = Provider<Map<String, int>>((ref) {
  return ref.watch(bookingProvider).bookingStats;
});