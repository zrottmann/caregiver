import 'dart:convert';
import 'dart:io';

// Simple endpoint test without Flutter dependencies
Future<void> main() async {
  final projectId = '689fd36e0032936147b1';
  final functionId = '68c5c9dc0036c5a66172';

  final endpoints = [
    'https://nyc.cloud.appwrite.io/v1',  // NYC region (user provided)
    'https://cloud.appwrite.io/v1',     // US East (default)
    'https://eu.appwrite.io/v1',        // EU West
    'https://ap.appwrite.io/v1',        // Asia Pacific
  ];

  print('🔍 Testing Appwrite endpoints for project: $projectId');
  print('');

  for (final endpoint in endpoints) {
    print('Testing endpoint: $endpoint');
    try {
      final client = HttpClient();
      final uri = Uri.parse('$endpoint/functions/$functionId/executions');
      final request = await client.postUrl(uri);

      // Add required headers
      request.headers.set('X-Appwrite-Project', projectId);
      request.headers.set('Content-Type', 'application/json');

      // Simple test payload
      final payload = jsonEncode({
        'to': 'test@example.com',
        'subject': 'Test',
        'content': 'Test message'
      });

      request.write(payload);
      final response = await request.close();

      if (response.statusCode == 401) {
        final body = await response.transform(utf8.decoder).join();
        if (body.contains('not accessible in this region')) {
          print('❌ Region error - project not accessible from this endpoint');
        } else {
          print('✅ Authentication error (but endpoint is reachable!)');
          print('   This means the endpoint is correct, just need proper auth');
        }
      } else if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ SUCCESS - This is the correct endpoint!');
        break;
      } else {
        print('⚠️  Status: ${response.statusCode}');
        final body = await response.transform(utf8.decoder).join();
        print('   Response: ${body.substring(0, 100)}...');
      }

    } catch (e) {
      print('❌ Connection failed: $e');
    }
    print('');
  }
}