class AdvancedStats {
  final Map<String, dynamic> engagement;
  final Map<String, dynamic> contracts;
  final Map<String, dynamic> disputes;
  final Map<String, dynamic> ads;

  AdvancedStats({
    required this.engagement,
    required this.contracts,
    required this.disputes,
    required this.ads,
  });

  factory AdvancedStats.fromJson(Map<String, dynamic> json) {
    return AdvancedStats(
      engagement: json['engagement'] ?? {},
      contracts: json['contracts'] ?? {},
      disputes: json['disputes'] ?? {},
      ads: json['ads'] ?? {},
    );
  }

  double get completionRate => (contracts['completion_rate'] ?? 0).toDouble();
  double get avgContractValue =>
      (contracts['average_contract_value'] ?? 0).toDouble();
  double get engagementRate => (engagement['engagement_rate'] ?? 0).toDouble();
  double get adCTR => (ads['ctr'] ?? 0).toDouble();
}
