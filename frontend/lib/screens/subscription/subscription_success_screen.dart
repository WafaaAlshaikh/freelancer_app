// frontend/lib/screens/subscription/subscription_success_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

class SubscriptionSuccessScreen extends StatefulWidget {
  const SubscriptionSuccessScreen({super.key});

  @override
  State<SubscriptionSuccessScreen> createState() =>
      _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState extends State<SubscriptionSuccessScreen> {
  bool _isLoading = true;
  String _message = 'Processing your subscription...';
  bool _success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extractAndConfirm();
    });
  }

  Future<void> _extractAndConfirm() async {
    try {
      final uri = Uri.base;
      print('🔍 Full URL: ${uri.toString()}');

      final sessionId = uri.queryParameters['session_id'];

      if (sessionId != null && sessionId.isNotEmpty) {
        print('✅ Found session_id: $sessionId');
        await _confirmSubscription(sessionId);
      } else {
        print('❌ No session_id found');
        final hash = uri.fragment;
        if (hash.contains('session_id=')) {
          final extracted = hash.split('session_id=')[1].split('&')[0];
          print('✅ Extracted from hash: $extracted');
          await _confirmSubscription(extracted);
        }
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  Future<void> _confirmSubscription(String sessionId) async {
    try {
      print('📡 Calling confirmCheckoutSession...');

      final response = await ApiService.confirmCheckoutSession(sessionId);

      print('📋 Response: $response');

      if (response['success'] == true) {
        print('✅ Subscription activated successfully!');
        setState(() {
          _isLoading = false;
          _message = '✅ Subscription activated successfully!';
          _success = true;
        });

        Fluttertoast.showToast(msg: 'Subscription activated!');

        await ApiService.refreshUserSubscription();

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            print('🔄 Navigating to /subscription/my');
            Navigator.pushReplacementNamed(context, '/subscription/my');
          }
        });
      } else {
        print('❌ Activation failed: ${response['message']}');
        setState(() {
          _isLoading = false;
          _message =
              '❌ ${response['message'] ?? 'Failed to activate subscription'}';
          _success = false;
        });
      }
    } catch (e) {
      print('❌ Error confirming: $e');
      setState(() {
        _isLoading = false;
        _message = '❌ Error: $e';
        _success = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xff14A800),
                      ),
                    )
                  : Icon(
                      _success ? Icons.check_circle : Icons.error,
                      size: 80,
                      color: _success ? Colors.green : Colors.red,
                    ),
              const SizedBox(height: 24),
              Text(
                _success ? 'Subscription Successful!' : 'Subscription Failed',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _message,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!_isLoading)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/subscription/my',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff14A800),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'View Subscription',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xff14A800)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Go Home',
                        style: TextStyle(color: Color(0xff14A800)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
