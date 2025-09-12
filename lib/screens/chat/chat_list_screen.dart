import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_message.dart';
import '../../services/user_presence_service.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChats();
      _subscribeToPresence();
    });
  }

  void _loadChats() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      ref.read(chatListProvider.notifier).loadUserChats(currentUser.$id);
    }
  }

  void _subscribeToPresence() {
    final chatListState = ref.read(chatListProvider);
    final userIds = <String>{};
    
    for (final chat in chatListState.chats) {
      userIds.add(chat.patientId);
      userIds.add(chat.caregiverId);
    }
    
    if (userIds.isNotEmpty) {
      ref.read(userPresenceProvider.notifier).subscribeToMultipleUserPresence(userIds.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final chatListState = ref.watch(chatListProvider);
    final currentUser = ref.watch(currentUserProvider);
    final totalUnreadCount = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Messages'),
            if (totalUnreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalUnreadCount',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(chatListProvider.notifier).refreshChats(),
            tooltip: 'Refresh chats',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'archived':
                  _showFeatureNotAvailable('Archived chats');
                  break;
                case 'search':
                  _showFeatureNotAvailable('Search chats');
                  break;
                case 'new_chat':
                  _showCreateChatDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_chat',
                child: Row(
                  children: [
                    Icon(Icons.add_comment),
                    SizedBox(width: 8),
                    Text('New Chat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('Search'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'archived',
                child: Row(
                  children: [
                    Icon(Icons.archive),
                    SizedBox(width: 8),
                    Text('Archived'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(chatListProvider.notifier).refreshChats();
        },
        child: _buildBody(context, chatListState, currentUser),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateChatDialog,
        tooltip: 'Start new chat',
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChatListState chatListState, currentUser) {
    if (chatListState.isLoading && chatListState.chats.isEmpty) {
      return _buildLoadingState();
    }

    if (chatListState.error != null) {
      return _buildErrorState(context, chatListState.error!);
    }

    if (chatListState.chats.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chatListState.chats.length,
      itemBuilder: (context, index) {
        final chat = chatListState.chats[index];
        final unreadCount = ref.watch(chatUnreadCountProvider(chat.id));
        return _buildChatListItem(context, chat, currentUser?.$id, unreadCount);
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) => _buildShimmerItem(),
    );
  }

  Widget _buildShimmerItem() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: const CircleAvatar(radius: 28),
          title: Container(
            height: 16,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 12,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          trailing: Container(
            height: 12,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading chats',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => ref.read(chatListProvider.notifier).clearError(),
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _loadChats,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start chatting with caregivers after booking services or create a new conversation',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.7).round()),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _showCreateChatDialog,
                  icon: const Icon(Icons.add_comment),
                  label: const Text('Start New Chat'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.search),
                  label: const Text('Find Caregivers'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatListItem(BuildContext context, Chat chat, String? currentUserId, int unreadCount) {
    final otherUserId = chat.getOtherUserId(currentUserId ?? '');
    final otherUserName = chat.getOtherUserName(currentUserId ?? '');
    final otherUserAvatar = chat.getOtherUserAvatar(currentUserId ?? '');
    final isPatientView = currentUserId == chat.patientId;
    final userOnline = ref.watch(userOnlineStatusProvider(otherUserId));
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Mark chat as read when opening
          ref.read(chatListProvider.notifier).resetUnreadCount(chat.id);
          context.push('/chat/${chat.id}');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with online status
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isPatientView
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                    backgroundImage: otherUserAvatar != null
                        ? CachedNetworkImageProvider(otherUserAvatar)
                        : null,
                    child: otherUserAvatar == null
                        ? Icon(
                            isPatientView ? Icons.medical_services : Icons.person,
                            color: Colors.white,
                            size: 28,
                          )
                        : null,
                  ),
                  // Online status indicator
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: userOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and role
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherUserName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (userOnline)
                          Text(
                            'Online',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isPatientView 
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.primary).withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPatientView ? 'Caregiver' : 'Patient/Family',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isPatientView 
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Last message or status
                    _buildLastMessagePreview(context, chat, unreadCount),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Time and unread indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatChatDate(chat.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: unreadCount > 0 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                      fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastMessagePreview(BuildContext context, Chat chat, int unreadCount) {
    if (chat.lastMessage == null) {
      return Text(
        'Tap to start chatting',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round()),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final message = chat.lastMessage!;
    final isOwnMessage = ref.watch(currentUserProvider)?.$id == message.senderId;
    
    String preview = '';
    IconData? messageIcon;

    switch (message.type) {
      case MessageType.text:
        preview = message.content;
        break;
      case MessageType.image:
        preview = 'Photo';
        messageIcon = Icons.image;
        break;
      case MessageType.file:
        preview = 'File: ${message.fileName ?? 'Document'}';
        messageIcon = Icons.attach_file;
        break;
      case MessageType.audio:
        preview = 'Voice message';
        messageIcon = Icons.mic;
        break;
      case MessageType.video:
        preview = 'Video';
        messageIcon = Icons.videocam;
        break;
      case MessageType.system:
        preview = message.content;
        messageIcon = Icons.info_outline;
        break;
    }

    if (isOwnMessage && message.type == MessageType.text) {
      preview = 'You: $preview';
    }

    return Row(
      children: [
        if (messageIcon != null) ...[
          Icon(
            messageIcon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round()),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            preview,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: unreadCount > 0 
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.7).round()),
              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isOwnMessage && message.type == MessageType.text) ...[
          const SizedBox(width: 4),
          Icon(
            _getDeliveryStatusIcon(message.deliveryStatus),
            size: 16,
            color: _getDeliveryStatusColor(context, message.deliveryStatus),
          ),
        ],
      ],
    );
  }

  IconData _getDeliveryStatusIcon(MessageDeliveryStatus status) {
    switch (status) {
      case MessageDeliveryStatus.pending:
        return Icons.schedule;
      case MessageDeliveryStatus.sending:
        return Icons.schedule;
      case MessageDeliveryStatus.delivered:
        return Icons.check;
      case MessageDeliveryStatus.read:
        return Icons.done_all;
      case MessageDeliveryStatus.failed:
        return Icons.error_outline;
    }
  }

  Color _getDeliveryStatusColor(BuildContext context, MessageDeliveryStatus status) {
    switch (status) {
      case MessageDeliveryStatus.pending:
        return Colors.orange;
      case MessageDeliveryStatus.sending:
        return Colors.blue;
      case MessageDeliveryStatus.delivered:
        return Colors.grey;
      case MessageDeliveryStatus.read:
        return Colors.blue;
      case MessageDeliveryStatus.failed:
        return Theme.of(context).colorScheme.error;
    }
  }

  String _formatChatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat('h:mm a').format(date);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat('EEEE').format(date);
    } else {
      // Older - show date
      return DateFormat('MMM d').format(date);
    }
  }

  void _showCreateChatDialog() {
    _showFeatureNotAvailable('Create new chat');
  }

  void _showFeatureNotAvailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}