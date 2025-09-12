import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/app_config.dart';
import 'appwrite_service.dart';

enum UserPresenceStatus {
  online,
  offline,
  away,
  busy,
}

class UserPresence {
  final String userId;
  final String userName;
  final UserPresenceStatus status;
  final DateTime lastSeen;
  final String? currentChatId;

  UserPresence({
    required this.userId,
    required this.userName,
    required this.status,
    required this.lastSeen,
    this.currentChatId,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'status': status.name,
      'lastSeen': lastSeen.toIso8601String(),
      'currentChatId': currentChatId,
    };
  }

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      status: UserPresenceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UserPresenceStatus.offline,
      ),
      lastSeen: DateTime.parse(json['lastSeen'] ?? DateTime.now().toIso8601String()),
      currentChatId: json['currentChatId'],
    );
  }

  UserPresence copyWith({
    String? userId,
    String? userName,
    UserPresenceStatus? status,
    DateTime? lastSeen,
    String? currentChatId,
  }) {
    return UserPresence(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      currentChatId: currentChatId ?? this.currentChatId,
    );
  }

  bool get isOnline {
    if (status == UserPresenceStatus.offline) return false;
    
    // Consider user offline if last seen was more than 5 minutes ago
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    return difference.inMinutes < 5;
  }

  String get statusText {
    if (!isOnline) return 'Offline';
    
    switch (status) {
      case UserPresenceStatus.online:
        return 'Online';
      case UserPresenceStatus.away:
        return 'Away';
      case UserPresenceStatus.busy:
        return 'Busy';
      case UserPresenceStatus.offline:
        return 'Offline';
    }
  }
}

class UserPresenceService {
  static final UserPresenceService _instance = UserPresenceService._internal();
  factory UserPresenceService() => _instance;
  UserPresenceService._internal();
  
  static UserPresenceService get instance => _instance;
  
  final AppwriteService _appwrite = AppwriteService.instance;
  
  // Stream controllers for real-time presence updates
  final Map<String, StreamController<UserPresence>> _presenceStreams = {};
  final Map<String, RealtimeSubscription> _presenceSubscriptions = {};
  
  // Current user presence management
  Timer? _heartbeatTimer;
  Timer? _awayTimer;
  String? _currentUserId;
  String? _currentUserName;
  UserPresenceStatus _currentStatus = UserPresenceStatus.online;
  String? _currentChatId;
  
  // Connectivity monitoring
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  
  // Cache for offline support
  final Map<String, UserPresence> _presenceCache = {};

  Future<void> initialize(String userId, String userName) async {
    _currentUserId = userId;
    _currentUserName = userName;
    
    // Monitor connectivity
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        // Coming back online - update presence
        _updatePresence(_currentStatus);
      } else if (wasOnline && !_isOnline) {
        // Going offline
        _setOfflineStatus();
      }
    });
    
    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
    
    if (_isOnline) {
      // Set initial online status
      await _updatePresence(UserPresenceStatus.online);
      
      // Start heartbeat to maintain presence
      _startHeartbeat();
      
      // Start away timer
      _startAwayTimer();
    }
  }

  // Update current user's presence status
  Future<void> updatePresenceStatus(UserPresenceStatus status, {String? chatId}) async {
    _currentStatus = status;
    _currentChatId = chatId;
    
    if (!_isOnline) {
      return; // Don't update if offline
    }
    
    await _updatePresence(status);
    
    // Reset away timer when user is active
    if (status == UserPresenceStatus.online) {
      _resetAwayTimer();
    }
  }

  // Set user as currently in a specific chat
  Future<void> setCurrentChat(String? chatId) async {
    _currentChatId = chatId;
    if (_isOnline) {
      await _updatePresence(_currentStatus);
    }
  }

  // Get presence for a specific user
  Future<UserPresence?> getUserPresence(String userId) async {
    try {
      if (!_isOnline && _presenceCache.containsKey(userId)) {
        return _presenceCache[userId];
      }

      final documents = await _appwrite.databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: 'user_presence', // You'll need to create this collection
        queries: [
          Query.equal('userId', userId),
          Query.limit(1),
        ],
      );

      if (documents.documents.isEmpty) {
        return null;
      }

      final presence = UserPresence.fromJson(documents.documents.first.data);
      _presenceCache[userId] = presence;
      return presence;
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('Error getting user presence: $e');
      }
      return _presenceCache[userId];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user presence: $e');
      }
      return _presenceCache[userId];
    }
  }

  // Get presence for multiple users
  Future<Map<String, UserPresence>> getMultipleUserPresence(List<String> userIds) async {
    final presences = <String, UserPresence>{};

    try {
      if (!_isOnline) {
        // Return cached data if offline
        for (final userId in userIds) {
          if (_presenceCache.containsKey(userId)) {
            presences[userId] = _presenceCache[userId]!;
          }
        }
        return presences;
      }

      final documents = await _appwrite.databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: 'user_presence',
        queries: [
          Query.equal('userId', userIds),
          Query.limit(100),
        ],
      );

      for (final doc in documents.documents) {
        final presence = UserPresence.fromJson(doc.data);
        presences[presence.userId] = presence;
        _presenceCache[presence.userId] = presence;
      }

      return presences;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting multiple user presence: $e');
      }
      
      // Return cached data on error
      for (final userId in userIds) {
        if (_presenceCache.containsKey(userId)) {
          presences[userId] = _presenceCache[userId]!;
        }
      }
      return presences;
    }
  }

  // Subscribe to presence updates for a user
  Stream<UserPresence> subscribeToUserPresence(String userId) {
    if (_presenceStreams.containsKey(userId)) {
      return _presenceStreams[userId]!.stream;
    }

    final controller = StreamController<UserPresence>.broadcast();
    _presenceStreams[userId] = controller;

    try {
      final subscription = _appwrite.realtime.subscribe([
        'databases.${AppConfig.databaseId}.collections.user_presence.documents'
      ]);

      subscription.stream.listen(
        (response) {
          try {
            if (response.events.contains('databases.*.collections.*.documents.*.create') ||
                response.events.contains('databases.*.collections.*.documents.*.update')) {
              final presenceData = response.payload;
              if (presenceData['userId'] == userId) {
                final presence = UserPresence.fromJson(presenceData);
                _presenceCache[userId] = presence;
                controller.add(presence);
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error processing real-time presence update: $e');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('Real-time presence subscription error: $error');
          }
          controller.addError(error);
        },
      );

      _presenceSubscriptions[userId] = subscription;
    } catch (e) {
      controller.addError(e);
    }

    return controller.stream;
  }

  // Subscribe to presence updates for multiple users
  Stream<Map<String, UserPresence>> subscribeToMultipleUserPresence(List<String> userIds) {
    final controller = StreamController<Map<String, UserPresence>>.broadcast();

    try {
      final subscription = _appwrite.realtime.subscribe([
        'databases.${AppConfig.databaseId}.collections.user_presence.documents'
      ]);

      subscription.stream.listen(
        (response) {
          try {
            if (response.events.contains('databases.*.collections.*.documents.*.create') ||
                response.events.contains('databases.*.collections.*.documents.*.update')) {
              final presenceData = response.payload;
              if (userIds.contains(presenceData['userId'])) {
                final presence = UserPresence.fromJson(presenceData);
                _presenceCache[presence.userId] = presence;
                
                // Send current cache for all requested users
                final presences = <String, UserPresence>{};
                for (final userId in userIds) {
                  if (_presenceCache.containsKey(userId)) {
                    presences[userId] = _presenceCache[userId]!;
                  }
                }
                controller.add(presences);
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error processing real-time presence update: $e');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('Real-time presence subscription error: $error');
          }
          controller.addError(error);
        },
      );
    } catch (e) {
      controller.addError(e);
    }

    return controller.stream;
  }

  // Private methods

  Future<void> _updatePresence(UserPresenceStatus status) async {
    if (_currentUserId == null || _currentUserName == null) return;

    try {
      final presence = UserPresence(
        userId: _currentUserId!,
        userName: _currentUserName!,
        status: status,
        lastSeen: DateTime.now(),
        currentChatId: _currentChatId,
      );

      // Try to update existing document first
      final documents = await _appwrite.databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: 'user_presence',
        queries: [
          Query.equal('userId', _currentUserId!),
          Query.limit(1),
        ],
      );

      if (documents.documents.isNotEmpty) {
        // Update existing
        await _appwrite.databases.updateDocument(
          databaseId: AppConfig.databaseId,
          collectionId: 'user_presence',
          documentId: documents.documents.first.$id,
          data: presence.toJson(),
        );
      } else {
        // Create new
        await _appwrite.databases.createDocument(
          databaseId: AppConfig.databaseId,
          collectionId: 'user_presence',
          documentId: ID.unique(),
          data: presence.toJson(),
        );
      }

      _presenceCache[_currentUserId!] = presence;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating presence: $e');
      }
    }
  }

  void _setOfflineStatus() {
    _currentStatus = UserPresenceStatus.offline;
    // Note: Can't update database when offline, will be updated when back online
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_isOnline && _currentStatus != UserPresenceStatus.offline) {
        _updatePresence(_currentStatus);
      }
    });
  }

  void _startAwayTimer() {
    _awayTimer?.cancel();
    _awayTimer = Timer(const Duration(minutes: 5), () {
      if (_currentStatus == UserPresenceStatus.online) {
        updatePresenceStatus(UserPresenceStatus.away);
      }
    });
  }

  void _resetAwayTimer() {
    _startAwayTimer();
  }

  // Mark user as offline when app is closing
  Future<void> setOffline() async {
    _heartbeatTimer?.cancel();
    _awayTimer?.cancel();
    
    if (_isOnline) {
      await _updatePresence(UserPresenceStatus.offline);
    }
  }

  // Cleanup methods
  void cancelPresenceSubscription(String userId) {
    _presenceSubscriptions[userId]?.close();
    _presenceSubscriptions.remove(userId);
    _presenceStreams[userId]?.close();
    _presenceStreams.remove(userId);
  }

  void cancelAllPresenceSubscriptions() {
    for (final subscription in _presenceSubscriptions.values) {
      subscription.close();
    }
    for (final stream in _presenceStreams.values) {
      stream.close();
    }
    
    _presenceSubscriptions.clear();
    _presenceStreams.clear();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _heartbeatTimer?.cancel();
    _awayTimer?.cancel();
    cancelAllPresenceSubscriptions();
    _presenceCache.clear();
  }
}