import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/models.dart';
import '../models/auth_state.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_presence_service.dart';
import '../services/chat_service.dart';

// Auth state provider that listens to auth service stream
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = AuthService.instance;
  return authService.authStateStream;
});

// Current user provider - extracts user from auth state
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Current user profile provider - extracts profile from auth state
final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.profile,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Is authenticated provider - checks if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.isAuthenticated,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Is loading provider - checks if auth is in loading state
final isAuthLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.isLoading,
    loading: () => true,
    error: (_, __) => false,
  );
});

// Auth error provider - gets current auth error
final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.error,
    loading: () => null,
    error: (error, _) => error.toString(),
  );
});

// User role provider - gets current user role
final userRoleProvider = Provider<String?>((ref) {
  final profile = ref.watch(currentUserProfileProvider);
  return profile?.role;
});

// Is patient provider
final isPatientProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'patient';
});

// Is caregiver provider
final isCaregiverProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'caregiver';
});

// Auth actions notifier - handles auth actions like login, logout, etc.
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService = AuthService.instance;
  final UserPresenceService _presenceService = UserPresenceService.instance;
  final ChatService _chatService = ChatService.instance;

  AuthNotifier() : super(const AsyncValue.data(null));

  // Initialize services
  Future<void> initialize() async {
    state = const AsyncValue.loading();
    try {
      await _authService.initialize();
      await _chatService.initialize();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Sign in
  Future<void> signIn(String email, String password, {bool rememberMe = false}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signIn(email, password, rememberMe: rememberMe);
      
      // Initialize presence service for the user
      final profile = await _authService.getUserProfile(user.$id);
      if (profile != null) {
        await _presenceService.initialize(user.$id, profile.name);
      }
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Sign up
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phoneNumber,
    String? location,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
        location: location,
      );
      
      // Initialize presence service for the new user
      await _presenceService.initialize(user.$id, name);
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      // Set user offline before signing out
      await _presenceService.setOffline();
      
      // Cancel all chat and presence subscriptions
      _chatService.cancelAllSubscriptions();
      _presenceService.cancelAllPresenceSubscriptions();
      
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authService.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Update password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    state = const AsyncValue.loading();
    try {
      await _authService.updatePassword(currentPassword, newPassword);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Update user profile (with userId parameter - for explicit calls)
  Future<void> updateProfileWithUserId(String userId, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      await _authService.updateUserProfile(userId, updates);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  // Update user profile (convenience method - automatically gets current user ID)
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        throw Exception('No authenticated user found');
      }
      await _authService.updateUserProfile(user.$id, updates);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    state = const AsyncValue.loading();
    try {
      await _authService.sendEmailVerification();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Verify email
  Future<void> verifyEmail(String userId, String secret) async {
    state = const AsyncValue.loading();
    try {
      await _authService.verifyEmail(userId, secret);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Try auto login
  Future<void> tryAutoLogin() async {
    state = const AsyncValue.loading();
    try {
      await _authService.tryAutoLogin();
      
      // If auto login successful, initialize presence
      final user = await _authService.getCurrentUser();
      if (user != null) {
        final profile = await _authService.getUserProfile(user.$id);
        if (profile != null) {
          await _presenceService.initialize(user.$id, profile.name);
        }
      }
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      return await _authService.getUserProfile(userId);
    } catch (error) {
      return null;
    }
  }

  // Clear auth error
  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

// Auth notifier provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier();
});

// User profile by ID provider (family)
final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final authNotifier = ref.read(authNotifierProvider.notifier);
  return await authNotifier.getUserProfile(userId);
});

// Helper providers for common UI states

// Show loading indicator when auth is performing an action
final showAuthLoadingProvider = Provider<bool>((ref) {
  final authAction = ref.watch(authNotifierProvider);
  final authState = ref.watch(authStateProvider);
  
  return authAction.isLoading || authState.when(
    data: (state) => state.isLoading,
    loading: () => true,
    error: (_, __) => false,
  );
});

// Combined auth error (from state or actions)
final combinedAuthErrorProvider = Provider<String?>((ref) {
  final authAction = ref.watch(authNotifierProvider);
  final authState = ref.watch(authStateProvider);
  
  if (authAction.hasError) {
    return authAction.error.toString();
  }
  
  return authState.when(
    data: (state) => state.error,
    loading: () => null,
    error: (error, _) => error.toString(),
  );
});

// User display name provider
final userDisplayNameProvider = Provider<String>((ref) {
  final profile = ref.watch(currentUserProfileProvider);
  return profile?.name ?? 'User';
});

// User email provider
final userEmailProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email ?? '';
});

// Can access chat provider (user is authenticated and has profile)
final canAccessChatProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  final profile = ref.watch(currentUserProfileProvider);
  return user != null && profile != null;
});

// Auth guard provider - used to protect routes
final authGuardProvider = Provider<bool>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final isLoading = ref.watch(isAuthLoadingProvider);
  
  // Allow access if authenticated, deny if not authenticated and not loading
  return isAuthenticated || isLoading;
});

// User initialization provider - checks if user services are initialized
class UserInitializationNotifier extends StateNotifier<bool> {
  UserInitializationNotifier() : super(false);
  
  void setInitialized(bool value) {
    state = value;
  }
}

final userInitializationProvider = StateNotifierProvider<UserInitializationNotifier, bool>((ref) {
  return UserInitializationNotifier();
});

// Auto-initialize user services when authenticated
final userServicesInitializationProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  final profile = ref.watch(currentUserProfileProvider);
  final initialized = ref.watch(userInitializationProvider);
  
  if (user != null && profile != null && !initialized) {
    // Initialize user services
    Future.microtask(() async {
      final presenceService = UserPresenceService.instance;
      final chatService = ChatService.instance;
      
      try {
        await presenceService.initialize(user.$id, profile.name);
        await chatService.initialize();
        
        ref.read(userInitializationProvider.notifier).setInitialized(true);
      } catch (e) {
        // Handle initialization error if needed
      }
    });
  } else if (user == null) {
    // Reset initialization state when user logs out
    if (initialized) {
      ref.read(userInitializationProvider.notifier).setInitialized(false);
    }
  }
});