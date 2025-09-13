import 'dart:convert';
import 'lib/config/env_config.dart';
import 'lib/services/appwrite_service.dart';

/// Direct test execution of the email function
/// Run: dart run execute_email_test.dart
void main() async {
  print('🚀 Executing Email Function Test...\n');

  try {
    // Initialize Appwrite
    await EnvConfig.init();
    await AppwriteService.instance.initialize();

    final appwrite = AppwriteService.instance;

    print('📧 Sending test email...');

    // Execute the function
    final execution = await appwrite.functions.createExecution(
      functionId: EnvConfig.emailFunctionId,
      body: jsonEncode({
        'to': 'test@christy-cares.com',
        'subject': 'Test Email from Christy Cares Platform',
        'content': '''Hello!

This is a test email from your deployed Appwrite function.

✅ Function ID: ${EnvConfig.emailFunctionId}
✅ Project ID: ${EnvConfig.appwriteProjectId}
✅ Database ID: ${EnvConfig.databaseId}

If you can see this, the email function is working correctly!

Best regards,
The Christy Cares Team''',
      }),
    );

    print('\n✅ Function executed successfully!');
    print('📊 Execution Details:');
    print('   Execution ID: ${execution.$id}');
    print('   Status: ${execution.status}');
    print('   Response Status Code: ${execution.responseStatusCode}');

    if (execution.responseBody.isNotEmpty) {
      print('\n📧 Function Response:');
      try {
        final response = jsonDecode(execution.responseBody);
        final formatted = JsonEncoder.withIndent('  ').convert(response);
        print(formatted);

        if (response['previewUrl'] != null) {
          print('\n🔗 Preview URL: ${response['previewUrl']}');
          print('   Click this URL to see the sent email!');
        }
      } catch (e) {
        print(execution.responseBody);
      }
    }

    if (execution.stderr.isNotEmpty) {
      print('\n⚠️  Function Logs (stderr):');
      print(execution.stderr);
    }

    if (execution.stdout.isNotEmpty) {
      print('\n📝 Function Logs (stdout):');
      print(execution.stdout);
    }

  } catch (e) {
    print('❌ Error executing function: $e');
  }
}