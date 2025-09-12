import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/chat_message.dart';
import 'appwrite_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();
  
  static ChatService get instance => _instance;
  
  final AppwriteService _appwrite = AppwriteService.instance;
  final Map<String, RealtimeSubscription> _messageSubscriptions = {};
  final Map<String, RealtimeSubscription> _chatSubscriptions = {};
  final Map<String, StreamController<ChatMessage>> _messageStreams = {};
  final Map<String, StreamController<Chat>> _chatStreams = {};
  final Map<String, Timer> _typingTimers = {};
  
  // Connectivity monitoring
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  
  // Cache for offline support
  final Map<String, List<ChatMessage>> _messageCache = {};
  final Map<String, List<Chat>> _chatCache = {};
  final List<Map<String, dynamic>> _pendingMessages = [];
  
  Future<void> initialize() async {
    // Monitor connectivity
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        _syncPendingMessages();
      }
    });
    
    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
  }

  Future<Chat> createOrGetChat(
    String bookingId, 
    String patientId, 
    String caregiverId, 
    String patientName, 
    String caregiverName,
  ) async {
    try {
      // First, try to find existing chat for this booking
      final documents = await _appwrite.databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.chatsCollectionId,
        queries: [
          Query.equal('bookingId', bookingId),
          Query.limit(1),
        ],
      );

      if (documents.documents.isNotEmpty) {
        final chat = Chat.fromJson(documents.documents.first.data);
        _updateChatCache(chat);
        return chat;
      }

      // Create new chat if doesn't exist
      final chat = Chat(
        id: '',
        bookingId: bookingId,
        patientId: patientId,
        caregiverId: caregiverId,
        patientName: patientName,
        caregiverName: caregiverName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final document = await _appwrite.databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.chatsCollectionId,
        documentId: ID.unique(),
        data: chat.toJson(),
      );

      final createdChat = Chat.fromJson(document.data);
      _updateChatCache(createdChat);
      return createdChat;
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    } catch (e) {
      throw 'Failed to create or get chat: ${e.toString()}';
    }
  }

  Future<List<Chat>> getUserChats(String userId) async {
    try {
      if (!_isOnline && _chatCache.containsKey(userId)) {
        return _chatCache[userId]!;
      }

      final documents = await _appwrite.databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.chatsCollectionId,
        queries: [
          Query.equal('patientId', userId),
          Query.orderDesc('\$updatedAt'),
          Query.limit(50),
        ],
      );

      final chats = <Chat>[];
      
      for (final doc in documents.documents) {
        final chat = Chat.fromJson(doc.data);
        
        // Get last message for this chat
        final lastMessage = await _getLastMessage(chat.id);
        final chatWithLastMessage = chat.copyWith(lastMessage: lastMessage);
        
        chats.add(chatWithLastMessage);
      }

      // Cache the results
      _chatCache[userId] = chats;
      
      return chats;
    } on AppwriteException catch (e) {
      if (!_isOnline && _chatCache.containsKey(userId)) {
        return _chatCache[userId]!;
      }
      throw _handleAppwriteException(e);
    } catch (e) {
      if (!_isOnline && _chatCache.containsKey(userId)) {
        return _chatCache[userId]!;
      }
      throw 'Failed to get user chats: ${e.toString()}';
    }
  }

  Future<Chat?> getChat(String chatId) async {
    try {
      final document = await _appwrite.databases.getDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.chatsCollectionId,
        documentId: chatId,
      );

      final chat = Chat.fromJson(document.data);
      _updateChatCache(chat);
      return chat;
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        return null;
      }
      throw _handleAppwriteException(e);
    } catch (e) {
      throw 'Failed to get chat: ${e.toString()}';
    }
  }

  Future<ChatMessage> sendMessage(
    String chatId, 
    String senderId, 
    String senderName, 
    String content, 
    MessageType type,
  ) async {
    final message = ChatMessage(
      id: '',
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      deliveryStatus: _isOnline ? MessageDeliveryStatus.sending : MessageDeliveryStatus.pending,
    );

    if (!_isOnline) {
      // Store message for later sending
      _pendingMessages.add({
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'type': type.name,
        'timestamp': message.timestamp.toIso8601String(),
      });
      
      // Add to local cache immediately
      _addMessageToCache(chatId, message);
      
      return message.copyWith(deliveryStatus: MessageDeliveryStatus.pending);
    }

    try {
      final document = await _appwrite.databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.messagesCollectionId,
        documentId: ID.unique(),
        data: message.toJson(),
      );

      // Update chat's updatedAt timestamp
      await _appwrite.databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.chatsCollectionId,
        documentId: chatId,
        data: {
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      final sentMessage = ChatMessage.fromJson(document.data)
          .copyWith(deliveryStatus: MessageDeliveryStatus.delivered);
      
      _addMessageToCache(chatId, sentMessage);
      
      return sentMessage;
    } on AppwriteException catch (e) {
      // If sending fails, mark as failed and store for retry
      _pendingMessages.add({
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'type': type.name,
        'timestamp': message.timestamp.toIso8601String(),
      });
      
      final failedMessage = message.copyWith(deliveryStatus: MessageDeliveryStatus.failed);
      _addMessageToCache(chatId, failedMessage);
      
      throw _handleAppwriteException(e);
    } catch (e) {
      _pendingMessages.add({
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'type': type.name,
        'timestamp': message.timestamp.toIso8601String(),
      });
      
      final failedMessage = message.copyWith(deliveryStatus: MessageDeliveryStatus.failed);
      _addMessageToCache(chatId, failedMessage);
      
      throw 'Failed to send message: ${e.toString()}';
    }
  }

  Future<List<ChatMessage>> getChatMessages(String chatId, {int limit = 50, String? cursor}) async {
    try {
      if (!_isOnline && _messageCache.containsKey(chatId)) {
        return _messageCache[chatId]!;
      }

      List<String> queries = [
        Query.equal('chatId', chatId),
        Query.orderDesc('\$createdAt'),
        Query.limit(limit),
      ];

      if (cursor != null) {
        queries.add(Query.cursorAfter(cursor));
      }

      final documents = await _appwrite.databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.messagesCollectionId,
        queries: queries,
      );

      final messages = documents.documents
          .map((doc) => ChatMessage.fromJson(doc.data))
          .toList()
          .reversed // Reverse to show oldest first
          .toList();

      // Cache the messages
      _messageCache[chatId] = messages;

      return messages;
    } on AppwriteException catch (e) {
      if (!_isOnline && _messageCache.containsKey(chatId)) {
        return _messageCache[chatId]!;
      }
      throw _handleAppwriteException(e);
    } catch (e) {
      if (!_isOnline && _messageCache.containsKey(chatId)) {
        return _messageCache[chatId]!;
      }
      throw 'Failed to get chat messages: ${e.toString()}';
    }
  }

  Future<ChatMessage?> _getLastMessage(String chatId) async {
    try {
      final documents = await _appwrite.databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.messagesCollectionId,
        queries: [
          Query.equal('chatId', chatId),
          Query.orderDesc('\$createdAt'),
          Query.limit(1),
        ],
      );

      if (documents.documents.isEmpty) return null;
      
      return ChatMessage.fromJson(documents.documents.first.data);
    } catch (e) {
      return null;
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _appwrite.databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.messagesCollectionId,
        documentId: messageId,
        data: {
          'isRead': true,
        },
      );
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    } catch (e) {
      throw 'Failed to mark message as read: ${e.toString()}';
    }
  }

  Future<void> markChatMessagesAsRead(String chatId, String userId) async {
    try {
      // Get all unread messages from other users
      final documents = await _appwrite.databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.messagesCollectionId,
        queries: [
          Query.equal('chatId', chatId),
          Query.notEqual('senderId', userId),
          Query.equal('isRead', false),
        ],
      );

      // Mark each message as read
      for (final doc in documents.documents) {
        await _appwrite.databases.updateDocument(
          databaseId: AppConfig.databaseId,
          collectionId: AppConfig.messagesCollectionId,
          documentId: doc.$id,
          data: {'isRead': true},
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to mark messages as read: $e');
      }
    }
  }

  Future<int> getUnreadMessageCount(String chatId, String userId) async {
    try {
      final documents = await _appwrite.databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.messagesCollectionId,
        queries: [
          Query.equal('chatId', chatId),
          Query.notEqual('senderId', userId),
          Query.equal('isRead', false),
        ],
      );

      return documents.total;
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    } catch (e) {
      throw 'Failed to get unread message count: ${e.toString()}';
    }
  }

  // Real-time message subscription with enhanced error handling
  Stream<ChatMessage> subscribeToMessages(String chatId) {
    if (_messageStreams.containsKey(chatId)) {
      return _messageStreams[chatId]!.stream;
    }

    final controller = StreamController<ChatMessage>.broadcast();
    _messageStreams[chatId] = controller;

    try {
      final subscription = _appwrite.realtime.subscribe([
        'databases.${AppConfig.databaseId}.collections.${AppConfig.messagesCollectionId}.documents'
      ]);

      subscription.stream.listen(
        (response) {
          try {
            if (response.events.contains('databases.*.collections.*.documents.*.create')) {
              final messageData = response.payload;
              if (messageData['chatId'] == chatId) {
                final message = ChatMessage.fromJson(messageData);
                _addMessageToCache(chatId, message);
                controller.add(message);
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error processing real-time message: $e');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('Real-time subscription error: $error');
          }
          controller.addError(error);
        },
      );

      _messageSubscriptions[chatId] = subscription;
    } catch (e) {
      controller.addError(e);
    }

    return controller.stream;
  }

  // Real-time chat list subscription
  Stream<List<Chat>> subscribeToChatList(String userId) {
    final streamKey = 'chats_$userId';
    if (_chatStreams.containsKey(streamKey)) {
      return _chatStreams[streamKey]!.stream.map((chat) => [chat]);
    }

    final controller = StreamController<Chat>.broadcast();
    _chatStreams[streamKey] = controller;

    try {
      final subscription = _appwrite.realtime.subscribe([
        'databases.${AppConfig.databaseId}.collections.${AppConfig.chatsCollectionId}.documents'
      ]);

      subscription.stream.listen(
        (response) {
          try {
            if (response.events.contains('databases.*.collections.*.documents.*.update') ||
                response.events.contains('databases.*.collections.*.documents.*.create')) {
              final chatData = response.payload;
              if (chatData['patientId'] == userId || chatData['caregiverId'] == userId) {
                final chat = Chat.fromJson(chatData);
                _updateChatCache(chat);
                controller.add(chat);
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error processing real-time chat update: $e');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('Real-time chat subscription error: $error');
          }
          controller.addError(error);
        },
      );

      _chatSubscriptions[streamKey] = subscription;
    } catch (e) {
      controller.addError(e);
    }

    return controller.stream.map((chat) => [chat]);
  }

  // Typing indicators
  Future<void> sendTypingIndicator(String chatId, String userId, String userName, bool isTyping) async {
    try {
      // In a real implementation, you'd send this to a separate collection or use a different mechanism
      // For now, we'll just emit it through real-time
      final typingData = {
        'chatId': chatId,
        'userId': userId,
        'userName': userName,
        'isTyping': isTyping,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Cancel existing timer for this user
      _typingTimers['${chatId}_$userId']?.cancel();

      if (isTyping) {
        // Set a timer to automatically stop typing after 3 seconds
        _typingTimers['${chatId}_$userId'] = Timer(const Duration(seconds: 3), () {
          sendTypingIndicator(chatId, userId, userName, false);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending typing indicator: $e');
      }
    }
  }

  // Cache management
  void _updateChatCache(Chat chat) {
    // Update in all relevant user caches
    for (final key in _chatCache.keys) {
      final chats = _chatCache[key]!;
      final index = chats.indexWhere((c) => c.id == chat.id);
      if (index >= 0) {
        chats[index] = chat;
      } else if (key == chat.patientId || key == chat.caregiverId) {
        chats.insert(0, chat);
      }
    }
  }

  void _addMessageToCache(String chatId, ChatMessage message) {
    if (!_messageCache.containsKey(chatId)) {
      _messageCache[chatId] = [];
    }
    _messageCache[chatId]!.add(message);
  }

  // Sync pending messages when coming back online
  Future<void> _syncPendingMessages() async {
    final messagesToRetry = List<Map<String, dynamic>>.from(_pendingMessages);
    _pendingMessages.clear();

    for (final messageData in messagesToRetry) {
      try {
        await sendMessage(
          messageData['chatId'],
          messageData['senderId'],
          messageData['senderName'],
          messageData['content'],
          MessageType.values.firstWhere(
            (e) => e.name == messageData['type'],
            orElse: () => MessageType.text,
          ),
        );
      } catch (e) {
        // If still failing, add back to pending
        _pendingMessages.add(messageData);
      }
    }
  }

  // Retry failed messages
  Future<void> retryFailedMessage(ChatMessage message) async {
    try {
      await sendMessage(
        message.chatId,
        message.senderId,
        message.senderName,
        message.content,
        message.type,
      );
      
      // Remove from cache and re-add with new status
      if (_messageCache.containsKey(message.chatId)) {
        _messageCache[message.chatId]!.removeWhere((m) => m.id == message.id);
      }
    } catch (e) {
      throw 'Failed to retry message: ${e.toString()}';
    }
  }

  // Cleanup methods
  void cancelMessageSubscription(String chatId) {
    _messageSubscriptions[chatId]?.close();
    _messageSubscriptions.remove(chatId);
    _messageStreams[chatId]?.close();
    _messageStreams.remove(chatId);
  }

  void cancelChatSubscription(String userId) {
    final streamKey = 'chats_$userId';
    _chatSubscriptions[streamKey]?.close();
    _chatSubscriptions.remove(streamKey);
    _chatStreams[streamKey]?.close();
    _chatStreams.remove(streamKey);
  }

  void cancelAllSubscriptions() {
    for (final subscription in _messageSubscriptions.values) {
      subscription.close();
    }
    for (final subscription in _chatSubscriptions.values) {
      subscription.close();
    }
    for (final stream in _messageStreams.values) {
      stream.close();
    }
    for (final stream in _chatStreams.values) {
      stream.close();
    }
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    
    _messageSubscriptions.clear();
    _chatSubscriptions.clear();
    _messageStreams.clear();
    _chatStreams.clear();
    _typingTimers.clear();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    cancelAllSubscriptions();
    _messageCache.clear();
    _chatCache.clear();
    _pendingMessages.clear();
  }

  String _handleAppwriteException(AppwriteException e) {
    switch (e.code) {
      case 401:
        return 'Unauthorized access';
      case 404:
        return 'Chat or message not found';
      case 400:
        return 'Invalid chat data';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}