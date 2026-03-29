// lib/screens/chat/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelancer_platform/utils/token_storage.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../services/socket_service.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final User otherUser;

  const ChatScreen({super.key, required this.chatId, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> messages = [];
  bool loading = true;
  bool hasMore = true;
  int currentPage = 0;
  final int pageSize = 20;

  int? currentUserId;
  bool _isOtherTyping = false;
  Timer? _typingTimer;
  bool _isSending = false;

  StreamSubscription? _newMessageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _readReceiptSubscription;
  StreamSubscription? _connectionSubscription;
  bool _listenersSetup = false;

  final SocketService _socket = SocketService.instance;

  final Set<int> _receivedMessageIds = {};

  @override
  void initState() {
    super.initState();
    _initAndLoad();
    _messageController.addListener(_onMessageChanged);
  }

  Future<void> _initAndLoad() async {
    final userIdStr = await TokenStorage.getUserId();
    if (mounted) {
      setState(() {
        currentUserId = userIdStr != null ? int.tryParse(userIdStr) : null;
      });
    }
    await _loadMessages();
    _setupSocketListeners();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;

    setState(() => loading = true);

    try {
      final result = await ChatService.getMessages(
        chatId: widget.chatId,
        limit: pageSize,
        offset: currentPage * pageSize,
      );

      if (!mounted) return;

      final newMessages = (result['messages'] as List)
          .map((json) => Message.fromJson(json))
          .toList();

      for (var msg in newMessages) {
        _receivedMessageIds.add(msg.id);
      }

      setState(() {
        messages.insertAll(0, newMessages);
        hasMore = result['hasMore'] ?? false;
        if (newMessages.isNotEmpty) currentPage++;
        loading = false;
      });

      _scrollToBottom();
      _socket.markAsRead(widget.chatId);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void _setupSocketListeners() {
    _newMessageSubscription?.cancel();
    _typingSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _connectionSubscription?.cancel();

    if (_socket.isConnected) {
      _socket.joinChat(widget.chatId);
    }

    _connectionSubscription = _socket.onConnectionChange.listen((connected) {
      if (connected && mounted) {
        _socket.joinChat(widget.chatId);
      }
    });

    _newMessageSubscription = _socket.onNewMessage.listen((message) {
      if (!mounted) return;
      if (_receivedMessageIds.contains(message.id)) return;
      _receivedMessageIds.add(message.id);

      if (message.chatId == widget.chatId) {
        setState(() => messages.add(message));
        _scrollToBottom();
        _socket.markAsRead(widget.chatId);
      }
    });

    _typingSubscription = _socket.onTyping.listen((data) {
      if (!mounted) return;
      if (data['userId'] == currentUserId) return;
      if (data['chatId'] == widget.chatId) {
        setState(() => _isOtherTyping = data['isTyping'] ?? false);
      }
    });

    _readReceiptSubscription = _socket.onReadReceipt.listen((data) {
      if (!mounted) return;
      if (data['chatId'] == widget.chatId) {
        setState(() {
          for (var message in messages) {
            if (message.senderId == data['userId'] &&
                !message.readBy.contains(data['userId'])) {
              message.readBy.add(data['userId']);
            }
          }
        });
      }
    });
  }

  void _onMessageChanged() {
    if (_typingTimer != null) _typingTimer!.cancel();

    if (_messageController.text.isNotEmpty) {
      _socket.sendTyping(widget.chatId, true);

      _typingTimer = Timer(const Duration(seconds: 2), () {
        _socket.sendTyping(widget.chatId, false);
      });
    }
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && messages.isNotEmpty) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    _isSending = true;
    _messageController.clear();

    if (!_socket.isConnected) {
      final connected = await _socket.ensureConnection();
      if (!connected) {
        Fluttertoast.showToast(msg: 'Could not connect. Please try again.');
        _messageController.text = content;
        _isSending = false;
        return;
      }
      _socket.joinChat(widget.chatId);
    }

    _socket.sendMessage(chatId: widget.chatId, content: content);
    _isSending = false;
  }

  void _loadMore() {
    if (hasMore && !loading && mounted) {
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _newMessageSubscription?.cancel();
    _typingSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _connectionSubscription?.cancel(); 
    _socket.leaveChat(widget.chatId);
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  widget.otherUser.avatar != null &&
                      widget.otherUser.avatar!.isNotEmpty
                  ? NetworkImage(widget.otherUser.avatar!)
                  : null,
              child:
                  widget.otherUser.avatar == null ||
                      widget.otherUser.avatar!.isEmpty
                  ? Text(
                      widget.otherUser.name?[0].toUpperCase() ?? '?',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isOtherTyping ? 'Typing...' : 'Online',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isOtherTyping ? Colors.green : Colors.grey,
                      fontStyle: _isOtherTyping
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isOtherTyping)
            Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(width: 56),
                  Text(
                    '${widget.otherUser.name} is typing...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: loading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? _buildEmptyMessages()
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels <= 0 &&
                          hasMore &&
                          !loading &&
                          mounted) {
                        _loadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - 1 - index];
                        final isMe = message.senderId == currentUserId;
                        return _buildMessageBubble(message, isMe);
                      },
                    ),
                  ),
          ),

          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    print(
      'Message from: ${message.senderId}, currentUser: $currentUserId, isMe: $isMe',
    );
    final alignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final color = isMe ? const Color(0xff14A800) : Colors.grey.shade200;
    final textColor = isMe ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  message.senderAvatar != null &&
                      message.senderAvatar!.isNotEmpty
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child:
                  message.senderAvatar == null || message.senderAvatar!.isEmpty
                  ? Text(
                      message.senderName.isNotEmpty
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    )
                  : null,
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && message.senderName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        message.senderName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  Text(message.content, style: TextStyle(color: textColor)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.readBy.length > 1
                              ? Icons.done_all
                              : Icons.done,
                          size: 12,
                          color: message.readBy.length > 1
                              ? Colors.lightBlueAccent
                              : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: () {
              Fluttertoast.showToast(msg: 'File upload coming soon');
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xff14A800),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
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
