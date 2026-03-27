// lib/services/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'api_service.dart';

class ChatService {
  static String get baseUrl => ApiService.baseUrl;
  
  static Future<List<ChatModel>> getUserChats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chats'),
        headers: ApiService.headers,
      );
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => ChatModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting user chats: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> getMessages({
    required int chatId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chats/$chatId/messages?limit=$limit&offset=$offset'),
        headers: ApiService.headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting messages: $e');
      return {'messages': [], 'total': 0, 'hasMore': false};
    }
  }
  
  static Future<Map<String, dynamic>> createChat(int otherUserId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats'),
        headers: ApiService.headers,
        body: jsonEncode({'otherUserId': otherUserId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating chat: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }
  
  static Future<Map<String, dynamic>> createChatFromContract(int contractId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats/contract/$contractId'),
        headers: ApiService.headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating chat from contract: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }
}