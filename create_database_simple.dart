import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final endpoint = 'https://nyc.cloud.appwrite.io/v1';
  final projectId = '689fd36e0032936147b1';

  // Read API key from command line argument or prompt
  String? apiKey;

  if (Platform.environment['APPWRITE_API_KEY'] != null &&
      Platform.environment['APPWRITE_API_KEY'] != 'YOUR_API_KEY_HERE') {
    apiKey = Platform.environment['APPWRITE_API_KEY'];
  }

  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Error: APPWRITE_API_KEY environment variable not set');
    print('Please get your API key from Appwrite Console > Settings > API Keys');
    print('And run: export APPWRITE_API_KEY=your_actual_api_key');
    print('Or manually create the database in Appwrite Console');
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
    print('The app should now work properly with email and messaging functionality.');

  } catch (e) {
    print('❌ Error: $e');
    print('You may need to create the database manually in Appwrite Console.');
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