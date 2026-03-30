// lib/screens/chat/chat_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cross_file/cross_file.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../services/socket_service.dart';
import '../../services/chat_service.dart';
import '../../utils/token_storage.dart';
import 'dart:html' as html;

class ChatScreen extends StatefulWidget {
  final int chatId;
  final int otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  List<Message> messages = [];
  bool loading = true;
  bool hasMore = true;
  int currentPage = 0;
  final int pageSize = 20;

  int? currentUserId;
  bool _isOtherTyping = false;
  Timer? _typingTimer;
  bool _isSending = false;
  Message? _replyingTo;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  StreamSubscription? _newMessageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _readReceiptSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _messageDeletedSubscription;
  StreamSubscription? _messageEditedSubscription;
  StreamSubscription? _reactionSubscription;
  StreamSubscription? _messageErrorSubscription;

  final SocketService _socket = SocketService.instance;
  final Set<int> _receivedMessageIds = {};

  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  final List<String> _allowedFileTypes = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'zip',
    'rar',
  ];
  final int _maxFileSize = 10 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initAndLoad();
    _messageController.addListener(() {
      print('📝 Text changed: "${_messageController.text}"');
    });
  }

  void _initAnimations() {
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _typingAnimation = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(
        parent: _typingAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initAndLoad() async {
    final userIdStr = await TokenStorage.getUserId();
    if (mounted) {
      setState(() {
        currentUserId = userIdStr != null ? int.tryParse(userIdStr) : null;
      });
    }
    await _loadMessages();
    _setupSocketListeners();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final result = await ChatService.getMessages(
        chatId: widget.chatId,
        limit: pageSize,
        offset: currentPage * pageSize,
      );

      if (!mounted) return;

      final newMessages = (result['messages'] as List)
          .map((json) => Message.fromJson(json))
          .toList();

      for (var msg in newMessages) {
        _receivedMessageIds.add(msg.id);
      }

      setState(() {
        messages.insertAll(0, newMessages);
        hasMore = result['hasMore'] ?? false;
        if (newMessages.isNotEmpty) currentPage++;
        loading = false;
      });

      _scrollToBottom();
      _socket.markAsRead(widget.chatId);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      print('Error loading messages: $e');
    }
  }

  void _setupSocketListeners() {
    _newMessageSubscription?.cancel();
    _typingSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _connectionSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _messageEditedSubscription?.cancel();
    _reactionSubscription?.cancel();
    _messageErrorSubscription?.cancel();

    if (_socket.isConnected) {
      _socket.joinChat(widget.chatId);
    }

    _connectionSubscription = _socket.onConnectionChange.listen((connected) {
      if (connected && mounted) {
        _socket.joinChat(widget.chatId);
      }
    });

    _newMessageSubscription = _socket.onNewMessage.listen((message) {
      if (!mounted) return;
      if (_receivedMessageIds.contains(message.id)) return;
      _receivedMessageIds.add(message.id);

      if (message.chatId == widget.chatId) {
        setState(() => messages.add(message));
        _scrollToBottom();
        _socket.markAsRead(widget.chatId);
      }
    });

    _typingSubscription = _socket.onTyping.listen((data) {
      if (!mounted) return;
      if (data['userId'] == currentUserId) return;
      if (data['chatId'] == widget.chatId) {
        setState(() => _isOtherTyping = data['isTyping'] ?? false);
      }
    });

    _readReceiptSubscription = _socket.onReadReceipt.listen((data) {
      if (!mounted) return;
      if (data['chatId'] == widget.chatId) {
        setState(() {
          for (var message in messages) {
            if (message.senderId == data['userId'] &&
                !message.readBy.contains(data['userId'])) {
              message.readBy.add(data['userId']);
            }
          }
        });
      }
    });

    _messageDeletedSubscription = _socket.onMessageDeleted.listen((data) {
      if (!mounted) return;
      print('🗑️ Message deleted received: $data');
      if (data['chatId'] == widget.chatId) {
        setState(() {
          messages.removeWhere((m) => m.id == data['messageId']);
        });
        Fluttertoast.showToast(msg: 'Message deleted');
      }
    });

    _messageEditedSubscription = _socket.onMessageEdited.listen((data) {
      if (!mounted) return;
      print('✏️ Message edited received: $data');
      if (data['chatId'] == widget.chatId) {
        setState(() {
          final index = messages.indexWhere((m) => m.id == data['messageId']);
          if (index != -1) {
            messages[index] = messages[index].copyWith(
              content: data['content'],
              isEdited: true,
              editedAt: DateTime.now(),
            );
          }
        });
        Fluttertoast.showToast(msg: 'Message edited');
      }
    });

    _reactionSubscription = _socket.onReaction.listen((data) {
      if (!mounted) return;
      print('😊 Reaction received: $data');
      if (data['chatId'] == widget.chatId) {
        setState(() {
          final index = messages.indexWhere((m) => m.id == data['messageId']);
          if (index != -1) {
            messages[index] = messages[index].copyWith(
              reaction: data['reaction'],
            );
          }
        });
        Fluttertoast.showToast(msg: 'Reaction added: ${data['reaction']}');
      }
    });

    _messageErrorSubscription = _socket.onMessageError.listen((error) {
      if (!mounted) return;
      print('❌ Message error: $error');
      Fluttertoast.showToast(
        msg: error['error'] ?? 'Failed to send message',
        backgroundColor: Colors.red,
      );
    });
  }

  void _onMessageChanged() {
    if (_typingTimer != null) _typingTimer!.cancel();

    if (_messageController.text.isNotEmpty) {
      _socket.sendTyping(widget.chatId, true);
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _socket.sendTyping(widget.chatId, false);
      });
    }
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && messages.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final rawText = _messageController.text;
    final content = rawText.trim();

    print('🔍 Debug - Raw text: "$rawText"');
    print('🔍 Debug - Trimmed content: "$content"');
    print('🔍 Debug - Text length: ${rawText.length}');

    if (content.isEmpty && _replyingTo == null) {
      print('⚠️ Cannot send empty message');
      Fluttertoast.showToast(
        msg: 'Please enter a message',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (_isSending) {
      print('⚠️ Already sending message');
      return;
    }

    _isSending = true;

    try {
      if (!_socket.isConnected) {
        print('⚠️ Socket not connected, attempting to reconnect...');
        final connected = await _socket.ensureConnection();
        if (!connected) {
          Fluttertoast.showToast(
            msg: 'Could not connect to chat server',
            backgroundColor: Colors.red,
          );
          _isSending = false;
          return;
        }
        _socket.joinChat(widget.chatId);
      }

      print('📤 Sending message:');
      print('  chatId: ${widget.chatId}');
      print('  content: $content');
      print('  replyTo: ${_replyingTo?.id}');

      _socket.sendMessage(
        chatId: widget.chatId,
        content: content,
        replyTo: _replyingTo?.id,
      );

      _messageController.clear();
      setState(() {
        _replyingTo = null;
      });
    } catch (e) {
      print('❌ Error sending message: $e');
      Fluttertoast.showToast(
        msg: 'Error sending message: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      _isSending = false;
    }
  }

  Future<void> _uploadAndSendFileWithProgress(
    String filePath,
    String type,
  ) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final file = XFile(filePath);
      final bytes = await file.readAsBytes();
      final fileName = filePath.split('/').last;

      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          if (_uploadProgress < 0.9) {
            _uploadProgress += 0.1;
          } else {
            timer.cancel();
          }
        });
      });

      final fileUrl = await ChatService.uploadFile(bytes, fileName, type);

      setState(() => _uploadProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 300));

      if (fileUrl != null && mounted) {
        _socket.sendMessage(
          chatId: widget.chatId,
          content: fileUrl,
          type: type,
          fileName: fileName,
        );
        Fluttertoast.showToast(msg: '✅ File uploaded successfully');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Error uploading file: $e');
    } finally {
      if (mounted)
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
    }
  }

  Widget _buildUploadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade100,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Uploading file...'),
        ],
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    if (kIsWeb) {
      _pickAndSendImageWeb();
    } else {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        await _uploadAndSendFile(pickedFile.path, 'image');
      }
    }
  }

  Future<void> _pickAndSendFile() async {
    if (kIsWeb) {
      _pickAndSendFileWeb();
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
      );

      if (result != null) {
        final filePath = result.files.single.path;
        if (filePath != null) {
          await _uploadAndSendFile(filePath, 'file');
        } else if (result.files.single.bytes != null) {
          final bytes = result.files.single.bytes!;
          final fileName = result.files.single.name;
          await _uploadAndSendBytes(bytes, fileName, 'file');
        }
      }
    }
  }

  final List<String> _allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

  Future<void> _uploadAndSendFile(String filePath, String type) async {
    setState(() => _isUploading = true);

    try {
      final file = XFile(filePath);
      final bytes = await file.readAsBytes();
      final fileName = filePath.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      if (bytes.length > _maxFileSize) {
        Fluttertoast.showToast(
          msg: 'File too large. Max size: 10 MB',
          backgroundColor: Colors.orange,
        );
        return;
      }

      if (type == 'image' && !_allowedImageTypes.contains(fileExtension)) {
        Fluttertoast.showToast(
          msg: 'Only images are allowed: ${_allowedImageTypes.join(", ")}',
          backgroundColor: Colors.orange,
        );
        return;
      }

      if (type == 'file' && !_allowedFileTypes.contains(fileExtension)) {
        Fluttertoast.showToast(
          msg: 'File type not allowed: ${_allowedFileTypes.join(", ")}',
          backgroundColor: Colors.orange,
        );
        return;
      }

      print(
        '📤 Uploading file: $fileName, type: $type, size: ${bytes.length} bytes',
      );

      final fileUrl = await ChatService.uploadFile(bytes, fileName, type);

      if (fileUrl != null && mounted) {
        _socket.sendMessage(
          chatId: widget.chatId,
          content: fileUrl,
          type: type,
          fileName: fileName,
        );
        Fluttertoast.showToast(msg: '✅ File uploaded successfully');
      } else {
        Fluttertoast.showToast(msg: '❌ Failed to upload file');
      }
    } catch (e) {
      print('❌ Error uploading file: $e');
      Fluttertoast.showToast(msg: 'Error uploading file: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadAndSendBytes(
    Uint8List bytes,
    String fileName,
    String type,
  ) async {
    setState(() => _isUploading = true);

    try {
      print(
        '📤 Uploading bytes: $fileName, type: $type, size: ${bytes.length} bytes',
      );

      final fileUrl = await ChatService.uploadFile(bytes, fileName, type);

      if (fileUrl != null && mounted) {
        _socket.sendMessage(
          chatId: widget.chatId,
          content: fileUrl,
          type: type,
          fileName: fileName,
        );
        Fluttertoast.showToast(msg: 'File uploaded successfully');
      } else {
        Fluttertoast.showToast(msg: 'Failed to upload file');
      }
    } catch (e) {
      print('❌ Error uploading file: $e');
      Fluttertoast.showToast(msg: 'Error uploading file: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAndSendImageWeb() async {
    if (!kIsWeb) return;

    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();

    input.onChange.listen((event) {
      if (input.files != null && input.files!.isNotEmpty) {
        final file = input.files!.first;
        _uploadAndSendFileForWeb(file, 'image');
      }
    });
  }

  Future<void> _pickAndSendFileWeb() async {
    if (!kIsWeb) return;

    final input = html.FileUploadInputElement();
    input.click();

    input.onChange.listen((event) {
      if (input.files != null && input.files!.isNotEmpty) {
        final file = input.files!.first;
        _uploadAndSendFileForWeb(file, 'file');
      }
    });
  }

  Future<void> _uploadAndSendFileForWeb(html.File file, String type) async {
    setState(() => _isUploading = true);

    try {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final bytes = reader.result as Uint8List;
      final fileName = file.name;

      final fileUrl = await ChatService.uploadFile(bytes, fileName, type);

      if (fileUrl != null && mounted) {
        _socket.sendMessage(
          chatId: widget.chatId,
          content: fileUrl,
          type: type,
          fileName: fileName,
        );
        Fluttertoast.showToast(msg: 'File uploaded successfully');
      } else {
        Fluttertoast.showToast(msg: 'Failed to upload file');
      }
    } catch (e) {
      print('Error uploading file: $e');
      Fluttertoast.showToast(msg: 'Error uploading file: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  _showReactionPicker(Message message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _reactionButton('👍', message),
            _reactionButton('❤️', message),
            _reactionButton('😂', message),
            _reactionButton('😮', message),
            _reactionButton('😢', message),
            _reactionButton('👎', message),
          ],
        ),
      ),
    );
  }

  Widget _reactionButton(String emoji, Message message) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _socket.sendReaction(message.id, emoji);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  void _showMessageOptions(Message message, bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyingTo = message);
                _messageFocusNode.requestFocus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions),
              title: const Text('React'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(message);
              },
            ),
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _editMessage(Message message) {
    final controller = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Edit your message...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                _socket.editMessage(message.id, newContent);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _socket.deleteMessage(message.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _loadMore() {
    if (hasMore && !loading && mounted) {
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _newMessageSubscription?.cancel();
    _typingSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _connectionSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _messageEditedSubscription?.cancel();
    _socket.leaveChat(widget.chatId);
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _typingTimer?.cancel();
    _typingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  widget.otherUserAvatar != null &&
                      widget.otherUserAvatar!.isNotEmpty
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              child:
                  widget.otherUserAvatar == null ||
                      widget.otherUserAvatar!.isEmpty
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isOtherTyping)
                    AnimatedBuilder(
                      animation: _typingAnimation,
                      builder: (context, child) {
                        return Row(
                          children: [
                            Container(
                              width: 6 * _typingAnimation.value,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Typing...',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  else
                    const Text(
                      'Online',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              Fluttertoast.showToast(msg: 'Voice call coming soon');
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              Fluttertoast.showToast(msg: 'Video call coming soon');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_replyingTo != null) _buildReplyingBar(),
          if (_isOtherTyping && _replyingTo == null) _buildTypingIndicator(),
          Expanded(
            child: loading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? _buildEmptyMessages()
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels <= 0 &&
                          hasMore &&
                          !loading &&
                          mounted) {
                        _loadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - 1 - index];
                        final isMe = message.senderId == currentUserId;
                        return GestureDetector(
                          onLongPress: () => _showMessageOptions(message, isMe),
                          child: _buildMessageBubble(message, isMe),
                        );
                      },
                    ),
                  ),
          ),
          if (_isUploading) _buildUploadingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildReplyingBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replyingTo!.senderName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  _replyingTo!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: widget.otherUserAvatar != null
                ? NetworkImage(widget.otherUserAvatar!)
                : null,
            child: widget.otherUserAvatar == null
                ? Text(widget.otherUserName[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(delay: 0),
                const SizedBox(width: 4),
                _buildTypingDot(delay: 0.3),
                const SizedBox(width: 4),
                _buildTypingDot(delay: 0.6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot({double delay = 0}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (delay * 1000).toInt()),
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade600.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () => setState(() {}),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final alignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final color = isMe ? const Color(0xff14A800) : Colors.grey.shade200;
    final textColor = isMe ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  message.senderAvatar != null &&
                      message.senderAvatar!.isNotEmpty
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child:
                  message.senderAvatar == null || message.senderAvatar!.isEmpty
                  ? Text(
                      message.senderName.isNotEmpty
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    )
                  : null,
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.replyTo != null) _buildReplyPreview(message),
                  if (!isMe && message.senderName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        message.senderName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  if (message.reaction != null) _buildReactionBadge(message),
                  _buildMessageContent(message, textColor),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                      if (message.isEdited)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '(edited)',
                            style: TextStyle(
                              fontSize: 9,
                              color: isMe
                                  ? Colors.white60
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.readBy.length > 1
                              ? Icons.done_all
                              : Icons.done,
                          size: 12,
                          color: message.readBy.length > 1
                              ? Colors.lightBlueAccent
                              : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(Message message) {
    if (message.replyTo == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '↳ ${message.replyTo!.senderName}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            message.replyTo!.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionBadge(Message message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message.reaction!, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildMessageContent(Message message, Color textColor) {
    if (message.type == 'image') {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImage(imageUrl: message.content),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: message.content,
            height: 200,
            width: 200,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              width: 200,
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              width: 200,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, size: 40),
            ),
          ),
        ),
      );
    } else if (message.type == 'file') {
      return GestureDetector(
        onTap: () => _openFile(message.content),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file, size: 20),
              const SizedBox(width: 8),
              Text(
                message.fileName ?? message.content.split('/').last,
                style: TextStyle(color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    } else {
      return Text(message.content, style: TextStyle(color: textColor));
    }
  }

  Future<void> _openFile(String url) async {
    try {
      if (url.startsWith('/uploads/')) {
        final fullUrl = 'http://localhost:5000$url';
        if (kIsWeb) {
          html.window.open(fullUrl, '_blank');
        } else {
          await OpenFile.open(fullUrl);
        }
      } else {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print('Error opening file: $e');
      Fluttertoast.showToast(msg: 'Could not open file');
    }
  }

  Widget _buildFileMessage(String url, String fileName, Color textColor) {
    return GestureDetector(
      onTap: () => _openFile(url),
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.open_in_browser),
                  title: const Text('Open'),
                  onTap: () {
                    Navigator.pop(context);
                    _openFile(url);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Download'),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadFile(url, fileName);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareFile(url, fileName);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: textColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Tap to open • Long press for options',
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      if (kIsWeb) {
        html.window.open(url, '_blank');
      } else {
        Fluttertoast.showToast(msg: 'Download started: $fileName');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error downloading file: $e');
    }
  }

  Future<void> _shareFile(String url, String fileName) async {
    try {
      await Share.share('Check out this file: $fileName\n$url');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error sharing file: $e');
    }
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: Color(0xff14A800)),
            onPressed: _isUploading ? null : _pickAndSendImage,
            tooltip: 'Send Image',
          ),
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: _isUploading ? null : _pickAndSendFile,
            tooltip: 'Attach File',
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              enabled: !_isUploading,
              decoration: InputDecoration(
                hintText: _replyingTo != null
                    ? 'Reply...'
                    : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isUploading ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isUploading ? Colors.grey : const Color(0xff14A800),
                shape: BoxShape.circle,
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSendImageWithPreview() async {
    if (kIsWeb) {
      _pickAndSendImageWeb();
    } else {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Preview Image'),
            content: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(pickedFile.path),
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _uploadAndSendFile(pickedFile.path, 'image');
                },
                child: const Text('Send'),
              ),
            ],
          ),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return '${time.day}/${time.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white, size: 50),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
