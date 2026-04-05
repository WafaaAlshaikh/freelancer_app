import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/subscription_plan_model.dart';
import '../services/subscription_service.dart';

class PlanCard extends StatefulWidget {
  final SubscriptionPlan plan;
  final bool isCurrentPlan;
  final VoidCallback onUpgrade;

  const PlanCard({
    Key? key,
    required this.plan,
    this.isCurrentPlan = false,
    required this.onUpgrade,
  }) : super(key: key);

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard> {
  bool _isLoading = false;
  String? _couponCode;
  final _couponController = TextEditingController();
  bool _showCouponInput = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    if (widget.isCurrentPlan) {
      Fluttertoast.showToast(msg: 'You are already on this plan');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final checkoutUrl = await SubscriptionService.createCheckoutSession(
        widget.plan.slug,
        couponCode: _couponCode,
      );

      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          Fluttertoast.showToast(
            msg: 'Complete payment in the browser',
            timeInSecForIosWeb: 3,
          );
          widget.onUpgrade();
        } else {
          throw Exception('Could not launch checkout URL');
        }
      } else {
        throw Exception('Failed to create checkout session');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result = await SubscriptionService.validateCoupon(
        code,
        widget.plan.slug,
      );

      if (result != null && result['valid'] == true) {
        setState(() {
          _couponCode = code;
          _showCouponInput = false;
          _couponController.clear();
        });
        final discount = result['discount'];
        final discountText = discount['type'] == 'percentage'
            ? '${discount['value']}% off'
            : '\$${discount['value']} off';
        Fluttertoast.showToast(msg: 'Coupon applied! $discountText');
      } else {
        Fluttertoast.showToast(msg: result?['message'] ?? 'Invalid coupon');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error validating coupon');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFree = widget.plan.price == 0;
    final isPopular = widget.plan.isRecommended;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xff14A800),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.plan.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      widget.plan.formattedPrice,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isFree ? Colors.grey : const Color(0xff14A800),
                      ),
                    ),
                  ],
                ),
                if (widget.plan.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.plan.description!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 20),
                ...widget.plan.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: const Color(0xff14A800),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  ),
                ),
                if (!isFree && widget.plan.trialDays > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, size: 16, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.plan.trialDays}-day free trial included! Cancel anytime.',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                if (!isFree && !widget.isCurrentPlan)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _showCouponInput = !_showCouponInput);
                    },
                    icon: const Icon(Icons.local_offer, size: 16),
                    label: const Text('Have a coupon?'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                if (_showCouponInput && !widget.isCurrentPlan)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            decoration: const InputDecoration(
                              hintText: 'Enter coupon code',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _applyCoupon,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _subscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isCurrentPlan
                          ? Colors.grey.shade300
                          : const Color(0xff14A800),
                      foregroundColor: widget.isCurrentPlan
                          ? Colors.grey.shade700
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.isCurrentPlan
                                ? 'Current Plan'
                                : isFree
                                ? 'Get Started'
                                : 'Start Free Trial',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
