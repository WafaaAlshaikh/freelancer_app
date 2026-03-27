// lib/models/message_model.dart
class Message {
  final int id;
  final int chatId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String type;
  final String? mediaUrl;
  final DateTime createdAt;
  final List<int> readBy;
  final bool isReadByMe;

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
    required this.isReadByMe,
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
      createdAt: DateTime.parse(json['createdAt']),
      readBy: (json['read_by'] as List?)?.map((e) => e as int).toList() ?? [],
      isReadByMe: json['is_read_by_me'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'content': content,
      'type': type,
      'media_url': mediaUrl,
      'createdAt': createdAt.toIso8601String(),
      'read_by': readBy,
      'is_read_by_me': isReadByMe,
    };
  }
}