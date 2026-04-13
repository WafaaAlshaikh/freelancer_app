// lib/screens/payment/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import 'dart:html' as html;

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
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initPaymentSheet();
    }
  }

  Future<void> _confirmPaymentManually() async {
    setState(() => _confirming = true);

    try {
      final result = await ApiService.manualConfirmPayment(widget.contractId);

      if (result['success'] == true) {
        Fluttertoast.showToast(msg: '✅ Payment confirmed!');
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/contract',
            arguments: {'contractId': widget.contractId, 'userRole': 'client'},
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Failed to confirm payment',
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
      print('🔍 Creating checkout session for contract: ${widget.contractId}');
      print('🔍 Payment Intent ID: ${widget.paymentIntent['paymentIntentId']}');

      final checkoutUrl = await ApiService.createCheckoutSession(
        contractId: widget.contractId,
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
              Navigator.pushReplacementNamed(
                context,
                '/contract',
                arguments: {
                  'contractId': widget.contractId,
                  'userRole': 'client',
                },
              );
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
      print('❌ Payment error: $e');
      if (mounted) {
        Fluttertoast.showToast(msg: 'Payment failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  double _parseMoney(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
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

    final agreed = _parseMoney(
      widget.paymentIntent['agreed_amount'] ?? widget.paymentIntent['amount'],
    );
    final discount = _parseMoney(widget.paymentIntent['coupon_discount']);
    final chargeFallback = _parseMoney(
      widget.paymentIntent['amount_to_charge'],
    );
    final displayCharge = amount > 0
        ? amount
        : (chargeFallback > 0 ? chargeFallback : agreed - discount);
    final commission = widget.paymentIntent['commission_preview'];
    Map<String, dynamic>? commissionMap;
    if (commission is Map) {
      commissionMap = Map<String, dynamic>.from(commission);
    }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _paymentLine('Contract total', agreed),
                  if (discount > 0) ...[
                    const SizedBox(height: 6),
                    _paymentLine(
                      'Coupon discount',
                      -discount,
                      valueColor: Colors.green.shade700,
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Charged now (escrow)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '\$${displayCharge.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (commissionMap != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Commission (on release): ~${commissionMap['rate_percent'] ?? '—'}% · est. fee \$${_parseMoney(commissionMap['estimated_fee_on_release'] ?? commissionMap['estimated_fee']).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                    if (commissionMap['note'] != null &&
                        commissionMap['note'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          commissionMap['note'].toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
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
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: _confirming ? null : _confirmPaymentManually,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xff14A800)),
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
              'By paying, you agree to our Terms of Service',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentLine(String label, double signedAmount, {Color? valueColor}) {
    final negative = signedAmount < 0;
    final body = '\$${signedAmount.abs().toStringAsFixed(2)}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        Text(
          negative ? '-$body' : body,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
