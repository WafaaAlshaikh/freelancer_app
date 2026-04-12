// lib/screens/client/compare_freelancers_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/fl_chart.dart' as fl;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../services/api_service.dart';

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

  final List<MetricOption> _metrics = [
    MetricOption(
      id: 0,
      title: 'Overall',
      icon: Icons.star,
      color: Colors.amber,
      description: 'Overall rating and performance',
    ),
    MetricOption(
      id: 1,
      title: 'Skills',
      icon: Icons.code,
      color: Colors.blue,
      description: 'Skills match with your project',
    ),
    MetricOption(
      id: 2,
      title: 'Experience',
      icon: Icons.work,
      color: Colors.green,
      description: 'Years of experience & project count',
    ),
    MetricOption(
      id: 3,
      title: 'Reliability',
      icon: Icons.verified,
      color: Colors.purple,
      description: 'Completion rate & on-time delivery',
    ),
    MetricOption(
      id: 4,
      title: 'Communication',
      icon: Icons.chat,
      color: Colors.orange,
      description: 'Response time & feedback',
    ),
    MetricOption(
      id: 5,
      title: 'Value',
      icon: Icons.attach_money,
      color: Colors.teal,
      description: 'Price vs quality ratio',
    ),
  ];

  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4F46E5);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _info = Color(0xFF3B82F6);
  static const Color _dark = Color(0xFF1F2937);
  static const Color _gray = Color(0xFF6B7280);
  static const Color _lightGray = Color(0xFFF9FAFB);
  static const Color _border = Color(0xFFE5E7EB);

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
      print('Error loading comparison data: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      appBar: AppBar(
        title: const Text(
          'Compare Freelancers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildMetricSelector(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showDetailedComparison ? Icons.grid_view : Icons.compare_arrows,
              color: _primary,
            ),
            onPressed: () {
              setState(() {
                _showDetailedComparison = !_showDetailedComparison;
              });
            },
            tooltip: _showDetailedComparison
                ? 'Switch to Card View'
                : 'Switch to Detailed View',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
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
                      _buildComparisonView(),
                      _buildDetailedTableView(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComparisonChart(),
        icon: const Icon(Icons.bar_chart),
        label: const Text('View Charts'),
        backgroundColor: _primary,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, _primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
            'Analyzing freelancers...',
            style: TextStyle(fontSize: 16, color: _gray),
          ),
          const SizedBox(height: 8),
          Text(
            'Comparing skills, experience, and performance',
            style: TextStyle(fontSize: 12, color: _gray),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No freelancers to compare',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select at least 2 freelancers to start comparing',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
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

  Widget _buildMetricSelector() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _metrics.length,
        itemBuilder: (context, index) {
          final metric = _metrics[index];
          final isSelected = _selectedMetric == metric.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedMetric = metric.id),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? metric.color : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: isSelected ? metric.color : _border),
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
                      color: isSelected ? Colors.white : _dark,
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
    final recommended = _freelancers.firstWhere(
      (f) => f.id == _recommendedFreelancerId,
      orElse: () => _freelancers.first,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.3),
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
                const Text(
                  'AI Recommendation',
                  style: TextStyle(
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
                  '${recommended.skillsMatch}% match with your project',
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
                color: _primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonView() {
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
                child: _buildComparisonCard(freelancer, index, isRecommended),
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
  ) {
    final metric = _metrics[_selectedMetric];
    final metricValue = _getMetricValue(f, _selectedMetric);
    final maxValue = _getMaxValue(_selectedMetric);
    final percentage = (metricValue / maxValue) * 100;
    double safePercentage = percentage.isNaN || percentage.isInfinite
        ? 0
        : percentage;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isRecommended ? Border.all(color: _primary, width: 2) : null,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isRecommended
                    ? [_primary, _primaryDark]
                    : rank == 0
                    ? [Colors.amber.shade400, Colors.amber.shade600]
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
                            ? _primary
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
                            color: Colors.white,
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
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: _primary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'AI Pick',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _primary,
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
                            color: _dark,
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
                    backgroundColor: _border,
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
                  'Overall Rating',
                  f.rating.toStringAsFixed(1),
                  Icons.star,
                  Colors.amber,
                  'out of 5',
                ),
                const Divider(height: 24),
                _buildStatRow(
                  'Skills Match',
                  '${f.skillsMatch}%',
                  Icons.code,
                  Colors.blue,
                  'with your project',
                ),
                const Divider(height: 24),
                _buildStatRow(
                  'Completion Rate',
                  '${f.completionRate}%',
                  Icons.check_circle,
                  _success,
                  'of projects completed',
                ),
                const Divider(height: 24),
                _buildStatRow(
                  'On-Time Delivery',
                  '${f.onTimeDelivery}%',
                  Icons.access_time,
                  _info,
                  'of deadlines met',
                ),
                const Divider(height: 24),
                _buildStatRow(
                  'Response Time',
                  f.responseTimeHours <= 1
                      ? '< 1 hour'
                      : '${f.responseTimeHours} hours',
                  Icons.chat_bubble,
                  Colors.orange,
                  'average response',
                ),
                const Divider(height: 24),
                _buildStatRow(
                  'Projects Completed',
                  '${f.completedProjects}',
                  Icons.work,
                  _success,
                  'total projects',
                ),
                const Divider(height: 24),
                _buildStatRow(
                  'Experience',
                  '${f.experienceYears} years',
                  Icons.trending_up,
                  Colors.green,
                  'in the field',
                ),
                const Divider(height: 24),
                _buildStatRow(
                  'Hourly Rate',
                  '\$${f.hourlyRate.toStringAsFixed(0)}/hr',
                  Icons.attach_money,
                  Colors.teal,
                  'budget: \$${f.projectBudget}',
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
                  const Text(
                    'Top Skills',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _gray,
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
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(fontSize: 12, color: _primary),
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
                    label: const Text('View Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: _primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _hireFreelancer(f.id),
                    icon: const Icon(Icons.how_to_reg, size: 18),
                    label: const Text('Hire'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _success,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: WidgetStateProperty.resolveWith(
          (states) => _primary.withOpacity(0.1),
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
            'Overall Rating',
            _freelancers.map((f) => '${f.rating}/5').toList(),
          ),
          _buildDataRow(
            'Skills Match',
            _freelancers.map((f) => '${f.skillsMatch}%').toList(),
          ),
          _buildDataRow(
            'Completion Rate',
            _freelancers.map((f) => '${f.completionRate}%').toList(),
          ),
          _buildDataRow(
            'On-Time Delivery',
            _freelancers.map((f) => '${f.onTimeDelivery}%').toList(),
          ),
          _buildDataRow(
            'Response Time',
            _freelancers.map((f) => '${f.responseTimeHours}h').toList(),
          ),
          _buildDataRow(
            'Projects',
            _freelancers.map((f) => '${f.completedProjects}').toList(),
          ),
          _buildDataRow(
            'Experience',
            _freelancers.map((f) => '${f.experienceYears}y').toList(),
          ),
          _buildDataRow(
            'Hourly Rate',
            _freelancers.map((f) => '\$${f.hourlyRate}').toList(),
          ),
          _buildDataRow(
            'Reviews',
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
                  color: _gray,
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
                  Text(subtitle, style: TextStyle(fontSize: 11, color: _gray)),
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
    switch (metricId) {
      case 0:
        return '${f.rating.toStringAsFixed(1)}/5';
      case 1:
        return '${f.skillsMatch}%';
      case 2:
        return '${f.experienceYears}y, ${f.completedProjects}prj';
      case 3:
        return '${f.completionRate}%';
      case 4:
        return f.responseTimeHours <= 1 ? '<1h' : '${f.responseTimeHours}h';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Performance Comparison',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Text(
                      'Ratings Comparison',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

                    const Text(
                      'Skills Match',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

                    const Text(
                      'Completion Rate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                        _success,
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Comprehensive Analysis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                      style: const TextStyle(fontSize: 10),
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
                  style: const TextStyle(fontSize: 10),
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
              color: Colors.grey.shade200,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300),
            left: BorderSide(color: Colors.grey.shade300),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'Radar chart will be implemented here',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  void _viewProfile(int userId) {
    Navigator.pushNamed(context, '/profile', arguments: userId);
  }

  void _hireFreelancer(int userId) {
    Navigator.pop(context, userId);
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
