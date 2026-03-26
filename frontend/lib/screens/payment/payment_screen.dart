// lib/screens/payment/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final int contractId;
  final Map<String, dynamic> paymentIntent;

  const PaymentScreen({
    super.key,
    required this.contractId,
    required this.paymentIntent,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initPaymentSheet();
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

      final result = await ApiService.confirmPayment(
        contractId: widget.contractId,
        paymentIntentId: widget.paymentIntent['paymentIntentId'],
      );

      if (result['message'] != null) {
        Fluttertoast.showToast(msg: '✅ Payment successful!');
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/contract',
            arguments: {'contractId': widget.contractId, 'userRole': 'client'},
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: 'Payment failed: $e');
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
      final checkoutUrl = await ApiService.createCheckoutSession(
        contractId: widget.contractId,
        paymentIntentId: widget.paymentIntent['paymentIntentId'],
      );

      if (checkoutUrl != null) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          Fluttertoast.showToast(
            msg: 'Complete payment in your browser',
            timeInSecForIosWeb: 3, 
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          );

          Navigator.pop(context);
        } else {
          throw Exception('Could not launch checkout URL');
        }
      } else {
        throw Exception('No checkout URL returned');
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: 'Payment failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = (widget.paymentIntent['amount'] ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
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
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_clock,
                size: 64,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Secure Payment',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            const Text(
              'Your payment will be held in escrow until the project is completed.',
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
                  const Text('Contract Amount', style: TextStyle(fontSize: 16)),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment is secure and will only be released when you approve each milestone.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
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
                  backgroundColor: const Color(0xff14A800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        kIsWeb ? 'Pay with Stripe' : 'Pay Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'By paying, you agree to our Terms of Service',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
