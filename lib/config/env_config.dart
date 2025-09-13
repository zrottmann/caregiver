import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static late String appwriteEndpoint;
  static late String appwriteProjectId;
  static late String appwriteApiKey;

  // Database IDs
  static late String databaseId;
  static late String appointmentsCollectionId;
  static late String patientsCollectionId;
  static late String caregiversCollectionId;
  static late String messagesCollectionId;

  // Function IDs
  static late String emailFunctionId;
  static late String smsFunctionId;
  static late String pushFunctionId;

  // Storage
  static late String bucketId;

  // Email Configuration
  static late String emailFromAddress;
  static late String emailFromName;

  // Optional Twilio Configuration
  static String? twilioAccountSid;
  static String? twilioAuthToken;
  static String? twilioPhoneNumber;

  // Optional Push Configuration
  static String? fcmServerKey;
  static String? apnsKeyId;
  static String? apnsTeamId;

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // .env file might not exist in web deployment, use environment variables or defaults
      print('Warning: .env file not found, using defaults: $e');
    }

    // Safe access to environment variables
    String? getEnvVar(String key) {
      try {
        return dotenv.env[key];
      } catch (e) {
        return null;
      }
    }

    // Required Appwrite Configuration
    // Using NYC regional endpoint as project is hosted there
    appwriteEndpoint = getEnvVar('APPWRITE_ENDPOINT') ?? 'https://nyc.cloud.appwrite.io/v1';
    appwriteProjectId = getEnvVar('APPWRITE_PROJECT_ID') ?? '689fd36e0032936147b1';
    appwriteApiKey = getEnvVar('APPWRITE_API_KEY') ?? '';

    // Database Configuration
    databaseId = getEnvVar('APPWRITE_DATABASE_ID') ?? 'christy-cares-db';
    appointmentsCollectionId = getEnvVar('APPWRITE_APPOINTMENTS_COLLECTION_ID') ?? 'appointments';
    patientsCollectionId = getEnvVar('APPWRITE_PATIENTS_COLLECTION_ID') ?? 'patients';
    caregiversCollectionId = getEnvVar('APPWRITE_CAREGIVERS_COLLECTION_ID') ?? 'caregivers';
    messagesCollectionId = getEnvVar('APPWRITE_MESSAGES_COLLECTION_ID') ?? 'messages';

    // Function Configuration
    emailFunctionId = getEnvVar('APPWRITE_EMAIL_FUNCTION_ID') ?? '68c5c9dc0036c5a66172';
    smsFunctionId = getEnvVar('APPWRITE_SMS_FUNCTION_ID') ?? '';
    pushFunctionId = getEnvVar('APPWRITE_PUSH_FUNCTION_ID') ?? '';

    // Storage Configuration
    bucketId = getEnvVar('APPWRITE_BUCKET_ID') ?? '';

    // Email Configuration
    emailFromAddress = getEnvVar('EMAIL_FROM_ADDRESS') ?? 'noreply@christy-cares.com';
    emailFromName = getEnvVar('EMAIL_FROM_NAME') ?? 'Christy Cares';

    // Optional Configurations
    twilioAccountSid = getEnvVar('TWILIO_ACCOUNT_SID');
    twilioAuthToken = getEnvVar('TWILIO_AUTH_TOKEN');
    twilioPhoneNumber = getEnvVar('TWILIO_PHONE_NUMBER');

    fcmServerKey = getEnvVar('FCM_SERVER_KEY');
    apnsKeyId = getEnvVar('APNS_KEY_ID');
    apnsTeamId = getEnvVar('APNS_TEAM_ID');
  }

  static bool get isConfigured {
    return appwriteProjectId.isNotEmpty &&
           databaseId.isNotEmpty;
  }

  static bool get isServerConfigured {
    return isConfigured && appwriteApiKey.isNotEmpty;
  }

  static bool get hasEmailFunction => emailFunctionId.isNotEmpty;
  static bool get hasSmsFunction => smsFunctionId.isNotEmpty && twilioAccountSid != null;
  static bool get hasPushFunction => pushFunctionId.isNotEmpty && (fcmServerKey != null || apnsKeyId != null);
}