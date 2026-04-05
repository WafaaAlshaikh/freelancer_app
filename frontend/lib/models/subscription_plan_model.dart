class SubscriptionPlan {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final String billingPeriod;
  final List<String> features;
  final int? proposalLimit;
  final int? activeProjectLimit;
  final bool aiInsights;
  final bool prioritySupport;
  final bool apiAccess;
  final bool customBranding;
  final int trialDays;
  final int sortOrder;
  final bool isRecommended;
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    required this.billingPeriod,
    required this.features,
    this.proposalLimit,
    this.activeProjectLimit,
    required this.aiInsights,
    required this.prioritySupport,
    required this.apiAccess,
    required this.customBranding,
    required this.trialDays,
    required this.sortOrder,
    required this.isRecommended,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
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

    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    return SubscriptionPlan(
      id: parseInt(json['id']),
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      price: parseDouble(json['price']),
      billingPeriod: json['billing_period'] ?? 'monthly',
      features: List<String>.from(json['features'] ?? []),
      proposalLimit: json['proposal_limit'] != null
          ? parseInt(json['proposal_limit'])
          : null,
      activeProjectLimit: json['active_project_limit'] != null
          ? parseInt(json['active_project_limit'])
          : null,
      aiInsights: parseBool(json['ai_insights']),
      prioritySupport: parseBool(json['priority_support']),
      apiAccess: parseBool(json['api_access']),
      customBranding: parseBool(json['custom_branding']),
      trialDays: parseInt(json['trial_days']),
      sortOrder: parseInt(json['sort_order']),
      isRecommended: parseBool(json['is_recommended']),
      isActive: parseBool(json['is_active']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'description': description,
      'price': price,
      'billing_period': billingPeriod,
      'features': features,
      'proposal_limit': proposalLimit,
      'active_project_limit': activeProjectLimit,
      'ai_insights': aiInsights,
      'priority_support': prioritySupport,
      'api_access': apiAccess,
      'custom_branding': customBranding,
      'trial_days': trialDays,
      'sort_order': sortOrder,
      'is_recommended': isRecommended,
      'is_active': isActive,
    };
  }

  String get formattedPrice {
    if (price == 0) return 'Free';
    return '\$${price.toStringAsFixed(0)}/${billingPeriod == 'monthly' ? 'mo' : 'yr'}';
  }
}
