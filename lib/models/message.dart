import 'package:appwrite/models.dart' as models;

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String senderPhone;
  final String receiverId;
  final String recipientName;
  final String recipientEmail;
  final String recipientPhone;
  final String content;
  final String subject;
  final DateTime timestamp;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final String channel;
  final String status;
  final List<String> attachments;
  final String metadata;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.senderPhone,
    required this.receiverId,
    required this.recipientName,
    required this.recipientEmail,
    required this.recipientPhone,
    required this.content,
    required this.subject,
    required this.timestamp,
    required this.createdAt,
    required this.isRead,
    this.readAt,
    required this.channel,
    required this.status,
    required this.attachments,
    required this.metadata,
  });

  factory Message.fromAppwriteDocument(models.Document document) {
    final data = document.data;
    return Message(
      id: document.$id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderEmail: data['senderEmail'] ?? '',
      senderPhone: data['senderPhone'] ?? '',
      receiverId: data['receiverId'] ?? '',
      recipientName: data['recipientName'] ?? '',
      recipientEmail: data['recipientEmail'] ?? '',
      recipientPhone: data['recipientPhone'] ?? '',
      content: data['content'] ?? '',
      subject: data['subject'] ?? '',
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: data['isRead'] ?? false,
      readAt: data['readAt'] != null ? DateTime.parse(data['readAt']) : null,
      channel: data['channel'] ?? 'direct',
      status: data['status'] ?? 'sent',
      attachments: data['attachments'] != null
          ? List<String>.from(data['attachments'])
          : [],
      metadata: data['metadata'] ?? '{}',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'senderPhone': senderPhone,
      'receiverId': receiverId,
      'recipientName': recipientName,
      'recipientEmail': recipientEmail,
      'recipientPhone': recipientPhone,
      'content': content,
      'subject': subject,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'channel': channel,
      'status': status,
      'attachments': attachments,
      'metadata': metadata,
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? senderPhone,
    String? receiverId,
    String? recipientName,
    String? recipientEmail,
    String? recipientPhone,
    String? content,
    String? subject,
    DateTime? timestamp,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    String? channel,
    String? status,
    List<String>? attachments,
    String? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      senderPhone: senderPhone ?? this.senderPhone,
      receiverId: receiverId ?? this.receiverId,
      recipientName: recipientName ?? this.recipientName,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      content: content ?? this.content,
      subject: subject ?? this.subject,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      channel: channel ?? this.channel,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
    );
  }
}