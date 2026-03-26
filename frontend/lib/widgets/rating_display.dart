// widgets/rating_display.dart
import 'package:flutter/material.dart';
import '../models/rating_model.dart';

class RatingDisplay extends StatelessWidget {
  final RatingStats stats;
  final List<Rating>? recentRatings;

  const RatingDisplay({
    super.key,
    required this.stats,
    this.recentRatings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              stats.average.toStringAsFixed(1),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < stats.average.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
                Text(
                  '${stats.total} reviews',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        ...List.generate(5, (index) {
          final starNumber = 5 - index;
          final count = stats.distribution[starNumber] ?? 0;
          final percentage = stats.total > 0 ? count / stats.total : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '$starNumber ★',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        starNumber > 3
                            ? Colors.green
                            : starNumber > 2
                                ? Colors.orange
                                : Colors.red,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    count.toString(),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),

        if (recentRatings != null && recentRatings!.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Recent Reviews',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...recentRatings!.take(3).map((rating) => _buildReviewCard(rating)),
        ],
      ],
    );
  }

  Widget _buildReviewCard(Rating rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: rating.fromUser?['avatar'] != null
                    ? NetworkImage(rating.fromUser!['avatar'])
                    : null,
                child: rating.fromUser?['avatar'] == null
                    ? Text(rating.fromUser?['name']?[0].toUpperCase() ?? '?')
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.fromUser?['name'] ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 12,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(rating.createdAt),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.comment!,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }
}