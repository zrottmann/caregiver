import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userKey = 'current_user';

  // Initialize the service
  Future<void> initialize() async {
    await _appwrite.initialize();
    await _checkAuthStatus();
  }

  // Sign up with email and password
  Future<User> signUp({
    required String email, 
    required String password, 
    required String name, 
    required String role,
    String? phoneNumber,
    String? location,
  }) async {
    try {
      _updateAuthState(AuthState.loading());
      
      // Validate input
      _validateSignUpInput(email, password, name, role);
      
      // Create user account
      final user = await _appwrite.account.create(
        userId: ID.unique(),
        email: email.toLowerCase().trim(),
        password: password,
        name: name.trim(),
      );
      
      // Create user profile
      await _createUserProfile(
        user: user, 
        role: role.toLowerCase(),
        phoneNumber: phoneNumber,
        location: location,
      );
      
      // Auto sign in after registration
      await _performSignIn(email, password);
      
      // Store credentials securely for auto-login
      await _storeCredentials(email, password);
      
      return user;
    } on AppwriteException catch (e) {
      final errorMessage = _handleAppwriteException(e);
      _updateAuthState(AuthState.error(errorMessage));
      throw AuthException(errorMessage);
    } catch (e) {
      const errorMessage = 'Registration failed. Please try again.';
      _updateAuthState(AuthState.error(errorMessage));
      throw AuthException(errorMessage);
    }
  }

  // Sign in with email and password
  Future<User> signIn(String email, String password, {bool rememberMe = false}) async {
    try {
      _updateAuthState(AuthState.loading());
      
      // Validate input
      _validateSignInInput(email, password);
      
      final user = await _performSignIn(email, password);
      
      // Store credentials if remember me is enabled
      if (rememberMe) {
        await _storeCredentials(email, password);
      } else {
        await _clearStoredCredentials();
      }
      
      return user;
    } on AppwriteException catch (e) {
      final errorMessage = _handleAppwriteException(e);
      _updateAuthState(AuthState.error(errorMessage));
      throw AuthException(errorMessage);
    } catch (e) {
      const errorMessage = 'Sign in failed. Please check your credentials.';
      _updateAuthState(AuthState.error(errorMessage));
      throw AuthException(errorMessage);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _updateAuthState(AuthState.loading());
      
      await _appwrite.account.deleteSession(sessionId: 'current');
      await _clearStoredCredentials();
      
      _updateAuthState(AuthState.unauthenticated());
    } catch (e) {
      // Even if logout fails on server, clear local state
      await _clearStoredCredentials();
      _updateAuthState(AuthState.unauthenticated());
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      return await _appwrite.account.get();
    } catch (e) {
      return null;
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final document = await _appwrite.databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollectionId,
        documentId: userId,
      );
      
      return UserProfile.fromJson(document.data);
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<UserProfile> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      final document = await _appwrite.databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.profilesCollectionId,
        documentId: userId,
        data: {
          ...updates,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final updatedProfile = UserProfile.fromJson(document.data);
      
      // Update current auth state if this is the current user
      if (_currentAuthState.user?.$id == userId) {
        _updateAuthState(_currentAuthState.copyWith(profile: updatedProfile));
      }
      
      return updatedProfile;
    } on AppwriteException catch (e) {
      throw AuthException(_handleAppwriteException(e));
    } catch (e) {
      throw AuthException('Failed to update profile. Please try again.');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _appwrite.account.createRecovery(
        email: email.toLowerCase().trim(),
        url: '${AppConfig.appwriteEndpoint}/reset-password',
      );
    } on AppwriteException catch (e) {
      throw AuthException(_handleAppwriteException(e));
    } catch (e) {
      throw AuthException('Failed to send password reset email. Please try again.');
    }
  }

  // Update password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      _updateAuthState(_currentAuthState.copyWith(isLoading: true));
      
      await _appwrite.account.updatePassword(
        password: newPassword,
        oldPassword: currentPassword,
      );
      
      _updateAuthState(_currentAuthState.copyWith(isLoading: false));
    } on AppwriteException catch (e) {
      final errorMessage = _handleAppwriteException(e);
      _updateAuthState(_currentAuthState.copyWith(isLoading: false));
      throw AuthException(errorMessage);
    } catch (e) {
      _updateAuthState(_currentAuthState.copyWith(isLoading: false));
      throw AuthException('Failed to update password. Please try again.');
    }
  }

  // Verify email
  Future<void> verifyEmail(String userId, String secret) async {
    try {
      await _appwrite.account.updateVerification(
        userId: userId,
        secret: secret,
      );
      
      // Refresh user data after verification
      await _checkAuthStatus();
    } on AppwriteException catch (e) {
      throw AuthException(_handleAppwriteException(e));
    } catch (e) {
      throw AuthException('Email verification failed. Please try again.');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _appwrite.account.createVerification(
        url: '${AppConfig.appwriteEndpoint}/verify-email',
      );
    } on AppwriteException catch (e) {
      throw AuthException(_handleAppwriteException(e));
    } catch (e) {
      throw AuthException('Failed to send verification email. Please try again.');
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null;
  }

  // Try auto login with stored credentials
  Future<void> tryAutoLogin() async {
    try {
      final email = await _storage.read(key: 'user_email');
      final password = await _storage.read(key: 'user_password');
      
      if (email != null && password != null) {
        await signIn(email, password);
      }
    } catch (e) {
      // Auto login failed, clear stored credentials
      await _clearStoredCredentials();
    }
  }

  // Dispose resources
  void dispose() {
    _authStateController.close();
  }

  // Private methods

  Future<void> _checkAuthStatus() async {
    try {
      _updateAuthState(AuthState.loading());
      
      final user = await getCurrentUser();
      if (user != null) {
        final profile = await getUserProfile(user.$id);
        if (profile != null) {
          _updateAuthState(AuthState.authenticated(user: user, profile: profile));
        } else {
          _updateAuthState(AuthState.unauthenticated());
        }
      } else {
        _updateAuthState(AuthState.unauthenticated());
      }
    } catch (e) {
      _updateAuthState(AuthState.unauthenticated());
    }
  }

  Future<User> _performSignIn(String email, String password) async {
    await _appwrite.account.createEmailSession(
      email: email.toLowerCase().trim(),
      password: password,
    );
    
    final user = await _appwrite.account.get();
    final profile = await getUserProfile(user.$id);
    
    if (profile == null) {
      throw AuthException('User profile not found. Please contact support.');
    }
    
    _updateAuthState(AuthState.authenticated(user: user, profile: profile));
    return user;
  }

  Future<void> _createUserProfile({
    required User user, 
    required String role,
    String? phoneNumber,
    String? location,
  }) async {
    final profile = UserProfile(
      id: user.$id,
      userId: user.$id,
      name: user.name,
      email: user.email,
      role: role,
      phoneNumber: phoneNumber,
      location: location,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _appwrite.databases.createDocument(
      databaseId: AppConfig.databaseId,
      collectionId: AppConfig.profilesCollectionId,
      documentId: user.$id,
      data: profile.toJson(),
    );
  }

  Future<void> _storeCredentials(String email, String password) async {
    await _storage.write(key: 'user_email', value: email);
    await _storage.write(key: 'user_password', value: password);
  }

  Future<void> _clearStoredCredentials() async {
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_password');
  }

  void _updateAuthState(AuthState newState) {
    _currentAuthState = newState;
    _authStateController.add(newState);
  }

  void _validateSignUpInput(String email, String password, String name, String role) {
    if (email.isEmpty || !email.contains('@')) {
      throw AuthException('Please enter a valid email address');
    }
    
    if (password.length < 8) {
      throw AuthException('Password must be at least 8 characters long');
    }
    
    if (name.trim().isEmpty) {
      throw AuthException('Please enter your full name');
    }
    
    if (!AppConfig.validRoles.contains(role.toLowerCase())) {
      throw AuthException('Invalid user role selected');
    }
  }

  void _validateSignInInput(String email, String password) {
    if (email.isEmpty || !email.contains('@')) {
      throw AuthException('Please enter a valid email address');
    }
    
    if (password.isEmpty) {
      throw AuthException('Please enter your password');
    }
  }

  String _handleAppwriteException(AppwriteException e) {
    switch (e.code) {
      case 401:
        return 'Invalid email or password';
      case 409:
        return 'An account with this email already exists';
      case 429:
        return 'Too many requests. Please wait before trying again';
      case 400:
        return 'Please check your input and try again';
      case 404:
        return 'Account not found';
      case 500:
        return 'Server error. Please try again later';
      default:
        return e.message ?? 'An unexpected error occurred';
    }
  }
}

// Custom exception class for authentication errors
class AuthException implements Exception {
  final String message;
  
  const AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}