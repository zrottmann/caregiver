import 'package:appwrite/models.dart';
import 'user_profile.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final UserProfile? profile;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.profile,
    this.errorMessage,
    this.isLoading = false,
  });

  // Getters for convenience
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null && profile != null;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => status == AuthStatus.error && errorMessage != null;
  String? get error => errorMessage; // Add getter for backwards compatibility
  bool get isCaregiver => profile?.isCaregiver ?? false;
  bool get isPatient => profile?.isPatient ?? false;
  bool get hasProfile => profile != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    UserProfile? profile,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Factory constructors for common states
  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  
  factory AuthState.loading() => const AuthState(
    status: AuthStatus.loading,
    isLoading: true,
  );
  
  factory AuthState.authenticated({
    required User user,
    required UserProfile profile,
  }) => AuthState(
    status: AuthStatus.authenticated,
    user: user,
    profile: profile,
    isLoading: false,
  );
  
  factory AuthState.unauthenticated() => const AuthState(
    status: AuthStatus.unauthenticated,
    isLoading: false,
  );
  
  factory AuthState.error(String message) => AuthState(
    status: AuthStatus.error,
    errorMessage: message,
    isLoading: false,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AuthState &&
        other.status == status &&
        other.user == user &&
        other.profile == profile &&
        other.errorMessage == errorMessage &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        user.hashCode ^
        profile.hashCode ^
        errorMessage.hashCode ^
        isLoading.hashCode;
  }

  @override
  String toString() {
    return 'AuthState(status: $status, isLoading: $isLoading, hasUser: ${user != null}, hasProfile: ${profile != null}, error: $errorMessage)';
  }
}