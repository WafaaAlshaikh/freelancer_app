import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/subscription_plan_model.dart';
import '../../services/api_service.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  List<SubscriptionPlan> _plans = [];
  bool _loading = true;
  bool _isPurchasing = false;
  final TextEditingController _couponController = TextEditingController();
  String? _couponError;
  bool _couponApplied = false;
  Map<String, dynamic>? _appliedCoupon;
  String? _selectedPlanSlug;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getSubscriptionPlans();
      print('📊 Subscription response: $response');

      if (response['success'] == true && response['plans'] != null) {
        final plansList = response['plans'] as List;
        setState(() {
          _plans = plansList.map((p) => SubscriptionPlan.fromJson(p)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      Fluttertoast.showToast(msg: 'Error loading plans: $e');
    }
  }

  Future<void> _applyCoupon(String planSlug) async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _couponError = 'Please enter a coupon code');
      return;
    }
    setState(() => _couponError = null);
    try {
      final result = await ApiService.validateCoupon(code, planSlug);
      if (result['valid'] == true) {
        setState(() {
          _couponApplied = true;
          _appliedCoupon = result['coupon'];
        });
        Fluttertoast.showToast(
          msg: 'Coupon applied! ${result['discount']['value']}% off',
        );
      } else {
        setState(() => _couponError = result['message'] ?? 'Invalid coupon');
      }
    } catch (e) {
      setState(() => _couponError = 'Error validating coupon');
    }
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    if (plan.price == 0) {
      Fluttertoast.showToast(msg: 'You are already on the Free plan');
      return;
    }

    setState(() {
      _isPurchasing = true;
      _selectedPlanSlug = plan.slug;
    });

    try {
      final checkoutUrl =
          await ApiService.createSubscriptionCheckoutSessionDirect(
            plan.slug,
            couponCode: _couponApplied ? _couponController.text : null,
          );

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Failed to create checkout session');
      }

      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Fluttertoast.showToast(
          msg: 'Complete payment in the browser to activate your subscription.',
        );
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception('Could not launch checkout URL');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Subscription failed: $e');
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _activateManually(SubscriptionPlan plan) async {
    setState(() => _isPurchasing = true);
    try {
      final response = await ApiService.manualActivateSubscription(plan.slug);
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: '✅ ${response['message']}');
        Navigator.pushReplacementNamed(context, '/subscription/my');
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Error activating');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: () {
              Navigator.pushNamed(context, '/subscription/compare');
            },
            tooltip: 'Compare Plans',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final plan = _plans[index];
                return _buildPlanCard(plan);
              },
            ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isFree = plan.price == 0;
    final isPopular = plan.slug == 'pro';
    final isProcessing = _isPurchasing && _selectedPlanSlug == plan.slug;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isPopular
            ? Border.all(color: const Color(0xff14A800), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xff14A800),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      plan.formattedPrice,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isFree ? Colors.grey : const Color(0xff14A800),
                      ),
                    ),
                  ],
                ),
                if (plan.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    plan.description!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 20),
                ...plan.features.map(
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
                if (!isFree) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, size: 16, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '14-day free trial included! Cancel anytime.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (!isFree) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          decoration: InputDecoration(
                            hintText: 'Coupon code',
                            errorText: _couponError,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: ElevatedButton(
                          onPressed: () => _applyCoupon(plan.slug),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                  if (_couponApplied)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Coupon applied: ${_appliedCoupon?['code']}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : () => _subscribe(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFree
                          ? Colors.grey.shade300
                          : const Color(0xff14A800),
                      foregroundColor: isFree
                          ? Colors.grey.shade700
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isFree ? 'Current Plan' : 'Start Free Trial',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (!isFree)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => _activateManually(plan),
                      icon: const Icon(Icons.developer_mode, size: 16),
                      label: const Text(
                        'DEV: Activate Manually',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
}
