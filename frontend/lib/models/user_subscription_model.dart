// lib/models/user_subscription_model.dart

import 'package:freelancer_platform/models/subscription_plan_model.dart';

class UserSubscription {
  final int id;
  final SubscriptionPlan plan;
  final String status;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final DateTime? trialEnd;

  UserSubscription({
    required this.id,
    required this.plan,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    this.trialEnd,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    print('📥 UserSubscription.fromJson raw: $json');

    if (json['plan'] == null) {
      print('❌ No plan found in subscription data');
      throw Exception('No plan data found');
    }

    SubscriptionPlan plan;
    try {
      plan = SubscriptionPlan.fromJson(json['plan']);
      print('✅ Plan parsed: ${plan.name}');
    } catch (e) {
      print('❌ Error parsing plan: $e');
      print('❌ Plan data: ${json['plan']}');
      rethrow;
    }

    return UserSubscription(
      id: json['id'] ?? 0,
      plan: plan,
      status: json['status'] ?? 'active',
      currentPeriodStart: json['current_period_start'] != null
          ? DateTime.parse(json['current_period_start'])
          : DateTime.now(),
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'])
          : DateTime.now().add(const Duration(days: 30)),
      cancelAtPeriodEnd: json['cancel_at_period_end'] ?? false,
      trialEnd: json['trial_end'] != null
          ? DateTime.tryParse(json['trial_end'])
          : null,
    );
  }

  bool get isActive => status == 'active' || status == 'trialing';
  bool get isTrialing => status == 'trialing';
  bool get isFree => plan.slug == 'free';

  int get daysRemaining {
    final now = DateTime.now();
    final end = currentPeriodEnd;
    return end.difference(now).inDays;
  }

  String get remainingDaysText {
    if (daysRemaining <= 0) return 'Expired';
    if (daysRemaining == 1) return '1 day left';
    return '$daysRemaining days left';
  }
}
