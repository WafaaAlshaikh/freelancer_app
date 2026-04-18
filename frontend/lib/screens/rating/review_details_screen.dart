// lib/screens/rating/review_details_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelancer_platform/screens/freelancer/profile_screen.dart';
import '../../services/api_service.dart';
import '../../models/rating_model.dart';
import 'add_reply_screen.dart';

class ReviewDetailsScreen extends StatefulWidget {
  final Rating review;

  const ReviewDetailsScreen({super.key, required this.review});

  @override
  State<ReviewDetailsScreen> createState() => _ReviewDetailsScreenState();
}

class _ReviewDetailsScreenState extends State<ReviewDetailsScreen> {
  bool _isHelpfulLoading = false;
  int _helpfulCount = 0;
  bool _isHelpfulMarked = false;
  String? _reply;
  DateTime? _repliedAt;

  @override
  void initState() {
    super.initState();
    _helpfulCount = widget.review.helpfulCount;
    _reply = widget.review.reply;
    _repliedAt = widget.review.repliedAt;
  }

  Future<void> _markHelpful() async {
    if (_isHelpfulMarked) {
      Fluttertoast.showToast(msg: 'You already marked this as helpful');
      return;
    }

    setState(() => _isHelpfulLoading = true);
    final result = await ApiService.markReviewHelpful(widget.review.id);
    setState(() {
      _isHelpfulLoading = false;
      if (result['success'] == true) {
        _isHelpfulMarked = true;
        _helpfulCount++;
        Fluttertoast.showToast(msg: 'Thanks for your feedback!');
      }
    });
  }

  Future<void> _addReply() async {
    final reply = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AddReplyScreen(reviewId: widget.review.id),
      ),
    );
    if (reply != null && reply.isNotEmpty) {
      setState(() {
        _reply = reply;
        _repliedAt = DateTime.now();
      });
      Fluttertoast.showToast(msg: 'Reply added successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromUserName = widget.review.fromUser?['name'] ?? 'User';
    final fromUserAvatar = widget.review.fromUser?['avatar'];
    final projectTitle =
        widget.review.contract?['Project']?['title'] ?? 'Project';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (widget.review.role == 'freelancer' &&
              (_reply == null || _reply!.isEmpty))
            IconButton(
              icon: const Icon(Icons.reply, color: Color(0xff14A800)),
              onPressed: _addReply,
              tooltip: 'Reply to review',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(fromUserName, fromUserAvatar, projectTitle),
            const SizedBox(height: 24),
            _buildRatingDetails(),
            const SizedBox(height: 24),
            if (widget.review.comment != null &&
                widget.review.comment!.isNotEmpty)
              _buildComment(),
            _buildReply(),
            const SizedBox(height: 24),
            _buildHelpfulButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildReply() {
    if (_reply == null || _reply!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seller Response',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_reply!, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 8),
              Text(
                _formatDate(_repliedAt!),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String userName, String? avatar, String projectTitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.amber.shade100,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.review.roleLabel,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (widget.review.isVerifiedPurchase)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Verified',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                projectTitle,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                widget.review.formattedDate,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.review.rating.toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      RatingStars(
                        rating: widget.review.rating.toDouble(),
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'out of 5',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.review.qualityRating != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildDetailRating('Quality', widget.review.qualityRating!),
                _buildDetailRating(
                  'Communication',
                  widget.review.communicationRating ?? widget.review.rating,
                ),
                _buildDetailRating(
                  'Deadline',
                  widget.review.deadlineRating ?? widget.review.rating,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRating(String label, int rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  size: 14,
                  color: Colors.amber,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.review.comment!,
            style: const TextStyle(height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpfulButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: _isHelpfulLoading ? null : _markHelpful,
        icon: Icon(
          _isHelpfulMarked ? Icons.thumb_up : Icons.thumb_up_outlined,
          size: 18,
          color: _isHelpfulMarked ? Colors.blue : Colors.grey,
        ),
        label: Text(
          _isHelpfulLoading
              ? '...'
              : _isHelpfulMarked
              ? 'You found this helpful ($_helpfulCount)'
              : 'Was this review helpful? ($_helpfulCount)',
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: BorderSide(
            color: _isHelpfulMarked ? Colors.blue : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
