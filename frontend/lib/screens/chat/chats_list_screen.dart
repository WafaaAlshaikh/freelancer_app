// lib/screens/chat/chats_list_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelancer_platform/models/message_model.dart';
import 'dart:async';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import '../../services/socket_service.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  List<ChatModel> chats = [];
  bool loading = true;
  int unreadCount = 0;
  
  final SocketService _socket = SocketService.instance;
  
  StreamSubscription? _chatsSubscription;
  StreamSubscription? _newMessageSubscription;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _chatsSubscription = _socket.onChatsUpdate.listen((updatedChats) {
      if (!mounted) return;
      setState(() {
        chats = updatedChats;
        _updateUnreadCount(updatedChats);
      });
    });
    
  
    _newMessageSubscription = _socket.onNewMessage.listen((message) {
      if (!mounted) return;
      _updateUnreadCountFromMessage(message);
    });
  }
  
  void _updateUnreadCountFromMessage(Message message) {
    final chatIndex = chats.indexWhere((c) => c.id == message.chatId);
    if (chatIndex != -1 && mounted) {
      setState(() {
        final updatedChat = chats[chatIndex];
        final newUnreadCount = updatedChat.unreadCount + 1;
        final newChats = List<ChatModel>.from(chats);
        newChats[chatIndex] = ChatModel(
          id: updatedChat.id,
          uniqueId: updatedChat.uniqueId,
          otherUser: updatedChat.otherUser,
          lastMessage: message.content,
          lastMessageTime: message.createdAt,
          lastMessageSenderId: message.senderId,
          unreadCount: newUnreadCount,
          lastMessages: updatedChat.lastMessages,
          createdAt: updatedChat.createdAt,
          updatedAt: DateTime.now(),
        );
        chats = newChats;
        _updateUnreadCount(chats);
      });
    }
  }

  Future<void> _loadChats() async {
    if (!mounted) return;
    
    setState(() => loading = true);
    
    try {
      final loadedChats = await ChatService.getUserChats();
      if (!mounted) return;
      
      setState(() {
        chats = loadedChats;
        _updateUnreadCount(loadedChats);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void _updateUnreadCount(List<ChatModel> chatsList) {
    unreadCount = chatsList.fold(0, (sum, chat) => sum + chat.unreadCount);
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _newMessageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6F8),
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xff14A800),
              ),
            )
          : chats.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  color: const Color(0xff14A800),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return _buildChatCard(chat);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation from a project',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/projects');
            },
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Find Projects'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff14A800),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(ChatModel chat) {
    final otherUser = chat.otherUser;
    final isUnread = chat.unreadCount > 0;
    final lastMessage = chat.lastMessage ?? 'No messages yet';
    final lastMessageTime = chat.lastMessageTime;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () async {
          _socket.markAsRead(chat.id);
          
          if (otherUser != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: chat.id,
                  otherUser: otherUser,
                ),
              ),
            );
            
            if (result == true && mounted) {
              _loadChats();
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: otherUser?.avatar != null && otherUser!.avatar!.isNotEmpty
                        ? NetworkImage(otherUser.avatar!)
                        : null,
                    child: otherUser?.avatar == null || otherUser!.avatar!.isEmpty
                        ? Text(
                            otherUser?.name?.isNotEmpty == true
                                ? otherUser!.name![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  if (isUnread)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xff14A800),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherUser?.name ?? 'Unknown User',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMessageTime != null)
                          Text(
                            _formatTime(lastMessageTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: isUnread ? Colors.black54 : Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isUnread ? Colors.black87 : Colors.grey.shade600,
                              fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xff14A800),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${chat.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 7) {
      return '${time.day}/${time.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}