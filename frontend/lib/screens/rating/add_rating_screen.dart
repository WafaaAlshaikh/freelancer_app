// screens/rating/add_rating_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AddRatingScreen extends StatefulWidget {
  final int contractId;
  final String projectTitle;
  final String otherPartyName;
  final String role;

  const AddRatingScreen({
    super.key,
    required this.contractId,
    required this.projectTitle,
    required this.otherPartyName,
    required this.role,
  });

  @override
  State<AddRatingScreen> createState() => _AddRatingScreenState();
}

class _AddRatingScreenState extends State<AddRatingScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.rateYourExperience),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.project,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.projectTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${t.youAreRating}: ${widget.otherPartyName}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              t.yourRating,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              t.yourReviewOptional,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: t.shareYourExperience,
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
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _rating == 0
                    ? null
                    : _isLoading
                    ? null
                    : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _rating == 0 ? t.pleaseSelectRating : t.submitRating,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  t.maybeLater,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    final result = await ApiService.addRating(
      contractId: widget.contractId,
      rating: _rating,
      comment: _commentController.text.isNotEmpty
          ? _commentController.text
          : null,
    );

    setState(() => _isLoading = false);

    if (result['rating'] != null) {
      Fluttertoast.showToast(msg: t.thankYouForRating);
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? t.errorSubmittingRating);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
