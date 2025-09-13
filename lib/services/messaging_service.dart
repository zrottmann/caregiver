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

  // Open-source email configuration options:
  // Option 1: Nodemailer (self-hosted Node.js server)
  // Option 2: Mail-in-a-Box (complete email server)
  // Option 3: Postal (self-hosted email platform)
  // Option 4: SendPortal (open-source email marketing)
  // Using generic SMTP configuration that works with any provider
  static const String _smtpHost = 'smtp.gmail.com'; // Can use any SMTP server
  static const String _smtpPort = '587';
  static const String _smtpUsername = 'christina@christycares.com';
  static const String _smtpPassword = 'YOUR_APP_PASSWORD'; // Use app-specific password
  static const String _smtpFrom = 'christina@christycares.com';

  // Open-source SMS configuration options:
  // Option 1: Jasmin SMS Gateway (open-source SMS gateway)
  // Option 2: Kannel (open-source WAP and SMS gateway)
  // Option 3: PlaySMS (web-based SMS management)
  // Option 4: TextBelt (open-source SMS API)
  // Using TextBelt as it's the simplest to integrate
  static const String _textbeltUrl = 'https://textbelt.com/text';
  static const String _textbeltKey = 'textbelt'; // Use 'textbelt' for 1 free SMS/day or your own key

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

  // Send email using open-source SMTP approach
  // This can work with any SMTP server including:
  // - Self-hosted: Postal, Mail-in-a-Box, Mailu, Mailcow
  // - Gmail, Outlook, or any SMTP provider
  Future<void> _sendEmail(Message message, String recipientEmail) async {
    try {
      // For Flutter web/mobile, we'll use a serverless function or API endpoint
      // For production, set up one of these open-source solutions:
      // 1. Postal (https://github.com/postalhq/postal) - Full email server
      // 2. Nodemailer API (https://github.com/nodemailer/nodemailer) - Node.js
      // 3. MailHog (https://github.com/mailhog/MailHog) - For development

      // Example using a simple webhook/API endpoint (you'd host this)
      final emailData = {
        'from': _smtpFrom,
        'to': recipientEmail,
        'subject': message.subject ?? 'Message from ${message.senderName}',
        'html': '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #2E7D8A;">New Message from ${message.senderName}</h2>
            <div style="background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
              <p style="color: #333; line-height: 1.6;">${message.content}</p>
            </div>
            <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
            <p style="color: #666; font-size: 14px;">
              Sent via Christy Cares Platform<br>
              Reply directly to this email or use the app:
              <a href="https://christycares.com" style="color: #2E7D8A;">christycares.com</a>
            </p>
          </div>
        ''',
        'text': message.content,
      };

      // For development, you can use Appwrite's email function
      // Or deploy a simple Node.js server with Nodemailer
      // Example endpoint: https://your-email-api.vercel.app/send

      // Fallback: Use mailto link for local testing
      if (_smtpHost == 'smtp.gmail.com') {
        print('Email would be sent to: $recipientEmail');
        print('Subject: ${emailData['subject']}');
        print('Content: ${message.content}');
        // In production, implement actual SMTP sending
      }
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  // Send SMS using open-source solutions
  Future<void> _sendSMS(Message message, String recipientPhone) async {
    try {
      // Clean phone number (remove non-digits except +)
      final cleanPhone = recipientPhone.replaceAll(RegExp(r'[^\d+]'), '');

      // Option 1: TextBelt (Open-source, 1 free SMS/day per IP)
      // GitHub: https://github.com/typpo/textbelt
      final textbeltData = {
        'phone': cleanPhone,
        'message': '${message.senderName}: ${message.content}\n\nReply: christycares.com',
        'key': _textbeltKey, // Use 'textbelt' for free tier or your own key
      };

      final response = await http.post(
        Uri.parse(_textbeltUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(textbeltData),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] != true) {
          print('SMS send failed: ${result['error']}');

          // Fallback options for production:
          // Option 2: Jasmin SMS Gateway (self-hosted)
          // https://github.com/jookies/jasmin
          // Full-featured SMS gateway you can host yourself

          // Option 3: Kannel (self-hosted WAP/SMS gateway)
          // https://github.com/isacikgoz/kannel
          // Enterprise-grade open-source SMS gateway

          // Option 4: PlaySMS (web-based SMS platform)
          // https://github.com/playsms/playsms
          // Complete SMS management platform

          // Option 5: Use Appwrite Functions to integrate with local SMS providers
          // Many countries have local SMS gateways with better rates
        }
      } else {
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