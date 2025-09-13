import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('Warning: Could not load .env file: $e');
  }

  final endpoint = dotenv.env['APPWRITE_ENDPOINT'] ?? 'https://nyc.cloud.appwrite.io/v1';
  final projectId = dotenv.env['APPWRITE_PROJECT_ID'] ?? '689fd36e0032936147b1';
  final apiKey = dotenv.env['APPWRITE_API_KEY'] ?? '';

  if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
    print('❌ Error: APPWRITE_API_KEY not set in .env file');
    print('Please get your API key from Appwrite Console > Settings > API Keys');
    print('And update the APPWRITE_API_KEY in your .env file');
    return;
  }

  print('🏗️ Creating database and collections...');

  try {
    // Create database
    await createDatabase(endpoint, projectId, apiKey);

    // Create collections
    await createCollection(endpoint, projectId, apiKey, 'appointments', 'Appointments');
    await createCollection(endpoint, projectId, apiKey, 'patients', 'Patients');
    await createCollection(endpoint, projectId, apiKey, 'caregivers', 'Caregivers');
    await createCollection(endpoint, projectId, apiKey, 'messages', 'Messages');

    print('✅ Database and collections created successfully!');

  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> createDatabase(String endpoint, String projectId, String apiKey) async {
  final client = HttpClient();

  try {
    final uri = Uri.parse('$endpoint/databases');
    final request = await client.postUrl(uri);

    request.headers.set('X-Appwrite-Project', projectId);
    request.headers.set('X-Appwrite-Key', apiKey);
    request.headers.set('Content-Type', 'application/json');

    final payload = jsonEncode({
      'databaseId': 'christy-cares-db',
      'name': 'Christy Cares Database'
    });

    request.write(payload);
    final response = await request.close();

    if (response.statusCode == 201) {
      print('✅ Database created successfully');
    } else if (response.statusCode == 409) {
      print('ℹ️ Database already exists');
    } else {
      final body = await response.transform(utf8.decoder).join();
      print('❌ Database creation failed: ${response.statusCode} - $body');
    }
  } finally {
    client.close();
  }
}

Future<void> createCollection(String endpoint, String projectId, String apiKey, String collectionId, String name) async {
  final client = HttpClient();

  try {
    final uri = Uri.parse('$endpoint/databases/christy-cares-db/collections');
    final request = await client.postUrl(uri);

    request.headers.set('X-Appwrite-Project', projectId);
    request.headers.set('X-Appwrite-Key', apiKey);
    request.headers.set('Content-Type', 'application/json');

    final payload = jsonEncode({
      'collectionId': collectionId,
      'name': name,
      'permissions': ['read("any")', 'write("any")'],
      'documentSecurity': false
    });

    request.write(payload);
    final response = await request.close();

    if (response.statusCode == 201) {
      print('✅ Collection "$name" created successfully');
    } else if (response.statusCode == 409) {
      print('ℹ️ Collection "$name" already exists');
    } else {
      final body = await response.transform(utf8.decoder).join();
      print('❌ Collection "$name" creation failed: ${response.statusCode} - $body');
    }
  } finally {
    client.close();
  }
}