import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final endpoint = 'https://nyc.cloud.appwrite.io/v1';
  final projectId = '689fd36e0032936147b1';

  // Read API key from .env file
  String? apiKey;
  try {
    final envFile = File('.env');
    if (await envFile.exists()) {
      final contents = await envFile.readAsString();
      final lines = contents.split('\n');

      for (final line in lines) {
        if (line.startsWith('APPWRITE_API_KEY=')) {
          apiKey = line.split('=')[1].trim();
          break;
        }
      }
    }
  } catch (e) {
    print('Warning: Could not read .env file: $e');
  }

  if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
    print('❌ Error: APPWRITE_API_KEY not found in .env file');
    return;
  }

  print('🏗️ Creating collection attributes...');

  try {
    // Messages collection attributes
    await createStringAttribute(endpoint, projectId, apiKey, 'messages', 'senderId', 50, true);
    await createStringAttribute(endpoint, projectId, apiKey, 'messages', 'receiverId', 50, true);
    await createStringAttribute(endpoint, projectId, apiKey, 'messages', 'content', 1000, true);
    await createDateTimeAttribute(endpoint, projectId, apiKey, 'messages', 'createdAt', true);
    await createBooleanAttribute(endpoint, projectId, apiKey, 'messages', 'isRead', false, false);

    // Appointments collection attributes
    await createStringAttribute(endpoint, projectId, apiKey, 'appointments', 'patientId', 50, true);
    await createStringAttribute(endpoint, projectId, apiKey, 'appointments', 'caregiverId', 50, true);
    await createStringAttribute(endpoint, projectId, apiKey, 'appointments', 'patientName', 100, true);
    await createStringAttribute(endpoint, projectId, apiKey, 'appointments', 'caregiverName', 100, true);
    await createStringAttribute(endpoint, projectId, apiKey, 'appointments', 'patientEmail', 100, false);
    await createStringAttribute(endpoint, projectId, apiKey, 'appointments', 'serviceType', 100, true);
    await createDateTimeAttribute(endpoint, projectId, apiKey, 'appointments', 'scheduledDate', true);
    await createIntegerAttribute(endpoint, projectId, apiKey, 'appointments', 'duration', true);
    await createStringAttribute(endpoint, projectId, apiKey, 'appointments', 'status', 20, true);
    await createFloatAttribute(endpoint, projectId, apiKey, 'appointments', 'totalCost', false);
    await createDateTimeAttribute(endpoint, projectId, apiKey, 'appointments', 'createdAt', true);

    // Patients collection attributes
    await createStringAttribute(endpoint, projectId, apiKey, 'patients', 'name', 100, true);
    await createStringAttribute(endpoint, projectId, apiKey, 'patients', 'email', 100, false);
    await createStringAttribute(endpoint, projectId, apiKey, 'patients', 'phone', 20, false);
    await createStringAttribute(endpoint, projectId, apiKey, 'patients', 'address', 200, false);
    await createDateTimeAttribute(endpoint, projectId, apiKey, 'patients', 'dateOfBirth', false);
    await createStringAttribute(endpoint, projectId, apiKey, 'patients', 'medicalConditions', 500, false);
    await createStringAttribute(endpoint, projectId, apiKey, 'patients', 'emergencyContact', 100, false);

    // Caregivers collection attributes
    await createStringAttribute(endpoint, projectId, apiKey, 'caregivers', 'name', 100, true);
    await createStringAttribute(endpoint, projectId, apiKey, 'caregivers', 'email', 100, true);
    await createStringAttribute(endpoint, projectId, apiKey, 'caregivers', 'phone', 20, false);
    await createStringAttribute(endpoint, projectId, apiKey, 'caregivers', 'specializations', 200, false);
    await createFloatAttribute(endpoint, projectId, apiKey, 'caregivers', 'hourlyRate', false);
    await createBooleanAttribute(endpoint, projectId, apiKey, 'caregivers', 'isAvailable', true, true);

    print('✅ All collection attributes created successfully!');

  } catch (e) {
    print('❌ Error creating attributes: $e');
  }
}

Future<void> createStringAttribute(String endpoint, String projectId, String apiKey,
    String collectionId, String key, int size, bool required, [String? defaultValue]) async {
  await createAttribute(endpoint, projectId, apiKey, collectionId, {
    'key': key,
    'type': 'string',
    'size': size,
    'required': required,
    if (defaultValue != null) 'default': defaultValue,
  });
}

Future<void> createIntegerAttribute(String endpoint, String projectId, String apiKey,
    String collectionId, String key, bool required, [int? defaultValue]) async {
  await createAttribute(endpoint, projectId, apiKey, collectionId, {
    'key': key,
    'type': 'integer',
    'required': required,
    if (defaultValue != null) 'default': defaultValue,
  });
}

Future<void> createFloatAttribute(String endpoint, String projectId, String apiKey,
    String collectionId, String key, bool required, [double? defaultValue]) async {
  await createAttribute(endpoint, projectId, apiKey, collectionId, {
    'key': key,
    'type': 'double',
    'required': required,
    if (defaultValue != null) 'default': defaultValue,
  });
}

Future<void> createBooleanAttribute(String endpoint, String projectId, String apiKey,
    String collectionId, String key, bool defaultValue, bool required) async {
  await createAttribute(endpoint, projectId, apiKey, collectionId, {
    'key': key,
    'type': 'boolean',
    'required': required,
    'default': defaultValue,
  });
}

Future<void> createDateTimeAttribute(String endpoint, String projectId, String apiKey,
    String collectionId, String key, bool required, [String? defaultValue]) async {
  await createAttribute(endpoint, projectId, apiKey, collectionId, {
    'key': key,
    'type': 'datetime',
    'required': required,
    if (defaultValue != null) 'default': defaultValue,
  });
}

Future<void> createAttribute(String endpoint, String projectId, String apiKey,
    String collectionId, Map<String, dynamic> attributeData) async {
  final client = HttpClient();

  try {
    final uri = Uri.parse('$endpoint/databases/christy-cares-db/collections/$collectionId/attributes/${attributeData['type']}');
    final request = await client.postUrl(uri);

    request.headers.set('X-Appwrite-Project', projectId);
    request.headers.set('X-Appwrite-Key', apiKey);
    request.headers.set('Content-Type', 'application/json');

    final payload = jsonEncode(attributeData);
    request.write(payload);
    final response = await request.close();

    if (response.statusCode == 201) {
      print('✅ Created ${attributeData['key']} attribute in $collectionId collection');
    } else if (response.statusCode == 409) {
      print('ℹ️ Attribute ${attributeData['key']} already exists in $collectionId');
    } else {
      final body = await response.transform(utf8.decoder).join();
      print('❌ Failed to create ${attributeData['key']} in $collectionId: ${response.statusCode} - $body');
    }
  } finally {
    client.close();
  }
}