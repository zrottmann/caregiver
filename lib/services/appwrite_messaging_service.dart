import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../config/app_config.dart';
import '../config/env_config.dart';
import '../models/message.dart';
import '../services/auth_service.dart';

class AppwriteMessagingService {
  late final Client _client;
  late final Account _account;
  late final Databases _databases;
  late final Functions _functions;
  final AuthService _authService = AuthService();

  AppwriteMessagingService() {
    _initializeClient();
  }

  void _initializeClient() {
    _client = Client()
        .setEndpoint(EnvConfig.appwriteEndpoint)
        .setProject(EnvConfig.appwriteProjectId);

    _account = Account(_client);
    _databases = Databases(_client);
    _functions = Functions(_client);
  }

  Future<void> _ensureAuthenticated() async {
    try {
      final session = await _authService.getCurrentSession();
      if (session == null) {
        throw Exception('User not authenticated - no session found');
      }

      _client.setJWT(session.secret);
    } catch (e) {
      print('Authentication check failed: $e');
      throw Exception('User not authenticated: ${e.toString()}');
    }
  }

  /// Send a broadcast message to all users
  Future<Message> sendBroadcastMessage({
    required String senderId,
    required String senderName,
    required String content,
    String? senderEmail,
    String? senderPhone,
  }) async {
    try {
      // Ensure user is authenticated and set JWT
      await _ensureAuthenticated();

      // Create message document with proper permissions
      final document = await _databases.createDocument(
        databaseId: EnvConfig.databaseId,
        collectionId: EnvConfig.messagesCollectionId,
        documentId: ID.unique(),
        data: {
          'senderId': senderId,
          'senderName': senderName,
          'senderEmail': senderEmail ?? '',
          'senderPhone': senderPhone ?? '',
          'receiverId': 'broadcast', // Special ID for broadcast messages
          'recipientName': 'All Users',
          'recipientEmail': '',
          'recipientPhone': '',
          'content': content,
          'subject': 'Community Message from $senderName',
          'timestamp': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'isRead': false,
          'readAt': null,
          'channel': 'broadcast',
          'status': 'sent',
          'attachments': [],
          'metadata': '{}',
        },
        permissions: [
          Permission.read(Role.any()), // Allow anyone to read broadcast messages
          Permission.update(Role.user(senderId)), // Allow sender to update
          Permission.delete(Role.user(senderId)), // Allow sender to delete
        ],
      );

      return Message.fromAppwriteDocument(document);
    } catch (e) {
      print('Error sending broadcast message: $e');
      throw Exception('Failed to send broadcast message: ${e.toString()}');
    }
  }

  /// Send a direct message to a specific user
  Future<Message> sendDirectMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String content,
    String? recipientName,
    String? senderEmail,
    String? senderPhone,
    String? recipientEmail,
    String? recipientPhone,
    String? subject,
    List<String>? attachments,
  }) async {
    try {
      // Ensure user is authenticated and set JWT
      await _ensureAuthenticated();

      // Create message document
      final document = await _databases.createDocument(
        databaseId: EnvConfig.databaseId,
        collectionId: EnvConfig.messagesCollectionId,
        documentId: ID.unique(),
        data: {
          'senderId': senderId,
          'senderName': senderName,
          'senderEmail': senderEmail ?? '',
          'senderPhone': senderPhone ?? '',
          'receiverId': receiverId,
          'recipientName': recipientName ?? '',
          'recipientEmail': recipientEmail ?? '',
          'recipientPhone': recipientPhone ?? '',
          'content': content,
          'subject': subject ?? 'Message from $senderName',
          'timestamp': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'isRead': false,
          'readAt': null,
          'channel': 'direct',
          'status': 'sent',
          'attachments': attachments ?? [],
          'metadata': '{}',
        },
        permissions: [
          Permission.read(Role.user(senderId)),
          Permission.read(Role.user(receiverId)),
          Permission.update(Role.user(senderId)),
          Permission.update(Role.user(receiverId)),
          Permission.delete(Role.user(senderId)),
        ],
      );

      return Message.fromAppwriteDocument(document);
    } catch (e) {
      print('Error sending direct message: $e');
      throw Exception('Failed to send direct message: ${e.toString()}');
    }
  }

  /// Get all messages (for broadcast view)
  Future<List<Message>> getAllMessages() async {
    try {
      // Ensure user is authenticated and set JWT
      await _ensureAuthenticated();

      final response = await _databases.listDocuments(
        databaseId: EnvConfig.databaseId,
        collectionId: EnvConfig.messagesCollectionId,
        queries: [
          Query.equal('channel', ['broadcast']),
          Query.orderDesc('timestamp'),
          Query.limit(100),
        ],
      );

      return response.documents
          .map((doc) => Message.fromAppwriteDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching messages: $e');
      throw Exception('Failed to fetch messages: ${e.toString()}');
    }
  }

  /// Get messages for a specific user
  Future<List<Message>> getUserMessages(String userId) async {
    try {
      // Ensure user is authenticated and set JWT
      await _ensureAuthenticated();

      final response = await _databases.listDocuments(
        databaseId: EnvConfig.databaseId,
        collectionId: EnvConfig.messagesCollectionId,
        queries: [
          Query.or([
            Query.equal('senderId', [userId]),
            Query.equal('receiverId', [userId]),
            Query.equal('receiverId', ['broadcast']),
          ]),
          Query.orderDesc('timestamp'),
          Query.limit(100),
        ],
      );

      return response.documents
          .map((doc) => Message.fromAppwriteDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching user messages: $e');
      throw Exception('Failed to fetch user messages: ${e.toString()}');
    }
  }

  /// Mark a message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      // Ensure user is authenticated and set JWT
      await _ensureAuthenticated();

      await _databases.updateDocument(
        databaseId: EnvConfig.databaseId,
        collectionId: EnvConfig.messagesCollectionId,
        documentId: messageId,
        data: {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error marking message as read: $e');
      throw Exception('Failed to mark message as read: ${e.toString()}');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      // Ensure user is authenticated and set JWT
      await _ensureAuthenticated();

      await _databases.deleteDocument(
        databaseId: EnvConfig.databaseId,
        collectionId: EnvConfig.messagesCollectionId,
        documentId: messageId,
      );
    } catch (e) {
      print('Error deleting message: $e');
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }

  /// Call the send-message function (alternative method using Appwrite Functions)
  Future<Map<String, dynamic>> sendMessageViaFunction({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String content,
    String? recipientName,
    String? senderEmail,
    String? recipientEmail,
    bool sendEmail = false,
  }) async {
    try {
      // Ensure user is authenticated and set JWT
      await _ensureAuthenticated();

      final execution = await _functions.createExecution(
        functionId: 'send-message',
        body: {
          'senderId': senderId,
          'senderName': senderName,
          'senderEmail': senderEmail ?? '',
          'receiverId': receiverId,
          'recipientName': recipientName ?? '',
          'recipientEmail': recipientEmail ?? '',
          'content': content,
          'subject': 'Message from $senderName',
          'sendEmail': sendEmail,
        }.toString(),
      );

      if (execution.responseStatusCode == 200) {
        return {'success': true, 'data': execution.responseBody};
      } else {
        throw Exception('Function execution failed: ${execution.responseBody}');
      }
    } catch (e) {
      print('Error calling send-message function: $e');
      throw Exception('Failed to send message via function: ${e.toString()}');
    }
  }
}