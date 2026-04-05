class SubscriptionStats {
  final int totalSubscriptions;
  final int activeSubscriptions;
  final int trialingSubscriptions;
  final int canceledSubscriptions;
  final int expiredSubscriptions;
  final double monthlyRecurringRevenue;
  final double yearlyRecurringRevenue;
  final Map<String, dynamic>? popularPlan;
  final double upgradeRate;
  final double churnRate;
  final Map<String, double> revenueByPlan;
  final Map<String, int> subscriptionsByPlan;

  SubscriptionStats({
    required this.totalSubscriptions,
    required this.activeSubscriptions,
    required this.trialingSubscriptions,
    required this.canceledSubscriptions,
    required this.expiredSubscriptions,
    required this.monthlyRecurringRevenue,
    required this.yearlyRecurringRevenue,
    this.popularPlan,
    required this.upgradeRate,
    required this.churnRate,
    required this.revenueByPlan,
    required this.subscriptionsByPlan,
  });

  factory SubscriptionStats.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return SubscriptionStats(
      totalSubscriptions: parseInt(json['total_subscriptions']),
      activeSubscriptions: parseInt(json['active_subscriptions']),
      trialingSubscriptions: parseInt(json['trialing_subscriptions']),
      canceledSubscriptions: parseInt(json['canceled_subscriptions']),
      expiredSubscriptions: parseInt(json['expired_subscriptions']),
      monthlyRecurringRevenue: parseDouble(json['monthly_recurring_revenue']),
      yearlyRecurringRevenue: parseDouble(json['yearly_recurring_revenue']),
      popularPlan: json['popular_plan'],
      upgradeRate: parseDouble(json['upgrade_rate']),
      churnRate: parseDouble(json['churn_rate']),
      revenueByPlan: Map<String, double>.from(json['revenue_by_plan'] ?? {}),
      subscriptionsByPlan: Map<String, int>.from(
        json['subscriptions_by_plan'] ?? {},
      ),
    );
  }
}
