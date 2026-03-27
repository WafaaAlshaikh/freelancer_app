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
    return ChatModel(
      id: json['id'],
      uniqueId: json['unique_id'] ?? '',
      otherUser: json['otherUser'] != null 
          ? User.fromJson(json['otherUser']) 
          : null,
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      lastMessageSenderId: json['last_message_sender_id'],
      unreadCount: json['unreadCount'] ?? 0,
      lastMessages: json['lastMessages'] != null
          ? (json['lastMessages'] as List)
              .map((m) => Message.fromJson(m))
              .toList()
          : [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}