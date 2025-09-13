import 'package:appwrite/appwrite.dart';
import '../config/app_config.dart';

/// Script to set up Appwrite collections for messaging
/// Run this once to create all necessary collections
class SetupAppwriteCollections {
  static final Client client = Client()
      .setEndpoint(AppConfig.endpoint)
      .setProject(AppConfig.projectId)
      .setKey('YOUR_API_KEY'); // Add your Appwrite API key with database.write scope

  static final Databases databases = Databases(client);

  static Future<void> setupCollections() async {
    try {
      // Create messages collection
      await _createMessagesCollection();

      // Create conversations collection
      await _createConversationsCollection();

      // Create notifications collection
      await _createNotificationsCollection();

      print('✅ All collections created successfully!');
    } catch (e) {
      print('Error setting up collections: $e');
    }
  }

  static Future<void> _createMessagesCollection() async {
    try {
      // Create collection
      await databases.createCollection(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        name: 'Messages',
        permissions: [
          Permission.read(Role.users()),
          Permission.create(Role.users()),
          Permission.update(Role.users()),
        ],
      );

      // Create attributes
      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'senderId',
        size: 255,
        required: true,
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'senderName',
        size: 255,
        required: true,
      );

      await databases.createEmailAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'senderEmail',
        required: true,
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'senderPhone',
        size: 20,
        required: false,
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'recipientId',
        size: 255,
        required: true,
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'recipientName',
        size: 255,
        required: true,
      );

      await databases.createEmailAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'recipientEmail',
        required: true,
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'recipientPhone',
        size: 20,
        required: false,
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'content',
        size: 5000,
        required: true,
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'subject',
        size: 255,
        required: false,
      );

      await databases.createDatetimeAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'timestamp',
        required: true,
      );

      await databases.createBooleanAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'isRead',
        required: true,
        default: false,
      );

      await databases.createDatetimeAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'readAt',
        required: false,
      );

      await databases.createEnumAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'channel',
        elements: ['app', 'email', 'sms', 'all'],
        required: true,
        default: 'app',
      );

      await databases.createEnumAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'status',
        elements: ['sent', 'delivered', 'read', 'failed'],
        required: true,
        default: 'sent',
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'attachments',
        size: 2000,
        required: false,
        array: true,
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'metadata',
        size: 2000,
        required: false,
      );

      // Create indexes
      await databases.createIndex(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'senderId_index',
        type: 'key',
        attributes: ['senderId'],
      );

      await databases.createIndex(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'recipientId_index',
        type: 'key',
        attributes: ['recipientId'],
      );

      await databases.createIndex(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        key: 'timestamp_index',
        type: 'key',
        attributes: ['timestamp'],
      );

      print('✅ Messages collection created');
    } catch (e) {
      print('Error creating messages collection: $e');
    }
  }

  static Future<void> _createConversationsCollection() async {
    try {
      // Create collection
      await databases.createCollection(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        name: 'Conversations',
        permissions: [
          Permission.read(Role.users()),
          Permission.create(Role.users()),
          Permission.update(Role.users()),
        ],
      );

      // Create attributes
      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        key: 'participant1Id',
        size: 255,
        required: true,
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        key: 'participant1Name',
        size: 255,
        required: true,
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        key: 'participant2Id',
        size: 255,
        required: true,
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        key: 'participant2Name',
        size: 255,
        required: true,
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        key: 'lastMessage',
        size: 500,
        required: false,
      );

      await databases.createDatetimeAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        key: 'lastMessageTime',
        required: false,
      );

      await databases.createIntegerAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        key: 'unreadCount1',
        required: true,
        default: 0,
      );

      await databases.createIntegerAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        key: 'unreadCount2',
        required: true,
        default: 0,
      );

      await databases.createBooleanAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        key: 'isActive',
        required: true,
        default: true,
      );

      // Create indexes
      await databases.createIndex(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        key: 'participant1_index',
        type: 'key',
        attributes: ['participant1Id'],
      );

      await databases.createIndex(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        key: 'participant2_index',
        type: 'key',
        attributes: ['participant2Id'],
      );

      print('✅ Conversations collection created');
    } catch (e) {
      print('Error creating conversations collection: $e');
    }
  }

  static Future<void> _createNotificationsCollection() async {
    try {
      // Create collection
      await databases.createCollection(
        databaseId: AppConfig.databaseId,
        collectionId: 'notifications',
        name: 'Notifications',
        permissions: [
          Permission.read(Role.users()),
          Permission.create(Role.users()),
          Permission.update(Role.users()),
        ],
      );

      // Create attributes
      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'notifications',
        key: 'userId',
        size: 255,
        required: true,
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'notifications',
        key: 'title',
        size: 255,
        required: true,
      );

      await databases.createStringAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'notifications',
        key: 'body',
        size: 1000,
        required: true,
      );

      await databases.createDatetimeAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'notifications',
        key: 'timestamp',
        required: true,
      );

      await databases.createBooleanAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'notifications',
        key: 'isRead',
        required: true,
        default: false,
      );

      await databases.createEnumAttribute(
        databaseId: AppConfig.databaseId,
        collectionId: 'notifications',
        key: 'type',
        elements: ['message', 'appointment', 'system', 'alert'],
        required: true,
        default: 'message',
      );

      // Create indexes
      await databases.createIndex(
        databaseId: AppConfig.databaseId,
        collectionId: 'notifications',
        key: 'userId_index',
        type: 'key',
        attributes: ['userId'],
      );

      await databases.createIndex(
        databaseId: AppConfig.databaseId,
        collectionId: 'notifications',
        key: 'timestamp_index',
        type: 'key',
        attributes: ['timestamp'],
      );

      print('✅ Notifications collection created');
    } catch (e) {
      print('Error creating notifications collection: $e');
    }
  }
}

// Run this function to set up collections
void main() async {
  await SetupAppwriteCollections.setupCollections();
}