// lib/screens/interview/question_library_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

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

  final List<String> _categories = [
    'technical',
    'portfolio',
    'softSkills',
    'cultural',
  ];
  final Map<String, String> _categoryNames = {
    'technical': 'Technical Questions',
    'portfolio': 'Portfolio Review',
    'softSkills': 'Soft Skills',
    'cultural': 'Cultural Fit',
  };

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _loading = true);
    final result = await ApiService.getQuestionLibrary();
    setState(() {
      _questions = result['questions'] ?? {};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Interview Question Library'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCategoryTabs(),
                Expanded(child: _buildQuestionsList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRandomQuestion(),
        icon: const Icon(Icons.shuffle),
        label: const Text('Random Question'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  Widget _buildCategoryTabs() {
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
            backgroundColor: Colors.white,
            selectedColor: Colors.purple.shade100,
            checkmarkColor: Colors.purple,
          );
        },
      ),
    );
  }

  Widget _buildQuestionsList() {
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
            Icon(Icons.question_mark, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No questions found',
              style: TextStyle(color: Colors.grey.shade600),
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
    Color getDifficultyColor(String difficulty) {
      switch (difficulty) {
        case 'Easy':
          return Colors.green;
        case 'Medium':
          return Colors.orange;
        case 'Hard':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ),
        ),
        title: Text(
          question['question'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: getDifficultyColor(
                  question['difficulty'],
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                question['difficulty'],
                style: TextStyle(
                  fontSize: 10,
                  color: getDifficultyColor(question['difficulty']),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              question['category'],
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Tips for answering:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  _getTipForQuestion(question['question']),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.content_copy, size: 18),
                      onPressed: () => _copyToClipboard(question['question']),
                      tooltip: 'Copy question',
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_border, size: 18),
                      onPressed: () => _saveToFavorites(question),
                      tooltip: 'Save to favorites',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 18),
                      onPressed: () => _shareQuestion(question['question']),
                      tooltip: 'Share',
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Questions'),
        content: TextField(
          onChanged: (value) {
            setState(() => _searchQuery = value);
            Navigator.pop(context);
          },
          decoration: const InputDecoration(
            hintText: 'Search by keyword...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
      ),
    );
  }

  void _showRandomQuestion() {
    final allQuestions = [..._questions.values.expand((q) => q as List)];
    if (allQuestions.isEmpty) return;

    final random =
        allQuestions[DateTime.now().millisecondsSinceEpoch %
            allQuestions.length];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 48, color: Colors.purple),
            const SizedBox(height: 16),
            const Text(
              'Random Question for You',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                random['question'],
                style: const TextStyle(fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(random['question']),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTipForQuestion(String question) {
    if (question.contains('experience')) {
      return 'Use the STAR method (Situation, Task, Action, Result) to structure your answer.';
    }
    if (question.contains('challenge')) {
      return 'Focus on the problem-solving process and what you learned.';
    }
    if (question.contains('deadline')) {
      return 'Show your time management skills and ability to prioritize.';
    }
    return 'Be honest and provide specific examples from your experience.';
  }

  void _copyToClipboard(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question copied to clipboard!')),
    );
  }

  void _saveToFavorites(Map<String, dynamic> question) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Added to favorites!')));
  }

  void _shareQuestion(String question) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share feature coming soon!')));
  }
}
