import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../services/auth_service.dart';
import '../models/user_profile.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, models.User?>(
  (ref) => CurrentUserNotifier(ref.read(authServiceProvider)),
);

final currentUserProfileProvider = StateNotifierProvider<CurrentUserProfileNotifier, UserProfile?>(
  (ref) => CurrentUserProfileNotifier(ref.read(authServiceProvider)),
);

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

class CurrentUserNotifier extends StateNotifier<models.User?> {
  final AuthService _authService;

  CurrentUserNotifier(this._authService) : super(null) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _authService.getCurrentUser();
      state = user;
    } catch (e) {
      state = null;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final session = await _authService.login(email, password);
      final user = await _authService.getCurrentUser();
      state = user;
    } catch (e) {
      state = null;
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    String role = 'patient',
  }) async {
    try {
      final user = await _authService.register(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      state = user;
    } catch (e) {
      state = null;
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } finally {
      state = null;
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      state = user;
    } catch (e) {
      state = null;
    }
  }
}

class CurrentUserProfileNotifier extends StateNotifier<UserProfile?> {
  final AuthService _authService;

  CurrentUserProfileNotifier(this._authService) : super(null) {
    _init();
  }

  Future<void> _init() async {
    try {
      final profile = await _authService.getCurrentUserProfile();
      state = profile;
    } catch (e) {
      state = null;
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      final updatedProfile = await _authService.updateUserProfile(profile);
      state = updatedProfile;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final profile = await _authService.getCurrentUserProfile();
      state = profile;
    } catch (e) {
      state = null;
    }
  }

  void setProfile(UserProfile? profile) {
    state = profile;
  }
}