enum MessageType {
  text,
  image,
  system,
  file,
  audio,
  video,
}

enum MessageDeliveryStatus {
  pending,   // Message is waiting to be sent (offline)
  sending,   // Message is being sent
  delivered, // Message has been delivered to server
  read,      // Message has been read by recipient
  failed,    // Message failed to send
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final MessageDeliveryStatus deliveryStatus;
  final String? replyToId;
  final ChatMessage? replyToMessage;
  final Map<String, dynamic>? metadata;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? thumbnailUrl;
  final Duration? audioDuration;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.deliveryStatus = MessageDeliveryStatus.delivered,
    this.replyToId,
    this.replyToMessage,
    this.metadata,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.thumbnailUrl,
    this.audioDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'deliveryStatus': deliveryStatus.name,
      'replyToId': replyToId,
      'metadata': metadata,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
      'audioDuration': audioDuration?.inMilliseconds,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['\$id'] ?? json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      deliveryStatus: MessageDeliveryStatus.values.firstWhere(
        (e) => e.name == json['deliveryStatus'],
        orElse: () => MessageDeliveryStatus.delivered,
      ),
      replyToId: json['replyToId'],
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      thumbnailUrl: json['thumbnailUrl'],
      audioDuration: json['audioDuration'] != null 
          ? Duration(milliseconds: json['audioDuration']) 
          : null,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    MessageDeliveryStatus? deliveryStatus,
    String? replyToId,
    ChatMessage? replyToMessage,
    Map<String, dynamic>? metadata,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? thumbnailUrl,
    Duration? audioDuration,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      metadata: metadata ?? this.metadata,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      audioDuration: audioDuration ?? this.audioDuration,
    );
  }

  bool get isSystemMessage => type == MessageType.system;
  bool get hasFile => fileUrl != null;
  bool get isImage => type == MessageType.image;
  bool get isAudio => type == MessageType.audio;
  bool get isVideo => type == MessageType.video;
  bool get hasReply => replyToId != null;
  bool get isPending => deliveryStatus == MessageDeliveryStatus.pending;
  bool get isFailed => deliveryStatus == MessageDeliveryStatus.failed;
  bool get isSending => deliveryStatus == MessageDeliveryStatus.sending;

  String get fileDisplaySize {
    if (fileSize == null) return '';
    
    final kb = fileSize! / 1024;
    final mb = kb / 1024;
    
    if (mb >= 1) {
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      return '${kb.toStringAsFixed(0)} KB';
    }
  }

  String get audioDurationText {
    if (audioDuration == null) return '';
    
    final minutes = audioDuration!.inMinutes;
    final seconds = audioDuration!.inSeconds % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, type: $type, timestamp: $timestamp)';
  }
}

class Chat {
  final String id;
  final String bookingId;
  final String patientId;
  final String caregiverId;
  final String patientName;
  final String caregiverName;
  final String? patientAvatar;
  final String? caregiverAvatar;
  final ChatMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  Chat({
    required this.id,
    required this.bookingId,
    required this.patientId,
    required this.caregiverId,
    required this.patientName,
    required this.caregiverName,
    this.patientAvatar,
    this.caregiverAvatar,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.isActive = true,
    this.metadata,
  });

  String getOtherUserName(String currentUserId) {
    return currentUserId == patientId ? caregiverName : patientName;
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == patientId ? caregiverId : patientId;
  }

  String? getOtherUserAvatar(String currentUserId) {
    return currentUserId == patientId ? caregiverAvatar : patientAvatar;
  }

  bool isUserPatient(String userId) {
    return userId == patientId;
  }

  bool isUserCaregiver(String userId) {
    return userId == caregiverId;
  }

  String getUserRole(String userId) {
    if (isUserPatient(userId)) return 'Patient/Family';
    if (isUserCaregiver(userId)) return 'Caregiver';
    return 'Unknown';
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'patientId': patientId,
      'caregiverId': caregiverId,
      'patientName': patientName,
      'caregiverName': caregiverName,
      'patientAvatar': patientAvatar,
      'caregiverAvatar': caregiverAvatar,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['\$id'] ?? json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      patientId: json['patientId'] ?? '',
      caregiverId: json['caregiverId'] ?? '',
      patientName: json['patientName'] ?? '',
      caregiverName: json['caregiverName'] ?? '',
      patientAvatar: json['patientAvatar'],
      caregiverAvatar: json['caregiverAvatar'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String()),
      unreadCount: json['unreadCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

  Chat copyWith({
    String? id,
    String? bookingId,
    String? patientId,
    String? caregiverId,
    String? patientName,
    String? caregiverName,
    String? patientAvatar,
    String? caregiverAvatar,
    ChatMessage? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return Chat(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      patientName: patientName ?? this.patientName,
      caregiverName: caregiverName ?? this.caregiverName,
      patientAvatar: patientAvatar ?? this.patientAvatar,
      caregiverAvatar: caregiverAvatar ?? this.caregiverAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Chat(id: $id, patientName: $patientName, caregiverName: $caregiverName)';
  }
}

// Typing indicator model
class TypingIndicator {
  final String chatId;
  final String userId;
  final String userName;
  final bool isTyping;
  final DateTime timestamp;

  TypingIndicator({
    required this.chatId,
    required this.userId,
    required this.userName,
    required this.isTyping,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'userId': userId,
      'userName': userName,
      'isTyping': isTyping,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      chatId: json['chatId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      isTyping: json['isTyping'] ?? false,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Check if typing indicator is still valid (within 5 seconds)
  bool get isValid {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inSeconds <= 5;
  }
}

// Chat statistics model
class ChatStatistics {
  final String chatId;
  final int totalMessages;
  final int unreadMessages;
  final DateTime? lastMessageAt;
  final DateTime? lastReadAt;
  final Map<String, int> messagesByType;
  final Map<String, int> messagesByUser;

  ChatStatistics({
    required this.chatId,
    required this.totalMessages,
    required this.unreadMessages,
    this.lastMessageAt,
    this.lastReadAt,
    required this.messagesByType,
    required this.messagesByUser,
  });

  factory ChatStatistics.empty(String chatId) {
    return ChatStatistics(
      chatId: chatId,
      totalMessages: 0,
      unreadMessages: 0,
      messagesByType: {},
      messagesByUser: {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'totalMessages': totalMessages,
      'unreadMessages': unreadMessages,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastReadAt': lastReadAt?.toIso8601String(),
      'messagesByType': messagesByType,
      'messagesByUser': messagesByUser,
    };
  }

  factory ChatStatistics.fromJson(Map<String, dynamic> json) {
    return ChatStatistics(
      chatId: json['chatId'] ?? '',
      totalMessages: json['totalMessages'] ?? 0,
      unreadMessages: json['unreadMessages'] ?? 0,
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.parse(json['lastMessageAt']) 
          : null,
      lastReadAt: json['lastReadAt'] != null 
          ? DateTime.parse(json['lastReadAt']) 
          : null,
      messagesByType: Map<String, int>.from(json['messagesByType'] ?? {}),
      messagesByUser: Map<String, int>.from(json['messagesByUser'] ?? {}),
    );
  }
}