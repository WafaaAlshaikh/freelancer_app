import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/token_storage.dart';
import '../models/subscription_plan_model.dart';

class SubscriptionService {
  static String get baseUrl => BASE_URL;

  static Future<Map<String, String>> get _headers async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/subscription/plans'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> plansJson = data['plans'];
        return plansJson
            .map((json) => SubscriptionPlan.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting plans: $e');
      return [];
    }
  }

  static Future<String?> createCheckoutSession(
    String planSlug, {
    String? couponCode,
  }) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/subscription/checkout-session'),
        headers: headers,
        body: jsonEncode({
          'planSlug': planSlug,
          if (couponCode != null) 'couponCode': couponCode,
        }),
      );

      final data = jsonDecode(response.body);
      return data['checkoutUrl'];
    } catch (e) {
      print('Error creating checkout session: $e');
      return null;
    }
  }

  static Future<UserSubscription?> getCurrentSubscription() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/subscription/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['subscription'] != null) {
          return UserSubscription.fromJson(data['subscription']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting subscription: $e');
      return null;
    }
  }

  static Future<bool> cancelSubscription() async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/subscription/cancel'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Error canceling subscription: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> validateCoupon(
    String code,
    String planSlug,
  ) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/subscription/validate-coupon'),
        headers: headers,
        body: jsonEncode({'code': code, 'planSlug': planSlug}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      print('Error validating coupon: $e');
      return null;
    }
  }

  static Future<List<Invoice>> getInvoices({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/invoices?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> invoicesJson = data['invoices'];
        return invoicesJson.map((json) => Invoice.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting invoices: $e');
      return [];
    }
  }

  static Future<UsageStats> getUsageStats() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/user/usage'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UsageStats.fromJson(data['usage']);
      }
      return UsageStats.empty();
    } catch (e) {
      print('Error getting usage stats: $e');
      return UsageStats.empty();
    }
  }

  static Future<bool> upgradePlan(String newPlanSlug) async {
    try {
      final checkoutUrl = await createCheckoutSession(newPlanSlug);
      if (checkoutUrl != null) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error upgrading plan: $e');
      return false;
    }
  }
}

class UserSubscription {
  final int id;
  final SubscriptionPlan plan;
  final String status;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  UserSubscription({
    required this.id,
    required this.plan,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
  });

  bool get isActive => status == 'active' || status == 'trialing';
  bool get isTrialing => status == 'trialing';
  bool get isFree => plan.price == 0;

  int get daysRemaining {
    final now = DateTime.now();
    return currentPeriodEnd.difference(now).inDays;
  }

  String get remainingDaysText {
    if (daysRemaining <= 0) return 'Expired';
    if (daysRemaining == 1) return '1 day left';
    return '$daysRemaining days left';
  }

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'],
      plan: SubscriptionPlan.fromJson(json['plan']),
      status: json['status'],
      currentPeriodStart: DateTime.parse(json['current_period_start']),
      currentPeriodEnd: DateTime.parse(json['current_period_end']),
      cancelAtPeriodEnd: json['cancel_at_period_end'] ?? false,
    );
  }
}

class UsageStats {
  final int proposalsUsed;
  final int proposalsLimit;
  final int activeProjectsUsed;
  final int activeProjectsLimit;

  UsageStats({
    required this.proposalsUsed,
    required this.proposalsLimit,
    required this.activeProjectsUsed,
    required this.activeProjectsLimit,
  });

  double get proposalsPercentage =>
      proposalsLimit > 0 ? proposalsUsed / proposalsLimit : 0;
  double get activeProjectsPercentage =>
      activeProjectsLimit > 0 ? activeProjectsUsed / activeProjectsLimit : 0;
  bool get hasReachedProposalLimit =>
      proposalsUsed >= proposalsLimit && proposalsLimit > 0;
  bool get hasReachedProjectLimit =>
      activeProjectsUsed >= activeProjectsLimit && activeProjectsLimit > 0;

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      proposalsUsed: json['proposals_used'] ?? 0,
      proposalsLimit: json['proposals_limit'] ?? 0,
      activeProjectsUsed: json['active_projects_used'] ?? 0,
      activeProjectsLimit: json['active_projects_limit'] ?? 0,
    );
  }

  factory UsageStats.empty() {
    return UsageStats(
      proposalsUsed: 0,
      proposalsLimit: 0,
      activeProjectsUsed: 0,
      activeProjectsLimit: 0,
    );
  }
}

class Invoice {
  final int id;
  final String invoiceNumber;
  final double amount;
  final double discount;
  final double tax;
  final double total;
  final String status;
  final String? pdfUrl;
  final DateTime createdAt;
  final DateTime? paidAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.amount,
    required this.discount,
    required this.tax,
    required this.total,
    required this.status,
    this.pdfUrl,
    required this.createdAt,
    this.paidAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      invoiceNumber: json['invoice_number'],
      amount: double.parse(json['amount'].toString()),
      discount: double.parse(json['discount'].toString()),
      tax: double.parse(json['tax'].toString()),
      total: double.parse(json['total'].toString()),
      status: json['status'],
      pdfUrl: json['pdf_url'],
      createdAt: DateTime.parse(json['createdAt']),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
    );
  }
}
