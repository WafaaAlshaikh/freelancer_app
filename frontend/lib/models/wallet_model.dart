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
    return WalletModel(
      id: json['id'],
      userId: json['UserId'],
      balance: (json['balance'] ?? 0).toDouble(),
      pendingBalance: (json['pending_balance'] ?? 0).toDouble(),
      totalEarned: (json['total_earned'] ?? 0).toDouble(),
      totalWithdrawn: (json['total_withdrawn'] ?? 0).toDouble(),
      stripeAccountId: json['stripe_account_id'],
    );
  }
}