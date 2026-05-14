import 'dart:ui';

import 'package:flutter/material.dart';

class PredictiveAnalytics {
  final int expectedNewUsers;
  final double expectedRevenue;
  final double revenueConfidence;
  final int expectedDisputes;
  final String disputeRisk;
  final Map<String, double> growthForecast;

  PredictiveAnalytics({
    required this.expectedNewUsers,
    required this.expectedRevenue,
    required this.revenueConfidence,
    required this.expectedDisputes,
    required this.disputeRisk,
    required this.growthForecast,
  });

  factory PredictiveAnalytics.fromJson(Map<String, dynamic> json) {
    return PredictiveAnalytics(
      expectedNewUsers: json['expected_new_users'] ?? 0,
      expectedRevenue: (json['expected_revenue'] ?? 0).toDouble(),
      revenueConfidence: (json['revenue_confidence'] ?? 0).toDouble(),
      expectedDisputes: json['expected_disputes'] ?? 0,
      disputeRisk: json['dispute_risk'] ?? 'low',
      growthForecast: Map<String, double>.from(json['growth_forecast'] ?? {}),
    );
  }

  Color get riskColor {
    switch (disputeRisk) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}
