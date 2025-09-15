import 'package:appwrite/models.dart' as models;

enum MessageType {
  text,
  image,
  file,
  system,
}

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String conversationId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final String? attachmentName;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.conversationId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
    this.attachmentName,
    this.metadata,
  });

  bool get isFromCurrentUser => senderId == receiverId;

  factory Message.fromDocument(models.Document document) {
    final data = document.data;
    return Message(
      id: document.$id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      conversationId: data['conversationId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (t) => t.name == (data['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: data['isRead'] ?? false,
      attachmentUrl: data['attachmentUrl'],
      attachmentName: data['attachmentName'],
      metadata: data['metadata'] is Map ? data['metadata'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'conversationId': conversationId,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'metadata': metadata,
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? conversationId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    String? attachmentUrl,
    String? attachmentName,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      metadata: metadata ?? this.metadata,
    );
  }
}

class Conversation {
  final String id;
  final List<String> participantIds;
  final String? appointmentId;
  final String title;
  final Message? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  Conversation({
    required this.id,
    required this.participantIds,
    this.appointmentId,
    required this.title,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory Conversation.fromDocument(models.Document document) {
    final data = document.data;
    return Conversation(
      id: document.$id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      appointmentId: data['appointmentId'],
      title: data['title'] ?? '',
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      metadata: data['metadata'] is Map ? data['metadata'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'appointmentId': appointmentId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  Conversation copyWith({
    String? id,
    List<String>? participantIds,
    String? appointmentId,
    String? title,
    Message? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      appointmentId: appointmentId ?? this.appointmentId,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}