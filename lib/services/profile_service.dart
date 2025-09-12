import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';
import '../models/user_profile.dart';
import 'appwrite_service.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();
  
  static ProfileService get instance => _instance;
  
  final AppwriteService _appwrite = AppwriteService.instance;

  Future<UserProfile?> getProfile(String userId) async {
    try {
      final document = await _appwrite.databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollectionId,
        documentId: userId,
      );
      
      return UserProfile.fromJson(document.data);
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        return null; // Profile not found
      }
      throw _handleAppwriteException(e);
    } catch (e) {
      throw 'Failed to get profile: ${e.toString()}';
    }
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      final document = await _appwrite.databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollectionId,
        documentId: profile.id,
        data: profile.toJson(),
      );
      
      return UserProfile.fromJson(document.data);
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    } catch (e) {
      throw 'Failed to update profile: ${e.toString()}';
    }
  }

  Future<List<UserProfile>> searchCaregivers({
    String? location,
    List<String>? services,
    double? maxHourlyRate,
    double? minRating,
    int limit = 20,
  }) async {
    try {
      List<String> queries = [
        Query.equal('role', AppConfig.roleCaregiver),
      ];

      if (location != null && location.isNotEmpty) {
        queries.add(Query.search('location', location));
      }

      if (services != null && services.isNotEmpty) {
        for (String service in services) {
          queries.add(Query.equal('services', service));
        }
      }

      if (maxHourlyRate != null) {
        queries.add(Query.lessThanEqual('hourlyRate', maxHourlyRate));
      }

      if (minRating != null) {
        queries.add(Query.greaterThanEqual('rating', minRating));
      }

      queries.add(Query.limit(limit));
      queries.add(Query.orderDesc('rating'));

      final documents = await _appwrite.databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollectionId,
        queries: queries,
      );

      return documents.documents
          .map((doc) => UserProfile.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    } catch (e) {
      throw 'Failed to search caregivers: ${e.toString()}';
    }
  }

  Future<List<UserProfile>> getFeaturedCaregivers({int limit = 10}) async {
    try {
      final documents = await _appwrite.databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollectionId,
        queries: [
          Query.equal('role', AppConfig.roleCaregiver),
          Query.greaterThan('rating', 4.0),
          Query.isNotNull('profileImageUrl'),
          Query.limit(limit),
          Query.orderDesc('rating'),
        ],
      );

      return documents.documents
          .map((doc) => UserProfile.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    } catch (e) {
      throw 'Failed to get featured caregivers: ${e.toString()}';
    }
  }

  Future<String?> uploadProfileImage(String userId, XFile imageFile) async {
    try {
      // Convert XFile to InputFile for Appwrite
      final file = InputFile.fromPath(
        path: imageFile.path,
        filename: 'profile_$userId.jpg',
      );

      // Upload file to Appwrite Storage
      final uploadedFile = await _appwrite.storage.createFile(
        bucketId: AppConfig.profileImagesBucketId,
        fileId: ID.unique(),
        file: file,
      );

      // Return the file URL
      return _appwrite.storage.getFileView(
        bucketId: AppConfig.profileImagesBucketId,
        fileId: uploadedFile.$id,
      ).toString();
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    } catch (e) {
      throw 'Failed to upload image: ${e.toString()}';
    }
  }

  Future<void> deleteProfileImage(String fileId) async {
    try {
      await _appwrite.storage.deleteFile(
        bucketId: AppConfig.profileImagesBucketId,
        fileId: fileId,
      );
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    } catch (e) {
      throw 'Failed to delete image: ${e.toString()}';
    }
  }

  Future<void> updateRating(String caregiverId, double newRating) async {
    try {
      final profile = await getProfile(caregiverId);
      if (profile == null) throw 'Caregiver profile not found';

      final currentRating = profile.rating ?? 0.0;
      final currentReviewCount = profile.reviewCount ?? 0;
      
      // Calculate new average rating
      final totalRating = (currentRating * currentReviewCount) + newRating;
      final newReviewCount = currentReviewCount + 1;
      final averageRating = totalRating / newReviewCount;

      await _appwrite.databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollectionId,
        documentId: caregiverId,
        data: {
          'rating': averageRating,
          'reviewCount': newReviewCount,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    } catch (e) {
      throw 'Failed to update rating: ${e.toString()}';
    }
  }

  String _handleAppwriteException(AppwriteException e) {
    switch (e.code) {
      case 401:
        return 'Unauthorized access';
      case 404:
        return 'Profile not found';
      case 409:
        return 'Profile already exists';
      case 400:
        return 'Invalid profile data';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}