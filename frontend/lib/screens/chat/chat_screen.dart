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

class _C {
  static const sidebarBg = Color(0xFF2D2B55);
  static const sidebarText = Color(0xFFC8C6E8);
  static const accent = Color(0xFF6C63FF);
  static const accentDark = Color(0xFF4F46E5);
  static const accentLight = Color(0xFFA78BFA);
  static const accentBg = Color(0xFFEEF2FF);
  static const green = Color(0xFF14A800);
  static const greenBg = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFFFBEB);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const infoBg = Color(0xFFEFF6FF);
  static const pageBg = Color(0xFFF5F6F8);
  static const card = Colors.white;
  static const dark = Color(0xFF1F2937);
  static const gray = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF0F0F0);
}

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
  final List<String> _allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  final int _maxFileSize = 10 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initAndLoad();
    _messageController.addListener(_onMessageChanged);
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
      setState(
        () =>
            currentUserId = userIdStr != null ? int.tryParse(userIdStr) : null,
      );
    }
    await _loadMessages();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _newMessageSubscription?.cancel();
    _typingSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _connectionSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _messageEditedSubscription?.cancel();
    _reactionSubscription?.cancel();
    _messageErrorSubscription?.cancel();
    _socket.leaveChat(widget.chatId);
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _typingTimer?.cancel();
    _typingAnimationController.dispose();
    super.dispose();
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
          .map((j) => Message.fromJson(j))
          .toList();
      for (var msg in newMessages) _receivedMessageIds.add(msg.id);
      setState(() {
        messages.insertAll(0, newMessages);
        hasMore = result['hasMore'] ?? false;
        if (newMessages.isNotEmpty) currentPage++;
        loading = false;
      });
      _scrollToBottom();
      _socket.markAsRead(widget.chatId);
    } catch (e) {
      if (mounted) setState(() => loading = false);
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

    if (_socket.isConnected) _socket.joinChat(widget.chatId);

    _connectionSubscription = _socket.onConnectionChange.listen((connected) {
      if (connected && mounted) _socket.joinChat(widget.chatId);
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
      if (data['chatId'] == widget.chatId)
        setState(() => _isOtherTyping = data['isTyping'] ?? false);
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
      if (data['chatId'] == widget.chatId) {
        setState(() => messages.removeWhere((m) => m.id == data['messageId']));
        Fluttertoast.showToast(msg: 'Message deleted');
      }
    });

    _messageEditedSubscription = _socket.onMessageEdited.listen((data) {
      if (!mounted) return;
      if (data['chatId'] == widget.chatId) {
        setState(() {
          final i = messages.indexWhere((m) => m.id == data['messageId']);
          if (i != -1) {
            messages[i] = messages[i].copyWith(
              content: data['content'],
              isEdited: true,
              editedAt: DateTime.now(),
            );
          }
        });
      }
    });

    _reactionSubscription = _socket.onReaction.listen((data) {
      if (!mounted) return;
      if (data['chatId'] == widget.chatId) {
        setState(() {
          final i = messages.indexWhere((m) => m.id == data['messageId']);
          if (i != -1)
            messages[i] = messages[i].copyWith(reaction: data['reaction']);
        });
      }
    });

    _messageErrorSubscription = _socket.onMessageError.listen((error) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: error['error'] ?? 'Failed to send message',
        backgroundColor: _C.danger,
      );
    });
  }

  void _onMessageChanged() {
    _typingTimer?.cancel();
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
    final content = _messageController.text.trim();
    if (content.isEmpty && _replyingTo == null) return;
    if (_isSending) return;
    _isSending = true;
    try {
      if (!_socket.isConnected) {
        final connected = await _socket.ensureConnection();
        if (!connected) {
          Fluttertoast.showToast(
            msg: 'Could not connect to chat server',
            backgroundColor: _C.danger,
          );
          return;
        }
        _socket.joinChat(widget.chatId);
      }
      _socket.sendMessage(
        chatId: widget.chatId,
        content: content,
        replyTo: _replyingTo?.id,
      );
      _messageController.clear();
      setState(() => _replyingTo = null);
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error sending message: $e',
        backgroundColor: _C.danger,
      );
    } finally {
      _isSending = false;
    }
  }

  Future<void> _uploadAndSendFile(String filePath, String type) async {
    setState(() => _isUploading = true);
    try {
      final file = XFile(filePath);
      final bytes = await file.readAsBytes();
      final fileName = filePath.split('/').last;
      final ext = fileName.split('.').last.toLowerCase();

      if (bytes.length > _maxFileSize) {
        Fluttertoast.showToast(
          msg: 'File too large. Max size: 10 MB',
          backgroundColor: _C.warning,
        );
        return;
      }
      if (type == 'image' && !_allowedImageTypes.contains(ext)) {
        Fluttertoast.showToast(
          msg: 'Only images: ${_allowedImageTypes.join(", ")}',
          backgroundColor: _C.warning,
        );
        return;
      }
      if (type == 'file' && !_allowedFileTypes.contains(ext)) {
        Fluttertoast.showToast(
          msg: 'File type not allowed: ${_allowedFileTypes.join(", ")}',
          backgroundColor: _C.warning,
        );
        return;
      }

      final fileUrl = await ChatService.uploadFile(bytes, fileName, type);
      if (fileUrl != null && mounted) {
        _socket.sendMessage(
          chatId: widget.chatId,
          content: fileUrl,
          type: type,
          fileName: fileName,
        );
        Fluttertoast.showToast(
          msg: 'File uploaded successfully',
          backgroundColor: _C.green,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to upload file',
          backgroundColor: _C.danger,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: _C.danger,
      );
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
      final fileUrl = await ChatService.uploadFile(bytes, fileName, type);
      if (fileUrl != null && mounted) {
        _socket.sendMessage(
          chatId: widget.chatId,
          content: fileUrl,
          type: type,
          fileName: fileName,
        );
        Fluttertoast.showToast(
          msg: 'File uploaded successfully',
          backgroundColor: _C.green,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: _C.danger,
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    if (kIsWeb) {
      _pickAndSendImageWeb();
    } else {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) await _uploadAndSendFile(file.path, 'image');
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
        final path = result.files.single.path;
        if (path != null) {
          await _uploadAndSendFile(path, 'file');
        } else if (result.files.single.bytes != null) {
          await _uploadAndSendBytes(
            result.files.single.bytes!,
            result.files.single.name,
            'file',
          );
        }
      }
    }
  }

  Future<void> _pickAndSendImageWeb() async {
    if (!kIsWeb) return;
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((e) {
      if (input.files != null && input.files!.isNotEmpty)
        _uploadAndSendFileForWeb(input.files!.first, 'image');
    });
  }

  Future<void> _pickAndSendFileWeb() async {
    if (!kIsWeb) return;
    final input = html.FileUploadInputElement();
    input.click();
    input.onChange.listen((e) {
      if (input.files != null && input.files!.isNotEmpty)
        _uploadAndSendFileForWeb(input.files!.first, 'file');
    });
  }

  Future<void> _uploadAndSendFileForWeb(html.File file, String type) async {
    setState(() => _isUploading = true);
    try {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      final bytes = reader.result as Uint8List;
      final fileUrl = await ChatService.uploadFile(bytes, file.name, type);
      if (fileUrl != null && mounted) {
        _socket.sendMessage(
          chatId: widget.chatId,
          content: fileUrl,
          type: type,
          fileName: file.name,
        );
        Fluttertoast.showToast(
          msg: 'File uploaded successfully',
          backgroundColor: _C.green,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: _C.danger,
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showReactionPicker(Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['👍', '❤️', '😂', '😮', '😢', '👎']
              .map(
                (emoji) => GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _socket.sendReaction(message.id, emoji);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _C.pageBg,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showMessageOptions(Message message, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: _C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _optionTile(ctx, Icons.reply_rounded, 'Reply', _C.dark, () {
              setState(() => _replyingTo = message);
              _messageFocusNode.requestFocus();
            }),
            _optionTile(
              ctx,
              Icons.emoji_emotions_outlined,
              'React',
              _C.dark,
              () {
                _showReactionPicker(message);
              },
            ),
            if (isMe) ...[
              _optionTile(
                ctx,
                Icons.edit_outlined,
                'Edit',
                _C.accent,
                () => _editMessage(message),
              ),
              _optionTile(
                ctx,
                Icons.delete_outline,
                'Delete',
                _C.danger,
                () => _deleteMessage(message),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(
    BuildContext ctx,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
    );
  }

  void _editMessage(Message message) {
    final ctrl = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Message',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Edit your message...',
            filled: true,
            fillColor: _C.pageBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _C.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _C.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _C.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: _C.gray)),
          ),
          ElevatedButton(
            onPressed: () {
              final newContent = ctrl.text.trim();
              if (newContent.isNotEmpty && newContent != message.content)
                _socket.editMessage(message.id, newContent);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(Message message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Message',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        content: const Text(
          'Are you sure you want to delete this message?',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: _C.gray)),
          ),
          TextButton(
            onPressed: () {
              _socket.deleteMessage(message.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: _C.danger)),
          ),
        ],
      ),
    );
  }

  void _loadMore() {
    if (hasMore && !loading && mounted) _loadMessages();
  }

  Future<void> _openFile(String url) async {
    try {
      final fullUrl = url.startsWith('/uploads/')
          ? 'http://localhost:5000$url'
          : url;
      if (kIsWeb) {
        html.window.open(fullUrl, '_blank');
      } else {
        await launchUrl(Uri.parse(fullUrl));
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Could not open file',
        backgroundColor: _C.danger,
      );
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      if (kIsWeb) {
        html.window.open(url, '_blank');
      } else {
        Fluttertoast.showToast(msg: 'Download started: $fileName');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e', backgroundColor: _C.danger);
    }
  }

  Future<void> _shareFile(String url, String fileName) async {
    try {
      await Share.share('Check out this file: $fileName\n$url');
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error sharing: $e',
        backgroundColor: _C.danger,
      );
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 7) return '${time.day}/${time.month}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.pageBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_replyingTo != null) _buildReplyingBar(),
          Expanded(
            child: loading && messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: _C.accent),
                  )
                : messages.isEmpty
                ? _buildEmptyMessages()
                : NotificationListener<ScrollNotification>(
                    onNotification: (info) {
                      if (info.metrics.pixels <= 0 &&
                          hasMore &&
                          !loading &&
                          mounted)
                        _loadMore();
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = messages[messages.length - 1 - i];
                        final isMe = msg.senderId == currentUserId;
                        return GestureDetector(
                          onLongPress: () => _showMessageOptions(msg, isMe),
                          child: _buildMessageBubble(msg, isMe),
                        );
                      },
                    ),
                  ),
          ),
          if (_isUploading) _buildUploadingIndicator(),
          if (_isOtherTyping) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _C.card,
      foregroundColor: _C.dark,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _C.accentBg,
                backgroundImage: widget.otherUserAvatar?.isNotEmpty == true
                    ? NetworkImage(widget.otherUserAvatar!)
                    : null,
                child: widget.otherUserAvatar?.isNotEmpty != true
                    ? Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _C.accent,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _C.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.card, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _C.dark,
                  ),
                ),
                if (_isOtherTyping)
                  AnimatedBuilder(
                    animation: _typingAnimation,
                    builder: (_, __) => Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _C.green.withOpacity(_typingAnimation.value),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Typing...',
                          style: TextStyle(
                            fontSize: 11,
                            color: _C.green,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _C.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Online',
                        style: TextStyle(fontSize: 11, color: _C.green),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _appBarAction(
          Icons.phone_outlined,
          () => Fluttertoast.showToast(msg: 'Voice call coming soon'),
        ),
        _appBarAction(
          Icons.videocam_outlined,
          () => Fluttertoast.showToast(msg: 'Video call coming soon'),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: _C.border),
      ),
    );
  }

  Widget _appBarAction(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _C.pageBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.border),
        ),
        child: IconButton(
          icon: Icon(icon, size: 17, color: _C.gray),
          onPressed: onTap,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildReplyingBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _C.card,
        border: Border(
          top: BorderSide(color: _C.border),
          left: const BorderSide(color: _C.accent, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replyingTo!.senderName}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _C.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingTo!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _C.gray),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _replyingTo = null),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _C.pageBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, size: 14, color: _C.gray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6, top: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: _C.accentBg,
            backgroundImage: widget.otherUserAvatar != null
                ? NetworkImage(widget.otherUserAvatar!)
                : null,
            child: widget.otherUserAvatar == null
                ? Text(
                    widget.otherUserName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 11, color: _C.accent),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                0,
                1,
                2,
              ].map((i) => _buildTypingDot(delay: i * 0.2)).toList(),
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
      builder: (_, value, __) => Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.only(right: 3),
        decoration: BoxDecoration(
          color: _C.gray.withOpacity(value),
          shape: BoxShape.circle,
        ),
      ),
      onEnd: () => setState(() {}),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _C.accentBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: _C.accent,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _C.dark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start the conversation below',
            style: TextStyle(fontSize: 13, color: _C.gray),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _C.card,
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: _C.accent),
          ),
          const SizedBox(width: 10),
          const Text(
            'Uploading...',
            style: TextStyle(fontSize: 13, color: _C.gray),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 15,
              backgroundColor: _C.accentBg,
              backgroundImage: message.senderAvatar?.isNotEmpty == true
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child: message.senderAvatar?.isNotEmpty != true
                  ? Text(
                      message.senderName.isNotEmpty
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 11, color: _C.accent),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? _C.accent : _C.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: _C.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.replyTo != null)
                    _buildReplyPreview(message, isMe),
                  if (!isMe && message.senderName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        message.senderName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _C.accent,
                        ),
                      ),
                    ),
                  if (message.reaction != null)
                    _buildReactionBadge(message, isMe),
                  _buildMessageContent(message, isMe ? Colors.white : _C.dark),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white54 : _C.gray,
                        ),
                      ),
                      if (message.isEdited)
                        Text(
                          ' · edited',
                          style: TextStyle(
                            fontSize: 9,
                            color: isMe
                                ? Colors.white38
                                : _C.gray.withOpacity(0.6),
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
                              ? _C.accentLight
                              : Colors.white54,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(Message message, bool isMe) {
    if (message.replyTo == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.15) : _C.accentBg,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: isMe ? Colors.white54 : _C.accent, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '↳ ${message.replyTo!.senderName}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isMe ? Colors.white70 : _C.accent,
            ),
          ),
          Text(
            message.replyTo!.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isMe ? Colors.white60 : _C.gray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionBadge(Message message, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.2) : _C.pageBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isMe ? Colors.white24 : _C.border),
      ),
      child: Text(message.reaction!, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildMessageContent(Message message, Color textColor) {
    if (message.type == 'image') {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenImage(imageUrl: message.content),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: message.content,
            height: 200,
            width: 200,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 200,
              width: 200,
              color: _C.pageBg,
              child: const Center(
                child: CircularProgressIndicator(
                  color: _C.accent,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 200,
              width: 200,
              color: _C.pageBg,
              child: const Icon(
                Icons.broken_image_outlined,
                color: _C.gray,
                size: 36,
              ),
            ),
          ),
        ),
      );
    } else if (message.type == 'file') {
      return GestureDetector(
        onTap: () => _openFile(message.content),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: textColor.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 18,
                color: textColor.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.fileName ?? message.content.split('/').last,
                  style: TextStyle(color: textColor, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Text(
      message.content,
      style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: _C.card,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          _inputAction(
            Icons.image_outlined,
            _C.accent,
            _isUploading ? null : _pickAndSendImage,
          ),
          const SizedBox(width: 4),
          _inputAction(
            Icons.attach_file_rounded,
            _C.gray,
            _isUploading ? null : _pickAndSendFile,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _C.pageBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _C.border),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                enabled: !_isUploading,
                style: const TextStyle(fontSize: 14, color: _C.dark),
                decoration: InputDecoration(
                  hintText: _replyingTo != null
                      ? 'Reply...'
                      : 'Type a message...',
                  hintStyle: const TextStyle(color: _C.gray, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isUploading ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isUploading ? _C.border : _C.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _isUploading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputAction(IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: onTap == null ? _C.gray : color, size: 18),
      ),
    );
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
        iconTheme: const IconThemeData(color: Colors.white),
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
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
