import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/subscription_plan_model.dart';
import '../../models/user_subscription_model.dart';
import '../../models/usage_limits_model.dart';
import '../../services/api_service.dart';

class MySubscriptionScreen extends StatefulWidget {
  const MySubscriptionScreen({super.key});

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen>
    with SingleTickerProviderStateMixin {
  UserSubscription? _subscription;
  UsageLimits? _usage;
  List<MonthlyUsage> _monthlyUsage = [];
  bool _loading = true;
  bool _canceling = false;
  String? _errorMessage;
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
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> subscriptionRes = {};
      Map<String, dynamic> usageRes = {};

      try {
        subscriptionRes = await ApiService.getUserSubscription();
        print('📡 Subscription response: $subscriptionRes');
      } catch (e) {
        print('❌ Error fetching subscription: $e');
        _errorMessage = 'Could not load subscription data';
      }

      try {
        usageRes = await ApiService.getUserUsage();
        print('📡 Usage response: $usageRes');
      } catch (e) {
        print('❌ Error fetching usage: $e');
      }

      if (subscriptionRes.isNotEmpty && subscriptionRes['success'] == true) {
        try {
          final subData = subscriptionRes['subscription'];
          if (subData != null && subData is Map) {
            if (subData.containsKey('plan')) {
              _subscription = UserSubscription.fromJson(
                subData as Map<String, dynamic>,
              );
            } else if (subData.containsKey('name')) {
              final plan = SubscriptionPlan.fromJson(
                subData as Map<String, dynamic>,
              );
              _subscription = UserSubscription(
                id: 0,
                plan: plan,
                status: 'active',
                currentPeriodStart: DateTime.now(),
                currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
                cancelAtPeriodEnd: false,
              );
            }
          }
        } catch (e) {
          print('❌ Error parsing subscription: $e');
        }
      }

      if (_subscription == null) {
        print('⚠️ No subscription found, using free plan');
        final freePlan = SubscriptionPlan(
          id: 0,
          name: 'Free',
          slug: 'free',
          price: 0,
          billingPeriod: 'monthly',
          features: ['Basic features', 'Limited proposals'],
          proposalLimit: 5,
          activeProjectLimit: 1,
          aiInsights: false,
          prioritySupport: false,
          apiAccess: false,
          customBranding: false,
          trialDays: 0,
          sortOrder: 0,
          isRecommended: false,
          isActive: true,
        );
        _subscription = UserSubscription(
          id: 0,
          plan: freePlan,
          status: 'active',
          currentPeriodStart: DateTime.now(),
          currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
          cancelAtPeriodEnd: false,
        );
      }

      if (usageRes.isNotEmpty &&
          usageRes['success'] == true &&
          usageRes['usage'] != null) {
        try {
          _usage = UsageLimits.fromJson(usageRes['usage']);
        } catch (e) {
          print('❌ Error parsing usage: $e');
        }
      }

      if (_usage == null) {
        _usage = UsageLimits(
          proposalsUsed: 0,
          proposalsLimit: _subscription?.plan.proposalLimit,
          activeProjectsUsed: 0,
          activeProjectsLimit: _subscription?.plan.activeProjectLimit,
        );
      }

      _monthlyUsage = [
        MonthlyUsage(month: 'Jan', proposals: 2, projects: 1),
        MonthlyUsage(month: 'Feb', proposals: 4, projects: 1),
        MonthlyUsage(month: 'Mar', proposals: 6, projects: 1),
        MonthlyUsage(month: 'Apr', proposals: 8, projects: 2),
        MonthlyUsage(month: 'May', proposals: 10, projects: 2),
        MonthlyUsage(month: 'Jun', proposals: 12, projects: 2),
      ];

      setState(() => _loading = false);
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        _loading = false;
        _errorMessage = 'Failed to load data: $e';
      });
      Fluttertoast.showToast(msg: 'Error loading data: $e');
    }
  }

  Future<void> _cancelSubscription() async {
    if (_subscription == null || _subscription!.isFree) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your subscription? '
          'You will continue to have access until the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _canceling = true);
    try {
      final response = await ApiService.cancelSubscription();
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: 'Subscription canceled successfully');
        _loadData();
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Error canceling');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _canceling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('My Subscription'),
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
            icon: const Icon(Icons.receipt),
            onPressed: () {
              Navigator.pushNamed(context, '/subscription/invoices');
            },
            tooltip: 'Invoices',
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: () {
              Navigator.pushNamed(context, '/subscription/comparison');
            },
            tooltip: 'Compare Plans',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          if (_subscription != null &&
              !_subscription!.isFree &&
              _subscription!.isActive)
            TextButton(
              onPressed: _canceling ? null : _cancelSubscription,
              child: _canceling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading subscription data...'),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _subscription == null
          ? _buildNoSubscriptionState()
          : TabBarView(
              controller: _tabController,
              children: [_buildOverviewTab(), _buildAnalyticsTab()],
            ),
    );
  }

  Widget _buildNoSubscriptionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Active Subscription',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are currently on the Free plan',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/subscription/plans');
            },
            icon: const Icon(Icons.star),
            label: const Text('View Plans'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff14A800),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final plan = _subscription!.plan;
    final isFree = plan.price == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isFree
                    ? [Colors.grey.shade400, Colors.grey.shade600]
                    : [const Color(0xff14A800), const Color(0xff0F7A00)],
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
                    Expanded(
                      child: Text(
                        plan.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_subscription!.isTrialing)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'TRIAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  plan.formattedPrice,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                if (!isFree && _subscription!.isActive) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (_subscription!.daysRemaining / 30).clamp(0.0, 1.0),
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subscription!.remainingDaysText,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (_usage != null) ...[
            _buildUsageCard(
              title: 'Proposals This Month',
              used: _usage!.proposalsUsed,
              limit: _usage!.proposalsLimit,
              icon: Icons.send,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildUsageCard(
              title: 'Active Projects',
              used: _usage!.activeProjectsUsed,
              limit: _usage!.activeProjectsLimit,
              icon: Icons.work,
              color: Colors.green,
            ),
          ],

          const SizedBox(height: 20),

          _buildFeaturesCard(plan),

          const SizedBox(height: 20),

          if (!isFree && _subscription!.isActive) _buildBillingInfoCard(),

          const SizedBox(height: 20),

          if (isFree)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/subscription/plans');
                },
                icon: const Icon(Icons.star),
                label: const Text(
                  'Upgrade Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff14A800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildUsageChart(),
          const SizedBox(height: 20),

          if (_usage != null) _buildStatsGrid(),
          const SizedBox(height: 20),

          if (_subscription!.plan.price == 0) _buildUpgradeTips(),
        ],
      ),
    );
  }

  Widget _buildUsageCard({
    required String title,
    required int used,
    int? limit,
    required IconData icon,
    required Color color,
  }) {
    if (limit == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
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
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Unlimited',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final percentage = used / limit;
    final remaining = limit - used;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$used / $limit',
                style: TextStyle(
                  fontSize: 14,
                  color: remaining <= 0 ? Colors.red : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                remaining <= 0 ? Colors.red : color,
              ),
              minHeight: 8,
            ),
          ),
          if (remaining <= 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'You have reached your limit. Upgrade to continue.',
                      style: TextStyle(fontSize: 11, color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/subscription/plans');
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Upgrade',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard(SubscriptionPlan plan) {
    final features = plan.features;
    if (features.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No features information available')),
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
            'Included Features',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Color(0xff14A800),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingInfoCard() {
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
            'Billing Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Next Billing Date'),
              Text(
                '${_subscription!.currentPeriodEnd.day}/${_subscription!.currentPeriodEnd.month}/${_subscription!.currentPeriodEnd.year}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (_subscription!.cancelAtPeriodEnd) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, size: 14, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your subscription will end on the next billing date.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsageChart() {
    if (_monthlyUsage.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No usage data available')),
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
            'Monthly Usage',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _monthlyUsage.length) {
                          return Text(
                            _monthlyUsage[index].month,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
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
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
                barGroups: List.generate(_monthlyUsage.length, (index) {
                  final usage = _monthlyUsage[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: usage.proposals.toDouble(),
                        color: Colors.blue,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: usage.projects.toDouble(),
                        color: Colors.green,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.blue, 'Proposals'),
              const SizedBox(width: 24),
              _buildLegendItem(Colors.green, 'Projects'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildStatsGrid() {
    if (_usage == null) return const SizedBox.shrink();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Proposals',
          '${_usage!.proposalsUsed}',
          Icons.send,
          Colors.blue,
        ),
        _buildStatCard(
          'Active Projects',
          '${_usage!.activeProjectsUsed}',
          Icons.work,
          Colors.green,
        ),
        _buildStatCard(
          'Remaining Proposals',
          _usage!.proposalsLimit == null
              ? '∞'
              : '${_usage!.remainingProposals}',
          Icons.assignment,
          Colors.orange,
        ),
        _buildStatCard(
          'Remaining Projects',
          _usage!.activeProjectsLimit == null
              ? '∞'
              : '${_usage!.remainingActiveProjects}',
          Icons.folder,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeTips() {
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
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Pro Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• Upgrade to Pro to get 50 proposals/month\n'
            '• Business plan gives you unlimited proposals\n'
            '• Save 20% with yearly billing\n'
            '• Contact sales for custom enterprise plans',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/subscription/plans');
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View Upgrade Options'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyUsage {
  final String month;
  final int proposals;
  final int projects;

  MonthlyUsage({
    required this.month,
    required this.proposals,
    required this.projects,
  });
}
