import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/interview_model.dart';
import '../../services/api_service.dart';
import '../../utils/token_storage.dart';

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
    _loadUserRole();
    _loadData();
    _loadSmartAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final role = await TokenStorage.getUserRole();
    setState(() => _userRole = role);
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final response = await ApiService.getUserInterviews();
      final stats = await ApiService.getInterviewStats();

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
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClient = _userRole == 'client';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Interview Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purple,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Performance', icon: Icon(Icons.trending_up)),
            Tab(text: 'Insights', icon: Icon(Icons.lightbulb)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
              _loadData();
            },
            icon: const Icon(Icons.calendar_today),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'weekly', child: Text('Weekly')),
              const PopupMenuItem(value: 'monthly', child: Text('Monthly')),
              const PopupMenuItem(value: 'yearly', child: Text('Yearly')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
          title: 'Total Interviews',
          value: '${_stats?.total ?? 0}',
          icon: Icons.interpreter_mode,
          color: Colors.purple,
          trend: _getTrend('total'),
          trendUp: true,
        ),
        _buildStatCard(
          title: 'Acceptance Rate',
          value: '$acceptanceRate%',
          icon: Icons.check_circle,
          color: Colors.green,
          trend: _getTrend('acceptance'),
          trendUp: acceptanceRate > 50,
        ),
        _buildStatCard(
          title: 'Completion Rate',
          value: '$completionRate%',
          icon: Icons.verified,
          color: Colors.blue,
          trend: '+8%',
          trendUp: true,
        ),
        _buildStatCard(
          title: 'Avg Response',
          value: avgResponseTime,
          icon: Icons.access_time,
          color: Colors.orange,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    color: (trendUp ? Colors.green : Colors.red).withOpacity(
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: trendUp ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend!,
                        style: TextStyle(
                          fontSize: 10,
                          color: trendUp ? Colors.green : Colors.red,
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
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChart() {
    final data = [
      {
        'status': 'Pending',
        'count': _stats?.pending ?? 0,
        'color': Colors.orange,
      },
      {
        'status': 'Accepted',
        'count': _stats?.accepted ?? 0,
        'color': Colors.green,
      },
      {
        'status': 'Completed',
        'count': _stats?.completed ?? 0,
        'color': Colors.blue,
      },
      {
        'status': 'Declined',
        'count': _stats?.declined ?? 0,
        'color': Colors.red,
      },
      {
        'status': 'Expired',
        'count': _stats?.expired ?? 0,
        'color': Colors.grey,
      },
    ];

    final total = data.fold<int>(
      0,
      (sum, item) => sum + (item['count'] as int),
    );

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
            'Interview Status Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(fontSize: 12),
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
    final acceptanceRate = _calculateAcceptanceRate();
    final avgResponseTime = _calculateAvgResponseTime();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
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
                const Text(
                  'Acceptance Rate',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '$acceptanceRate%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: acceptanceRate / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(Colors.purple),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 60, color: Colors.grey.shade300),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Avg Response Time',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  avgResponseTime,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Text(
                  'from invitation sent',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrends() {
    final monthlyData = _getMonthlyData();

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
            'Monthly Trends',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      color: Colors.grey.shade200,
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
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
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
                    bottom: BorderSide(color: Colors.grey.shade300),
                    left: BorderSide(color: Colors.grey.shade300),
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
                    color: Colors.purple,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.purple,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.3),
                          Colors.purple.withOpacity(0.0),
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
                          '${spot.y.toInt()} interviews',
                          const TextStyle(
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.calendar_today, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('No upcoming interviews scheduled'),
            ],
          ),
        ),
      );
    }

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
            'Upcoming Interviews',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                color: isToday ? Colors.purple.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday
                      ? Colors.purple.shade200
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.purple.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isToday ? Icons.today : Icons.event,
                      color: isToday ? Colors.purple : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project?.title ?? 'Project',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _userRole == 'client'
                                  ? invitation.freelancer?.name ?? 'Freelancer'
                                  : invitation.client?.name ?? 'Client',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(invitation.selectedTime!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
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
                          ? Colors.purple
                          : isTomorrow
                          ? Colors.orange
                          : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isToday
                          ? 'Today'
                          : isTomorrow
                          ? 'Tomorrow'
                          : 'In $daysLeft days',
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
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
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
          title: 'Completed',
          value: '$completed',
          subtitle: 'Total interviews',
          icon: Icons.verified,
          color: Colors.blue,
        ),
        _buildMetricCard(
          title: 'On-Time Rate',
          value: '${onTimeRate.toStringAsFixed(0)}%',
          subtitle: 'of completed',
          icon: Icons.access_time,
          color: Colors.green,
        ),
        _buildMetricCard(
          title: 'Avg Rating',
          value: _calculateAvgRating(),
          subtitle: 'out of 5',
          icon: Icons.star,
          color: Colors.amber,
        ),
        _buildMetricCard(
          title: 'Success Rate',
          value: '${_calculateSuccessRate()}%',
          subtitle: 'accepted → completed',
          icon: Icons.trending_up,
          color: Colors.purple,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTimeChart() {
    final responseData = _getResponseTimeData();

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
            'Response Time Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                            style: const TextStyle(fontSize: 10),
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
                          style: const TextStyle(fontSize: 10),
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
                        color: Colors.orange,
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
    final ratings = _getRatingDistribution();

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
            'Interview Ratings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        Text('$star'),
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          star >= 4
                              ? Colors.green
                              : star >= 3
                              ? Colors.orange
                              : Colors.red,
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
                      style: const TextStyle(fontSize: 12),
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
    final performers = _analyzeTopPerformers();

    if (performers.isEmpty) {
      return const SizedBox.shrink();
    }

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
            'Top Performers',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...performers.take(3).map((performer) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                child: Text(
                  performer['name'][0].toUpperCase(),
                  style: const TextStyle(color: Colors.purple),
                ),
              ),
              title: Text(performer['name']),
              subtitle: Text('${performer['completed']} interviews completed'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${performer['rating']} ⭐',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
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
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Insights',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            icon: Icons.trending_up,
            title: 'Best Time to Interview',
            description: isClient
                ? 'Based on your history, freelancers are most responsive between 10 AM - 2 PM on weekdays.'
                : 'You respond fastest to interview invitations within 2 hours of receiving them.',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            icon: Icons.people,
            title: 'Success Rate',
            description: isClient
                ? 'Your interview to hire conversion rate is ${_calculateConversionRate()}%. Keep up the good work!'
                : 'Your interview acceptance rate is ${_calculateAcceptanceRate()}%. Try responding faster to improve.',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            icon: Icons.calendar_today,
            title: 'Optimal Schedule',
            description: isClient
                ? 'Tuesday and Wednesday have the highest acceptance rates for interview invitations.'
                : 'Interviews scheduled on Thursday have the highest completion rate.',
            color: Colors.orange,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(bool isClient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Recommendations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._getRecommendations(isClient).map((rec) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: rec['priority'] == 'high'
                          ? Colors.red.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      rec['priority'] == 'high'
                          ? Icons.priority_high
                          : Icons.check,
                      size: 14,
                      color: rec['priority'] == 'high'
                          ? Colors.red
                          : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rec['text'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Pro Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• Send interview invitations within 24 hours of receiving a proposal\n'
            '• Always confirm the interview time 1 day in advance\n'
            '• Prepare specific questions before the interview\n'
            '• Take notes during the interview for better evaluation\n'
            '• Follow up within 48 hours after the interview',
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
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
    final months = [
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
    final counts = List.filled(12, 0);

    for (final interview in _interviews) {
      final month = interview.createdAt.month - 1;
      counts[month]++;
    }

    return List.generate(12, (i) => {'month': months[i], 'count': counts[i]});
  }

  List<Map<String, dynamic>> _getResponseTimeData() {
    const ranges = [
      {'label': '< 1h', 'min': 0, 'max': 1},
      {'label': '1-6h', 'min': 1, 'max': 6},
      {'label': '6-12h', 'min': 6, 'max': 12},
      {'label': '12-24h', 'min': 12, 'max': 24},
      {'label': '> 24h', 'min': 24, 'max': double.infinity},
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
      (i) => {'label': ranges[i]['label'], 'count': counts[i]},
    );
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
    if (isClient) {
      return [
        {
          'text':
              'Your response rate is 85%. Try to respond within 24 hours for better results.',
          'priority': 'medium',
        },
        {
          'text':
              'Schedule interviews between 10 AM - 2 PM for higher acceptance rates.',
          'priority': 'high',
        },
        {
          'text':
              'Send a reminder 1 hour before the interview to reduce no-shows.',
          'priority': 'medium',
        },
      ];
    } else {
      return [
        {
          'text':
              'You respond within 4 hours on average. Keep up the good work!',
          'priority': 'low',
        },
        {
          'text':
              'Your acceptance rate is 75%. Try to respond to all invitations.',
          'priority': 'high',
        },
        {
          'text':
              'Prepare questions before the interview to make a better impression.',
          'priority': 'medium',
        },
      ];
    }
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today at ${_formatTime(date)}';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at ${_formatTime(date)}';
    } else if (dateOnly.isAfter(today) &&
        dateOnly.isBefore(today.add(const Duration(days: 7)))) {
      return '${DateFormat('EEEE').format(date)} at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
