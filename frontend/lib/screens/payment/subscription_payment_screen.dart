// lib/screens/payment/subscription_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import 'dart:html' as html;

class SubscriptionPaymentScreen extends StatefulWidget {
  final String planSlug;
  final Map<String, dynamic> paymentIntent;
  final String planName;
  final String planPrice;

  const SubscriptionPaymentScreen({
    super.key,
    required this.planSlug,
    required this.paymentIntent,
    required this.planName,
    required this.planPrice,
  });

  @override
  State<SubscriptionPaymentScreen> createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  bool _isProcessing = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initPaymentSheet();
    }
  }

  Future<void> _confirmSubscriptionManually() async {
    setState(() => _confirming = true);

    try {
      final result = await ApiService.manualConfirmSubscriptionPayment(
        widget.planSlug,
      );

      if (result['success'] == true) {
        Fluttertoast.showToast(msg: '✅ Subscription payment confirmed!');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/subscription/my');
        }
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Failed to confirm subscription payment',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _confirming = false);
      }
    }
  }

  Future<void> _initPaymentSheet() async {
    if (kIsWeb) return;
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: widget.paymentIntent['clientSecret'],
          merchantDisplayName: 'Freelancer Platform',
          style: ThemeMode.light,
        ),
      );
    } catch (e) {
      print('❌ Error initializing payment sheet: $e');
    }
  }

  Future<void> _presentPaymentSheet() async {
    if (kIsWeb) {
      await _openStripeCheckout();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await Stripe.instance.presentPaymentSheet();

      final result = await ApiService.confirmSubscriptionPayment(
        planSlug: widget.planSlug,
        paymentIntentId: widget.paymentIntent['paymentIntentId'],
      );

      if (result['message'] != null) {
        Fluttertoast.showToast(msg: '✅ Subscription payment successful!');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/subscription/my');
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: 'Subscription payment failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _openStripeCheckout() async {
    setState(() => _isProcessing = true);

    try {
      print(
        '🔍 Creating checkout session for subscription: ${widget.planSlug}',
      );
      print('🔍 Payment Intent ID: ${widget.paymentIntent['paymentIntentId']}');

      final checkoutUrl = await ApiService.createSubscriptionCheckoutSession(
        planSlug: widget.planSlug,
        paymentIntentId: widget.paymentIntent['paymentIntentId'],
      );

      print('🔍 Checkout URL received: $checkoutUrl');

      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        final uri = Uri.parse(checkoutUrl);
        print('🔍 Opening URL: $uri');

        if (kIsWeb) {
          html.window.open(checkoutUrl, '_blank');

          Fluttertoast.showToast(
            msg: 'Complete payment in the new tab',
            timeInSecForIosWeb: 3,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          );

          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/subscription/my');
            }
          });
        } else {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            throw Exception('Could not launch checkout URL: $checkoutUrl');
          }
        }
      } else {
        throw Exception('No checkout URL returned from server');
      }
    } catch (e) {
      print('❌ Subscription payment error: $e');
      if (mounted) {
        Fluttertoast.showToast(msg: 'Subscription payment failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double amount = 0.0;
    if (widget.paymentIntent['amount'] != null) {
      final amountValue = widget.paymentIntent['amount'];
      if (amountValue is double) {
        amount = amountValue;
      } else if (amountValue is int) {
        amount = amountValue.toDouble();
      } else if (amountValue is String) {
        amount = double.tryParse(amountValue) ?? 0.0;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Subscription Payment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.subscriptions,
                size: 64,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Subscription Payment',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text(
              widget.planName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Your subscription will be activated immediately after payment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            Container(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subscription Price',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    widget.planPrice,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment is secure and will grant you immediate access to all premium features.',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: kIsWeb ? Colors.amber.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    kIsWeb ? Icons.web : Icons.phone_android,
                    color: kIsWeb
                        ? Colors.amber.shade700
                        : Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      kIsWeb
                          ? 'You will be redirected to Stripe secure checkout page.'
                          : 'Secure in-app payment with Stripe.',
                      style: TextStyle(
                        color: kIsWeb
                            ? Colors.amber.shade800
                            : Colors.green.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _presentPaymentSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        kIsWeb ? 'Pay with Stripe' : 'Subscribe Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: _confirming
                        ? null
                        : _confirmSubscriptionManually,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _confirming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Confirm Payment (Manual)',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            Text(
              'By subscribing, you agree to our Terms of Service and Privacy Policy',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
