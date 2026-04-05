import 'package:flutter/material.dart';
import '../../services/subscription_service.dart';
import '../../widgets/usage_progress.dart';

class SubscriptionUsageScreen extends StatefulWidget {
  const SubscriptionUsageScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionUsageScreen> createState() =>
      _SubscriptionUsageScreenState();
}

class _SubscriptionUsageScreenState extends State<SubscriptionUsageScreen> {
  UsageStats? _usage;
  UserSubscription? _subscription;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final usage = await SubscriptionService.getUsageStats();
      final subscription = await SubscriptionService.getCurrentSubscription();
      setState(() {
        _usage = usage;
        _subscription = subscription;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print('Error loading usage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Usage Statistics'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _usage == null
          ? const Center(child: Text('No usage data available'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_subscription != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _subscription!.isFree
                              ? [Colors.grey.shade400, Colors.grey.shade600]
                              : [
                                  const Color(0xff14A800),
                                  const Color(0xff0F7A00),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _subscription!.plan.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _subscription!.plan.formattedPrice,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if (!_subscription!.isFree) ...[
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: (_subscription!.daysRemaining / 30).clamp(
                                0.0,
                                1.0,
                              ),
                              backgroundColor: Colors.white30,
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _subscription!.remainingDaysText,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  UsageProgress(
                    title: 'Proposals This Month',
                    used: _usage!.proposalsUsed,
                    limit: _usage!.proposalsLimit,
                    icon: Icons.send,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 12),

                  UsageProgress(
                    title: 'Active Projects',
                    used: _usage!.activeProjectsUsed,
                    limit: _usage!.activeProjectsLimit,
                    icon: Icons.work,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 24),

                  if (_subscription != null && _subscription!.isFree)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Want more?',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Upgrade to Pro or Business for unlimited proposals and more features.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/subscription/plans',
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Upgrade'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
