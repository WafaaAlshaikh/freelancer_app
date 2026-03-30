// lib/models/chat_model.dart
import 'user_model.dart';
import 'message_model.dart';

class ChatModel {
  final int id;
  final String uniqueId;
  final User? otherUser;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int? lastMessageSenderId;
  final int unreadCount;
  final List<Message>? lastMessages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.uniqueId,
    this.otherUser,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    this.lastMessages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    print('📦 ChatModel.fromJson: $json');

    User? otherUser;
    if (json['otherUser'] != null) {
      try {
        otherUser = User.fromJson(json['otherUser']);
      } catch (e) {
        print('⚠️ Error parsing otherUser: $e');
        otherUser = User(
          id: json['otherUserId'] ?? 0,
          name: json['otherUserName'] ?? 'User',
          avatar: json['otherUserAvatar'],
        );
      }
    } else if (json['other_user'] != null) {
      try {
        otherUser = User.fromJson(json['other_user']);
      } catch (e) {
        print('⚠️ Error parsing other_user: $e');
      }
    }

    return ChatModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      uniqueId: json['unique_id']?.toString() ?? '',
      otherUser: otherUser,
      lastMessage: json['last_message']?.toString(),
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.tryParse(json['last_message_time'].toString())
          : null,
      lastMessageSenderId: json['last_message_sender_id'] != null
          ? int.tryParse(json['last_message_sender_id'].toString())
          : null,
      unreadCount: int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
      lastMessages: json['lastMessages'] != null
          ? (json['lastMessages'] as List)
                .map((m) => Message.fromJson(m))
                .toList()
          : [],
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
