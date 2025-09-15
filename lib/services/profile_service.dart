import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../config/app_config.dart';
import '../models/user_profile.dart';

class ProfileService {
  final Databases _databases = Databases(AppConfig.client);

  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: 'profiles',
        documentId: userId,
      );
      return UserProfile.fromDocument(document);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<UserProfile> createUserProfile(UserProfile profile) async {
    try {
      final document = await _databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: 'profiles',
        documentId: profile.uid,
        data: profile.toMap(),
      );
      return UserProfile.fromDocument(document);
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  Future<UserProfile> updateUserProfile(String userId, UserProfile profile) async {
    try {
      final updatedData = profile.toMap();
      updatedData['updatedAt'] = DateTime.now().toIso8601String();

      final document = await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: 'profiles',
        documentId: userId,
        data: updatedData,
      );
      return UserProfile.fromDocument(document);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<void> deleteUserProfile(String userId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppConfig.databaseId,
        collectionId: 'profiles',
        documentId: userId,
      );
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  Future<List<UserProfile>> getCaregivers({
    List<String>? specializations,
    double? minRating,
    double? maxHourlyRate,
    bool? isAvailable,
  }) async {
    try {
      List<String> queries = ['equal("role", "caregiver")'];

      if (specializations != null && specializations.isNotEmpty) {
        queries.add('equal("specializations", "${specializations.join('","')}")');
      }

      if (minRating != null) {
        queries.add('greaterThanEqual("rating", $minRating)');
      }

      if (maxHourlyRate != null) {
        queries.add('lessThanEqual("hourlyRate", $maxHourlyRate)');
      }

      if (isAvailable != null && isAvailable) {
        queries.add('equal("isAvailable", true)');
      }

      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: 'profiles',
        queries: queries,
      );

      return response.documents
          .map((doc) => UserProfile.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get caregivers: $e');
    }
  }
}