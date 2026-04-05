import 'package:flutter/material.dart';
import '../../models/subscription_plan_model.dart';
import '../../services/api_service.dart';

class SubscriptionComparisonScreen extends StatefulWidget {
  const SubscriptionComparisonScreen({super.key});

  @override
  State<SubscriptionComparisonScreen> createState() =>
      _SubscriptionComparisonScreenState();
}

class _SubscriptionComparisonScreenState
    extends State<SubscriptionComparisonScreen> {
  List<SubscriptionPlan> _plans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getSubscriptionPlans();
      if (response['success'] == true && response['plans'] != null) {
        final List<dynamic> plansJson = response['plans'];
        setState(() {
          _plans = plansJson
              .map((json) => SubscriptionPlan.fromJson(json))
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load plans';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Compare Plans'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPlans),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPlans,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _plans.isEmpty
          ? const Center(child: Text('No plans available'))
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeatureColumn(),
                          const SizedBox(width: 12),
                          ..._plans.map((plan) => _buildPlanColumn(plan)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFeatureColumn() {
    final features = [
      {'icon': Icons.attach_money, 'label': 'Price'},
      {'icon': Icons.send, 'label': 'Proposals / month'},
      {'icon': Icons.work, 'label': 'Active Projects'},
      {'icon': Icons.auto_awesome, 'label': 'AI Insights'},
      {'icon': Icons.support_agent, 'label': 'Priority Support'},
      {'icon': Icons.api, 'label': 'API Access'},
      {'icon': Icons.branding_watermark, 'label': 'Custom Branding'},
      {'icon': Icons.free_breakfast, 'label': 'Trial Period'},
    ];

    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1F2937),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Center(
              child: Text(
                'Features',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ...features.map(
            (feature) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature['label'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildPlanColumn(SubscriptionPlan plan) {
    final isPopular = plan.isRecommended;
    final isFree = plan.price == 0;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isPopular
            ? Border.all(color: const Color(0xff14A800), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 70,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isFree
                    ? [Colors.grey.shade400, Colors.grey.shade600]
                    : [const Color(0xff14A800), const Color(0xff0F7A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isPopular)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Center(
              child: Text(
                plan.formattedPrice,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isFree ? Colors.grey : const Color(0xff14A800),
                ),
              ),
            ),
          ),
          _buildComparisonCell(
            plan.proposalLimit == null ? 'Unlimited' : '${plan.proposalLimit}',
          ),
          _buildComparisonCell(
            plan.activeProjectLimit == null
                ? 'Unlimited'
                : '${plan.activeProjectLimit}',
          ),
          _buildComparisonCell(
            plan.aiInsights ? '✅' : '❌',
            isHighlight: plan.aiInsights,
          ),
          _buildComparisonCell(
            plan.prioritySupport ? '✅' : '❌',
            isHighlight: plan.prioritySupport,
          ),
          _buildComparisonCell(
            plan.apiAccess ? '✅' : '❌',
            isHighlight: plan.apiAccess,
          ),
          _buildComparisonCell(
            plan.customBranding ? '✅' : '❌',
            isHighlight: plan.customBranding,
          ),
          _buildComparisonCell(
            plan.trialDays > 0 ? '${plan.trialDays} days' : 'No trial',
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: () {
                  if (!isFree) {
                    Navigator.pushNamed(context, '/subscription/plans');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFree
                      ? Colors.grey.shade300
                      : const Color(0xff14A800),
                  foregroundColor: isFree ? Colors.grey.shade700 : Colors.white,
                  textStyle: const TextStyle(fontSize: 12),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isFree ? 'Current' : 'Select'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCell(String value, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Center(
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight
                ? const Color(0xff14A800)
                : value.contains('❌')
                ? Colors.grey
                : Colors.black87,
          ),
        ),
      ),
    );
  }
}
