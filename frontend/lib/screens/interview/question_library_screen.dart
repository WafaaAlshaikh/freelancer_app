// lib/screens/interview/question_library_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class QuestionLibraryScreen extends StatefulWidget {
  const QuestionLibraryScreen({super.key});

  @override
  State<QuestionLibraryScreen> createState() => _QuestionLibraryScreenState();
}

class _QuestionLibraryScreenState extends State<QuestionLibraryScreen> {
  Map<String, dynamic> _questions = {};
  bool _loading = true;
  String _selectedCategory = 'technical';
  String _searchQuery = '';

  List<String> get _categories {
    final t = AppLocalizations.of(context);
    return ['technical', 'portfolio', 'softSkills', 'cultural'];
  }

  Map<String, String> get _categoryNames {
    final t = AppLocalizations.of(context);
    return {
      'technical': t?.technicalQuestions ?? 'Technical Questions',
      'portfolio': t?.portfolioReview ?? 'Portfolio Review',
      'softSkills': t?.softSkills ?? 'Soft Skills',
      'cultural': t?.culturalFit ?? 'Cultural Fit',
    };
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    final result = await ApiService.getQuestionLibrary();
    setState(() {
      _questions = result['questions'] ?? {};
      _loading = false;
    });
  }

  Color _getDifficultyColor(String difficulty) {
    final t = AppLocalizations.of(context);
    final difficultyLower = difficulty.toLowerCase();
    if (difficultyLower == 'easy' ||
        difficultyLower == (t?.easy?.toLowerCase() ?? 'easy')) {
      return AppColors.success;
    } else if (difficultyLower == 'medium' ||
        difficultyLower == (t?.medium?.toLowerCase() ?? 'medium')) {
      return AppColors.warning;
    } else {
      return AppColors.danger;
    }
  }

  String _getTipForQuestion(String question) {
    final t = AppLocalizations.of(context);
    if (question.contains('experience') || question.contains('تجربة')) {
      return t?.tipStarMethod ??
          'Use the STAR method (Situation, Task, Action, Result) to structure your answer.';
    }
    if (question.contains('challenge') || question.contains('تحدي')) {
      return t?.tipChallenge ??
          'Focus on the problem-solving process and what you learned.';
    }
    if (question.contains('deadline') || question.contains('موعد')) {
      return t?.tipDeadline ??
          'Show your time management skills and ability to prioritize.';
    }
    return t?.tipGeneral ??
        'Be honest and provide specific examples from your experience.';
  }

  void _copyToClipboard(String text) {
    final t = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.questionCopiedToClipboard),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _saveToFavorites(Map<String, dynamic> question) {
    final t = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.addedToFavorites),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _shareQuestion(String question) {
    final t = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.shareFeatureComingSoon),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showSearchDialog() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          t.searchQuestions,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: TextField(
          onChanged: (value) {
            setState(() => _searchQuery = value);
            Navigator.pop(context);
          },
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: t.searchByKeyword,
            hintStyle: TextStyle(color: AppColors.gray),
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
          autofocus: true,
        ),
      ),
    );
  }

  void _showRandomQuestion() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final allQuestions = [..._questions.values.expand((q) => q as List)];
    if (allQuestions.isEmpty) return;

    final random =
        allQuestions[DateTime.now().millisecondsSinceEpoch %
            allQuestions.length];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              t.randomQuestionForYou,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                random['question'],
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(random['question']),
                    icon: Icon(Icons.copy, color: theme.colorScheme.primary),
                    label: Text(
                      t.copy,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: Text(t.close),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.interviewQuestionLibrary),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.iconTheme.color),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : Column(
              children: [
                _buildCategoryTabs(),
                Expanded(child: _buildQuestionsList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRandomQuestion(),
        icon: const Icon(Icons.shuffle),
        label: Text(t.randomQuestion),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 50,
      margin: const EdgeInsets.all(16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return FilterChip(
            label: Text(_categoryNames[category]!),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedCategory = category),
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            selectedColor: theme.colorScheme.primary.withOpacity(0.2),
            labelStyle: TextStyle(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            checkmarkColor: theme.colorScheme.primary,
          );
        },
      ),
    );
  }

  Widget _buildQuestionsList() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final questions = _questions[_selectedCategory] ?? [];
    final filteredQuestions = _searchQuery.isEmpty
        ? questions
        : questions
              .where(
                (q) =>
                    q['question'].toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    q['category'].toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

    if (filteredQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.question_mark,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              t.noQuestionsFound,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredQuestions.length,
      itemBuilder: (context, index) {
        final question = filteredQuestions[index];
        return _buildQuestionCard(question, index);
      },
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ExpansionTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        title: Text(
          question['question'],
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getDifficultyColor(
                  question['difficulty'],
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                question['difficulty'],
                style: TextStyle(
                  fontSize: 10,
                  color: _getDifficultyColor(question['difficulty']),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              question['category'],
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.tipsForAnswering,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getTipForQuestion(question['question']),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.content_copy,
                        size: 18,
                        color: theme.iconTheme.color,
                      ),
                      onPressed: () => _copyToClipboard(question['question']),
                      tooltip: t.copyQuestion,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: theme.iconTheme.color,
                      ),
                      onPressed: () => _saveToFavorites(question),
                      tooltip: t.saveToFavorites,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.share,
                        size: 18,
                        color: theme.iconTheme.color,
                      ),
                      onPressed: () => _shareQuestion(question['question']),
                      tooltip: t.share,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
