import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'appwrite_service.dart';
import '../config/app_config.dart';

enum MessageChannel {
  inApp,
  email,
  sms,
  all,
}

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String recipientName;
  final String content;
  final DateTime timestamp;
  final MessageChannel channel;
  final bool isRead;
  final String? subject;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.recipientName,
    required this.content,
    required this.timestamp,
    required this.channel,
    this.isRead = false,
    this.subject,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'channel': channel.toString(),
      'isRead': isRead,
      'subject': subject,
      'metadata': metadata,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      recipientId: json['recipientId'],
      recipientName: json['recipientName'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      channel: MessageChannel.values.firstWhere(
        (e) => e.toString() == json['channel'],
        orElse: () => MessageChannel.inApp,
      ),
      isRead: json['isRead'] ?? false,
      subject: json['subject'],
      metadata: json['metadata'],
    );
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? recipientId,
    String? recipientName,
    String? content,
    DateTime? timestamp,
    MessageChannel? channel,
    bool? isRead,
    String? subject,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      channel: channel ?? this.channel,
      isRead: isRead ?? this.isRead,
      subject: subject ?? this.subject,
      metadata: metadata ?? this.metadata,
    );
  }
}

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  static const String _messagesKey = 'messages';
  static const String _conversationsKey = 'conversations';

  final AppwriteService _appwrite = AppwriteService.instance;

  // Email configuration (using EmailJS or similar service)
  static const String _emailServiceUrl = 'https://api.emailjs.com/api/v1.0/email/send';
  static const String _emailServiceId = 'service_christycares';
  static const String _emailTemplateId = 'template_message';
  static const String _emailUserId = 'user_christycares';

  // SMS configuration (using Twilio API)
  static const String _twilioAccountSid = 'YOUR_TWILIO_ACCOUNT_SID';
  static const String _twilioAuthToken = 'YOUR_TWILIO_AUTH_TOKEN';
  static const String _twilioFromNumber = '+1234567890';
  static const String _twilioApiUrl = 'https://api.twilio.com/2010-04-01/Accounts';

  // Send message through all channels
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String recipientId,
    required String recipientName,
    required String content,
    String? subject,
    MessageChannel channel = MessageChannel.all,
    String? recipientEmail,
    String? recipientPhone,
    Map<String, dynamic>? metadata,
  }) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    final message = Message(
      id: messageId,
      senderId: senderId,
      senderName: senderName,
      recipientId: recipientId,
      recipientName: recipientName,
      content: content,
      timestamp: DateTime.now(),
      channel: channel,
      subject: subject ?? 'New message from $senderName',
      metadata: metadata,
    );

    // Save to local storage and Appwrite
    await _saveMessageLocally(message);
    await _saveMessageToAppwrite(message);

    // Send through requested channels
    if (channel == MessageChannel.all || channel == MessageChannel.email) {
      if (recipientEmail != null) {
        await _sendEmail(message, recipientEmail);
      }
    }

    if (channel == MessageChannel.all || channel == MessageChannel.sms) {
      if (recipientPhone != null) {
        await _sendSMS(message, recipientPhone);
      }
    }
  }

  // Save message locally
  Future<void> _saveMessageLocally(Message message) async {
    final prefs = await SharedPreferences.getInstance();
    final messages = await getLocalMessages();
    messages.add(message);

    final messagesJson = messages
        .map((msg) => jsonEncode(msg.toJson()))
        .toList();

    await prefs.setStringList(_messagesKey, messagesJson);
  }

  // Save message to Appwrite for sync
  Future<void> _saveMessageToAppwrite(Message message) async {
    try {
      await _appwrite.databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        documentId: message.id,
        data: message.toJson(),
      );
    } catch (e) {
      print('Failed to save message to Appwrite: $e');
    }
  }

  // Send email using EmailJS
  Future<void> _sendEmail(Message message, String recipientEmail) async {
    try {
      final emailData = {
        'service_id': _emailServiceId,
        'template_id': _emailTemplateId,
        'user_id': _emailUserId,
        'template_params': {
          'to_email': recipientEmail,
          'to_name': message.recipientName,
          'from_name': message.senderName,
          'subject': message.subject,
          'message': message.content,
          'reply_to': 'christina@christycares.com',
        },
      };

      final response = await http.post(
        Uri.parse(_emailServiceUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(emailData),
      );

      if (response.statusCode != 200) {
        print('Failed to send email: ${response.body}');
      }
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  // Send SMS using Twilio
  Future<void> _sendSMS(Message message, String recipientPhone) async {
    try {
      // Clean phone number (remove non-digits)
      final cleanPhone = recipientPhone.replaceAll(RegExp(r'[^\d+]'), '');

      final twilioUrl = '$_twilioApiUrl/$_twilioAccountSid/Messages.json';

      final smsData = {
        'From': _twilioFromNumber,
        'To': cleanPhone,
        'Body': '${message.senderName}: ${message.content}\n\nReply in app: christycares.com',
      };

      final response = await http.post(
        Uri.parse(twilioUrl),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_twilioAccountSid:$_twilioAuthToken'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: Uri(queryParameters: smsData).query,
      );

      if (response.statusCode != 201) {
        print('Failed to send SMS: ${response.body}');
      }
    } catch (e) {
      print('Error sending SMS: $e');
    }
  }

  // Get local messages
  Future<List<Message>> getLocalMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getStringList(_messagesKey) ?? [];

    return messagesJson
        .map((json) => Message.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get messages from Appwrite (for sync)
  Future<List<Message>> getSyncedMessages(String userId) async {
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: 'messages',
        queries: [
          'equal("recipientId", "$userId")',
          'orderDesc("timestamp")',
        ],
      );

      return response.documents
          .map((doc) => Message.fromJson(doc.data))
          .toList();
    } catch (e) {
      print('Failed to get synced messages: $e');
      return [];
    }
  }

  // Get conversation between two users
  Future<List<Message>> getConversation(String userId1, String userId2) async {
    final messages = await getLocalMessages();

    return messages.where((msg) =>
      (msg.senderId == userId1 && msg.recipientId == userId2) ||
      (msg.senderId == userId2 && msg.recipientId == userId1)
    ).toList();
  }

  // Mark message as read
  Future<void> markAsRead(String messageId) async {
    final messages = await getLocalMessages();
    final index = messages.indexWhere((msg) => msg.id == messageId);

    if (index != -1) {
      messages[index] = messages[index].copyWith(isRead: true);

      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages
          .map((msg) => jsonEncode(msg.toJson()))
          .toList();

      await prefs.setStringList(_messagesKey, messagesJson);

      // Update in Appwrite
      try {
        await _appwrite.databases.updateDocument(
          databaseId: AppConfig.databaseId,
          collectionId: 'messages',
          documentId: messageId,
          data: {'isRead': true},
        );
      } catch (e) {
        print('Failed to mark message as read in Appwrite: $e');
      }
    }
  }

  // Get unread message count
  Future<int> getUnreadCount(String userId) async {
    final messages = await getLocalMessages();
    return messages.where((msg) =>
      msg.recipientId == userId && !msg.isRead
    ).length;
  }

  // Open SMS app with pre-filled message
  Future<void> openSMSApp(String phoneNumber, String message) async {
    final uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // Open email app with pre-filled message
  Future<void> openEmailApp(String email, String subject, String body) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // Sync messages from all channels
  Future<void> syncMessages(String userId) async {
    // Get messages from Appwrite
    final syncedMessages = await getSyncedMessages(userId);

    // Merge with local messages
    final localMessages = await getLocalMessages();
    final allMessageIds = <String>{};
    final mergedMessages = <Message>[];

    // Add all messages, avoiding duplicates
    for (final msg in [...syncedMessages, ...localMessages]) {
      if (!allMessageIds.contains(msg.id)) {
        allMessageIds.add(msg.id);
        mergedMessages.add(msg);
      }
    }

    // Save merged messages locally
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = mergedMessages
        .map((msg) => jsonEncode(msg.toJson()))
        .toList();

    await prefs.setStringList(_messagesKey, messagesJson);
  }

  // Clear all local messages (for logout)
  Future<void> clearLocalMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_messagesKey);
    await prefs.remove(_conversationsKey);
  }
}