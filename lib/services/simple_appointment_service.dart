import 'dart:convert';
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
}