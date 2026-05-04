// lib/screens/client/compare_freelancers_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:freelancer_platform/screens/chat/chat_screen.dart';
import 'package:freelancer_platform/screens/client/hire_freelancer_dialog.dart';
import 'package:freelancer_platform/services/chat_service.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class CompareFreelancersScreen extends StatefulWidget {
  final int projectId;
  final List<int> freelancerIds;

  const CompareFreelancersScreen({
    super.key,
    required this.projectId,
    required this.freelancerIds,
  });

  @override
  State<CompareFreelancersScreen> createState() =>
      _CompareFreelancersScreenState();
}

class _CompareFreelancersScreenState extends State<CompareFreelancersScreen>
    with SingleTickerProviderStateMixin {
  List<FreelancerComparison> _freelancers = [];
  bool _loading = true;
  int _selectedMetric = 0;
  bool _showDetailedComparison = false;
  late TabController _tabController;
  int? _recommendedFreelancerId;

  List<MetricOption> _getMetrics(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return [
      MetricOption(
        id: 0,
        title: t.overall,
        icon: Icons.star,
        color: Colors.amber,
        description: t.overallRatingDescription,
      ),
      MetricOption(
        id: 1,
        title: t.skills,
        icon: Icons.code,
        color: Colors.blue,
        description: t.skillsMatchDescription,
      ),
      MetricOption(
        id: 2,
        title: t.experience,
        icon: Icons.work,
        color: Colors.green,
        description: t.experienceDescription,
      ),
      MetricOption(
        id: 3,
        title: t.reliability,
        icon: Icons.verified,
        color: Colors.purple,
        description: t.reliabilityDescription,
      ),
      MetricOption(
        id: 4,
        title: t.communication,
        icon: Icons.chat,
        color: Colors.orange,
        description: t.communicationDescription,
      ),
      MetricOption(
        id: 5,
        title: t.value,
        icon: Icons.attach_money,
        color: Colors.teal,
        description: t.valueDescription,
      ),
    ];
  }

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

    try {
      final result = await ApiService.compareFreelancers(
        freelancerIds: widget.freelancerIds,
        projectId: widget.projectId,
      );

      if (result['success'] == true && result['comparisons'] != null) {
        final freelancers = (result['comparisons'] as List)
            .map((json) => FreelancerComparison.fromJson(json))
            .toList();

        _recommendedFreelancerId = _calculateAIRecommendation(freelancers);

        setState(() {
          _freelancers = freelancers;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error loading comparison data: $e');
      setState(() => _loading = false);
    }
  }

  int _calculateAIRecommendation(List<FreelancerComparison> freelancers) {
    if (freelancers.isEmpty) return -1;

    double bestScore = 0;
    int bestId = -1;

    for (final f in freelancers) {
      double score = 0;
      score += f.rating * 20;
      score += (f.skillsMatch / 100) * 25;
      score += (f.completionRate / 100) * 20;
      score += (f.responseTimeHours <= 2
          ? 15
          : f.responseTimeHours <= 6
          ? 10
          : 5);
      score += (f.completedProjects / 20) * 10;
      score += (f.experienceYears / 10) * 10;

      if (score > bestScore) {
        bestScore = score;
        bestId = f.id;
      }
    }

    return bestId;
  }

  bool _isDarkMode() {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();
    final metrics = _getMetrics(context);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          t.compareFreelancers,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? AppColors.darkTextPrimary : Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildMetricSelector(metrics),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showDetailedComparison ? Icons.grid_view : Icons.compare_arrows,
              color: AppColors.accent,
            ),
            onPressed: () {
              setState(() {
                _showDetailedComparison = !_showDetailedComparison;
              });
            },
            tooltip: _showDetailedComparison
                ? t.switchToCardView
                : t.switchToDetailedView,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: t.refresh,
          ),
        ],
      ),
      body: _loading
          ? _buildLoadingState()
          : _freelancers.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                if (_recommendedFreelancerId != -1)
                  _buildAIRecommendationBanner(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildComparisonView(metrics),
                      _buildDetailedTableView(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComparisonChart(),
        icon: const Icon(Icons.bar_chart),
        label: Text(t.viewCharts),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primaryDark,
      ),
    );
  }

  String _getMetricLabel(String key) {
    final t = AppLocalizations.of(context)!;
    switch (key) {
      case 'overall':
        return t.overall;
      case 'skills':
        return t.skills;
      case 'experience':
        return t.experience;
      case 'reliability':
        return t.reliability;
      case 'communication':
        return t.communication;
      case 'value':
        return t.value;
      default:
        return key;
    }
  }

  Widget _buildLoadingState() {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t.analyzingFreelancers,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.comparingFreelancersDesc,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextHint : AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 80,
            color: isDark ? AppColors.darkTextHint : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            t.noFreelancersToCompare,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.selectAtLeastTwoFreelancers,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: Text(t.goBack),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSelector(List<MetricOption> metrics) {
    final isDark = _isDarkMode();

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.primaryDark : AppColors.border,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: metrics.length,
        itemBuilder: (context, index) {
          final metric = metrics[index];
          final isSelected = _selectedMetric == metric.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedMetric = metric.id),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? metric.color : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? metric.color
                      : (isDark ? AppColors.primaryDark : AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    metric.icon,
                    size: 18,
                    color: isSelected ? Colors.white : metric.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    metric.title,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.dark),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAIRecommendationBanner() {
    final t = AppLocalizations.of(context)!;
    final recommended = _freelancers.firstWhere(
      (f) => f.id == _recommendedFreelancerId,
      orElse: () => _freelancers.first,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.aiRecommendation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  recommended.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${recommended.skillsMatch}% ${t.matchWithProject}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${recommended.overallScore}%',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonView(List<MetricOption> metrics) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _freelancers.length,
        itemBuilder: (context, index) {
          final freelancer = _freelancers[index];
          final isRecommended = freelancer.id == _recommendedFreelancerId;
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50,
              child: FadeInAnimation(
                child: _buildComparisonCard(
                  freelancer,
                  index,
                  isRecommended,
                  metrics,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComparisonCard(
    FreelancerComparison f,
    int rank,
    bool isRecommended,
    List<MetricOption> metrics,
  ) {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();
    final metric = metrics[_selectedMetric];
    final metricValue = _getMetricValue(f, _selectedMetric);
    final maxValue = _getMaxValue(_selectedMetric);
    final percentage = (metricValue / maxValue) * 100;
    double safePercentage = percentage.isNaN || percentage.isInfinite
        ? 0
        : percentage;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isRecommended
            ? Border.all(color: AppColors.accent, width: 2)
            : null,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isRecommended
                  ? AppColors.primaryGradient
                  : rank == 0
                  ? const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: isDark
                          ? [
                              AppColors.darkTextSecondary,
                              AppColors.darkTextHint,
                            ]
                          : [Colors.grey.shade400, Colors.grey.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${rank + 1}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isRecommended
                            ? AppColors.accent
                            : rank == 0
                            ? Colors.amber
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  backgroundImage: f.avatar != null
                      ? NetworkImage(f.avatar!)
                      : null,
                  child: f.avatar == null
                      ? Text(
                          f.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              f.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (isRecommended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    t.aiPick,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.title,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(metric.icon, color: metric.color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          metric.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: metric.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getMetricDisplay(f, _selectedMetric),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: metric.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: safePercentage / 100,
                    backgroundColor: isDark
                        ? AppColors.primaryDark
                        : AppColors.border,
                    valueColor: AlwaysStoppedAnimation(metric.color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatRow(
                  t.overallRating,
                  f.rating.toStringAsFixed(1),
                  Icons.star,
                  Colors.amber,
                  t.outOf5,
                  isDark,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  t.skillsMatch,
                  '${f.skillsMatch}%',
                  Icons.code,
                  Colors.blue,
                  t.withYourProject,
                  isDark,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  t.completionRate,
                  '${f.completionRate}%',
                  Icons.check_circle,
                  AppColors.success,
                  t.ofProjectsCompleted,
                  isDark,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  t.onTimeDelivery,
                  '${f.onTimeDelivery}%',
                  Icons.access_time,
                  AppColors.info,
                  t.ofDeadlinesMet,
                  isDark,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  t.responseTime,
                  f.responseTimeHours <= 1
                      ? '< 1 ${t.hour}'
                      : '${f.responseTimeHours} ${t.hours}',
                  Icons.chat_bubble,
                  Colors.orange,
                  t.averageResponse,
                  isDark,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  t.projectsCompleted,
                  '${f.completedProjects}',
                  Icons.work,
                  AppColors.success,
                  t.totalProjects,
                  isDark,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  t.experience,
                  '${f.experienceYears} ${t.years}',
                  Icons.trending_up,
                  Colors.green,
                  t.inTheField,
                  isDark,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  t.hourlyRate,
                  '\$${f.hourlyRate.toStringAsFixed(0)}/${t.hr}',
                  Icons.attach_money,
                  Colors.teal,
                  '${t.budget}: \$${f.projectBudget}',
                  isDark,
                ),
              ],
            ),
          ),

          if (f.skills.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.topSkills,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.gray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: f.skills.take(5).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.accent,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewProfile(f.id),
                    icon: const Icon(Icons.person, size: 18),
                    label: Text(t.viewProfile),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _startChatFromCompare(f.id, f.name, f.avatar),
                    icon: const Icon(Icons.chat, size: 18),
                    label: Text(t.message),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: BorderSide(color: AppColors.info),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _hireFreelancer(f.id),
                    icon: const Icon(Icons.how_to_reg, size: 18),
                    label: Text(t.hire),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedTableView() {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: WidgetStateProperty.resolveWith(
          (states) => AppColors.accent.withOpacity(0.1),
        ),
        columns: [
          const DataColumn(
            label: Text(
              'Criteria',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          ..._freelancers.map(
            (f) => DataColumn(
              label: Container(
                width: 150,
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: f.avatar != null
                          ? NetworkImage(f.avatar!)
                          : null,
                      child: f.avatar == null
                          ? Text(f.name[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        rows: [
          _buildDataRow(
            t.overallRating,
            _freelancers.map((f) => '${f.rating}/5').toList(),
          ),
          _buildDataRow(
            t.skillsMatch,
            _freelancers.map((f) => '${f.skillsMatch}%').toList(),
          ),
          _buildDataRow(
            t.completionRate,
            _freelancers.map((f) => '${f.completionRate}%').toList(),
          ),
          _buildDataRow(
            t.onTimeDelivery,
            _freelancers.map((f) => '${f.onTimeDelivery}%').toList(),
          ),
          _buildDataRow(
            t.responseTime,
            _freelancers.map((f) => '${f.responseTimeHours}h').toList(),
          ),
          _buildDataRow(
            t.projectsCompleted,
            _freelancers.map((f) => '${f.completedProjects}').toList(),
          ),
          _buildDataRow(
            t.experience,
            _freelancers.map((f) => '${f.experienceYears}y').toList(),
          ),
          _buildDataRow(
            t.hourlyRate,
            _freelancers.map((f) => '\$${f.hourlyRate}').toList(),
          ),
          _buildDataRow(
            t.reviews,
            _freelancers.map((f) => '${f.totalReviews}').toList(),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(String criteria, List<String> values) {
    return DataRow(
      cells: [
        DataCell(
          Text(criteria, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        ...values.map(
          (value) => DataCell(
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color color,
    String subtitle,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextHint : AppColors.gray,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  num _getMetricValue(FreelancerComparison f, int metricId) {
    switch (metricId) {
      case 0:
        return f.rating;
      case 1:
        return f.skillsMatch;
      case 2:
        return f.experienceYears * 10 + f.completedProjects;
      case 3:
        return f.completionRate;
      case 4:
        return (f.responseTimeHours <= 1
            ? 100
            : f.responseTimeHours <= 6
            ? 60
            : 30);
      case 5:
        if (f.hourlyRate == 0) return 0;
        return (f.rating * 20 + f.completionRate * 0.3) / (f.hourlyRate / 10);
      default:
        return f.rating;
    }
  }

  double _getMaxValue(int metricId) {
    switch (metricId) {
      case 0:
        return 5;
      case 1:
        return 100;
      case 2:
        return 100;
      case 3:
        return 100;
      case 4:
        return 100;
      case 5:
        return 100;
      default:
        return 100;
    }
  }

  String _getMetricDisplay(FreelancerComparison f, int metricId) {
    final t = AppLocalizations.of(context)!;
    switch (metricId) {
      case 0:
        return '${f.rating.toStringAsFixed(1)}/5';
      case 1:
        return '${f.skillsMatch}%';
      case 2:
        return '${f.experienceYears}y, ${f.completedProjects}${t.prj}';
      case 3:
        return '${f.completionRate}%';
      case 4:
        return f.responseTimeHours <= 1
            ? '<1${t.hour}'
            : '${f.responseTimeHours}${t.hours}';
      case 5:
        if (f.hourlyRate == 0) return '0%';
        final value =
            (f.rating * 20 + f.completionRate * 0.3) / (f.hourlyRate / 10);
        if (value.isNaN || value.isInfinite) return '0%';
        return '${value.toInt()}%';
      default:
        return '${f.rating}/5';
    }
  }

  void _showComparisonChart() {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkTextHint : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t.performanceComparison,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text(
                      t.ratingsComparison,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: _buildBarChart(
                        _freelancers.map((f) => f.rating).toList(),
                        _freelancers.map((f) => f.name).toList(),
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      t.skillsMatch,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: _buildBarChart(
                        _freelancers
                            .map((f) => f.skillsMatch.toDouble())
                            .toList(),
                        _freelancers.map((f) => f.name).toList(),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      t.completionRate,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: _buildBarChart(
                        _freelancers
                            .map((f) => f.completionRate.toDouble())
                            .toList(),
                        _freelancers.map((f) => f.name).toList(),
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      t.comprehensiveAnalysis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(height: 280, child: _buildRadarChart()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<double> values, List<String> labels, Color color) {
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.2;
    final isDark = _isDarkMode();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.gray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 50,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.gray,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? AppColors.primaryDark : Colors.grey.shade200,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.primaryDark : Colors.grey.shade300,
            ),
            left: BorderSide(
              color: isDark ? AppColors.primaryDark : Colors.grey.shade300,
            ),
          ),
        ),
        barGroups: List.generate(values.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: values[index],
                color: color,
                width: 40,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRadarChart() {
    final isDark = _isDarkMode();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'Radar chart will be implemented here',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : Colors.grey,
          ),
        ),
      ),
    );
  }

  void _viewProfile(int userId) {
    Navigator.pushNamed(context, '/profile', arguments: userId);
  }

  void _hireFreelancer(int userId) {
    final freelancer = _freelancers.firstWhere(
      (f) => f.id == userId,
      orElse: () => _freelancers.first,
    );

    showDialog(
      context: context,
      builder: (context) => HireFreelancerDialog(
        freelancerId: userId,
        freelancerName: freelancer.name,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Offer sent to ${freelancer.name}!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  void _startChatFromCompare(
    int userId,
    String userName,
    String? avatar,
  ) async {
    try {
      final chatResult = await ChatService.getOrCreateChat(userId);

      int chatId;
      if (chatResult['success'] == true && chatResult['chatId'] != null) {
        chatId = chatResult['chatId'] as int;
      } else {
        chatId = 0;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserId: userId,
              otherUserName: userName,
              otherUserAvatar: avatar,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting chat: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start chat: $e')));
    }
  }
}

class MetricOption {
  final int id;
  final String title;
  final IconData icon;
  final Color color;
  final String description;

  MetricOption({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class FreelancerComparison {
  final int id;
  final String name;
  final String? avatar;
  final String title;
  final double rating;
  final List<String> skills;
  final int experienceYears;
  final int completedProjects;
  final double completionRate;
  final double onTimeDelivery;
  final int responseTimeHours;
  final double hourlyRate;
  final int totalReviews;
  final int skillsMatch;
  final double projectBudget;
  final double overallScore;

  FreelancerComparison({
    required this.id,
    required this.name,
    this.avatar,
    required this.title,
    required this.rating,
    required this.skills,
    required this.experienceYears,
    required this.completedProjects,
    required this.completionRate,
    required this.onTimeDelivery,
    required this.responseTimeHours,
    required this.hourlyRate,
    required this.totalReviews,
    required this.skillsMatch,
    required this.projectBudget,
    required this.overallScore,
  });

  factory FreelancerComparison.fromJson(Map<String, dynamic> json) {
    return FreelancerComparison(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      avatar: json['avatar'],
      title: json['title'] ?? 'Freelancer',
      rating: (json['rating'] ?? 0).toDouble(),
      skills: List<String>.from(json['skills'] ?? []),
      experienceYears: json['experience'] ?? 0,
      completedProjects: json['projectsCompleted'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      onTimeDelivery: (json['onTimeDelivery'] ?? 0).toDouble(),
      responseTimeHours: json['responseTime'] ?? 24,
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      skillsMatch: json['skillsMatch'] ?? 0,
      projectBudget: (json['projectBudget'] ?? 0).toDouble(),
      overallScore: (json['overallScore'] ?? 0).toDouble(),
    );
  }
}
