// lib/models/wallet_model.dart
class WalletModel {
  final int id;
  final int userId;
  final double balance;
  final double pendingBalance;
  final double totalEarned;
  final double totalWithdrawn;
  final String? stripeAccountId;

  WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    required this.pendingBalance,
    required this.totalEarned,
    required this.totalWithdrawn,
    this.stripeAccountId,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    try {
      double parseToDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.parse(value);
        return 0.0;
      }

      return WalletModel(
        id: json['id'],
        userId: json['UserId'],
        balance: parseToDouble(json['balance']),
        pendingBalance: parseToDouble(json['pending_balance']),
        totalEarned: parseToDouble(json['total_earned']),
        totalWithdrawn: parseToDouble(json['total_withdrawn']),
        stripeAccountId: json['stripe_account_id'],
      );
    } catch (e) {
      print('❌ Error creating WalletModel from JSON: $e');
      print('📄 JSON data: $json');
      rethrow;
    }
  }
}
