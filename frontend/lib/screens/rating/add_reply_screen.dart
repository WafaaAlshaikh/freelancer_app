// lib/screens/rating/add_reply_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AddReplyScreen extends StatefulWidget {
  final int reviewId;

  const AddReplyScreen({super.key, required this.reviewId});

  @override
  State<AddReplyScreen> createState() => _AddReplyScreenState();
}

class _AddReplyScreenState extends State<AddReplyScreen> {
  final TextEditingController _replyController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.replyToReview),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitReply,
            child: Text(
              t.post,
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.replyVisibilityMessage,
                      style: TextStyle(fontSize: 12, color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              t.yourReply,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _replyController,
              maxLines: 6,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: t.replyHint,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade50,
                alignLabelWithHint: true,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_replyController.text.length}/1000',
                style: TextStyle(
                  fontSize: 11,
                  color: _replyController.text.length > 1000
                      ? AppColors.danger
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 0,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber,
                    ),
                    title: Text(
                      t.tipsForGoodReply,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      '${t.beProfessionalAndPolite}\n'
                      '${t.addressSpecificConcerns}\n'
                      '${t.thankReviewerForFeedback}\n'
                      '${t.showWillingnessToImprove}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_replyController.text.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.preview,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.reply,
                                size: 14,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t.sellerResponse,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _replyController.text,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.justNow,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReply() async {
    final t = AppLocalizations.of(context)!;
    final reply = _replyController.text.trim();
    if (reply.isEmpty) {
      Fluttertoast.showToast(msg: t.pleaseEnterReply);
      return;
    }

    if (reply.length < 10) {
      Fluttertoast.showToast(msg: t.replyMinLength);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.addReviewReply(widget.reviewId, reply);

      if (result['success'] == true) {
        Fluttertoast.showToast(
          msg: t.replyPostedSuccess,
          backgroundColor: AppColors.success,
        );
        Navigator.pop(context, reply);
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? t.errorPostingReply,
          backgroundColor: AppColors.danger,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: '${t.error}: $e',
        backgroundColor: AppColors.danger,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }
}
