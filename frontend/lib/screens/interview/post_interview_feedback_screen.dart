// lib/screens/interview/post_interview_feedback_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

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
  void dispose() {
    _commentController.dispose();
    _improvementsController.dispose();
    super.dispose();
  }

  String _getRatingText(double rating) {
    final t = AppLocalizations.of(context);
    if (rating >= 4.5) return t?.excellent ?? 'Excellent! 🌟';
    if (rating >= 3.5) return t?.veryGood ?? 'Very Good! 👍';
    if (rating >= 2.5) return t?.good ?? 'Good 👌';
    if (rating >= 1.5) return t?.fair ?? 'Fair 😐';
    return t?.poor ?? 'Poor 😞';
  }

  Color _getRatingColor(double rating) {
    final theme = Theme.of(context);
    if (rating >= 4) return theme.colorScheme.secondary;
    if (rating >= 3) return AppColors.warning;
    return AppColors.danger;
  }

  Future<void> _submitFeedback() async {
    final t = AppLocalizations.of(context)!;
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
        msg: t.thankYouForFeedback,
        backgroundColor: AppColors.success,
      );
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? t.errorSubmittingFeedback,
        backgroundColor: AppColors.danger,
      );
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
        title: Text(t.interviewFeedback),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.purple.shade900.withOpacity(0.5),
                  Colors.blue.shade900.withOpacity(0.5),
                ]
              : [Colors.purple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.feedback, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            t.shareYourExperience,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.feedbackDescription(widget.freelancerName),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallRating() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.overallRating,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.detailedRatings,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ..._quickRatings.map(
            (rating) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getRatingLabel(rating),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
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

  String _getRatingLabel(String ratingKey) {
    final t = AppLocalizations.of(context)!;
    switch (ratingKey) {
      case 'Professionalism':
        return t.ratingLabelProfessionalism;
      case 'Communication':
        return t.ratingLabelCommunication;
      case 'Technical Skills':
        return t.ratingLabelTechnicalSkills;
      case 'Punctuality':
        return t.ratingLabelPunctuality;
      default:
        return ratingKey;
    }
  }

  Widget _buildCommentSection() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.whatWentWell,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _commentController,
            maxLines: 4,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: t.whatWentWellHint,
              hintStyle: TextStyle(color: AppColors.gray),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementsSection() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.whatCouldBeImproved,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _improvementsController,
            maxLines: 3,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: t.whatCouldBeImprovedHint,
              hintStyle: TextStyle(color: AppColors.gray),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHireAgain() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.people, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.wouldYouHireAgain,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: _wouldHireAgain,
            onChanged: (value) => setState(() => _wouldHireAgain = value),
            activeColor: theme.colorScheme.secondary,
          ),
          Text(
            _wouldHireAgain ? t.yes : t.no,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _wouldHireAgain
                  ? theme.colorScheme.secondary
                  : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _submitting || _rating == 0 ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _submitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                t.submitFeedback,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
