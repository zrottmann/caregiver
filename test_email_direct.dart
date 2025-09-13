import 'dart:convert';
import 'lib/services/appwrite_service.dart';
import 'lib/config/env_config.dart';

Future<void> main() async {
  print('🔧 Testing email function directly...');

  try {
    // Initialize environment config
    await EnvConfig.init();
    print('✅ Environment config initialized');
    print('   Project ID: ${EnvConfig.appwriteProjectId}');
    print('   Email Function ID: ${EnvConfig.emailFunctionId}');

    // Initialize Appwrite service
    await AppwriteService.instance.initialize();
    print('✅ Appwrite service initialized');

    // Test email function execution
    final testPayload = {
      'to': 'test@example.com', // Replace with your actual email
      'subject': 'Test Email from Christy Cares',
      'content': '''Hello!

This is a test email from the Christy Cares platform to verify the email function is working correctly.

Best regards,
Christy Cares Team'''
    };

    print('📧 Sending test email...');
    final response = await AppwriteService.instance.functions.createExecution(
      functionId: EnvConfig.emailFunctionId,
      body: jsonEncode(testPayload),
    );

    print('✅ Email function executed successfully!');
    print('   Status: ${response.status}');
    print('   Response: ${response.responseBody}');

  } catch (e) {
    print('❌ Email test failed: $e');
  }
}