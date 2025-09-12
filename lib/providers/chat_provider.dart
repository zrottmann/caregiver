import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/user_presence_service.dart';

// State classes for different aspects of chat

// Main chat list state
class ChatListState {
  final List<Chat> chats;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final bool hasMore;
  final Map<String, int> unreadCounts;

  ChatListState({
    this.chats = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.hasMore = true,
    this.unreadCounts = const {},
  });

  ChatListState copyWith({
    List<Chat>? chats,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool? hasMore,
    Map<String, int>? unreadCounts,
  }) {
    return ChatListState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }

  int get totalUnreadCount => unreadCounts.values.fold(0, (sum, count) => sum + count);
}

// Individual chat room state
class ChatRoomState {
  final String chatId;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSendingMessage;
  final String? error;
  final bool hasMore;
  final String? replyToMessageId;
  final ChatMessage? replyToMessage;
  final List<TypingIndicator> typingIndicators;
  final bool isOnline;

  ChatRoomState({
    required this.chatId,
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSendingMessage = false,
    this.error,
    this.hasMore = true,
    this.replyToMessageId,
    this.replyToMessage,
    this.typingIndicators = const [],
    this.isOnline = true,
  });

  ChatRoomState copyWith({
    String? chatId,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSendingMessage,
    String? error,
    bool? hasMore,
    String? replyToMessageId,
    ChatMessage? replyToMessage,
    List<TypingIndicator>? typingIndicators,
    bool? isOnline,
  }) {
    return ChatRoomState(
      chatId: chatId ?? this.chatId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      typingIndicators: typingIndicators ?? this.typingIndicators,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  List<TypingIndicator> get validTypingIndicators {
    return typingIndicators.where((indicator) => indicator.isValid && indicator.isTyping).toList();
  }
}

// User presence state
class UserPresenceState {
  final Map<String, UserPresence> presences;
  final bool isLoading;
  final String? error;

  UserPresenceState({
    this.presences = const {},
    this.isLoading = false,
    this.error,
  });

  UserPresenceState copyWith({
    Map<String, UserPresence>? presences,
    bool? isLoading,
    String? error,
  }) {
    return UserPresenceState(
      presences: presences ?? this.presences,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  UserPresence? getPresence(String userId) => presences[userId];
  bool isUserOnline(String userId) => presences[userId]?.isOnline ?? false;
  String getUserStatus(String userId) => presences[userId]?.statusText ?? 'Unknown';
}

// Notifier classes

class ChatListNotifier extends StateNotifier<ChatListState> {
  final ChatService _chatService = ChatService.instance;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _refreshTimer;

  ChatListNotifier() : super(ChatListState()) {
    _initializeConnectivityMonitoring();
    _startAutoRefresh();
  }

  void _initializeConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;
      if (isOnline && state.chats.isEmpty && !state.isLoading) {
        // Auto-refresh when coming back online
        _refreshChats();
      }
    });
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!state.isLoading && !state.isRefreshing) {
        refreshChats();
      }
    });
  }

  Future<void> loadUserChats(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final chats = await _chatService.getUserChats(userId);
      final unreadCounts = <String, int>{};
      
      // Get unread counts for each chat
      for (final chat in chats) {
        try {
          final count = await _chatService.getUnreadMessageCount(chat.id, userId);
          unreadCounts[chat.id] = count;
        } catch (e) {
          if (kDebugMode) {
            print('Error getting unread count for chat ${chat.id}: $e');
          }
          unreadCounts[chat.id] = 0;
        }
      }
      
      state = state.copyWith(
        chats: chats,
        isLoading: false,
        unreadCounts: unreadCounts,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshChats() async {
    if (state.isRefreshing) return;
    
    await _refreshChats();
  }

  Future<void> _refreshChats() async {
    // Implementation would require current user ID
    // This would typically come from an auth provider
    if (kDebugMode) {
      print('Refreshing chats...');
    }
  }

  Future<Chat> createOrGetChat(
    String bookingId,
    String patientId,
    String caregiverId,
    String patientName,
    String caregiverName,
  ) async {
    try {
      final chat = await _chatService.createOrGetChat(
        bookingId,
        patientId,
        caregiverId,
        patientName,
        caregiverName,
      );

      // Add to state if not already present
      final existingIndex = state.chats.indexWhere((c) => c.id == chat.id);
      if (existingIndex == -1) {
        state = state.copyWith(
          chats: [chat, ...state.chats],
          unreadCounts: {...state.unreadCounts, chat.id: 0},
        );
      }

      return chat;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void updateChatLastMessage(String chatId, ChatMessage message) {
    final chatIndex = state.chats.indexWhere((c) => c.id == chatId);
    if (chatIndex >= 0) {
      final updatedChat = state.chats[chatIndex].copyWith(
        lastMessage: message,
        updatedAt: message.timestamp,
      );
      
      final updatedChats = List<Chat>.from(state.chats);
      updatedChats[chatIndex] = updatedChat;
      
      // Sort chats by last message timestamp
      updatedChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      state = state.copyWith(chats: updatedChats);
    }
  }

  void incrementUnreadCount(String chatId) {
    final currentCount = state.unreadCounts[chatId] ?? 0;
    state = state.copyWith(
      unreadCounts: {...state.unreadCounts, chatId: currentCount + 1},
    );
  }

  void resetUnreadCount(String chatId) {
    state = state.copyWith(
      unreadCounts: {...state.unreadCounts, chatId: 0},
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final ChatService _chatService = ChatService.instance;
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _typingTimer;

  ChatRoomNotifier(String chatId) : super(ChatRoomState(chatId: chatId)) {
    _initializeChat();
    _initializeConnectivityMonitoring();
  }

  void _initializeChat() {
    loadMessages(refresh: true);
    _subscribeToMessages();
  }

  void _initializeConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;
      state = state.copyWith(isOnline: isOnline);
      
      if (isOnline && state.messages.isEmpty && !state.isLoading) {
        loadMessages(refresh: true);
      }
    });
  }

  Future<void> loadMessages({bool refresh = false}) async {
    if (!refresh && (state.isLoading || state.isLoadingMore)) return;
    if (refresh && state.isLoading) return;

    try {
      state = state.copyWith(
        isLoading: refresh,
        isLoadingMore: !refresh,
        error: null,
      );
      
      final messages = await _chatService.getChatMessages(state.chatId);
      
      state = state.copyWith(
        messages: messages,
        isLoading: false,
        isLoadingMore: false,
        hasMore: messages.length >= 50,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> sendMessage(
    String senderId,
    String senderName,
    String content,
    MessageType type,
  ) async {
    if (content.trim().isEmpty && type == MessageType.text) return;

    try {
      state = state.copyWith(isSendingMessage: true, error: null);
      
      final message = await _chatService.sendMessage(
        state.chatId,
        senderId,
        senderName,
        content,
        type,
      );

      // Add message to local state for immediate UI update
      final updatedMessages = [...state.messages, message];
      
      state = state.copyWith(
        messages: updatedMessages,
        isSendingMessage: false,
        replyToMessageId: null,
        replyToMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isSendingMessage: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> retryFailedMessage(ChatMessage message) async {
    try {
      await _chatService.retryFailedMessage(message);
      
      // Update the message status in local state
      final updatedMessages = state.messages.map((m) {
        if (m.id == message.id) {
          return m.copyWith(deliveryStatus: MessageDeliveryStatus.delivered);
        }
        return m;
      }).toList();
      
      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setReplyToMessage(ChatMessage? message) {
    state = state.copyWith(
      replyToMessage: message,
      replyToMessageId: message?.id,
    );
  }

  void clearReply() {
    state = state.copyWith(
      replyToMessage: null,
      replyToMessageId: null,
    );
  }

  Future<void> markMessagesAsRead(String userId) async {
    try {
      await _chatService.markChatMessagesAsRead(state.chatId, userId);
      
      // Update local messages to mark as read
      final updatedMessages = state.messages.map((message) {
        if (message.senderId != userId && !message.isRead) {
          return message.copyWith(isRead: true);
        }
        return message;
      }).toList();
      
      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      if (kDebugMode) {
        print('Error marking messages as read: $e');
      }
    }
  }

  void sendTypingIndicator(String userId, String userName, bool isTyping) {
    _chatService.sendTypingIndicator(state.chatId, userId, userName, isTyping);
    
    if (isTyping) {
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        sendTypingIndicator(userId, userName, false);
      });
    }
  }

  void _subscribeToMessages() {
    _messageSubscription = _chatService.subscribeToMessages(state.chatId).listen(
      (message) {
        // Avoid duplicates
        final exists = state.messages.any((m) => m.id == message.id);
        if (!exists) {
          final updatedMessages = [...state.messages, message];
          state = state.copyWith(messages: updatedMessages);
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('Message subscription error: $error');
        }
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _typingTimer?.cancel();
    _chatService.cancelMessageSubscription(state.chatId);
    super.dispose();
  }
}

class UserPresenceNotifier extends StateNotifier<UserPresenceState> {
  final UserPresenceService _presenceService = UserPresenceService.instance;
  final Map<String, StreamSubscription<UserPresence>> _presenceSubscriptions = {};

  UserPresenceNotifier() : super(UserPresenceState());

  Future<void> loadUserPresence(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final presence = await _presenceService.getUserPresence(userId);
      if (presence != null) {
        state = state.copyWith(
          presences: {...state.presences, userId: presence},
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMultipleUserPresence(List<String> userIds) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final presences = await _presenceService.getMultipleUserPresence(userIds);
      
      state = state.copyWith(
        presences: {...state.presences, ...presences},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void subscribeToUserPresence(String userId) {
    if (_presenceSubscriptions.containsKey(userId)) return;

    _presenceSubscriptions[userId] = _presenceService.subscribeToUserPresence(userId).listen(
      (presence) {
        state = state.copyWith(
          presences: {...state.presences, userId: presence},
        );
      },
      onError: (error) {
        if (kDebugMode) {
          print('Presence subscription error for $userId: $error');
        }
      },
    );
  }

  void subscribeToMultipleUserPresence(List<String> userIds) {
    for (final userId in userIds) {
      subscribeToUserPresence(userId);
    }
  }

  void unsubscribeFromUserPresence(String userId) {
    _presenceSubscriptions[userId]?.cancel();
    _presenceSubscriptions.remove(userId);
    _presenceService.cancelPresenceSubscription(userId);
  }

  void updatePresenceStatus(UserPresenceStatus status, {String? chatId}) {
    _presenceService.updatePresenceStatus(status, chatId: chatId);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    for (final subscription in _presenceSubscriptions.values) {
      subscription.cancel();
    }
    _presenceSubscriptions.clear();
    _presenceService.cancelAllPresenceSubscriptions();
    super.dispose();
  }
}

// Provider definitions
final chatListProvider = StateNotifierProvider<ChatListNotifier, ChatListState>((ref) {
  return ChatListNotifier();
});

final chatRoomProvider = StateNotifierProvider.family<ChatRoomNotifier, ChatRoomState, String>((ref, chatId) {
  return ChatRoomNotifier(chatId);
});

final userPresenceProvider = StateNotifierProvider<UserPresenceNotifier, UserPresenceState>((ref) {
  return UserPresenceNotifier();
});

// Additional utility providers
final totalUnreadCountProvider = Provider<int>((ref) {
  final chatListState = ref.watch(chatListProvider);
  return chatListState.totalUnreadCount;
});

final chatUnreadCountProvider = Provider.family<int, String>((ref, chatId) {
  final chatListState = ref.watch(chatListProvider);
  return chatListState.unreadCounts[chatId] ?? 0;
});

final userOnlineStatusProvider = Provider.family<bool, String>((ref, userId) {
  final presenceState = ref.watch(userPresenceProvider);
  return presenceState.isUserOnline(userId);
});

final chatMessagesProvider = Provider.family<List<ChatMessage>, String>((ref, chatId) {
  final chatRoomState = ref.watch(chatRoomProvider(chatId));
  return chatRoomState.messages;
});

final isTypingProvider = Provider.family<List<TypingIndicator>, String>((ref, chatId) {
  final chatRoomState = ref.watch(chatRoomProvider(chatId));
  return chatRoomState.validTypingIndicators;
});