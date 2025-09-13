import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleAppointment {
  final String id;
  final String caregiverName;
  final DateTime dateTime;
  final double price;
  final String status;
  final String description;
  final String location;
  final String locationAddress;
  
  SimpleAppointment({
    required this.id,
    required this.caregiverName,
    required this.dateTime,
    required this.price,
    required this.status,
    required this.description,
    required this.location,
    required this.locationAddress,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caregiverName': caregiverName,
      'dateTime': dateTime.toIso8601String(),
      'price': price,
      'status': status,
      'description': description,
      'location': location,
      'locationAddress': locationAddress,
    };
  }
  
  factory SimpleAppointment.fromJson(Map<String, dynamic> json) {
    return SimpleAppointment(
      id: json['id'],
      caregiverName: json['caregiverName'],
      dateTime: DateTime.parse(json['dateTime']),
      price: json['price'].toDouble(),
      status: json['status'],
      description: json['description'],
      location: json['location'] ?? 'Home',
      locationAddress: json['locationAddress'] ?? '123 Main St, City, State',
    );
  }
}

class SimpleAppointmentService {
  static const String _appointmentsKey = 'appointments';
  
  Future<List<SimpleAppointment>> getAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentsJson = prefs.getStringList(_appointmentsKey) ?? [];
    
    return appointmentsJson
        .map((json) => SimpleAppointment.fromJson(jsonDecode(json)))
        .toList();
  }
  
  Future<void> bookAppointment(SimpleAppointment appointment) async {
    final appointments = await getAppointments();
    appointments.add(appointment);
    
    final prefs = await SharedPreferences.getInstance();
    final appointmentsJson = appointments
        .map((app) => jsonEncode(app.toJson()))
        .toList();
    
    await prefs.setStringList(_appointmentsKey, appointmentsJson);
  }
  
  double calculateCancellationFee(DateTime appointmentDateTime) {
    final now = DateTime.now();
    final hoursUntilAppointment = appointmentDateTime.difference(now).inHours;
    
    if (hoursUntilAppointment >= 48) {
      return 0.0; // No fee if cancelled 48+ hours in advance
    } else if (hoursUntilAppointment >= 24) {
      return 10.0; // $10 fee if cancelled 24-48 hours in advance
    } else if (hoursUntilAppointment >= 4) {
      return 25.0; // $25 fee if cancelled 4-24 hours in advance
    } else {
      return 50.0; // $50 fee if cancelled less than 4 hours in advance
    }
  }
  
  String getCancellationPolicyText(DateTime appointmentDateTime) {
    final now = DateTime.now();
    final hoursUntilAppointment = appointmentDateTime.difference(now).inHours;
    final fee = calculateCancellationFee(appointmentDateTime);
    
    if (fee == 0.0) {
      return 'Free cancellation (${hoursUntilAppointment}h+ notice)';
    } else {
      return 'Cancellation fee: \$${fee.toStringAsFixed(0)} (${hoursUntilAppointment}h notice)';
    }
  }
  
  Future<void> cancelAppointment(String appointmentId) async {
    final appointments = await getAppointments();
    appointments.removeWhere((app) => app.id == appointmentId);

    final prefs = await SharedPreferences.getInstance();
    final appointmentsJson = appointments
        .map((app) => jsonEncode(app.toJson()))
        .toList();

    await prefs.setStringList(_appointmentsKey, appointmentsJson);
  }

  Future<void> updateAppointment(SimpleAppointment updatedAppointment) async {
    final appointments = await getAppointments();
    final index = appointments.indexWhere((app) => app.id == updatedAppointment.id);

    if (index != -1) {
      appointments[index] = updatedAppointment;

      final prefs = await SharedPreferences.getInstance();
      final appointmentsJson = appointments
          .map((app) => jsonEncode(app.toJson()))
          .toList();

      await prefs.setStringList(_appointmentsKey, appointmentsJson);
    }
  }

  bool canEditAppointment(DateTime appointmentDateTime) {
    final now = DateTime.now();
    final hoursUntilAppointment = appointmentDateTime.difference(now).inHours;

    // Allow editing up to 2 hours before appointment
    return hoursUntilAppointment >= 2;
  }

  String getEditRestrictionMessage(DateTime appointmentDateTime) {
    final now = DateTime.now();
    final hoursUntilAppointment = appointmentDateTime.difference(now).inHours;

    if (hoursUntilAppointment < 2) {
      return 'Cannot edit appointments less than 2 hours before scheduled time';
    } else if (hoursUntilAppointment < 24) {
      return 'Changes may incur fees when made less than 24 hours in advance';
    } else {
      return 'Free changes allowed (24+ hours notice)';
    }
  }

  bool canRescheduleToTime(DateTime originalTime, DateTime newTime) {
    final now = DateTime.now();

    // New time must be at least 2 hours from now
    if (newTime.difference(now).inHours < 2) {
      return false;
    }

    // Can't reschedule to more than 30 days out
    if (newTime.difference(now).inDays > 30) {
      return false;
    }

    // Can't reschedule to past dates
    if (newTime.isBefore(now)) {
      return false;
    }

    return true;
  }
  
  String getGoogleMapsUrl(String address) {
    final encodedAddress = Uri.encodeComponent(address);
    return 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
  }
  
  String getAppleMapsUrl(String address) {
    final encodedAddress = Uri.encodeComponent(address);
    return 'http://maps.apple.com/?q=$encodedAddress';
  }
}