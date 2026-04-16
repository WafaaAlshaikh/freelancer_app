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
  String? _activeCouponPlanSlug;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
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
          _activeCouponPlanSlug = planSlug;
          _couponError = null;
        });
        Fluttertoast.showToast(
          msg: '🎉 Coupon applied! ${result['discount']['value']}% off',
          backgroundColor: Colors.green,
        );
      } else {
        setState(() => _couponError = result['message'] ?? 'Invalid coupon');
      }
    } catch (e) {
      setState(() => _couponError = 'Error validating coupon');
    }
  }

  void _clearCouponForDifferentPlan(String planSlug) {
    if (_couponApplied &&
        _activeCouponPlanSlug != null &&
        _activeCouponPlanSlug != planSlug) {
      _couponApplied = false;
      _appliedCoupon = null;
      _couponError = null;
      _couponController.clear();
      _activeCouponPlanSlug = null;
    }
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    if (plan.price == 0) {
      Fluttertoast.showToast(msg: '✨ You are already on the Free plan');
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
            couponCode: (_couponApplied && _activeCouponPlanSlug == plan.slug)
                ? _couponController.text
                : null,
          );

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Failed to create checkout session');
      }

      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Fluttertoast.showToast(
          msg:
              '💳 Complete payment in the browser to activate your subscription.',
          backgroundColor: Colors.purple,
        );
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception('Could not launch checkout URL');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Subscription failed: $e');
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
        if (mounted)
          Navigator.pushReplacementNamed(context, '/subscription/my');
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Error activating');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  void _navigateToCompare() {
    Navigator.pushNamed(context, '/subscription/compare');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final cardWidth = isSmallScreen ? 280.0 : 320.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 280,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHero(),
                    collapseMode: CollapseMode.parallax,
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16, top: 8),
                      child: GestureDetector(
                        onTap: _navigateToCompare,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.compare_arrows,
                                size: 18,
                                color: Colors.purple,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Compare',
                                style: TextStyle(color: Colors.purple),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 520,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _plans.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: cardWidth,
                            margin: const EdgeInsets.only(right: 16),
                            child: _buildPlanCard(_plans[index]),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  Widget _buildHero() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1529156069898-49953e39b3ac',
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
              colors: [
                Colors.purple.withOpacity(0.75),
                Colors.deepPurple.withOpacity(0.85),
              ],
            ),
          ),
        ),
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '✨ Your Plan, Your Choice ✨',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black26)],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Choose what fits you best • Cancel anytime',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isFree = plan.price == 0;
    final isPopular = plan.slug == 'pro';
    final isProcessing = _isPurchasing && _selectedPlanSlug == plan.slug;
    final hasCouponForThisPlan =
        _couponApplied && _activeCouponPlanSlug == plan.slug;

    final shouldShowCouponForThisPlan =
        _couponApplied && _activeCouponPlanSlug == plan.slug;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            blurRadius: 25,
            color: Colors.black.withOpacity(0.12),
            offset: const Offset(0, 8),
          ),
        ],
        border: isPopular
            ? Border.all(color: Colors.amber.shade600, width: 2)
            : null,
      ),
      child: Column(
        children: [
          if (isPopular || isFree)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: isPopular
                    ? const LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade400, Colors.grey.shade500],
                      ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPopular ? Icons.emoji_events : Icons.free_breakfast,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPopular ? '🔥 MOST POPULAR' : '🎁 FREE PLAN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.formattedPrice,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isFree ? Colors.grey.shade600 : Colors.purple,
                        ),
                      ),
                      if (!isFree)
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 6),
                          child: Text(
                            '/ month',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                    ],
                  ),

                  if (plan.description != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      plan.description!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(),

                  const SizedBox(height: 12),
                  const Text(
                    'What\'s included:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ...plan.features.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
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
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (!isFree)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade50,
                              Colors.pink.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.rocket, size: 18, color: Colors.purple),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '14-day free trial! Cancel anytime.',
                                style: TextStyle(
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
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Column(
              children: [
                if (!isFree) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          decoration: InputDecoration(
                            hintText: '🎟️ Coupon code',
                            errorText: _couponError,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _applyCoupon(plan.slug),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.purple, Colors.deepPurple],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (shouldShowCouponForThisPlan && _appliedCoupon != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_offer,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Coupon applied: ${_appliedCoupon!['code']}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : () => _subscribe(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFree
                          ? Colors.grey.shade300
                          : Colors.purple,
                      foregroundColor: isFree
                          ? Colors.grey.shade700
                          : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isFree ? '✨ Current Plan' : '🚀 Start Free Trial',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                if (!isFree)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _activateManually(plan),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.developer_mode,
                                size: 14,
                                color: Colors.orange.shade400,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'DEV: Activate Manually',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade400,
                                ),
                              ),
                            ],
                          ),
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
}
