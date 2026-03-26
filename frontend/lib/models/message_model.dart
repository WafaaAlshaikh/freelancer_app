// lib/models/message_model.dart
import 'package:freelancer_platform/main.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String type;
  final String? mediaUrl;
  final DateTime createdAt;
  final List<String> readBy;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName, 
    this.senderAvatar, 
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.createdAt,
    required this.readBy,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'] ?? '', 
      senderAvatar: json['sender_avatar'], 
      content: json['content'],
      type: json['type'] ?? 'text',
      mediaUrl: json['media_url'],
      createdAt: DateTime.parse(json['created_at']),
      readBy: List<String>.from(json['read_by'] ?? []),
    );
  }

  bool get isReadByMe => readBy.contains(supabase.auth.currentUser?.id);
}
