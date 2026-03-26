// lib/services/chat_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  final supabase = Supabase.instance.client;

  void _checkAuth() {
    if (supabase.auth.currentUser == null) {
      throw Exception('User not logged in');
    }
  }

  Future<String> createChat(String otherUserId) async {
    _checkAuth();
    
    final currentUserId = supabase.auth.currentUser!.id;
    if (currentUserId == otherUserId) {
      throw Exception('Cannot create chat with yourself');
    }

    final existingChat = await _getExistingChat(currentUserId, otherUserId);
    if (existingChat != null) {
      print('✅ Existing chat found: $existingChat');
      return existingChat;
    }

    print('📝 Creating new chat between $currentUserId and $otherUserId');
    final response = await supabase.from('chats').insert({
      'participant_ids': [currentUserId, otherUserId],
    }).select();

    final chatId = response.first['id'];
    print('✅ New chat created: $chatId');
    return chatId;
  }

  Future<String?> _getExistingChat(String uid1, String uid2) async {
    try {
      final response = await supabase
          .from('chats')
          .select()
          .contains('participant_ids', [uid1, uid2]);

      if (response.isNotEmpty) {
        return response.first['id'];
      }
      return null;
    } catch (e) {
      print('❌ Error checking existing chat: $e');
      return null;
    }
  }

  Stream<List<Chat>> getChats() {
  _checkAuth();
  
  final userId = supabase.auth.currentUser!.id;

  final stream = supabase
      .from('chats')
      .stream(primaryKey: ['id']);

  return stream.map((data) {
    return data
        .where((chat) {
          final participants = List<String>.from(chat['participant_ids'] ?? []);
          return participants.contains(userId);
        })
        .map((chat) => Chat.fromJson(chat))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  });
}

  Future<void> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    String? mediaUrl,
  }) async {
    _checkAuth();
    
    final senderId = supabase.auth.currentUser!.id;

    final senderProfile = await supabase
        .from('profiles')
        .select('full_name, avatar_url')
        .eq('id', senderId)
        .single();

    await supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_name': senderProfile['full_name'] ?? 'مستخدم',
      'sender_avatar': senderProfile['avatar_url'],
      'content': content,
      'type': type,
      'media_url': mediaUrl,
      'read_by': [senderId],
    });

    await supabase.from('chats').update({
      'last_message': content.length > 50 ? '${content.substring(0, 50)}...' : content,
      'last_message_time': DateTime.now().toIso8601String(),
      'last_message_sender_id': senderId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', chatId);
  }

  Stream<List<Message>> getMessages(String chatId) {
    _checkAuth();
    
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((data) => data.map((msg) => Message.fromJson(msg)).toList());
  }

  Future<void> markMessagesAsRead(String chatId) async {
    _checkAuth();
    
    final userId = supabase.auth.currentUser!.id;

    final messages = await supabase
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .not('read_by', 'cs', '{$userId}');

    for (var msg in messages) {
      final currentReadBy = List<String>.from(msg['read_by'] ?? []);
      if (!currentReadBy.contains(userId)) {
        currentReadBy.add(userId);
        await supabase
            .from('messages')
            .update({'read_by': currentReadBy})
            .eq('id', msg['id']);
      }
    }
  }
}