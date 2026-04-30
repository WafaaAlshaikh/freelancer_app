// frontend/lib/screens/ai/ai_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AIChatScreen extends StatefulWidget {
  final int? projectId;
  const AIChatScreen({super.key, this.projectId});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await ApiService.getChatHistory();
      print('📚 Loaded history: $history');

      if (history is List) {
        setState(() {
          _messages.clear();
          for (var msg in history) {
            if (msg is Map) {
              _messages.add(Map<String, dynamic>.from(msg));
            }
          }
        });
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  Future<void> _sendMessage() async {
    final t = AppLocalizations.of(context)!;
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();
    setState(() {
      _messages.add({
        "role": "user",
        "content": userMessage,
        "timestamp": DateTime.now().toIso8601String(),
      });
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await ApiService.chatWithAI(
        userMessage,
        projectId: widget.projectId,
      );

      setState(() {
        _messages.add({
          "role": "ai",
          "content": response["reply"],
          "suggestedActions": response["suggestedActions"],
          "timestamp": DateTime.now().toIso8601String(),
        });
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: '${t.error}: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _executeAction(Map<String, dynamic> action) {
    final actionType = action["action"];
    final screen = action["screen"];
    final url = action["url"];

    if (actionType == "navigate" && screen != null) {
      Navigator.pushNamed(context, screen);
    } else if (actionType == "open" && url != null) {
      final t = AppLocalizations.of(context)!;
      Fluttertoast.showToast(msg: '${t.opening} $url');
    }
  }

  Future<void> _clearChat() async {
    final t = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          t.clearChat,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          t.clearChatConfirmation,
          style: TextStyle(color: AppColors.gray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel, style: TextStyle(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              t.clear,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.clearChatHistory();
      setState(() => _messages.clear());
      Fluttertoast.showToast(msg: t.chatHistoryCleared);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              t.aiAssistant,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.iconTheme.color),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser
                              ? theme.colorScheme.secondary
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isUser
                                ? const Radius.circular(4)
                                : const Radius.circular(16),
                            bottomLeft: isUser
                                ? const Radius.circular(16)
                                : const Radius.circular(4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.3 : 0.05,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msg["content"],
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),

                      if (!isUser && msg["suggestedActions"] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List<Widget>.from(
                              (msg["suggestedActions"] as List).map((action) {
                                return ActionChip(
                                  label: Text(
                                    action["label"],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.info,
                                    ),
                                  ),
                                  onPressed: () => _executeAction(action),
                                  avatar: Icon(
                                    action["action"] == "navigate"
                                        ? Icons.arrow_forward
                                        : Icons.open_in_new,
                                    size: 14,
                                    color: AppColors.info,
                                  ),
                                  backgroundColor: AppColors.infoBg,
                                );
                              }),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: t.askMeAnything,
                      hintStyle: TextStyle(color: AppColors.gray),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade100,
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
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.secondary,
                          AppColors.secondaryDark,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
