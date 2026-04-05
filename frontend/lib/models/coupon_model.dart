class Coupon {
  final int id;
  final String code;
  final String discountType;
  final double discountValue;
  final DateTime validFrom;
  final DateTime validUntil;
  final int? maxUses;
  final int usedCount;
  final List<String>? applicablePlans;
  final bool isActive;
  final DateTime createdAt;

  Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.validFrom,
    required this.validUntil,
    this.maxUses,
    this.usedCount = 0,
    this.applicablePlans,
    this.isActive = true,
    required this.createdAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
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

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return Coupon(
      id: parseInt(json['id']),
      code: json['code'] ?? '',
      discountType: json['discount_type'] ?? 'percentage',
      discountValue: parseDouble(json['discount_value']),
      validFrom: parseDate(json['valid_from']),
      validUntil: parseDate(json['valid_until']),
      maxUses: json['max_uses'] != null ? parseInt(json['max_uses']) : null,
      usedCount: parseInt(json['used_count']),
      applicablePlans: json['applicable_plans'] != null
          ? List<String>.from(json['applicable_plans'])
          : null,
      isActive: parseBool(json['is_active']),
      createdAt: parseDate(json['createdAt']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'discount_type': discountType,
      'discount_value': discountValue,
      'valid_from': validFrom.toIso8601String().split('T')[0],
      'valid_until': validUntil.toIso8601String().split('T')[0],
      'max_uses': maxUses,
      'applicable_plans': applicablePlans,
      'is_active': isActive,
    };
  }

  String get formattedDiscount {
    if (discountType == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}% OFF';
    } else {
      return '\$${discountValue.toStringAsFixed(2)} OFF';
    }
  }
}
