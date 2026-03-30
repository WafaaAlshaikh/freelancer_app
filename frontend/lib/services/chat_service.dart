// lib/services/chat_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
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
        Uri.parse(
          '$baseUrl/chats/$chatId/messages?limit=$limit&offset=$offset',
        ),
        headers: ApiService.headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting messages: $e');
      return {'messages': [], 'total': 0, 'hasMore': false};
    }
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int chatId,
    required String content,
    String type = 'text',
    String? mediaUrl,
    String? fileName,
    int? replyToId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats/$chatId/messages'),
        headers: ApiService.headers,
        body: jsonEncode({
          'content': content,
          'type': type,
          'media_url': mediaUrl,
          'file_name': fileName,
          'reply_to_id': replyToId,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error sending message: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<String?> uploadFile(
    Uint8List bytes,
    String fileName,
    String type,
  ) async {
    try {
      print('📤 Uploading file to server: $fileName');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/chats/upload'),
      );

      request.headers['Authorization'] = 'Bearer ${ApiService.token}';

      String mimeType = 'application/octet-stream';
      if (type == 'image') {
        if (fileName.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        } else if (fileName.endsWith('.gif')) {
          mimeType = 'image/gif';
        }
      } else if (type == 'file') {
        if (fileName.endsWith('.pdf')) {
          mimeType = 'application/pdf';
        } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
          mimeType = 'application/msword';
        }
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      print('📡 Upload response status: ${response.statusCode}');
      print('📡 Upload response body: $responseData');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseData);
        return data['url'] ?? data['fileUrl'];
      } else {
        print('❌ Upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading file: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> createChat(int otherUserId) async {
    try {
      print('📱 Creating chat with other user ID: $otherUserId');

      final response = await http.post(
        Uri.parse('$baseUrl/chats'),
        headers: ApiService.headers,
        body: jsonEncode({'otherUserId': otherUserId}),
      );

      print('📡 Create chat response status: ${response.statusCode}');
      print('📄 Create chat response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to create chat'};
      }
    } catch (e) {
      print('❌ Error creating chat: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<int?> createChatAndGetId(int otherUserId) async {
    try {
      final result = await createChat(otherUserId);
      print('📦 Create chat result: $result');

      if (result['success'] == true) {
        final chatData = result['chat'];
        if (chatData != null) {
          final chatId = chatData['id'];
          if (chatId != null) {
            print('✅ Chat created with ID: $chatId');
            return chatId is int ? chatId : int.tryParse(chatId.toString());
          }
        }
      }

      final chatId = result['id'] ?? result['chat_id'] ?? result['data']?['id'];
      if (chatId != null) {
        return chatId is int ? chatId : int.tryParse(chatId.toString());
      }

      print('❌ Failed to get chat ID from response: $result');
      return null;
    } catch (e) {
      print('❌ Error creating chat and getting ID: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> createChatFromContract(
    int contractId,
  ) async {
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

  static Future<Map<String, dynamic>> getOrCreateChat(int otherUserId) async {
    try {
      final chats = await getUserChats();
      final existingChat = chats.firstWhere(
        (chat) => chat.otherUser?.id == otherUserId,
        orElse: () => null as ChatModel,
      );

      if (existingChat != null) {
        return {'success': true, 'id': existingChat.id, 'exists': true};
      }

      return await createChat(otherUserId);
    } catch (e) {
      print('❌ Error getting or creating chat: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }
}
