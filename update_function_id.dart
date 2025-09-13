import 'dart:io';

/// Helper to update .env with Function ID
/// Run: dart run update_function_id.dart
void main() async {
  print('📧 Function ID Updater');
  print('═════════════════════════════════════════\n');

  print('🔗 Go to: https://cloud.appwrite.io/console/project-christy-cares-app/functions');
  print('📋 Find your email function and copy its ID\n');

  stdout.write('Enter the Email Function ID: ');
  final functionId = stdin.readLineSync() ?? '';

  if (functionId.isEmpty) {
    print('❌ Function ID cannot be empty');
    exit(1);
  }

  print('\n✅ Function ID: $functionId');

  // Update .env file
  final envFile = File('.env');
  var content = await envFile.readAsString();

  content = content.replaceAll(
    'APPWRITE_EMAIL_FUNCTION_ID=YOUR_EMAIL_FUNCTION_ID_HERE',
    'APPWRITE_EMAIL_FUNCTION_ID=$functionId'
  );

  await envFile.writeAsString(content);

  print('✅ Updated .env file!');
  print('\n🧪 Now you can test the function:');
  print('   dart run test_email_function.dart');
}