import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: '.env');

  final endpoint = dotenv.env['APPWRITE_ENDPOINT'] ?? '';
  final projectId = dotenv.env['APPWRITE_PROJECT_ID'] ?? '';
  final apiKey = dotenv.env['APPWRITE_API_KEY'] ?? '';
  final databaseId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'christy_cares_db';

  print('Setting up Appwrite database...');
  print('Endpoint: $endpoint');
  print('Project ID: $projectId');
  print('Database ID: $databaseId');

  // Initialize Appwrite client
  final client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setKey(apiKey);

  final databases = Databases(client);

  try {
    // Try to get existing database
    try {
      await databases.get(databaseId: databaseId);
      print('✅ Database already exists: $databaseId');
    } catch (e) {
      // Database doesn't exist, create it
      print('Creating database: $databaseId');
      await databases.create(
        databaseId: databaseId,
        name: 'Christy Cares Database',
      );
      print('✅ Database created successfully!');
    }

    // Create required collections
    final collections = [
      'appointments',
      'patients',
      'caregivers',
      'messages',
      'profiles'
    ];

    for (final collectionId in collections) {
      try {
        await databases.getCollection(
          databaseId: databaseId,
          collectionId: collectionId,
        );
        print('✅ Collection already exists: $collectionId');
      } catch (e) {
        // Collection doesn't exist, create it
        print('Creating collection: $collectionId');
        await databases.createCollection(
          databaseId: databaseId,
          collectionId: collectionId,
          name: collectionId.replaceAll('_', ' ').toUpperCase(),
        );
        print('✅ Collection created: $collectionId');
      }
    }

    print('\n🎉 Database setup completed successfully!');

  } catch (e) {
    print('❌ Error setting up database: $e');
    exit(1);
  }
}