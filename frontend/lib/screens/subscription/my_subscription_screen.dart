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
      backgroundColor: const Color(0xFFF5F6FA),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.purple),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading your subscription...',
                    style: TextStyle(color: Colors.purple),
                  ),
                ],
              ),
            )
          : _errorMessage != null
          ? _buildErrorState()
          : _subscription == null
          ? _buildNoSubscriptionState()
          : CustomScrollView(
              slivers: [
                _buildHeroSliver(),
                SliverToBoxAdapter(child: _buildTabBar()),
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildOverviewTab(), _buildAnalyticsTab()],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSliver() {
    final plan = _subscription!.plan;
    final isFree = plan.price == 0;

    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isFree
                      ? [
                          Colors.grey.withOpacity(0.85),
                          Colors.grey.shade800.withOpacity(0.95),
                        ]
                      : [
                          Colors.purple.withOpacity(0.85),
                          Colors.deepPurple.withOpacity(0.95),
                        ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      isFree ? Icons.free_breakfast : Icons.star,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    plan.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black26)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.formattedPrice,
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  if (!isFree && _subscription!.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _subscription!.remainingDaysText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
        collapseMode: CollapseMode.parallax,
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Container(
            margin: const EdgeInsets.only(right: 16, top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.more_vert, color: Colors.purple),
          ),
          onSelected: (value) {
            switch (value) {
              case 'invoices':
                Navigator.pushNamed(context, '/subscription/invoices');
                break;
              case 'compare':
                Navigator.pushNamed(context, '/subscription/comparison');
                break;
              case 'refresh':
                _loadData();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'invoices',
              child: Row(
                children: [
                  Icon(Icons.receipt, size: 20),
                  SizedBox(width: 12),
                  Text('Invoices'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'compare',
              child: Row(
                children: [
                  Icon(Icons.compare_arrows, size: 20),
                  SizedBox(width: 12),
                  Text('Compare Plans'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 12),
                  Text('Refresh'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.purple,
          borderRadius: BorderRadius.circular(30),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
          Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade100, Colors.pink.shade100],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_border,
              size: 80,
              color: Colors.purple.shade300,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Active Subscription',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are currently on the Free plan',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/subscription/plans');
            },
            icon: const Icon(Icons.star),
            label: const Text('View Plans'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
          if (!isFree && _subscription!.isActive) ...[
            _buildProgressCard(),
            const SizedBox(height: 16),
          ],

          if (_usage != null) ...[
            _buildUsageStats(),
            const SizedBox(height: 16),
          ],

          _buildFeaturesCard(plan),
          const SizedBox(height: 16),

          if (!isFree && _subscription!.isActive) _buildBillingInfoCard(),

          const SizedBox(height: 16),

          if (isFree) _buildUpgradeCard(),

          if (!isFree && _subscription!.isActive && !_canceling)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCancelButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timer, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Billing Cycle',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_subscription!.daysRemaining / 30).clamp(0.0, 1.0),
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_subscription!.daysRemaining} days remaining',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_subscription!.daysRemaining / 30 * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Usage Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildUsageStatItem(
                  icon: Icons.send,
                  label: 'Proposals',
                  used: _usage!.proposalsUsed,
                  limit: _usage!.proposalsLimit,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUsageStatItem(
                  icon: Icons.work,
                  label: 'Active Projects',
                  used: _usage!.activeProjectsUsed,
                  limit: _usage!.activeProjectsLimit,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStatItem({
    required IconData icon,
    required String label,
    required int used,
    int? limit,
    required Color color,
  }) {
    final percentage = limit != null ? (used / limit).clamp(0.0, 1.0) : 0.0;
    final isUnlimited = limit == null;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          isUnlimited ? '∞' : '$used / $limit',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: percentage >= 0.9 && !isUnlimited ? Colors.red : color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        if (!isUnlimited) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                percentage >= 0.9 ? Colors.red : color,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeaturesCard(SubscriptionPlan plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text(
                'Included Features',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 10),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text(
                'Billing Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Next Billing Date',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                '${_subscription!.currentPeriodEnd.day}/${_subscription!.currentPeriodEnd.month}/${_subscription!.currentPeriodEnd.year}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (_subscription!.cancelAtPeriodEnd) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.orange),
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

  Widget _buildCancelButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: _canceling ? null : _cancelSubscription,
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _canceling
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Cancel Subscription', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildUpgradeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.pink.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.rocket, color: Colors.purple, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ready for more?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Upgrade to unlock unlimited proposals, AI insights, and priority support!',
            style: TextStyle(fontSize: 14, color: Colors.purple),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/subscription/plans');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Upgrade Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 16),
          _buildStatsGrid(),
          const SizedBox(height: 16),
          if (_subscription!.plan.price == 0) _buildProTipsCard(),
        ],
      ),
    );
  }

  Widget _buildUsageChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Monthly Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
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
                      reservedSize: 35,
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
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                ),
                barGroups: List.generate(_monthlyUsage.length, (index) {
                  final usage = _monthlyUsage[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: usage.proposals.toDouble(),
                        color: Colors.blue,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                      BarChartRodData(
                        toY: usage.projects.toDouble(),
                        color: Colors.green,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                    barsSpace: 8,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Quick Stats',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
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
          ),
        ],
      ),
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
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
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

  Widget _buildProTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.purple, size: 24),
              SizedBox(width: 12),
              Text(
                'Pro Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                TipItem(
                  icon: Icons.trending_up,
                  text: 'Upgrade to Pro to get 50 proposals/month',
                ),
                SizedBox(height: 12),
                TipItem(
                  icon: Icons.stars,
                  text: 'Business plan gives you unlimited proposals',
                ),
                SizedBox(height: 12),
                TipItem(
                  icon: Icons.savings,
                  text: 'Save 20% with yearly billing',
                ),
                SizedBox(height: 12),
                TipItem(
                  icon: Icons.business,
                  text: 'Contact sales for custom enterprise plans',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/subscription/plans');
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View Upgrade Options'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const TipItem({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.purple),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
        ),
      ],
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
