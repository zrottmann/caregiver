import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../config/app_config.dart';
import '../models/message.dart';

class MessagesService {
  final Databases _databases = Databases(AppConfig.client);
  final Realtime _realtime = Realtime(AppConfig.client);

  Future<List<Conversation>> getConversations(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        queries: [
          Query.equal('participantIds', userId),
          Query.orderDesc('\$createdAt'),
        ],
      );

      final conversations = response.documents
          .map((doc) => Conversation.fromDocument(doc))
          .toList();

      for (int i = 0; i < conversations.length; i++) {
        final lastMessage = await _getLastMessageForConversation(conversations[i].id);
        conversations[i] = conversations[i].copyWith(lastMessage: lastMessage);
      }

      return conversations;
    } catch (e) {
      throw Exception('Failed to get conversations: $e');
    }
  }

  Future<Message?> _getLastMessageForConversation(String conversationId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        queries: [
          Query.equal('conversationId', conversationId),
          Query.orderDesc('timestamp'),
          Query.limit(1),
        ],
      );

      if (response.documents.isEmpty) return null;
      return Message.fromDocument(response.documents.first);
    } catch (e) {
      return null;
    }
  }

  Future<Conversation> createConversation({
    required List<String> participantIds,
    String? appointmentId,
    required String title,
  }) async {
    try {
      final conversationData = {
        'participantIds': participantIds,
        'appointmentId': appointmentId,
        'title': title,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final document = await _databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        documentId: ID.unique(),
        data: conversationData,
      );

      return Conversation.fromDocument(document);
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  Future<Conversation?> findOrCreateConversation({
    required List<String> participantIds,
    String? appointmentId,
    String? title,
  }) async {
    try {
      final sortedParticipants = List<String>.from(participantIds)..sort();

      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        queries: [
          Query.equal('participantIds', sortedParticipants),
          if (appointmentId != null) Query.equal('appointmentId', appointmentId),
        ],
      );

      if (response.documents.isNotEmpty) {
        return Conversation.fromDocument(response.documents.first);
      }

      return await createConversation(
        participantIds: participantIds,
        appointmentId: appointmentId,
        title: title ?? 'Conversation',
      );
    } catch (e) {
      throw Exception('Failed to find or create conversation: $e');
    }
  }

  Future<List<Message>> getMessages(String conversationId, {int limit = 50, String? offset}) async {
    try {
      final queries = [
        Query.equal('conversationId', conversationId),
        Query.orderDesc('timestamp'),
        Query.limit(limit),
      ];

      if (offset != null) {
        queries.add(Query.cursorAfter(offset));
      }

      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        queries: queries,
      );

      return response.documents
          .map((doc) => Message.fromDocument(doc))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    String? attachmentUrl,
    String? attachmentName,
  }) async {
    try {
      final messageData = {
        'conversationId': conversationId,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'type': type.name,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'attachmentUrl': attachmentUrl,
        'attachmentName': attachmentName,
      };

      final document = await _databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        documentId: ID.unique(),
        data: messageData,
      );

      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: 'conversations',
        documentId: conversationId,
        data: {
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      return Message.fromDocument(document);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        documentId: messageId,
        data: {'isRead': true},
      );
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  Future<void> markAllMessagesAsRead(String conversationId, String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        queries: [
          Query.equal('conversationId', conversationId),
          Query.equal('receiverId', userId),
          Query.equal('isRead', false),
        ],
      );

      for (final doc in response.documents) {
        await markMessageAsRead(doc.$id);
      }
    } catch (e) {
      throw Exception('Failed to mark all messages as read: $e');
    }
  }

  Stream<RealtimeMessage> subscribeToConversation(String conversationId) {
    return _realtime.subscribe([
      'databases.${AppConfig.databaseId}.collections.messages.documents',
    ]).stream.where((message) {
      if (message.payload.containsKey('conversationId')) {
        return message.payload['conversationId'] == conversationId;
      }
      return false;
    });
  }

  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        queries: [
          Query.equal('receiverId', userId),
          Query.equal('isRead', false),
        ],
      );

      return response.total;
    } catch (e) {
      return 0;
    }
  }
}