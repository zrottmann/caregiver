import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'appwrite_service.dart';
import '../config/env_config.dart';

class SimpleAppointment {
  final String id;
  final String caregiverName;
  final DateTime dateTime;
  final double price;
  final String status;
  final String description;
  final String location;
  final String locationAddress;
  final String? patientEmail;
  final String? patientName;
  
  SimpleAppointment({
    required this.id,
    required this.caregiverName,
    required this.dateTime,
    required this.price,
    required this.status,
    required this.description,
    required this.location,
    required this.locationAddress,
    this.patientEmail,
    this.patientName,
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
      'patientEmail': patientEmail,
      'patientName': patientName,
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
      patientEmail: json['patientEmail'],
      patientName: json['patientName'],
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
  
  Future<Map<String, dynamic>> bookAppointment(SimpleAppointment appointment) async {
    final appointments = await getAppointments();
    appointments.add(appointment);

    final prefs = await SharedPreferences.getInstance();
    final appointmentsJson = appointments
        .map((app) => jsonEncode(app.toJson()))
        .toList();

    await prefs.setStringList(_appointmentsKey, appointmentsJson);

    // Track email status
    String emailStatus = 'not_sent';
    String emailMessage = '';

    // Send confirmation email if patient email is provided
    if (appointment.patientEmail != null && appointment.patientEmail!.isNotEmpty) {
      try {
        await _sendAppointmentConfirmationEmail(appointment);
        emailStatus = 'sent';
        emailMessage = 'Confirmation email sent to ${appointment.patientEmail}';
      } catch (e) {
        print('Failed to send confirmation email: $e');
        emailStatus = 'failed';
        emailMessage = 'Failed to send confirmation email: ${e.toString()}';
        // Don't throw error - appointment booking should still succeed
      }
    } else {
      emailMessage = 'No email address provided';
    }

    return {
      'success': true,
      'emailStatus': emailStatus,
      'emailMessage': emailMessage,
      'appointmentId': appointment.id,
    };
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

  /// Send appointment confirmation email using Appwrite function
  Future<void> _sendAppointmentConfirmationEmail(SimpleAppointment appointment) async {
    try {
      // Double-check email is not null before proceeding
      if (appointment.patientEmail == null || appointment.patientEmail!.isEmpty) {
        print('⚠️ Cannot send email: patient email is null or empty');
        return;
      }

      // Ensure Appwrite service is initialized
      await AppwriteService.instance.initialize();

      final patientName = appointment.patientName ?? 'Valued Patient';
      final appointmentDate = _formatAppointmentDate(appointment.dateTime);
      final appointmentTime = _formatAppointmentTime(appointment.dateTime);

      final subject = 'Appointment Confirmation - ${appointment.caregiverName}';
      final content = _buildConfirmationEmailContent(
        patientName: patientName,
        caregiverName: appointment.caregiverName,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        location: appointment.location,
        locationAddress: appointment.locationAddress,
        description: appointment.description,
        price: appointment.price,
        appointmentId: appointment.id,
      );

      final payload = {
        'to': appointment.patientEmail!,
        'subject': subject,
        'content': content,
      };

      print('Sending confirmation email to: ${appointment.patientEmail}');

      final response = await AppwriteService.instance.functions.createExecution(
        functionId: EnvConfig.emailFunctionId,
        body: jsonEncode(payload),
      );

      print('Email function response: ${response.responseBody}');

      if (response.status == 'completed') {
        print('✅ Appointment confirmation email sent successfully');
      } else {
        print('⚠️ Email function execution status: ${response.status}');
      }

    } catch (e) {
      print('❌ Failed to send appointment confirmation email: $e');
      rethrow;
    }
  }

  String _formatAppointmentDate(DateTime dateTime) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatAppointmentTime(DateTime dateTime) {
    final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _buildConfirmationEmailContent({
    required String patientName,
    required String caregiverName,
    required String appointmentDate,
    required String appointmentTime,
    required String location,
    required String locationAddress,
    required String description,
    required double price,
    required String appointmentId,
  }) {
    return '''Dear $patientName,

Your appointment has been successfully scheduled with Christy Cares!

📅 APPOINTMENT DETAILS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Caregiver: $caregiverName
Date: $appointmentDate
Time: $appointmentTime
Location: $location
Address: $locationAddress

Service Description: $description
Total Cost: \$${price.toStringAsFixed(2)}

Appointment ID: $appointmentId

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 IMPORTANT REMINDERS:

• Please arrive 10-15 minutes early
• Bring a valid photo ID
• Have your insurance information ready
• Inform us of any changes to your health condition

🔄 NEED TO RESCHEDULE OR CANCEL?
Please contact us at least 24 hours in advance to avoid cancellation fees.

CANCELLATION POLICY:
• 48+ hours notice: Free cancellation
• 24-48 hours notice: \$10 fee
• 4-24 hours notice: \$25 fee
• Less than 4 hours: \$50 fee

📞 CONTACT INFORMATION:
Phone: (410) 555-CARE (2273)
Email: support@christy-cares.com
Website: www.christy-cares.com

We're committed to providing you with exceptional personalized care. If you have any questions or concerns before your appointment, please don't hesitate to reach out.

Thank you for choosing Christy Cares for your healthcare needs!

Warm regards,
The Christy Cares Team

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
This is an automated confirmation email. Please do not reply directly to this message.''';
  }
}