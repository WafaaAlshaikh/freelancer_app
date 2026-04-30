// lib/screens/rating/review_details_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
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
    final t = AppLocalizations.of(context)!;

    if (_isHelpfulMarked) {
      Fluttertoast.showToast(msg: t.alreadyMarkedHelpful);
      return;
    }

    setState(() => _isHelpfulLoading = true);
    final result = await ApiService.markReviewHelpful(widget.review.id);
    setState(() {
      _isHelpfulLoading = false;
      if (result['success'] == true) {
        _isHelpfulMarked = true;
        _helpfulCount++;
        Fluttertoast.showToast(msg: t.thanksForFeedback);
      }
    });
  }

  Future<void> _addReply() async {
    final t = AppLocalizations.of(context)!;

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
      Fluttertoast.showToast(msg: t.replyAddedSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fromUserName = widget.review.fromUser?['name'] ?? t.user;
    final fromUserAvatar = widget.review.fromUser?['avatar'];
    final projectTitle =
        widget.review.contract?['Project']?['title'] ?? t.project;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.reviewDetails),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (widget.review.role == 'freelancer' &&
              (_reply == null || _reply!.isEmpty))
            IconButton(
              icon: Icon(Icons.reply, color: AppColors.secondary),
              onPressed: _addReply,
              tooltip: t.replyToReview,
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_reply == null || _reply!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.sellerResponse,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard2 : AppColors.infoBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.grey.shade800
                  : AppColors.info.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _reply!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(_repliedAt!),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String userName, String? avatar, String projectTitle) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [AppColors.darkCard2, AppColors.darkSurface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
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
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.review.roleLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
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
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t.verified,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: theme.colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                projectTitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                widget.review.formattedDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDetails() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.rating,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.review.rating.toString(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
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
                        t.outOf5,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.review.qualityRating != null) ...[
                const SizedBox(height: 16),
                Divider(color: theme.colorScheme.onSurface.withOpacity(0.2)),
                const SizedBox(height: 12),
                _buildDetailRating(t.quality, widget.review.qualityRating!),
                _buildDetailRating(
                  t.communication,
                  widget.review.communicationRating ?? widget.review.rating,
                ),
                _buildDetailRating(
                  t.deadline,
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            ),
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.reviews,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard2 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.review.comment!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpfulButton() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: OutlinedButton.icon(
        onPressed: _isHelpfulLoading ? null : _markHelpful,
        icon: Icon(
          _isHelpfulMarked ? Icons.thumb_up : Icons.thumb_up_outlined,
          size: 18,
          color: _isHelpfulMarked
              ? AppColors.info
              : theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        label: Text(
          _isHelpfulLoading
              ? '...'
              : _isHelpfulMarked
              ? '${t.youFoundThisHelpful} ($_helpfulCount)'
              : '${t.wasThisReviewHelpful} ($_helpfulCount)',
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: BorderSide(
            color: _isHelpfulMarked
                ? AppColors.info
                : theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          foregroundColor: _isHelpfulMarked
              ? AppColors.info
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showNumber;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 14,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final fill = (rating >= index + 1)
              ? 1.0
              : (rating > index ? rating - index : 0.0);
          return Icon(
            fill >= 0.5 ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: size,
          );
        }),
        if (showNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }
}
