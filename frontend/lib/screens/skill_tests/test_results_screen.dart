// lib/screens/skill_tests/test_results_screen.dart
import 'package:flutter/material.dart' hide Badge;
import 'package:fluttertoast/fluttertoast.dart';
import '../../models/skill_test_model.dart';
import '../../services/skill_test_service.dart';

class TestResultsScreen extends StatefulWidget {
  final int userTestId;
  final SkillTest test;
  final Map<String, dynamic> result;

  const TestResultsScreen({
    super.key,
    required this.userTestId,
    required this.test,
    required this.result,
  });

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _detailedAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadDetailedResults();
  }

  Future<void> _loadDetailedResults() async {
    setState(() => _loading = true);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final passed = widget.result['passed'];
    final percentage = widget.result['percentage'];
    final totalPoints = widget.result['totalPoints'];
    final earnedPoints = widget.result['earnedPoints'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareResults),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResultHeader(passed, percentage),
                  const SizedBox(height: 24),
                  _buildScoreCard(percentage, totalPoints, earnedPoints),
                  const SizedBox(height: 24),
                  if (passed && widget.test.badge != null)
                    _buildBadgeCard(widget.test.badge!),
                  const SizedBox(height: 24),
                  _buildPerformanceAnalysis(percentage),
                  const SizedBox(height: 24),
                  _buildQuestionReview(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildResultHeader(bool passed, int percentage) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: passed
              ? [Colors.green.shade400, Colors.green.shade700]
              : [Colors.orange.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            passed ? Icons.celebration : Icons.sentiment_dissatisfied,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            passed ? 'Congratulations!' : 'Keep Learning!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            passed
                ? 'You passed the ${widget.test.name} test'
                : 'You scored ${percentage}% on the ${widget.test.name} test',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          if (!passed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Need ${widget.test.passingScore}% to pass',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(int percentage, int totalPoints, int earnedPoints) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Score',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: percentage >= widget.test.passingScore
                  ? Colors.green
                  : Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              percentage >= widget.test.passingScore
                  ? Colors.green
                  : Colors.red,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScoreDetail('Total Points', '$totalPoints'),
              _buildScoreDetail('Earned Points', '$earnedPoints'),
              _buildScoreDetail(
                'Passing Score',
                '${widget.test.passingScore}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDetail(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(Badge badge) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(
              int.parse(badge.color.replaceFirst('#', '0xff')),
            ).withOpacity(0.1),
            Color(
              int.parse(badge.color.replaceFirst('#', '0xff')),
            ).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(
            int.parse(badge.color.replaceFirst('#', '0xff')),
          ).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(
                int.parse(badge.color.replaceFirst('#', '0xff')),
              ).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              size: 32,
              color: Color(int.parse(badge.color.replaceFirst('#', '0xff'))),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Badge Earned!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(
                      int.parse(badge.color.replaceFirst('#', '0xff')),
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (badge.description != null)
                  Text(
                    badge.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceAnalysis(int percentage) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, size: 20, color: Color(0xff14A800)),
              SizedBox(width: 8),
              Text(
                'Performance Analysis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPerformanceItem(
            'Score Analysis',
            percentage >= 90
                ? 'Excellent! You have mastered this skill.'
                : percentage >= 70
                ? 'Good work! You have a solid understanding.'
                : percentage >= 50
                ? 'You have a basic understanding. Keep practicing!'
                : 'You need more practice. Review the material and try again.',
            Icons.trending_up,
          ),
          const SizedBox(height: 12),
          _buildPerformanceItem(
            'Recommended Actions',
            percentage < widget.test.passingScore
                ? '• Review the test questions\n• Study the topics you missed\n• Take the test again after preparation'
                : '• Apply your skills in real projects\n• Share your badge on your profile\n• Help others learn this skill',
            Icons.lightbulb,
          ),
          const SizedBox(height: 12),
          _buildPerformanceItem(
            'Next Steps',
            percentage >= 80
                ? 'Ready for advanced tests in this category!'
                : percentage >= 60
                ? 'Consider taking more practice tests'
                : 'Start with beginner-level materials first',
            Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.question_answer, size: 20, color: Color(0xff14A800)),
              SizedBox(width: 8),
              Text(
                'Question Review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Detailed answer review will be available soon.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (!widget.result['passed'])
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff14A800),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (widget.result['passed'])
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Done'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff14A800),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _shareResults() async {
    Fluttertoast.showToast(msg: 'Share feature coming soon!');
  }
}
