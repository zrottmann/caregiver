import 'package:appwrite/appwrite.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../models/booking.dart';
import '../models/service.dart';

class BookingService {
  final Client _client;
  final Databases _databases;
  static const String _databaseId = 'caregiver_platform';
  static const String _bookingsCollectionId = 'bookings';
  static const String _servicesCollectionId = 'services';
  static const String _categoriesCollectionId = 'service_categories';

  BookingService({Client? client})
      : _client = client ?? Client(),
        _databases = Databases(client ?? Client()) {
    _client
        .setEndpoint(AppConfig.appwriteEndpoint)
        .setProject(AppConfig.appwriteProjectId);
  }

  // Booking Management
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        queries: [
          Query.equal('patientId', userId),
          Query.orderDesc('\$createdAt'),
        ],
      );

      return response.documents.map((doc) => Booking.fromJson(doc.data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user bookings: $e');
    }
  }

  Future<List<Booking>> getCaregiverBookings(String caregiverId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        queries: [
          Query.equal('caregiverId', caregiverId),
          Query.orderDesc('\$createdAt'),
        ],
      );

      return response.documents.map((doc) => Booking.fromJson(doc.data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch caregiver bookings: $e');
    }
  }

  Future<Booking> getBooking(String bookingId) async {
    try {
      final response = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        documentId: bookingId,
      );

      return Booking.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch booking: $e');
    }
  }

  Future<Booking> createBooking(Booking booking) async {
    try {
      final bookingId = const Uuid().v4();
      final now = DateTime.now();

      final bookingData = booking.copyWith(
        id: bookingId,
        createdAt: now,
        updatedAt: now,
        status: BookingStatus.pending,
      );

      final response = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        documentId: bookingId,
        data: bookingData.toJson(),
      );

      return Booking.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<Booking> updateBooking(String bookingId, Booking updatedBooking) async {
    try {
      final bookingData = updatedBooking.copyWith(
        updatedAt: DateTime.now(),
      );

      final response = await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        documentId: bookingId,
        data: bookingData.toJson(),
      );

      return Booking.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update booking: $e');
    }
  }

  Future<Booking> updateBookingStatus(String bookingId, BookingStatus status, {String? notes}) async {
    try {
      final booking = await getBooking(bookingId);
      final updatedBooking = booking.copyWith(
        status: status,
        notes: notes ?? booking.notes,
        updatedAt: DateTime.now(),
      );

      final response = await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        documentId: bookingId,
        data: updatedBooking.toJson(),
      );

      return Booking.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    try {
      await updateBookingStatus(
        bookingId,
        BookingStatus.cancelled,
        notes: reason,
      );
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // Service Management
  Future<List<ServiceCategory>> getServiceCategories() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _categoriesCollectionId,
        queries: [
          Query.orderAsc('order'),
        ],
      );

      return response.documents.map((doc) => ServiceCategory.fromJson(doc.data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch service categories: $e');
    }
  }

  Future<List<CareService>> getServices({String? categoryId}) async {
    try {
      final queries = [
        Query.equal('isActive', true),
        Query.orderAsc('name'),
      ];

      if (categoryId != null) {
        queries.add(Query.equal('categoryId', categoryId));
      }

      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _servicesCollectionId,
        queries: queries,
      );

      return response.documents.map((doc) => CareService.fromJson(doc.data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch services: $e');
    }
  }

  Future<CareService> getService(String serviceId) async {
    try {
      final response = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _servicesCollectionId,
        documentId: serviceId,
      );

      return CareService.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch service: $e');
    }
  }

  // Availability Management
  Future<List<String>> getAvailableTimeSlots(String caregiverId, DateTime date) async {
    try {
      // Get existing bookings for the caregiver on the specified date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        queries: [
          Query.equal('caregiverId', caregiverId),
          Query.greaterThanEqual('scheduledDate', startOfDay.toIso8601String()),
          Query.lessThanEqual('scheduledDate', endOfDay.toIso8601String()),
          Query.notEqual('status', BookingStatus.cancelled.name),
        ],
      );

      final bookedSlots = response.documents
          .map((doc) => doc.data['timeSlot'] as String)
          .toSet();

      // Generate available time slots (9 AM to 5 PM)
      const allTimeSlots = [
        '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
        '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
        '15:00', '15:30', '16:00', '16:30', '17:00',
      ];

      // Filter out booked slots and past time slots for today
      final now = DateTime.now();
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

      return allTimeSlots.where((slot) {
        if (bookedSlots.contains(slot)) return false;
        
        if (isToday) {
          final slotTime = DateTime(
            date.year,
            date.month,
            date.day,
            int.parse(slot.split(':')[0]),
            int.parse(slot.split(':')[1]),
          );
          return slotTime.isAfter(now.add(const Duration(hours: 1))); // 1-hour buffer
        }
        
        return true;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch available time slots: $e');
    }
  }

  Future<bool> isTimeSlotAvailable(String caregiverId, DateTime date, String timeSlot) async {
    try {
      final availableSlots = await getAvailableTimeSlots(caregiverId, date);
      return availableSlots.contains(timeSlot);
    } catch (e) {
      throw Exception('Failed to check time slot availability: $e');
    }
  }

  // Booking Statistics
  Future<Map<String, int>> getBookingStats(String userId, {bool isCaregiver = false}) async {
    try {
      final field = isCaregiver ? 'caregiverId' : 'patientId';
      
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        queries: [
          Query.equal(field, userId),
        ],
      );

      final bookings = response.documents.map((doc) => Booking.fromJson(doc.data)).toList();

      return {
        'total': bookings.length,
        'pending': bookings.where((b) => b.status == BookingStatus.pending).length,
        'confirmed': bookings.where((b) => b.status == BookingStatus.confirmed).length,
        'completed': bookings.where((b) => b.status == BookingStatus.completed).length,
        'cancelled': bookings.where((b) => b.status == BookingStatus.cancelled).length,
      };
    } catch (e) {
      throw Exception('Failed to fetch booking statistics: $e');
    }
  }

  // Search and Filter
  Future<List<Booking>> searchBookings(String userId, {
    String? query,
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool isCaregiver = false,
  }) async {
    try {
      final field = isCaregiver ? 'caregiverId' : 'patientId';
      final queries = [
        Query.equal(field, userId),
      ];

      if (status != null) {
        queries.add(Query.equal('status', status.name));
      }

      if (startDate != null) {
        queries.add(Query.greaterThanEqual('scheduledDate', startDate.toIso8601String()));
      }

      if (endDate != null) {
        queries.add(Query.lessThanEqual('scheduledDate', endDate.toIso8601String()));
      }

      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        queries: queries,
      );

      var bookings = response.documents.map((doc) => Booking.fromJson(doc.data)).toList();

      // Apply text search if query is provided
      if (query != null && query.isNotEmpty) {
        final lowercaseQuery = query.toLowerCase();
        bookings = bookings.where((booking) {
          return booking.caregiverName.toLowerCase().contains(lowercaseQuery) ||
                 booking.description.toLowerCase().contains(lowercaseQuery) ||
                 booking.services.any((service) => service.toLowerCase().contains(lowercaseQuery));
        }).toList();
      }

      return bookings;
    } catch (e) {
      throw Exception('Failed to search bookings: $e');
    }
  }
}