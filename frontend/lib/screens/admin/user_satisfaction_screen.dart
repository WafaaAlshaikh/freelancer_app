import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart' as AppTheme;

class UserSatisfactionScreen extends StatefulWidget {
  const UserSatisfactionScreen({super.key});

  @override
  State<UserSatisfactionScreen> createState() => _UserSatisfactionScreenState();
}

class _UserSatisfactionScreenState extends State<UserSatisfactionScreen> {
  Map<String, dynamic> _analysis = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getUserSatisfaction();
      if (mounted && response['success'] == true) {
        setState(() {
          _analysis = response['analysis'] ?? {};
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.AppColors.darkBackground
          : const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.insights, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'User Satisfaction',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildOverallRatingCard(isDark, theme),
                    const SizedBox(height: 20),
                    _buildFeedbackBreakdown(isDark, theme),
                    const SizedBox(height: 20),
                    _buildWeeklyTrendChart(isDark, theme),
                    const SizedBox(height: 20),
                    if (_analysis.containsKey('recommendations') &&
                        (_analysis['recommendations'] as List).isNotEmpty)
                      _buildRecommendationsCard(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverallRatingCard(bool isDark, ThemeData theme) {
    final overall = _analysis['overall'] ?? {};
    final freelancerFeedback = _analysis['freelancer_feedback'];
    final clientFeedback = _analysis['client_feedback'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Overall Satisfaction',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(overall['average_rating'] ?? 0).toStringAsFixed(1)} / 5.0',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final rating = (overall['average_rating'] ?? 0).toDouble();
              return Icon(
                i < rating.floor()
                    ? Icons.star
                    : (i < rating.ceil() ? Icons.star_half : Icons.star_border),
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Based on ${overall['total_reviews'] ?? 0} reviews',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _feedbackMetric(
                'Freelancers',
                freelancerFeedback != null
                    ? freelancerFeedback['satisfaction_rate'] ?? 0
                    : 0,
              ),
              const SizedBox(width: 12),
              _feedbackMetric(
                'Clients',
                clientFeedback != null
                    ? clientFeedback['satisfaction_rate'] ?? 0
                    : 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feedbackMetric(String label, double rate) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${rate.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackBreakdown(bool isDark, ThemeData theme) {
    final freelancerFeedback = _analysis['freelancer_feedback'];
    final clientFeedback = _analysis['client_feedback'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Rating Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _distributionChart(
                  'Freelancers',
                  freelancerFeedback != null
                      ? freelancerFeedback['distribution'] ?? {}
                      : {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _distributionChart(
                  'Clients',
                  clientFeedback != null
                      ? clientFeedback['distribution'] ?? {}
                      : {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _distributionChart(String title, Map<String, dynamic> distribution) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...List.generate(5, (i) {
          final rating = 5 - i;
          final count = distribution[rating.toString()] ?? 0;
          final maxCount = distribution.values.isNotEmpty
              ? (distribution.values
                        .map((e) => e as num)
                        .reduce((a, b) => a > b ? a : b))
                    .toDouble()
              : 1;
          final percentage = maxCount > 0 ? count / maxCount : 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '$rating ★',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        _getRatingColor(rating),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 35,
                  child: Text(
                    '$count',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return const Color(0xFF14A800);
      case 4:
        return const Color(0xFF10B981);
      case 3:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  Widget _buildWeeklyTrendChart(bool isDark, ThemeData theme) {
    final weeklyTrend = _analysis['weekly_trend'] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Weekly Trend',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < weeklyTrend.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              weeklyTrend[value.toInt()]['week'] ?? '',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      weeklyTrend.length,
                      (i) => FlSpot(
                        i.toDouble(),
                        (weeklyTrend[i]['average_rating'] ?? 0).toDouble(),
                      ),
                    ),
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: theme.colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(bool isDark) {
    final recommendations = _analysis['recommendations'] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.orange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Recommendations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getPriorityColor(rec['priority']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getPriorityColor(rec['priority']).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(rec['priority']),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rec['priority'].toString().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          rec['area'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rec['issue'] ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec['suggestion'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
