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

    // Required Appwrite Configuration
    appwriteEndpoint = dotenv.env['APPWRITE_ENDPOINT'] ?? 'https://cloud.appwrite.io/v1';
    appwriteProjectId = dotenv.env['APPWRITE_PROJECT_ID'] ?? '689fd36e0032936147b1';
    appwriteApiKey = dotenv.env['APPWRITE_API_KEY'] ?? '';

    // Database Configuration
    databaseId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'christy-cares-db';
    appointmentsCollectionId = dotenv.env['APPWRITE_APPOINTMENTS_COLLECTION_ID'] ?? 'appointments';
    patientsCollectionId = dotenv.env['APPWRITE_PATIENTS_COLLECTION_ID'] ?? 'patients';
    caregiversCollectionId = dotenv.env['APPWRITE_CAREGIVERS_COLLECTION_ID'] ?? 'caregivers';
    messagesCollectionId = dotenv.env['APPWRITE_MESSAGES_COLLECTION_ID'] ?? 'messages';

    // Function Configuration
    emailFunctionId = dotenv.env['APPWRITE_EMAIL_FUNCTION_ID'] ?? '68c5c9dc0036c5a66172';
    smsFunctionId = dotenv.env['APPWRITE_SMS_FUNCTION_ID'] ?? '';
    pushFunctionId = dotenv.env['APPWRITE_PUSH_FUNCTION_ID'] ?? '';

    // Storage Configuration
    bucketId = dotenv.env['APPWRITE_BUCKET_ID'] ?? '';

    // Email Configuration
    emailFromAddress = dotenv.env['EMAIL_FROM_ADDRESS'] ?? 'noreply@christy-cares.com';
    emailFromName = dotenv.env['EMAIL_FROM_NAME'] ?? 'Christy Cares';

    // Optional Configurations
    twilioAccountSid = dotenv.env['TWILIO_ACCOUNT_SID'];
    twilioAuthToken = dotenv.env['TWILIO_AUTH_TOKEN'];
    twilioPhoneNumber = dotenv.env['TWILIO_PHONE_NUMBER'];

    fcmServerKey = dotenv.env['FCM_SERVER_KEY'];
    apnsKeyId = dotenv.env['APNS_KEY_ID'];
    apnsTeamId = dotenv.env['APNS_TEAM_ID'];
  }

  static bool get isConfigured {
    return appwriteProjectId.isNotEmpty &&
           appwriteApiKey.isNotEmpty &&
           databaseId.isNotEmpty;
  }

  static bool get hasEmailFunction => emailFunctionId.isNotEmpty;
  static bool get hasSmsFunction => smsFunctionId.isNotEmpty && twilioAccountSid != null;
  static bool get hasPushFunction => pushFunctionId.isNotEmpty && (fcmServerKey != null || apnsKeyId != null);
}