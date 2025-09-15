import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/messages_service.dart';
import 'auth_provider.dart';

final messagesServiceProvider = Provider<MessagesService>((ref) {
  return MessagesService();
});

final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final service = ref.read(messagesServiceProvider);
  return service.getConversations(user.$id);
});

final messagesProvider = FutureProvider.autoDispose.family<List<Message>, String>((ref, conversationId) async {
  final service = ref.read(messagesServiceProvider);
  return service.getMessages(conversationId);
});

final unreadMessageCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  final service = ref.read(messagesServiceProvider);
  return service.getUnreadMessageCount(user.$id);
});

class MessagesNotifier extends StateNotifier<AsyncValue<void>> {
  MessagesNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  final MessagesService _service;
  final Ref _ref;

  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    String? attachmentUrl,
    String? attachmentName,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('User not authenticated');

    state = const AsyncValue.loading();
    try {
      final message = await _service.sendMessage(
        conversationId: conversationId,
        senderId: user.$id,
        receiverId: receiverId,
        content: content,
        type: type,
        attachmentUrl: attachmentUrl,
        attachmentName: attachmentName,
      );

      _ref.invalidate(messagesProvider(conversationId));
      _ref.invalidate(conversationsProvider);
      _ref.invalidate(unreadMessageCountProvider);

      state = const AsyncValue.data(null);
      return message;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<Conversation> findOrCreateConversation({
    required List<String> participantIds,
    String? appointmentId,
    String? title,
  }) async {
    state = const AsyncValue.loading();
    try {
      final conversation = await _service.findOrCreateConversation(
        participantIds: participantIds,
        appointmentId: appointmentId,
        title: title,
      );

      _ref.invalidate(conversationsProvider);

      state = const AsyncValue.data(null);
      return conversation!;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> markAllMessagesAsRead(String conversationId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await _service.markAllMessagesAsRead(conversationId, user.$id);

      _ref.invalidate(messagesProvider(conversationId));
      _ref.invalidate(conversationsProvider);
      _ref.invalidate(unreadMessageCountProvider);
    } catch (error) {
      // Silently fail for marking as read
    }
  }
}

final messagesNotifierProvider = StateNotifierProvider<MessagesNotifier, AsyncValue<void>>((ref) {
  final service = ref.read(messagesServiceProvider);
  return MessagesNotifier(service, ref);
});