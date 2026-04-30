import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/interview_model.dart';
import '../../services/api_service.dart';
import '../../utils/token_storage.dart';
import '../../theme/app_theme.dart';

class InterviewStatsScreen extends StatefulWidget {
  const InterviewStatsScreen({super.key});

  @override
  State<InterviewStatsScreen> createState() => _InterviewStatsScreenState();
}

class _InterviewStatsScreenState extends State<InterviewStatsScreen>
    with SingleTickerProviderStateMixin {
  InterviewStats? _stats;
  List<InterviewInvitation> _interviews = [];
  bool _loading = true;
  String _selectedPeriod = 'monthly';
  String? _userRole;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserRole();
        _loadData(context);
        _loadSmartAnalytics();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final role = await TokenStorage.getUserRole();
    if (mounted) setState(() => _userRole = role);
  }

  Future<void> _loadData(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final response = await ApiService.getUserInterviews();
      final stats = await ApiService.getInterviewStats();

      if (!mounted) return;

      setState(() {
        _interviews =
            (response['invitations'] as List?)
                ?.map((j) => InterviewInvitation.fromJson(j))
                .toList() ??
            [];
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSmartAnalytics() async {
    try {
      final result = await ApiService.getSmartAnalytics();
      if (result['success'] == true && result['analytics'] != null) {
        final analytics = result['analytics'];
        print('📊 Smart Analytics: $analytics');
      }
    } catch (e) {
      print('Error loading smart analytics: $e');
    }
  }

  int _calculateAcceptanceRate() {
    final total = _stats?.total ?? 0;
    final accepted = (_stats?.accepted ?? 0) + (_stats?.completed ?? 0);
    return total > 0 ? ((accepted / total) * 100).round() : 0;
  }

  int _calculateConversionRate() {
    final accepted = (_stats?.accepted ?? 0) + (_stats?.completed ?? 0);
    final total = _stats?.total ?? 0;
    return total > 0 ? ((accepted / total) * 100).round() : 0;
  }

  int _calculateSuccessRate() {
    final completed = _stats?.completed ?? 0;
    final accepted = (_stats?.accepted ?? 0) + completed;
    return accepted > 0 ? ((completed / accepted) * 100).round() : 0;
  }

  String _calculateAvgRating() {
    final rated = _interviews.where((i) => i.rating != null).toList();
    if (rated.isEmpty) return 'N/A';
    final avg =
        rated.fold<int>(0, (sum, i) => sum + (i.rating ?? 0)) / rated.length;
    return avg.toStringAsFixed(1);
  }

  String _calculateAvgResponseTime() {
    final responded = _interviews.where((i) => i.respondedAt != null).toList();
    if (responded.isEmpty) return 'N/A';

    final totalHours = responded.fold<double>(0, (sum, i) {
      final diff = i.respondedAt!.difference(i.createdAt).inHours;
      return sum + diff;
    });

    final avgHours = totalHours / responded.length;
    if (avgHours < 1) return '< 1h';
    if (avgHours < 24) return '${avgHours.round()}h';
    return '${(avgHours / 24).round()}d';
  }

  String _getTrend(String metric) {
    final trends = {'total': '+15%', 'acceptance': '+8%', 'response': '-2h'};
    return trends[metric] ?? '+5%';
  }

  List<Map<String, dynamic>> _getMonthlyData() {
    final t = AppLocalizations.of(context);

    List<String> months;
    final monthsValue = t?.months;
    if (monthsValue is List<String>) {
      months = monthsValue as List<String>;
    } else {
      months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
    }

    final counts = List.filled(12, 0);

    for (final interview in _interviews) {
      final month = interview.createdAt.month - 1;
      if (month >= 0 && month < 12) {
        counts[month]++;
      }
    }

    return List.generate(12, (i) => {'month': months[i], 'count': counts[i]});
  }

  List<Map<String, dynamic>> _getResponseTimeData() {
    final t = AppLocalizations.of(context);

    List<String> labels;
    final rangesValue = t?.responseTimeRanges;
    if (rangesValue is List<String>) {
      labels = rangesValue as List<String>;
    } else {
      labels = ['< 1h', '1-6h', '6-12h', '12-24h', '> 24h'];
    }

    const ranges = [
      {'min': 0, 'max': 1},
      {'min': 1, 'max': 6},
      {'min': 6, 'max': 12},
      {'min': 12, 'max': 24},
      {'min': 24, 'max': double.infinity},
    ];

    final counts = List.filled(ranges.length, 0);

    for (final interview in _interviews) {
      if (interview.respondedAt != null) {
        final hours = interview.respondedAt!
            .difference(interview.createdAt)
            .inHours;
        for (int i = 0; i < ranges.length; i++) {
          final min = ranges[i]['min'] as num;
          final max = ranges[i]['max'] as num;

          if (hours >= min && hours < max) {
            counts[i]++;
            break;
          }
        }
      }
    }

    return List.generate(
      ranges.length,
      (i) => {'label': labels[i], 'count': counts[i]},
    );
  }

  Map<int, int> _getRatingDistribution() {
    final ratings = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final interview in _interviews) {
      if (interview.rating != null) {
        ratings[interview.rating!] = (ratings[interview.rating!] ?? 0) + 1;
      }
    }
    return ratings;
  }

  List<Map<String, dynamic>> _analyzeTopPerformers() {
    return [
      {'name': 'Ahmed Hassan', 'completed': 12, 'rating': 4.9},
      {'name': 'Sara Mohammad', 'completed': 10, 'rating': 4.8},
      {'name': 'Omar Khalid', 'completed': 8, 'rating': 4.7},
    ];
  }

  List<Map<String, dynamic>> _getRecommendations(bool isClient) {
    final t = AppLocalizations.of(context);
    if (isClient) {
      return [
        {
          'text':
              t?.recommendationClient1 ??
              'Your response rate is 85%. Try to respond within 24 hours for better results.',
          'priority': 'medium',
        },
        {
          'text':
              t?.recommendationClient2 ??
              'Schedule interviews between 10 AM - 2 PM for higher acceptance rates.',
          'priority': 'high',
        },
        {
          'text':
              t?.recommendationClient3 ??
              'Send a reminder 1 hour before the interview to reduce no-shows.',
          'priority': 'medium',
        },
      ];
    } else {
      return [
        {
          'text':
              t?.recommendationFreelancer1 ??
              'You respond within 4 hours on average. Keep up the good work!',
          'priority': 'low',
        },
        {
          'text':
              t?.recommendationFreelancer2 ??
              'Your acceptance rate is 75%. Try to respond to all invitations.',
          'priority': 'high',
        },
        {
          'text':
              t?.recommendationFreelancer3 ??
              'Prepare questions before the interview to make a better impression.',
          'priority': 'medium',
        },
      ];
    }
  }

  String _formatDateTime(DateTime date) {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return '${t?.today} ${t?.at ?? 'at'} ${_formatTime(date)}';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return '${t?.yesterday} ${t?.at ?? 'at'} ${_formatTime(date)}';
    } else if (dateOnly.isAfter(today) &&
        dateOnly.isBefore(today.add(const Duration(days: 7)))) {
      return '${DateFormat('EEEE').format(date)} ${t?.at ?? 'at'} ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${t?.at ?? 'at'} ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isClient = _userRole == 'client';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.interviewAnalytics,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
          tabs: [
            Tab(text: t.overview, icon: const Icon(Icons.dashboard)),
            Tab(text: t.performance, icon: const Icon(Icons.trending_up)),
            Tab(text: t.insights, icon: const Icon(Icons.lightbulb)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
              _loadData(context);
            },
            icon: Icon(Icons.calendar_today, color: theme.iconTheme.color),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'weekly', child: Text(t.weekly)),
              PopupMenuItem(value: 'monthly', child: Text(t.monthly)),
              PopupMenuItem(value: 'yearly', child: Text(t.yearly)),
            ],
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
            onPressed: () => _loadData(context),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPerformanceTab(),
                _buildInsightsTab(isClient),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsCards(),
          const SizedBox(height: 20),
          _buildStatusChart(),
          const SizedBox(height: 20),
          _buildResponseRateCard(),
          const SizedBox(height: 20),
          _buildMonthlyTrends(),
          const SizedBox(height: 20),
          _buildUpcomingInterviews(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final acceptanceRate = _calculateAcceptanceRate();
    final avgResponseTime = _calculateAvgResponseTime();
    const completionRate = 85;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          title: t.totalInterviews,
          value: '${_stats?.total ?? 0}',
          icon: Icons.interpreter_mode,
          color: theme.colorScheme.primary,
          trend: _getTrend('total'),
          trendUp: true,
        ),
        _buildStatCard(
          title: t.acceptanceRate,
          value: '$acceptanceRate%',
          icon: Icons.check_circle,
          color: theme.colorScheme.secondary,
          trend: _getTrend('acceptance'),
          trendUp: acceptanceRate > 50,
        ),
        _buildStatCard(
          title: t.completionRate,
          value: '$completionRate%',
          icon: Icons.verified,
          color: AppColors.info,
          trend: '+8%',
          trendUp: true,
        ),
        _buildStatCard(
          title: t.avgResponse,
          value: avgResponseTime,
          icon: Icons.access_time,
          color: AppColors.warning,
          trend: _getTrend('response'),
          trendUp: false,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
    bool trendUp = true,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (trendUp
                                ? theme.colorScheme.secondary
                                : AppColors.danger)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: trendUp
                            ? theme.colorScheme.secondary
                            : AppColors.danger,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend!,
                        style: TextStyle(
                          fontSize: 10,
                          color: trendUp
                              ? theme.colorScheme.secondary
                              : AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChart() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final data = [
      {
        'status': t.pending,
        'count': _stats?.pending ?? 0,
        'color': AppColors.warning,
      },
      {
        'status': t.accepted,
        'count': _stats?.accepted ?? 0,
        'color': theme.colorScheme.secondary,
      },
      {
        'status': t.completed,
        'count': _stats?.completed ?? 0,
        'color': AppColors.info,
      },
      {
        'status': t.declined,
        'count': _stats?.declined ?? 0,
        'color': AppColors.danger,
      },
      {
        'status': t.expired,
        'count': _stats?.expired ?? 0,
        'color': AppColors.gray,
      },
    ];

    final total = data.fold<int>(
      0,
      (sum, item) => sum + (item['count'] as int),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.interviewStatusDistribution,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: data.map((item) {
                  final count = item['count'] as int;
                  final percentage = total > 0 ? (count / total) * 100 : 0;
                  return PieChartSectionData(
                    value: count.toDouble(),
                    title: percentage > 10
                        ? '${percentage.toStringAsFixed(0)}%'
                        : '',
                    color: item['color'] as Color,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                startDegreeOffset: -90,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: data.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item['status']} (${item['count']})',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseRateCard() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final acceptanceRate = _calculateAcceptanceRate();
    final avgResponseTime = _calculateAvgResponseTime();

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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  t.acceptanceRate,
                  style: TextStyle(fontSize: 12, color: AppColors.gray),
                ),
                const SizedBox(height: 8),
                Text(
                  '$acceptanceRate%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: acceptanceRate / 100,
                    backgroundColor: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  t.avgResponseTime,
                  style: TextStyle(fontSize: 12, color: AppColors.gray),
                ),
                const SizedBox(height: 8),
                Text(
                  avgResponseTime,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
                Text(
                  t.fromInvitationSent,
                  style: TextStyle(fontSize: 11, color: AppColors.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrends() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monthlyData = _getMonthlyData();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.monthlyTrends,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < monthlyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthlyData[index]['month'],
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface,
                              ),
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
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
                    left: BorderSide(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['count'] as int).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: theme.cardColor,
                          strokeWidth: 2,
                          strokeColor: theme.colorScheme.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.3),
                          theme.colorScheme.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toInt()} ${t.interviews}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingInterviews() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final upcoming =
        _interviews
            .where(
              (i) =>
                  i.isAccepted &&
                  i.selectedTime != null &&
                  i.selectedTime!.isAfter(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.selectedTime!.compareTo(b.selectedTime!));

    if (upcoming.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 48, color: AppColors.gray),
            const SizedBox(height: 12),
            Text(
              t.noUpcomingInterviews,
              style: TextStyle(color: AppColors.gray),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.upcomingInterviews,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...upcoming.take(5).map((invitation) {
            final project = invitation.project;
            final daysLeft = invitation.selectedTime!
                .difference(DateTime.now())
                .inDays;
            final isToday = daysLeft == 0;
            final isTomorrow = daysLeft == 1;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isToday
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : (isDark ? AppColors.darkSurface : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday
                      ? theme.colorScheme.primary.withOpacity(0.3)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isToday
                          ? theme.colorScheme.primary.withOpacity(0.2)
                          : (isDark
                                ? AppColors.darkSurface
                                : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isToday ? Icons.today : Icons.event,
                      color: isToday
                          ? theme.colorScheme.primary
                          : AppColors.gray,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project?.title ?? t.project,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 12,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _userRole == 'client'
                                  ? invitation.freelancer?.name ?? t.freelancer
                                  : invitation.client?.name ?? t.client,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(invitation.selectedTime!),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? theme.colorScheme.primary
                          : isTomorrow
                          ? AppColors.warning
                          : theme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isToday
                          ? t.today
                          : isTomorrow
                          ? t.tomorrow
                          : t.inDays(daysLeft),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (upcoming.length > 5)
            TextButton(
              onPressed: () {
                // Navigate to calendar screen
              },
              child: Text(
                t.viewAll,
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPerformanceMetrics(),
          const SizedBox(height: 20),
          _buildResponseTimeChart(),
          const SizedBox(height: 20),
          _buildRatingDistribution(),
          const SizedBox(height: 20),
          _buildTopPerformers(),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final completed = _interviews.where((i) => i.isCompleted).length;
    final onTime = _interviews
        .where((i) => i.isCompleted && i.selectedTime != null)
        .length;
    final onTimeRate = completed > 0 ? (onTime / completed) * 100 : 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          title: t.completed,
          value: '$completed',
          subtitle: t.totalInterviews,
          icon: Icons.verified,
          color: AppColors.info,
        ),
        _buildMetricCard(
          title: t.onTimeRate,
          value: '${onTimeRate.toStringAsFixed(0)}%',
          subtitle: t.ofCompleted,
          icon: Icons.access_time,
          color: theme.colorScheme.secondary,
        ),
        _buildMetricCard(
          title: t.avgRating,
          value: _calculateAvgRating(),
          subtitle: t.outOf5,
          icon: Icons.star,
          color: Colors.amber,
        ),
        _buildMetricCard(
          title: t.successRate,
          value: '${_calculateSuccessRate()}%',
          subtitle: t.acceptedToCompleted,
          icon: Icons.trending_up,
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTimeChart() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final responseData = _getResponseTimeData();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.responseTimeDistribution,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    responseData
                        .map((d) => d['count'] as int)
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < responseData.length) {
                          return Text(
                            responseData[index]['label'],
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 40,
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
                            color: theme.colorScheme.onSurface,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                barGroups: responseData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (data['count'] as int).toDouble(),
                        color: AppColors.warning,
                        width: 30,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ratings = _getRatingDistribution();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.interviewRatings,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) {
            final star = 5 - index;
            final count = ratings[star] ?? 0;
            final total = ratings.values.reduce((a, b) => a + b);
            final percentage = total > 0 ? (count / total) * 100 : 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Row(
                      children: [
                        Text(
                          '$star',
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          star >= 4
                              ? theme.colorScheme.secondary
                              : star >= 3
                              ? AppColors.warning
                              : AppColors.danger,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      count.toString(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopPerformers() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final performers = _analyzeTopPerformers();

    if (performers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.topPerformers,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...performers.take(3).map((performer) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  performer['name'][0].toUpperCase(),
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
              title: Text(
                performer['name'],
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              subtitle: Text(
                '${performer['completed']} ${t.interviewsCompleted}',
                style: TextStyle(color: AppColors.gray),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${performer['rating']} ⭐',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(bool isClient) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAIInsights(isClient),
          const SizedBox(height: 20),
          _buildRecommendations(isClient),
          const SizedBox(height: 20),
          _buildTipsCard(),
        ],
      ),
    );
  }

  Widget _buildAIInsights(bool isClient) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final acceptanceRate = _calculateAcceptanceRate();
    final conversionRate = _calculateConversionRate();
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                t.aiInsights,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            icon: Icons.trending_up,
            title: t.bestTimeToInterview,
            description: isClient
                ? t.bestTimeToInterviewClient
                : t.bestTimeToInterviewFreelancer,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            icon: Icons.people,
            title: t.successRate,
            description: isClient
                ? t.successRateClient(conversionRate)
                : t.successRateFreelancer(acceptanceRate),
            color: AppColors.info,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            icon: Icons.calendar_today,
            title: t.optimalSchedule,
            description: isClient
                ? t.optimalScheduleClient
                : t.optimalScheduleFreelancer,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(bool isClient) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final recommendations = _getRecommendations(isClient);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                t.recommendations,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.map((rec) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: rec['priority'] == 'high'
                          ? AppColors.danger.withOpacity(0.1)
                          : AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      rec['priority'] == 'high'
                          ? Icons.priority_high
                          : Icons.check,
                      size: 14,
                      color: rec['priority'] == 'high'
                          ? AppColors.danger
                          : AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rec['text'],
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                t.proTips,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            t.proTipsContent,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
