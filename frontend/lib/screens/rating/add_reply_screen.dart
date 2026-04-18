// lib/screens/rating/add_reply_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reply to Review'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitReply,
            child: const Text(
              'Post',
              style: TextStyle(
                color: Color(0xff14A800),
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your reply will be visible to everyone. Be professional and courteous.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Your Reply',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _replyController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Write your response to this review...\n\n'
                    'Example: "Thank you for your feedback! We appreciate your business and will work on improving."',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
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
                  color: _replyController.text.length > 1000 ? Colors.red : Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
                    title: const Text('Tips for a good reply'),
                    subtitle: const Text(
                      '• Be professional and polite\n'
                      '• Address specific concerns\n'
                      '• Thank the reviewer for feedback\n'
                      '• Show willingness to improve',
                      style: TextStyle(fontSize: 11),
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
                  const Text(
                    'Preview',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
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
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.reply, size: 14, color: Colors.green),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Seller Response',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _replyController.text,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Just now',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
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
    final reply = _replyController.text.trim();
    if (reply.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter a reply');
      return;
    }

    if (reply.length < 10) {
      Fluttertoast.showToast(msg: 'Reply should be at least 10 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.addReviewReply(widget.reviewId, reply);

      if (result['success'] == true) {
        Fluttertoast.showToast(
          msg: '✅ Reply posted successfully',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context, reply);
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Error posting reply',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e', backgroundColor: Colors.red);
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