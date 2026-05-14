import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';
import '../../../models/admin_insight_model.dart';
import '../../../models/predictive_analytics_model.dart';
import '../../../theme/app_theme.dart' as AppTheme;

class AIInsightsDashboard extends StatefulWidget {
  const AIInsightsDashboard({super.key});

  @override
  State<AIInsightsDashboard> createState() => _AIInsightsDashboardState();
}

class _AIInsightsDashboardState extends State<AIInsightsDashboard>
    with SingleTickerProviderStateMixin {
  List<AdminInsight> _insights = [];
  PredictiveAnalytics? _predictions;
  bool _loading = true;
  late TabController _tabController;

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
      final [insightsRes, predictionsRes] = await Future.wait([
        ApiService.getActiveInsights(),
        ApiService.getPredictiveAnalytics(),
      ]);

      if (mounted) {
        setState(() {
          if (insightsRes['success'] == true) {
            _insights =
                (insightsRes['insights'] as List?)
                    ?.map((i) => AdminInsight.fromJson(i))
                    .toList() ??
                [];
          }
          if (predictionsRes['success'] == true) {
            _predictions = PredictiveAnalytics.fromJson(
              predictionsRes['predictions'],
            );
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      Fluttertoast.showToast(msg: 'Error loading insights: $e');
    }
  }

  Future<void> _resolveInsight(AdminInsight insight) async {
    final result = await ApiService.resolveInsight(insight.id);
    if (result['success'] == true) {
      Fluttertoast.showToast(msg: 'Insight resolved');
      _loadData();
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
                  colors: [Color(0xFF8B88FF), Color(0xFF5B58E2)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'AI Insights',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: isDark ? Colors.grey.shade500 : Colors.grey,
          tabs: const [
            Tab(text: 'Predictions', icon: Icon(Icons.trending_up)),
            Tab(text: 'Active Alerts', icon: Icon(Icons.notifications_active)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPredictionsTab(t, isDark),
                _buildInsightsTab(t, isDark),
              ],
            ),
    );
  }

  Widget _buildPredictionsTab(AppLocalizations t, bool isDark) {
    if (_predictions == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No prediction data available',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.AppColors.primary,
                  AppTheme.AppColors.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '📈 Growth Forecast',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_predictions!.growthForecast['users']?.toStringAsFixed(1) ?? 0}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _predictionCard(
                      'Expected New Users',
                      '${_predictions!.expectedNewUsers}',
                      Icons.person_add,
                      Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(width: 12),
                    _predictionCard(
                      'Expected Revenue',
                      '\$${_predictions!.expectedRevenue.toStringAsFixed(0)}',
                      Icons.attach_money,
                      Colors.white.withOpacity(0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _predictionCard(
                      'Expected Disputes',
                      '${_predictions!.expectedDisputes}',
                      Icons.gavel,
                      _predictions!.riskColor.withOpacity(0.3),
                      textColor: _predictions!.riskColor,
                    ),
                    const SizedBox(width: 12),
                    _predictionCard(
                      'Confidence Score',
                      '${_predictions!.revenueConfidence.toStringAsFixed(0)}%',
                      Icons.verified,
                      Colors.blue.withOpacity(0.2),
                      textColor: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
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
                        color: AppTheme.AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Revenue Prediction',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(height: 200, child: _buildPredictionChart()),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _predictions!.riskColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _predictions!.riskColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _predictions!.riskColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
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
                        'Risk Assessment: ${_predictions!.disputeRisk.toUpperCase()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _predictions!.riskColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _predictions!.disputeRisk == 'high'
                            ? 'High dispute risk detected. Consider reviewing dispute resolution policies.'
                            : _predictions!.disputeRisk == 'medium'
                            ? 'Moderate dispute risk. Monitor closely.'
                            : 'Dispute risk is within acceptable range.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _predictionCard(
    String title,
    String value,
    IconData icon,
    Color bgColor, {
    Color? textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor ?? Colors.white,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = [
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
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    months[value.toInt() % 12],
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
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
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              12,
              (i) => FlSpot(i.toDouble(), 1000 + i * 200 + (i % 3) * 100),
            ),
            isCurved: true,
            color: AppTheme.AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.AppColors.primary.withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: List.generate(
              12,
              (i) => FlSpot(i.toDouble(), 800 + i * 180 + (i % 2) * 80),
            ),
            isCurved: true,
            color: Colors.orange,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(AppLocalizations t, bool isDark) {
    if (_insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No active insights',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for AI recommendations',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _insights.length,
      itemBuilder: (context, index) {
        final insight = _insights[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: insight.severityColor.withOpacity(0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showInsightDetails(insight),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: insight.severityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            insight.severityIcon,
                            color: insight.severityColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                insight.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                insight.category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: insight.severityColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: insight.severityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            insight.severity,
                            style: TextStyle(
                              fontSize: 10,
                              color: insight.severityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      insight.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (insight.actionUrl != null)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Navigate to action URL
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: insight.severityColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                insight.actionText ?? 'View',
                                style: TextStyle(color: insight.severityColor),
                              ),
                            ),
                          ),
                        if (insight.actionUrl != null)
                          const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _resolveInsight(insight),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: insight.severityColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Resolve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showInsightDetails(AdminInsight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(insight.severityIcon, color: insight.severityColor),
            const SizedBox(width: 8),
            Text(insight.title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(insight.description),
              const SizedBox(height: 16),
              if (insight.data.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Additional Data:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...insight.data.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${e.key}: ${e.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resolveInsight(insight);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: insight.severityColor,
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }
}
