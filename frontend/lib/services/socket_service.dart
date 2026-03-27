// lib/services/socket_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../utils/token_storage.dart';

class SocketService {
  static SocketService? _instance;
  static SocketService get instance => _instance ??= SocketService._();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  bool _isDisposed = false;

  final _chatsController = StreamController<List<ChatModel>>.broadcast();
  final _newMessageController = StreamController<Message>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<List<ChatModel>> get onChatsUpdate => _chatsController.stream;
  Stream<Message> get onNewMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onReadReceipt =>
      _readReceiptController.stream;
  Stream<bool> get onConnectionChange => _connectionController.stream;

  SocketService._();

  bool get isConnected => _isConnected;

  int? getCurrentUserId() {
    if (_currentUserId != null) {
      return int.tryParse(_currentUserId!);
    }
    return null;
  }

  Future<void> init() async {
    final token = await TokenStorage.getToken();
    final userIdStr = await TokenStorage.getUserId();

    print('🔌 Socket init - Token: ${token != null ? "Exists" : "Missing"}');
    print('🔌 Socket init - UserId: $userIdStr');

    if (token == null || userIdStr == null) {
      print('❌ Cannot connect: No token or user ID');
      _connectionController.add(false);
      return;
    }

    _currentUserId = userIdStr;

    try {
      final String socketUrl = kIsWeb
          ? 'http://localhost:5000'
          : 'http://10.0.2.2:5000';
      print('🔌 Connecting to socket at: $socketUrl');

      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
        'auth': {'userId': int.parse(userIdStr), 'token': token},
        'extraHeaders': {'Authorization': 'Bearer $token'},
      });

      _setupListeners();
    } catch (e) {
      print('❌ Error creating socket: $e');
      _connectionController.add(false);
    }
  }

  Future<void> reconnect() async {
    print('🔄 Attempting to reconnect...');
    _isConnected = false;
    await init();
  }

  void _setupListeners() {
    _socket!.onConnecting((_) {
      print('🔄 Socket is connecting...');
    });

    _socket!.onConnectTimeout((_) {
      print('⏰ Socket connection timeout!');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onConnect((_) {
      if (_isDisposed) return;
      _isConnected = true;
      print('✅✅✅✅✅ Socket CONNECTED! ✅✅✅✅✅');
      _connectionController.add(true);
      _socket!.emit('ping', {'timestamp': DateTime.now().toIso8601String()});
    });

    _socket!.onConnectError((data) {
      if (_isDisposed) return;
      print('⚠️ Socket connection error: $data');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onDisconnect((_) {
      if (_isDisposed) return;
      print('❌ Socket disconnected');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.on('pong', (data) {
      if (_isDisposed) return;
      print('🏓 Socket pong received');
    });

    _socket!.on('chats_list', (data) {
      if (_isDisposed) return;
      print('📨 Received chats_list: ${data?.length ?? 0} chats');
      if (data != null) {
        final chats = (data as List)
            .map((json) => ChatModel.fromJson(json))
            .toList();
        _chatsController.add(chats);
      }
    });

    _socket!.on('new_message', (data) {
      if (_isDisposed) return;
      print('💬 New message received');
      if (data != null) {
        final message = Message.fromJson(data);
        _newMessageController.add(message);
      }
    });

    _socket!.on('user_typing', (data) {
      if (_isDisposed) return;
      print('✍️ Typing event: $data');
      if (data != null) {
        _typingController.add(data);
      }
    });

    _socket!.on('messages_read', (data) {
      if (_isDisposed) return;
      print('✅ Messages read: $data');
      if (data != null) {
        _readReceiptController.add(data);
      }
    });

    _socket!.on('new_message_notification', (data) {
      if (_isDisposed) return;
      print('🔔 New message notification: $data');
      final senderName = data?['sender']?['name'] ?? 'Someone';
      final messageContent = data?['message']?['content'] ?? '';
      Fluttertoast.showToast(
        msg: '$senderName: $messageContent',
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        timeInSecForIosWeb: 3,
      );
    });

    _socket!.on('message_error', (data) {
      if (_isDisposed) return;
      print('❌ Message error: $data');
      Fluttertoast.showToast(
        msg: data?['error'] ?? 'Failed to send message',
        backgroundColor: Colors.red,
      );
    });

    _socket!.on('chats_list_error', (data) {
      if (_isDisposed) return;
      print('❌ Chats list error: $data');
    });
  }

  void joinChat(int chatId) {
    if (_isConnected && _socket != null && chatId != null) {
      print('📢 Joining chat: $chatId');
      _socket!.emit('join_chat', chatId);
    } else {
      print(
        '⚠️ Cannot join chat: connected=$_isConnected, socket=${_socket != null}',
      );
    }
  }

  Future<int?> getCurrentUserIdAsync() async {
    if (_currentUserId != null) return int.tryParse(_currentUserId!);
    final userIdStr = await TokenStorage.getUserId();
    return userIdStr != null ? int.tryParse(userIdStr) : null;
  }

  void leaveChat(int chatId) {
    if (_isConnected && _socket != null && chatId != null) {
      print('👋 Leaving chat: $chatId');
      _socket!.emit('leave_chat', chatId);
    }
  }

  Future<bool> ensureConnection({int timeoutSeconds = 5}) async {
    if (_isConnected) return true;

    await reconnect();

    final completer = Completer<bool>();
    late StreamSubscription sub;

    sub = _connectionController.stream.listen((connected) {
      if (!completer.isCompleted) {
        completer.complete(connected);
        sub.cancel();
      }
    });

    return completer.future.timeout(
      Duration(seconds: timeoutSeconds),
      onTimeout: () {
        sub.cancel();
        return false;
      },
    );
  }

  void sendMessage({
    required int chatId,
    required String content,
    String type = 'text',
    String? mediaUrl,
  }) {
    if (!_isConnected) {
      print('⚠️ Cannot send message: Not connected');
      Fluttertoast.showToast(
        msg: 'Not connected to chat server. Please check your connection.',
        backgroundColor: Colors.red,
      );
      return;
    }

    print('📤 Sending message to chat $chatId: $content');
    _socket!.emit('send_message', {
      'chatId': chatId,
      'content': content,
      'type': type,
      'mediaUrl': mediaUrl,
    });
  }

  void sendTyping(int chatId, bool isTyping) {
    if (_isConnected && _socket != null) {
      print('✍️ Sending typing event for chat $chatId: $isTyping');
      _socket!.emit('typing', {'chatId': chatId, 'isTyping': isTyping});
    }
  }

  void markAsRead(int chatId) {
    if (_isConnected && _socket != null) {
      print('✅ Marking chat $chatId as read');
      _socket!.emit('mark_read', {'chatId': chatId});
    }
  }

  void loadMoreMessages(int chatId, int offset, {int limit = 20}) {
    if (_isConnected && _socket != null) {
      _socket!.emit('load_more_messages', {
        'chatId': chatId,
        'offset': offset,
        'limit': limit,
      });
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
    }
    _isConnected = false;
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _chatsController.close();
    _newMessageController.close();
    _typingController.close();
    _readReceiptController.close();
    _connectionController.close();
  }
}
