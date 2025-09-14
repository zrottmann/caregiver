import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../config/app_config.dart';
import '../config/env_config.dart';
import '../models/user_profile.dart';

class AuthService {
  late final Client _client;
  late final Account _account;
  late final Databases _databases;
  static AuthService? _instance;

  AuthService._internal() {
    _client = Client()
        .setEndpoint(EnvConfig.appwriteEndpoint)
        .setProject(EnvConfig.appwriteProjectId);

    _account = Account(_client);
    _databases = Databases(_client);
  }

  factory AuthService() {
    _instance ??= AuthService._internal();
    return _instance!;
  }

  Client get client => _client;

  Future<models.Session> login(String email, String password) async {
    try {
      final session = await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return session;
    } catch (e) {
      print('Login error: $e');
      throw Exception('Failed to login: ${e.toString()}');
    }
  }

  Future<models.User> register({
    required String email,
    required String password,
    required String name,
    String role = 'patient',
  }) async {
    try {
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      await _createUserProfile(user.$id, name, email, role);

      return user;
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Failed to register: ${e.toString()}');
    }
  }

  Future<void> _createUserProfile(String userId, String name, String email, [String role = 'patient']) async {
    try {
      await _databases.createDocument(
        databaseId: EnvConfig.databaseId,
        collectionId: 'profiles',
        documentId: userId,
        data: {
          'userId': userId,
          'name': name,
          'email': email,
          'role': role,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }

  Future<models.User?> getCurrentUser() async {
    try {
      final user = await _account.get();
      return user;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return null;

      final document = await _databases.getDocument(
        databaseId: EnvConfig.databaseId,
        collectionId: 'profiles',
        documentId: user.$id,
      );

      return UserProfile.fromDocument(document);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    try {
      final document = await _databases.updateDocument(
        databaseId: EnvConfig.databaseId,
        collectionId: 'profiles',
        documentId: profile.userId,
        data: profile.toMap()..['updatedAt'] = DateTime.now().toIso8601String(),
      );

      return UserProfile.fromDocument(document);
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout: ${e.toString()}');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      await _account.get();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<models.Session?> getCurrentSession() async {
    try {
      final session = await _account.getSession(sessionId: 'current');
      return session;
    } catch (e) {
      print('Error getting current session: $e');
      return null;
    }
  }

  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _account.updatePassword(
        password: newPassword,
        oldPassword: oldPassword,
      );
    } catch (e) {
      print('Error updating password: $e');
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }

  Future<void> sendPasswordRecovery(String email) async {
    try {
      await _account.createRecovery(
        email: email,
        url: 'https://caregiver.appwrite.network/reset-password',
      );
    } catch (e) {
      print('Error sending password recovery: $e');
      throw Exception('Failed to send recovery email: ${e.toString()}');
    }
  }
}