import 'package:appwrite/models.dart' as models;

/// Message channel enum
enum MessageChannel {
  app,
  email,
  sms,
  all,
}

/// Message model for the caregiver platform
class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String? senderPhone;
  final String recipientId;
  final String recipientName;
  final String recipientEmail;
  final String? recipientPhone;
  final String content;
  final String? subject;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? readAt;
  final MessageChannel channel;
  final String status;
  final List<String> attachments;
  final Map<String, dynamic> metadata;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    this.senderPhone,
    required this.recipientId,
    required this.recipientName,
    required this.recipientEmail,
    this.recipientPhone,
    required this.content,
    this.subject,
    required this.timestamp,
    required this.isRead,
    this.readAt,
    required this.channel,
    required this.status,
    required this.attachments,
    required this.metadata,
  });

  /// Create Message from Appwrite Document
  factory Message.fromDocument(models.Document doc) {
    return Message(
      id: doc.$id,
      senderId: doc.data['senderId'] ?? '',
      senderName: doc.data['senderName'] ?? '',
      senderEmail: doc.data['senderEmail'] ?? '',
      senderPhone: doc.data['senderPhone'],
      recipientId: doc.data['receiverId'] ?? '',
      recipientName: doc.data['recipientName'] ?? '',
      recipientEmail: doc.data['recipientEmail'] ?? '',
      recipientPhone: doc.data['recipientPhone'],
      content: doc.data['content'] ?? '',
      subject: doc.data['subject'],
      timestamp: DateTime.parse(doc.data['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: doc.data['isRead'] ?? false,
      readAt: doc.data['readAt'] != null ? DateTime.parse(doc.data['readAt']) : null,
      channel: _parseChannel(doc.data['channel'] ?? 'app'),
      status: doc.data['status'] ?? 'sent',
      attachments: List<String>.from(doc.data['attachments'] ?? []),
      metadata: Map<String, dynamic>.from(doc.data['metadata'] ?? {}),
    );
  }

  /// Parse channel string to enum
  static MessageChannel _parseChannel(String channel) {
    switch (channel) {
      case 'email':
        return MessageChannel.email;
      case 'sms':
        return MessageChannel.sms;
      case 'all':
        return MessageChannel.all;
      default:
        return MessageChannel.app;
    }
  }

  /// Convert channel enum to string
  static String channelToString(MessageChannel channel) {
    switch (channel) {
      case MessageChannel.email:
        return 'email';
      case MessageChannel.sms:
        return 'sms';
      case MessageChannel.all:
        return 'all';
      default:
        return 'app';
    }
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'senderPhone': senderPhone ?? '',
      'receiverId': recipientId,
      'recipientName': recipientName,
      'recipientEmail': recipientEmail,
      'recipientPhone': recipientPhone ?? '',
      'content': content,
      'subject': subject ?? '',
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'channel': channelToString(channel),
      'status': status,
      'attachments': attachments,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  Message copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? senderPhone,
    String? recipientId,
    String? recipientName,
    String? recipientEmail,
    String? recipientPhone,
    String? content,
    String? subject,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
    MessageChannel? channel,
    String? status,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      senderPhone: senderPhone ?? this.senderPhone,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      content: content ?? this.content,
      subject: subject ?? this.subject,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      channel: channel ?? this.channel,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
    );
  }
}