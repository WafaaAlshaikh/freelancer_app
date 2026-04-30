// lib/screens/skill_tests/skill_tests_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/skill_test_service.dart';
import '../../models/skill_test_model.dart';
import '../../theme/app_theme.dart';
import 'test_taking_screen.dart';
import 'test_results_screen.dart';

class SkillTestsScreen extends StatefulWidget {
  const SkillTestsScreen({super.key});

  @override
  State<SkillTestsScreen> createState() => _SkillTestsScreenState();
}

class _SkillTestsScreenState extends State<SkillTestsScreen>
    with SingleTickerProviderStateMixin {
  List<SkillTest> _tests = [];
  TestStats? _stats;
  bool _loading = true;
  String _selectedCategory = 'all';
  late TabController _tabController;

  final List<String> _categories = [
    'all',
    'Programming',
    'Design',
    'Writing',
    'Marketing',
    'Business',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.wait([_loadTests(), _loadStats()]);
    setState(() => _loading = false);
  }

  Future<void> _loadTests() async {
    final tests = await SkillTestService.getAvailableTests(
      skillCategory: _selectedCategory == 'all' ? null : _selectedCategory,
    );
    setState(() => _tests = tests);
  }

  Future<void> _loadStats() async {
    final stats = await SkillTestService.getUserTestStats();
    setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Skill Tests'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStatsCard(),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.secondary,
                unselectedLabelColor: isDark
                    ? Colors.grey.shade500
                    : Colors.grey,
                indicatorColor: theme.colorScheme.secondary,
                tabs: const [
                  Tab(text: 'Available Tests'),
                  Tab(text: 'My Results'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildAvailableTestsTab(), _buildResultsTab()],
            ),
    );
  }

  Widget _buildStatsCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.purple.shade900, Colors.blue.shade900]
              : [Colors.purple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('${_stats!.totalTests}', 'Tests Taken', Icons.quiz),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          _buildStatItem(
            '${_stats!.passedTests}',
            'Passed',
            Icons.check_circle,
            color: theme.colorScheme.secondary,
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          _buildStatItem(
            '${_stats!.averageScore}%',
            'Avg Score',
            Icons.analytics,
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          _buildStatItem(
            '${_stats!.passRate}%',
            'Pass Rate',
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    final defaultColor = theme.colorScheme.primary;

    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? defaultColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? defaultColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableTestsTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.toUpperCase()),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = cat;
                        _loadTests();
                      });
                    },
                    backgroundColor: isDark
                        ? AppColors.darkSurface
                        : Colors.grey.shade100,
                    selectedColor: theme.colorScheme.secondary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: _tests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz,
                        size: 64,
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tests available',
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tests.length,
                  itemBuilder: (context, index) {
                    final test = _tests[index];
                    return _buildTestCard(test);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTestCard(SkillTest test) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TestTakingScreen(test: test)),
          );
          if (result == true) {
            _loadData();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: test.difficultyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      test.difficultyText,
                      style: TextStyle(
                        fontSize: 11,
                        color: test.difficultyColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (test.userPassed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Passed',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                test.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                test.description ??
                    'Test your knowledge in ${test.skillCategory}',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.quiz, size: 14, color: AppColors.gray),
                  const SizedBox(width: 4),
                  Text(
                    '${test.questions.length} questions',
                    style: TextStyle(fontSize: 12, color: AppColors.gray),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timer, size: 14, color: AppColors.gray),
                  const SizedBox(width: 4),
                  Text(
                    '${test.timeLimitMinutes} min',
                    style: TextStyle(fontSize: 12, color: AppColors.gray),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${test.passingScore}% to pass',
                    style: TextStyle(fontSize: 12, color: AppColors.gray),
                  ),
                ],
              ),
              if (test.badge != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(test.badge!.color.replaceFirst('#', '0xff')),
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 14,
                        color: Color(
                          int.parse(
                            test.badge!.color.replaceFirst('#', '0xff'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Earn "${test.badge!.name}" badge upon passing',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(
                            int.parse(
                              test.badge!.color.replaceFirst('#', '0xff'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (test.userAttempts > 0 && !test.userPassed) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 14, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Attempt ${test.userAttempts}/${test.maxAttempts}. ${test.canRetake ? 'You can retake this test.' : 'No more attempts remaining.'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<List<TestResult>>(
      future: SkillTestService.getUserTestResults(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          );
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_turned_in,
                  size: 64,
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No test results yet',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take your first skill test to see results here',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return _buildResultCard(result);
          },
        );
      },
    );
  }

  Widget _buildResultCard(TestResult result) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: result.passed
                        ? theme.colorScheme.secondary.withOpacity(0.1)
                        : AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        result.passed ? Icons.check_circle : Icons.cancel,
                        size: 12,
                        color: result.passed
                            ? theme.colorScheme.secondary
                            : AppColors.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        result.passed ? 'Passed' : 'Failed',
                        style: TextStyle(
                          fontSize: 11,
                          color: result.passed
                              ? theme.colorScheme.secondary
                              : AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(result.completedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              result.testName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.skillCategory,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${result.percentage}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: result.passed
                                ? theme.colorScheme.secondary
                                : AppColors.danger,
                          ),
                        ),
                        Text(
                          'Score',
                          style: TextStyle(fontSize: 10, color: AppColors.gray),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Attempt ${result.attemptNumber}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Attempt',
                          style: TextStyle(fontSize: 10, color: AppColors.gray),
                        ),
                      ],
                    ),
                  ),
                ),
                if (result.badge != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(
                            result.badge!.color.replaceFirst('#', '0xff'),
                          ),
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 20,
                            color: Color(
                              int.parse(
                                result.badge!.color.replaceFirst('#', '0xff'),
                              ),
                            ),
                          ),
                          Text(
                            result.badge!.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(
                                int.parse(
                                  result.badge!.color.replaceFirst('#', '0xff'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (result.passed && result.badge != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Badge awarded: ${result.badge!.name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }
}

class TestStats {
  final int totalTests;
  final int passedTests;
  final int averageScore;
  final int passRate;
  final Map<String, dynamic> skillsStats;

  TestStats({
    required this.totalTests,
    required this.passedTests,
    required this.averageScore,
    required this.passRate,
    required this.skillsStats,
  });

  factory TestStats.fromJson(Map<String, dynamic> json) {
    return TestStats(
      totalTests: json['totalTests'] ?? 0,
      passedTests: json['passedTests'] ?? 0,
      averageScore: json['averageScore'] ?? 0,
      passRate: json['passRate'] ?? 0,
      skillsStats: json['skillsStats'] ?? {},
    );
  }
}
