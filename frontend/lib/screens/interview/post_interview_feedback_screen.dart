// lib/screens/interview/post_interview_feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

class PostInterviewFeedbackScreen extends StatefulWidget {
  final int invitationId;
  final String freelancerName;

  const PostInterviewFeedbackScreen({
    super.key,
    required this.invitationId,
    required this.freelancerName,
  });

  @override
  State<PostInterviewFeedbackScreen> createState() =>
      _PostInterviewFeedbackScreenState();
}

class _PostInterviewFeedbackScreenState
    extends State<PostInterviewFeedbackScreen> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _improvementsController = TextEditingController();
  bool _wouldHireAgain = true;
  bool _submitting = false;

  final List<String> _quickRatings = [
    'Professionalism',
    'Communication',
    'Technical Skills',
    'Punctuality',
  ];
  final Map<String, double> _quickRatingsValues = {};

  @override
  void initState() {
    super.initState();
    for (var rating in _quickRatings) {
      _quickRatingsValues[rating] = 3.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Interview Feedback'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildOverallRating(),
            const SizedBox(height: 24),
            _buildDetailedRatings(),
            const SizedBox(height: 24),
            _buildCommentSection(),
            const SizedBox(height: 24),
            _buildImprovementsSection(),
            const SizedBox(height: 24),
            _buildHireAgain(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.feedback, size: 48, color: Colors.purple),
          const SizedBox(height: 12),
          Text(
            'Share Your Experience',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your feedback helps ${widget.freelancerName} improve and helps other clients make informed decisions.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallRating() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Rating',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 40,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) {
                    setState(() => _rating = rating);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _getRatingText(_rating),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getRatingColor(_rating),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedRatings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Ratings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._quickRatings.map(
            (rating) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rating, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  RatingBar.builder(
                    initialRating: _quickRatingsValues[rating]!,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 24,
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                    onRatingUpdate: (value) {
                      setState(() => _quickRatingsValues[rating] = value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What went well?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share what you liked about the interview...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What could be improved?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _improvementsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Constructive feedback for improvement...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHireAgain() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, color: Colors.purple),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Would you hire this freelancer again?',
              style: TextStyle(fontSize: 14),
            ),
          ),
          Switch(
            value: _wouldHireAgain,
            onChanged: (value) => setState(() => _wouldHireAgain = value),
            activeColor: Colors.green,
          ),
          Text(
            _wouldHireAgain ? 'Yes' : 'No',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _wouldHireAgain ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _submitting || _rating == 0 ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff14A800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _submitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Submit Feedback',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    setState(() => _submitting = true);

    final averageRating =
        (_quickRatingsValues.values.reduce((a, b) => a + b) /
            _quickRatingsValues.length) +
        _rating;
    final finalRating = (averageRating / 2).round();

    final result = await ApiService.addPostInterviewFeedback(
      invitationId: widget.invitationId,
      rating: finalRating,
      comment: _commentController.text,
      improvements: _improvementsController.text,
      wouldHireAgain: _wouldHireAgain,
    );

    setState(() => _submitting = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(
        msg: 'Thank you for your feedback!',
        backgroundColor: Colors.green,
      );
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Error submitting feedback',
        backgroundColor: Colors.red,
      );
    }
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent! 🌟';
    if (rating >= 3.5) return 'Very Good! 👍';
    if (rating >= 2.5) return 'Good 👌';
    if (rating >= 1.5) return 'Fair 😐';
    return 'Poor 😞';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }
}
