// lib/screens/rating/reviews_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import '../../models/rating_model.dart';
import 'review_details_screen.dart';
import 'add_rating_screen.dart';

class ReviewsScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String userRole;

  const ReviewsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Rating> _reviews = [];
  RatingStats? _stats;
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getUserRatings(widget.userId);

      final ratingsList = response['ratings'] as List? ?? [];
      final statsData = response['stats'] as Map<String, dynamic>?;

      setState(() {
        _reviews = ratingsList.map((j) => Rating.fromJson(j)).toList();

        if (statsData != null) {
          _stats = RatingStats.fromJson(statsData);
        } else {
          _stats = RatingStats(
            total: _reviews.length,
            average: _reviews.isEmpty
                ? 0
                : _reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                      _reviews.length,
            distribution: {
              1: _reviews.where((r) => r.rating == 1).length,
              2: _reviews.where((r) => r.rating == 2).length,
              3: _reviews.where((r) => r.rating == 3).length,
              4: _reviews.where((r) => r.rating == 4).length,
              5: _reviews.where((r) => r.rating == 5).length,
            },
          );
        }

        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading reviews: $e');
      setState(() {
        _loading = false;
        _reviews = [];
        _stats = RatingStats(total: 0, average: 0, distribution: {});
      });
      Fluttertoast.showToast(msg: 'Error loading reviews: $e');
    }
  }

  List<Rating> get _filteredReviews {
    switch (_filter) {
      case 'positive':
        return _reviews.where((r) => r.rating >= 4).toList();
      case 'negative':
        return _reviews.where((r) => r.rating <= 2).toList();
      case 'with_comment':
        return _reviews
            .where((r) => r.comment != null && r.comment!.isNotEmpty)
            .toList();
      default:
        return _reviews;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName}\'s Reviews'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xff14A800),
          tabs: const [
            Tab(text: 'Reviews', icon: Icon(Icons.star)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildReviewsList(), _buildAnalyticsTab()],
            ),
    );
  }

  Widget _buildReviewsList() {
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Reviews will appear here once completed projects are rated',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
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
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _stats != null
                              ? _stats!.average.toStringAsFixed(1)
                              : '0.0',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RatingStars(rating: _stats?.average ?? 0, size: 16),
                        Text(
                          '${_stats?.total ?? 0} reviews',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.grey.shade300),
                  Expanded(
                    child: Column(
                      children: [
                        _buildFilterChip('All', 'all', _reviews.length),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSmallFilterChip(
                              'Positive',
                              'positive',
                              _reviews.where((r) => r.rating >= 4).length,
                              Colors.green,
                            ),
                            _buildSmallFilterChip(
                              'Negative',
                              'negative',
                              _reviews.where((r) => r.rating <= 2).length,
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredReviews.length,
            itemBuilder: (context, index) {
              final review = _filteredReviews[index];
              return _buildReviewCard(review);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallFilterChip(
    String label,
    String value,
    int count,
    Color color,
  ) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Rating review) {
    final fromUserName = review.fromUser?['name'] ?? 'User';
    final fromUserAvatar = review.fromUser?['avatar'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReviewDetailsScreen(review: review),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.amber.shade100,
                    backgroundImage: fromUserAvatar != null
                        ? NetworkImage(fromUserAvatar)
                        : null,
                    child: fromUserAvatar == null
                        ? Text(
                            fromUserName.isNotEmpty
                                ? fromUserName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fromUserName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          review.formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (review.isVerifiedPurchase)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              RatingStars(rating: review.rating.toDouble(), size: 16),
              const SizedBox(height: 8),
              if (review.comment != null && review.comment!.isNotEmpty)
                Text(
                  review.comment!,
                  style: const TextStyle(height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              if (review.helpfulCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.thumb_up, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${review.helpfulCount} found this helpful',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (review.reply != null && review.reply!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Response from seller:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(review.reply!, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingDistribution(),
          const SizedBox(height: 20),
          _buildRatingBreakdown(),
          const SizedBox(height: 20),
          _buildReviewHighlights(),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution() {
    if (_stats == null) return const SizedBox.shrink();

    final maxCount = _stats!.distribution.values
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (i) {
            final rating = 5 - i;
            final count = _stats!.distribution[rating] ?? 0;
            final percentage = _stats!.total > 0
                ? (count / _stats!.total * 100).toInt()
                : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$rating ★',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getRatingColor(rating),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxCount > 0 ? count / maxCount : 0,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getRatingColor(rating),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 45,
                    child: Text(
                      '$percentage%',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRatingBreakdown() {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBreakdownItem(
                'Positive',
                _stats!.positiveRate,
                Colors.green,
                _stats!.positiveCount,
              ),
              _buildBreakdownItem(
                'Neutral',
                _stats!.neutralRate,
                Colors.orange,
                _stats!.neutralCount,
              ),
              _buildBreakdownItem(
                'Negative',
                _stats!.negativeRate,
                Colors.red,
                _stats!.negativeCount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    double percentage,
    Color color,
    int count,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            '($count)',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewHighlights() {
    final withComments = _reviews
        .where((r) => r.comment != null && r.comment!.isNotEmpty)
        .length;
    final withReplies = _reviews
        .where((r) => r.reply != null && r.reply!.isNotEmpty)
        .length;
    final avgRating = _stats?.average ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _highlightItem('📝', '$withComments', 'With Comments'),
          _highlightItem('💬', '$withReplies', 'With Replies'),
          _highlightItem('⭐', avgRating.toStringAsFixed(1), 'Average'),
        ],
      ),
    );
  }

  Widget _highlightItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating == 3) return Colors.orange;
    return Colors.red;
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
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }
}
