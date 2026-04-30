// lib/screens/payment/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
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
    final t = AppLocalizations.of(context)!;
    setState(() => _confirming = true);

    try {
      final result = await ApiService.manualConfirmPayment(widget.contractId);

      if (result['success'] == true) {
        Fluttertoast.showToast(msg: t.paymentConfirmed);
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/contract',
            arguments: {'contractId': widget.contractId, 'userRole': 'client'},
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? t.failedToConfirmPayment,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.error}: $e');
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
    final t = AppLocalizations.of(context)!;
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
        Fluttertoast.showToast(msg: t.paymentSuccessful);
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
        Fluttertoast.showToast(msg: '${t.paymentFailed}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _openStripeCheckout() async {
    final t = AppLocalizations.of(context)!;
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
            msg: t.completePaymentInNewTab,
            timeInSecForIosWeb: 3,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: AppColors.info,
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
        Fluttertoast.showToast(msg: '${t.paymentFailed}: $e');
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.completePayment),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_clock, size: 64, color: AppColors.success),
            ),
            const SizedBox(height: 24),

            Text(
              t.securePayment,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              t.paymentHeldInEscrow,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _paymentLine(t.contractTotal, agreed),
                  if (discount > 0) ...[
                    const SizedBox(height: 6),
                    _paymentLine(
                      t.couponDiscount,
                      -discount,
                      valueColor: AppColors.success,
                    ),
                  ],
                  Divider(height: 20, color: theme.dividerColor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.chargedNowEscrow,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${t.dollar}${displayCharge.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  if (commissionMap != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${t.commissionOnRelease}: ~${commissionMap['rate_percent'] ?? '—'}% · ${t.estFee} ${t.dollar}${_parseMoney(commissionMap['estimated_fee_on_release'] ?? commissionMap['estimated_fee']).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.paymentSecureDescription,
                      style: TextStyle(color: AppColors.info, fontSize: 12),
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
                color: kIsWeb ? AppColors.warningBg : AppColors.successBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    kIsWeb ? Icons.web : Icons.phone_android,
                    color: kIsWeb ? AppColors.warning : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      kIsWeb ? t.stripeWebRedirect : t.stripeInAppPayment,
                      style: TextStyle(
                        color: kIsWeb ? AppColors.warning : AppColors.success,
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
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        kIsWeb ? t.payWithStripe : t.payNow,
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
                      side: BorderSide(color: AppColors.secondary),
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
                        : Text(
                            t.confirmPaymentManual,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.secondary,
                            ),
                          ),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            Text(
              t.agreeToTermsByPaying,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentLine(String label, double signedAmount, {Color? valueColor}) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final negative = signedAmount < 0;
    final body = '${t.dollar}${signedAmount.abs().toStringAsFixed(2)}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        Text(
          negative ? '-$body' : body,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
