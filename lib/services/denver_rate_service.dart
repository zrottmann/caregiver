import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CaregiverProfile {
  final String id;
  final String name;
  final String credentials;
  final double baseRate;
  final int totalHoursWorked;
  final int totalHoursAvailable;
  final List<String> specialties;
  final double rating;
  final DateTime joinDate;
  
  CaregiverProfile({
    required this.id,
    required this.name,
    required this.credentials,
    required this.baseRate,
    required this.totalHoursWorked,
    required this.totalHoursAvailable,
    required this.specialties,
    required this.rating,
    required this.joinDate,
  });
  
  double get bookingPercentage {
    if (totalHoursAvailable == 0) return 0.0;
    return (totalHoursWorked / totalHoursAvailable) * 100;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'credentials': credentials,
      'baseRate': baseRate,
      'totalHoursWorked': totalHoursWorked,
      'totalHoursAvailable': totalHoursAvailable,
      'specialties': specialties,
      'rating': rating,
      'joinDate': joinDate.toIso8601String(),
    };
  }
  
  factory CaregiverProfile.fromJson(Map<String, dynamic> json) {
    return CaregiverProfile(
      id: json['id'],
      name: json['name'],
      credentials: json['credentials'],
      baseRate: json['baseRate'].toDouble(),
      totalHoursWorked: json['totalHoursWorked'],
      totalHoursAvailable: json['totalHoursAvailable'],
      specialties: List<String>.from(json['specialties']),
      rating: json['rating'].toDouble(),
      joinDate: DateTime.parse(json['joinDate']),
    );
  }
}

class AvailabilitySlot {
  final String id;
  final String caregiverId;
  final DateTime startTime;
  final DateTime endTime;
  final bool isBooked;
  final String? appointmentId;
  
  AvailabilitySlot({
    required this.id,
    required this.caregiverId,
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
    this.appointmentId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caregiverId': caregiverId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isBooked': isBooked,
      'appointmentId': appointmentId,
    };
  }
  
  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      id: json['id'],
      caregiverId: json['caregiverId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      isBooked: json['isBooked'] ?? false,
      appointmentId: json['appointmentId'],
    );
  }
}

class DenverRateService {
  static const String _caregiversKey = 'caregivers';
  static const String _availabilityKey = 'availability_slots';
  
  // Denver, CO base rates (2024) - competitive market rates
  static const Map<String, double> denverBaseRates = {
    'Personal Care & Daily Activities': 22.0,
    'Companion Care & Emotional Support': 18.0,
    'Medication Management': 26.0,
    'Light Housekeeping & Meal Prep': 16.0,
    'Transportation & Errands': 15.0,
    'Specialized Dementia Care': 32.0,
  };
  
  // Booking percentage multipliers
  static double getBookingMultiplier(double bookingPercentage) {
    if (bookingPercentage >= 90) return 1.5; // 50% premium for high demand
    if (bookingPercentage >= 80) return 1.35; // 35% premium
    if (bookingPercentage >= 70) return 1.25; // 25% premium
    if (bookingPercentage >= 60) return 1.15; // 15% premium
    if (bookingPercentage >= 50) return 1.10; // 10% premium
    return 1.0; // Base rate
  }
  
  // Experience multipliers
  static double getExperienceMultiplier(String credentials) {
    switch (credentials.toLowerCase()) {
      case 'rn': // Registered Nurse
        return 1.4;
      case 'lpn': // Licensed Practical Nurse
        return 1.25;
      case 'cna': // Certified Nursing Assistant
        return 1.15;
      case 'hha': // Home Health Aide
        return 1.1;
      case 'pca': // Personal Care Assistant
        return 1.0;
      default:
        return 1.0;
    }
  }
  
  double calculateDynamicRate({
    required String serviceType,
    required double bookingPercentage,
    required String credentials,
    required double rating,
  }) {
    final baseRate = denverBaseRates[serviceType] ?? 20.0;
    final bookingMultiplier = getBookingMultiplier(bookingPercentage);
    final experienceMultiplier = getExperienceMultiplier(credentials);
    final ratingMultiplier = rating >= 4.8 ? 1.1 : (rating >= 4.5 ? 1.05 : 1.0);
    
    return baseRate * bookingMultiplier * experienceMultiplier * ratingMultiplier;
  }
  
  Future<List<CaregiverProfile>> getCaregivers() async {
    final prefs = await SharedPreferences.getInstance();
    final caregiversJson = prefs.getStringList(_caregiversKey) ?? [];
    
    if (caregiversJson.isEmpty) {
      // Initialize with default caregivers
      return _initializeDefaultCaregivers();
    }
    
    return caregiversJson
        .map((json) => CaregiverProfile.fromJson(jsonDecode(json)))
        .toList();
  }
  
  Future<void> saveCaregivers(List<CaregiverProfile> caregivers) async {
    final prefs = await SharedPreferences.getInstance();
    final caregiversJson = caregivers
        .map((caregiver) => jsonEncode(caregiver.toJson()))
        .toList();
    
    await prefs.setStringList(_caregiversKey, caregiversJson);
  }
  
  Future<List<AvailabilitySlot>> getAvailabilitySlots(String caregiverId) async {
    final prefs = await SharedPreferences.getInstance();
    final slotsJson = prefs.getStringList('${_availabilityKey}_$caregiverId') ?? [];
    
    return slotsJson
        .map((json) => AvailabilitySlot.fromJson(jsonDecode(json)))
        .toList();
  }
  
  Future<void> saveAvailabilitySlots(String caregiverId, List<AvailabilitySlot> slots) async {
    final prefs = await SharedPreferences.getInstance();
    final slotsJson = slots
        .map((slot) => jsonEncode(slot.toJson()))
        .toList();
    
    await prefs.setStringList('${_availabilityKey}_$caregiverId', slotsJson);
  }
  
  Future<void> addAvailabilitySlot(AvailabilitySlot slot) async {
    final slots = await getAvailabilitySlots(slot.caregiverId);
    slots.add(slot);
    await saveAvailabilitySlots(slot.caregiverId, slots);
  }
  
  Future<void> updateCaregiverStats(String caregiverId, int hoursWorked) async {
    final caregivers = await getCaregivers();
    final caregiverIndex = caregivers.indexWhere((c) => c.id == caregiverId);
    
    if (caregiverIndex != -1) {
      final caregiver = caregivers[caregiverIndex];
      final updatedCaregiver = CaregiverProfile(
        id: caregiver.id,
        name: caregiver.name,
        credentials: caregiver.credentials,
        baseRate: caregiver.baseRate,
        totalHoursWorked: caregiver.totalHoursWorked + hoursWorked,
        totalHoursAvailable: caregiver.totalHoursAvailable,
        specialties: caregiver.specialties,
        rating: caregiver.rating,
        joinDate: caregiver.joinDate,
      );
      
      caregivers[caregiverIndex] = updatedCaregiver;
      await saveCaregivers(caregivers);
    }
  }
  
  Future<List<CaregiverProfile>> _initializeDefaultCaregivers() async {
    final defaultCaregivers = [
      CaregiverProfile(
        id: 'christina_rottmann',
        name: 'Christina Rottmann (Owner)',
        credentials: 'RN',
        baseRate: 40.0,
        totalHoursWorked: 1200,
        totalHoursAvailable: 1400,
        specialties: ['All Services', 'Management', 'Training'],
        rating: 4.95,
        joinDate: DateTime(2016, 1, 1),
      ),
      CaregiverProfile(
        id: 'sarah_johnson',
        name: 'Sarah Johnson',
        credentials: 'RN',
        baseRate: 35.0,
        totalHoursWorked: 800,
        totalHoursAvailable: 1000,
        specialties: ['Medication Management', 'Personal Care'],
        rating: 4.8,
        joinDate: DateTime(2020, 3, 15),
      ),
      CaregiverProfile(
        id: 'emily_chen',
        name: 'Emily Chen',
        credentials: 'CNA',
        baseRate: 25.0,
        totalHoursWorked: 600,
        totalHoursAvailable: 800,
        specialties: ['Personal Care', 'Companion Care'],
        rating: 4.7,
        joinDate: DateTime(2021, 6, 1),
      ),
      CaregiverProfile(
        id: 'michael_davis',
        name: 'Michael Davis',
        credentials: 'HHA',
        baseRate: 22.0,
        totalHoursWorked: 400,
        totalHoursAvailable: 600,
        specialties: ['Transportation', 'Light Housekeeping'],
        rating: 4.6,
        joinDate: DateTime(2022, 1, 10),
      ),
      CaregiverProfile(
        id: 'lisa_brown',
        name: 'Lisa Brown',
        credentials: 'PCA',
        baseRate: 20.0,
        totalHoursWorked: 300,
        totalHoursAvailable: 500,
        specialties: ['Companion Care', 'Personal Care'],
        rating: 4.5,
        joinDate: DateTime(2022, 8, 20),
      ),
    ];
    
    await saveCaregivers(defaultCaregivers);
    return defaultCaregivers;
  }
}