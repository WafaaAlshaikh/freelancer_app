// lib/screens/chat/chats_list_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelancer_platform/models/message_model.dart';
import 'dart:async';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import '../../services/socket_service.dart';
import 'chat_screen.dart';

class _C {
  static const sidebarBg = Color(0xFF2D2B55);
  static const sidebarText = Color(0xFFC8C6E8);
  static const accent = Color(0xFF6C63FF);
  static const accentDark = Color(0xFF4F46E5);
  static const accentLight = Color(0xFFA78BFA);
  static const accentBg = Color(0xFFEEF2FF);
  static const green = Color(0xFF14A800);
  static const greenBg = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFFFBEB);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const infoBg = Color(0xFFEFF6FF);
  static const pageBg = Color(0xFFF5F6F8);
  static const card = Colors.white;
  static const dark = Color(0xFF1F2937);
  static const gray = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF0F0F0);
}

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  StreamSubscription? _chatsSubscription;
  StreamSubscription? _newMessageSubscription;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _setupSocketListeners();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _newMessageSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
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
    final i = chats.indexWhere((c) => c.id == message.chatId);
    if (i != -1 && mounted) {
      setState(() {
        final c = chats[i];
        final updated = ChatModel(
          id: c.id,
          uniqueId: c.uniqueId,
          otherUser: c.otherUser,
          lastMessage: message.content,
          lastMessageTime: message.createdAt,
          lastMessageSenderId: message.senderId,
          unreadCount: c.unreadCount + 1,
          lastMessages: c.lastMessages,
          createdAt: c.createdAt,
          updatedAt: DateTime.now(),
        );
        final newChats = List<ChatModel>.from(chats);
        newChats[i] = updated;
        chats = newChats;
        _updateUnreadCount(chats);
      });
    }
  }

  Future<void> _loadChats() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final loaded = await ChatService.getUserChats();
      if (!mounted) return;
      setState(() {
        chats = loaded;
        _updateUnreadCount(loaded);
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  void _updateUnreadCount(List<ChatModel> list) {
    unreadCount = list.fold(0, (sum, c) => sum + c.unreadCount);
  }

  List<ChatModel> get _filteredChats {
    if (_searchQuery.isEmpty) return chats;
    return chats.where((c) {
      final name = c.otherUser?.name?.toLowerCase() ?? '';
      final msg = (c.lastMessage ?? '').toLowerCase();
      return name.contains(_searchQuery) || msg.contains(_searchQuery);
    }).toList();
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 7) return '${time.day}/${time.month}';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.pageBg,
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: Container(
              color: _C.sidebarBg,
              child: SafeArea(
                child: Column(
                  children: [
                    _buildSidebarHeader(),
                    _buildSearchBox(),
                    _buildSidebarList(),
                  ],
                ),
              ),
            ),
          ),

          Expanded(child: _buildMainArea()),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _C.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Messages',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _C.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.search, size: 16, color: _C.sidebarText),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: _C.sidebarText, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarList() {
    final filtered = _filteredChats;
    if (loading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: _C.accent, strokeWidth: 2),
        ),
      );
    }
    if (filtered.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: _C.sidebarText.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No conversations',
                style: TextStyle(
                  color: _C.sidebarText.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: filtered.length,
        itemBuilder: (ctx, i) => _buildSidebarItem(filtered[i]),
      ),
    );
  }

  Widget _buildSidebarItem(ChatModel chat) {
    final user = chat.otherUser;
    final isUnread = chat.unreadCount > 0;

    return InkWell(
      onTap: () async {
        _socket.markAsRead(chat.id);
        if (user != null && user.id != null) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: chat.id,
                otherUserId: user.id!,
                otherUserName: user.name ?? 'User',
                otherUserAvatar: user.avatar,
              ),
            ),
          );
          if (result == true && mounted) _loadChats();
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _C.accent.withOpacity(0.3),
                  backgroundImage: user?.avatar?.isNotEmpty == true
                      ? NetworkImage(user!.avatar!)
                      : null,
                  child: user?.avatar?.isNotEmpty != true
                      ? Text(
                          user?.name?.isNotEmpty == true
                              ? user!.name![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : null,
                ),
                if (isUnread)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _C.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.sidebarBg, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                      color: isUnread ? Colors.white : _C.sidebarText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat.lastMessage ?? 'No messages yet',
                    style: TextStyle(
                      fontSize: 11,
                      color: isUnread
                          ? _C.sidebarText.withOpacity(0.85)
                          : _C.sidebarText.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (chat.lastMessageTime != null)
                  Text(
                    _formatTime(chat.lastMessageTime!),
                    style: TextStyle(
                      fontSize: 10,
                      color: _C.sidebarText.withOpacity(0.4),
                    ),
                  ),
                const SizedBox(height: 4),
                if (isUnread)
                  Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: _C.accent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        '${chat.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainArea() {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _C.accent));
    }

    if (_filteredChats.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: _C.pageBg,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        backgroundColor: _C.card,
        foregroundColor: _C.dark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _C.pageBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: _C.gray,
                ),
              ),
              onPressed: _loadChats,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _C.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadChats,
        color: _C.accent,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _filteredChats.length,
          itemBuilder: (ctx, i) => _buildChatCard(_filteredChats[i]),
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
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _C.accentBg,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: _C.accent,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _C.dark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a conversation from a project',
            style: TextStyle(fontSize: 14, color: _C.gray),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/projects'),
            icon: const Icon(Icons.search_rounded, size: 16),
            label: const Text('Find Projects'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(ChatModel chat) {
    final user = chat.otherUser;
    final isUnread = chat.unreadCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnread ? _C.accent.withOpacity(0.2) : _C.border,
        ),
      ),
      child: InkWell(
        onTap: () async {
          _socket.markAsRead(chat.id);
          if (user != null && user.id != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: chat.id,
                  otherUserId: user.id!,
                  otherUserName: user.name ?? 'User',
                  otherUserAvatar: user.avatar,
                ),
              ),
            );
            if (result == true && mounted) _loadChats();
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _C.accentBg,
                    backgroundImage: user?.avatar?.isNotEmpty == true
                        ? NetworkImage(user!.avatar!)
                        : null,
                    child: user?.avatar?.isNotEmpty != true
                        ? Text(
                            user?.name?.isNotEmpty == true
                                ? user!.name![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: _C.accent,
                            ),
                          )
                        : null,
                  ),
                  if (isUnread)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _C.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.card, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user?.name ?? 'Unknown User',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: _C.dark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.lastMessageTime != null)
                          Text(
                            _formatTime(chat.lastMessageTime!),
                            style: TextStyle(
                              fontSize: 11,
                              color: isUnread ? _C.accent : _C.gray,
                              fontWeight: isUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage ?? 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isUnread ? _C.dark : _C.gray,
                              fontWeight: isUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _C.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${chat.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
}
