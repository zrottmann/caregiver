import 'dart:convert';
import 'dart:io';

/// Test script for the deployed email function
/// Run: dart run test_email_function.dart
void main() async {
  print('🧪 Testing Email Function...\n');

  // Load environment variables
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('❌ Error: .env file not found');
    print('Please ensure .env file exists');
    exit(1);
  }

  final envContent = await envFile.readAsString();
  final env = <String, String>{};

  for (final line in envContent.split('\n')) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length == 2) {
      env[parts[0].trim()] = parts[1].trim();
    }
  }

  final projectId = env['APPWRITE_PROJECT_ID'] ?? '';
  final emailFunctionId = env['APPWRITE_EMAIL_FUNCTION_ID'] ?? '';

  print('📋 Configuration:');
  print('  Project ID: $projectId');
  print('  Email Function ID: $emailFunctionId');

  if (emailFunctionId.isEmpty || emailFunctionId == 'YOUR_EMAIL_FUNCTION_ID_HERE') {
    print('\n❌ Email Function ID not set in .env file');
    print('Please get the Function ID from Appwrite Console and add it to .env:');
    print('APPWRITE_EMAIL_FUNCTION_ID=your-function-id-here\n');

    print('📝 To find your Function ID:');
    print('1. Go to: https://cloud.appwrite.io/console/project-$projectId/functions');
    print('2. Click on your email function');
    print('3. Copy the Function ID from the URL or function details');
    print('4. Add it to your .env file');
    exit(1);
  }

  print('\n✅ Configuration looks good!');
  print('\n📧 Test email payload:');
  final testPayload = {
    'to': 'test@example.com',
    'subject': 'Test Email from Christy Cares',
    'content': 'Hello! This is a test email from your deployed Appwrite function. If you can see this, the email function is working correctly!',
  };

  print(JsonEncoder.withIndent('  ').convert(testPayload));

  print('\n🔗 Function execution URL:');
  print('https://cloud.appwrite.io/console/project-$projectId/functions/$emailFunctionId');

  print('\n🧪 To manually test the function:');
  print('1. Go to the function URL above');
  print('2. Click "Execute" tab');
  print('3. Paste the test payload above');
  print('4. Click "Execute Function"');
  print('5. Check the logs for the Ethereal Email preview URL');

  print('\n📊 Expected success response:');
  print('''{
  "success": true,
  "messageId": "some-unique-id",
  "previewUrl": "https://ethereal.email/message/xxx"
}''');

  print('\n💡 Remember: The function uses Ethereal Email for testing,');
  print('   so check the function logs for the preview URL to see the sent email!');
}