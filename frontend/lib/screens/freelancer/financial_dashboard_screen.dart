// ===== frontend/lib/screens/freelancer/financial_dashboard_screen.dart =====
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/financial_model.dart';
import '../../services/api_service.dart';
import '../../widgets/financial_charts.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen>
    with SingleTickerProviderStateMixin {
  FinancialStats? _stats;
  List<Map<String, dynamic>> _periodStats = [];
  List<FinancialTransaction> _recentTransactions = [];
  Map<String, dynamic>? _analytics;
  bool _loading = true;
  String _selectedPeriod = 'monthly';
  DateTimeRange? _selectedDateRange;
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
      final response = await ApiService.getFinancialStats(
        period: _selectedPeriod,
      );

      setState(() {
        _stats = response.stats;
        _periodStats = response.periodStats;
        _recentTransactions = response.recentTransactions;
        _loading = false;
      });

      _loadAnalytics();
    } catch (e) {
      setState(() => _loading = false);
      Fluttertoast.showToast(msg: 'Error loading financial data: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await ApiService.getAdvancedFinancialAnalytics();
      if (mounted) {
        setState(() => _analytics = analytics);
      }
    } catch (e) {
      print('Error loading analytics: $e');
    }
  }

  Future<void> _downloadReport() async {
    try {
      final endDate = _selectedDateRange?.end ?? DateTime.now();
      final startDate =
          _selectedDateRange?.start ??
          DateTime(endDate.year, endDate.month - 3, endDate.day);

      final reportUrl = await ApiService.generateFinancialReport(
        startDate: startDate,
        endDate: endDate,
      );

      if (reportUrl != null && mounted) {
        // TODO: فتح رابط التقرير
        Fluttertoast.showToast(msg: 'Report generated successfully');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error generating report: $e');
    }
  }

  Future<void> _requestWithdrawal() async {
    final amountController = TextEditingController();
    String selectedMethod = 'paypal';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Funds'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available: \$${_stats?.netEarnings.toStringAsFixed(2) ?? '0'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Withdrawal Method',
                ),
                items: const [
                  DropdownMenuItem(value: 'paypal', child: Text('PayPal')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'stripe', child: Text('Stripe')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setStateDialog(() => selectedMethod = value);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff14A800),
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (result == true && amountController.text.isNotEmpty) {
      final amount = double.parse(amountController.text);
      final response = await ApiService.requestWithdrawalV2(
        amount: amount,
        method: selectedMethod,
      );

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: 'Withdrawal request submitted');
        _loadData();
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Financial Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xff14A800),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadReport,
            tooltip: 'Download Report',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
          ? const Center(child: Text('No financial data available'))
          : TabBarView(
              controller: _tabController,
              children: [_buildOverviewTab(), _buildAnalyticsTab()],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _requestWithdrawal,
        backgroundColor: const Color(0xff14A800),
        icon: const Icon(Icons.arrow_upward),
        label: const Text('Withdraw'),
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
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildEarningsChart(),
          const SizedBox(height: 20),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          title: 'Total Earnings',
          value: '\$${_stats!.totalEarnings.toStringAsFixed(2)}',
          icon: Icons.trending_up,
          color: Colors.green,
          subtitle: 'All time',
        ),
        _buildStatCard(
          title: 'Platform Fees',
          value: '\$${_stats!.totalFees.toStringAsFixed(2)}',
          icon: Icons.receipt,
          color: Colors.orange,
          subtitle:
              '${((_stats!.totalFees / (_stats!.totalEarnings + 0.01)) * 100).toStringAsFixed(1)}%',
        ),
        _buildStatCard(
          title: 'Withdrawn',
          value: '\$${_stats!.totalWithdrawals.toStringAsFixed(2)}',
          icon: Icons.arrow_upward,
          color: Colors.blue,
          subtitle: 'Total withdrawn',
        ),
        _buildStatCard(
          title: 'Net Earnings',
          value: '\$${_stats!.netEarnings.toStringAsFixed(2)}',
          icon: Icons.account_balance_wallet,
          color: const Color(0xff14A800),
          subtitle: 'Available to withdraw',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['weekly', 'monthly', 'yearly'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = period);
                _loadData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xff14A800)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  period.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEarningsChart() {
    if (_periodStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No data available for this period')),
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
            'Earnings Overview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: FinancialCharts(
              periodStats: _periodStats,
              totalEarnings: _stats!.totalEarnings,
              chartType: 'bar',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    if (_recentTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentTransactions.length > 5
                ? 5
                : _recentTransactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tx = _recentTransactions[index];
              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tx.typeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      tx.typeIcon,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                title: Text(
                  _getTransactionTitle(tx.type),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  tx.description ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${tx.amount >= 0 ? '+' : ''}\$${tx.amount.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tx.isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      _formatDate(tx.transactionDate),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getTransactionTitle(String type) {
    switch (type) {
      case 'payment_received':
        return 'Payment Received';
      case 'payment_sent':
        return 'Payment Sent';
      case 'withdrawal':
        return 'Withdrawal';
      case 'deposit':
        return 'Deposit';
      case 'platform_fee':
        return 'Platform Fee';
      case 'bonus':
        return 'Bonus';
      case 'subscription':
        return 'Subscription';
      default:
        return type;
    }
  }

  Widget _buildAnalyticsTab() {
    if (_analytics == null) {
      return const Center(child: Text('No analytics data available'));
    }

    final topProjects = _analytics?['topProjects'] ?? [];
    final categoryDistribution = _analytics?['categoryDistribution'] ?? [];
    final projectedEarnings = _analytics?['projectedEarnings'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTopProjectsCard(topProjects),
          const SizedBox(height: 16),
          if (categoryDistribution.isNotEmpty)
            _buildCategoryDistributionCard(categoryDistribution),
          const SizedBox(height: 16),
          _buildProjectedEarningsCard(projectedEarnings),
        ],
      ),
    );
  }

  Widget _buildTopProjectsCard(List<dynamic> topProjects) {
    if (topProjects.isEmpty) return const SizedBox.shrink();

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
            'Top Projects',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...topProjects.map(
            (project) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.work, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project['Project']?['title'] ?? 'Untitled',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _formatDate(DateTime.parse(project['createdAt'])),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${project['agreed_amount']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff14A800),
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

  Widget _buildCategoryDistributionCard(List<dynamic> categories) {
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
            'Earnings by Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cat['category'] ?? 'Other'),
                      Text(
                        '\$${cat['total']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (cat['total'] / _stats!.totalEarnings).clamp(
                      0.0,
                      1.0,
                    ),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(Color(0xff14A800)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectedEarningsCard(double projected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.blue],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Projected Earnings',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '\$${projected.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                Text(
                  'Next 3 months based on your history',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
