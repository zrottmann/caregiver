class AppConfig {
  // Appwrite Configuration
  // TODO: Replace with your actual Appwrite endpoint and project ID
  static const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
  static const String appwriteProjectId = 'your-project-id';
  
  // Database IDs
  static const String databaseId = 'caregiver-platform';
  
  // Collection IDs
  static const String profilesCollectionId = 'profiles';
  static const String bookingsCollectionId = 'bookings';
  static const String messagesCollectionId = 'messages';
  static const String chatsCollectionId = 'chats';
  static const String servicesCollectionId = 'services';
  static const String reviewsCollectionId = 'reviews';
  
  // Storage Bucket IDs
  static const String profileImagesBucketId = 'profile-images';
  static const String documentsBucketId = 'documents';
  
  // Stripe Configuration
  // TODO: Replace with your actual Stripe keys
  static const String stripePublishableKey = 'pk_test_your_stripe_publishable_key';
  static const String stripeSecretKey = 'sk_test_your_stripe_secret_key';
  
  // App Constants
  static const double bookingFee = 50.0;
  static const String currency = 'USD';
  static const int passwordMinLength = 8;
  static const int maxImageSizeMB = 5;
  
  // User Roles
  static const String rolePatient = 'patient';
  static const String roleCaregiver = 'caregiver';
  static const String roleAdmin = 'admin';
  
  // Valid roles list for validation
  static const List<String> validRoles = [
    rolePatient,
    roleCaregiver,
    roleAdmin,
  ];
  
  // Role display names
  static const Map<String, String> roleDisplayNames = {
    rolePatient: 'Patient/Family Member',
    roleCaregiver: 'Caregiver',
    roleAdmin: 'Administrator',
  };
  
  // Service categories for caregivers
  static const List<String> serviceCategories = [
    'Personal Care',
    'Medical Care',
    'Companionship',
    'Household Help',
    'Transportation',
    'Specialized Care',
    'Emergency Care',
    'Respite Care',
  ];
  
  // Default app settings
  static const int sessionTimeoutMinutes = 30;
  static const int maxFileUploadSizeMB = 10;
  static const String defaultProfileImage = 'assets/images/default_avatar.png';
  
  // API Configuration
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  
  // Validation patterns
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^[\+]?[1-9][\d]{0,15}$';
  
  // URL schemes for deep linking
  static const String appScheme = 'caregiverplatform';
  
  // Social login configuration (if implemented)
  static const String googleClientId = 'your-google-client-id';
  static const String facebookAppId = 'your-facebook-app-id';
  
  // Push notification configuration
  static const String fcmServerKey = 'your-fcm-server-key';
  
  // Helper methods
  static bool isValidRole(String role) {
    return validRoles.contains(role.toLowerCase());
  }
  
  static String getRoleDisplayName(String role) {
    return roleDisplayNames[role] ?? role;
  }
  
  static bool isValidEmail(String email) {
    return RegExp(emailPattern).hasMatch(email);
  }
  
  static bool isValidPhone(String phone) {
    return RegExp(phonePattern).hasMatch(phone);
  }
  
  static bool isValidPassword(String password) {
    return password.length >= passwordMinLength;
  }
}