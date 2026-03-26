// lib/screens/chat/chats_list_screen.dart
import 'package:flutter/material.dart';
import 'package:freelancer_platform/main.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../models/chat_model.dart';
import '../../models/profile_model.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  Profile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final profile = await _authService.getCurrentProfile();
    setState(() {
      _currentProfile = profile;
    });
  }



  Future<Map<String, dynamic>> _getOtherParticipantData(Chat chat) async {
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId == null) return {};

    final otherId = chat.participantIds.firstWhere((id) => id != currentUserId);
    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', otherId)
        .single();

    return response;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: شاشة البحث عن مستخدمين
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Chat>>(
        stream: _chatService.getChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد محادثات بعد',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ابحث عن مستخدم لبدء محادثة',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: البحث عن مستخدمين
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('البحث عن مستخدمين'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff14A800),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              
              return FutureBuilder<Map<String, dynamic>>(
                future: _getOtherParticipantData(chat),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final otherUser = userSnapshot.data!;
                  final isMeLastSender = chat.lastMessageSenderId == _currentProfile?.id;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: otherUser['avatar_url'] != null
                          ? NetworkImage(otherUser['avatar_url'])
                          : null,
                      child: otherUser['avatar_url'] == null
                          ? Text(otherUser['full_name']?[0].toUpperCase() ?? '?')
                          : null,
                    ),
                    title: Text(
                      otherUser['full_name'] ?? 'مستخدم',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isMeLastSender ? 'أنت: ${chat.lastMessage ?? ""}' : chat.lastMessage ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (chat.lastMessageTime != null)
                          Text(
                            _formatTime(chat.lastMessageTime!),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                    onTap: () async {
                      await _chatService.markMessagesAsRead(chat.id);
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chat.id,
                            otherUserId: otherUser['id'],
                            otherUserName: otherUser['full_name'],
                            otherUserAvatar: otherUser['avatar_url'],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'الآن';
    }
  }
}