// lib/screens/wallet/wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import '../../models/wallet_model.dart';
import '../../models/transaction_model.dart';

class WalletScreen extends StatefulWidget {
  final String userRole;
  const WalletScreen({super.key, required this.userRole});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletModel? wallet;
  List<TransactionModel> transactions = [];
  bool loading = true;
  bool withdrawing = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() => loading = true);

    try {
      Map<String, dynamic> result;
      if (widget.userRole == 'client') {
        result = await ApiService.getWallet();
      } else {
        result = await ApiService.getFreelancerWallet();
      }

      setState(() {
        if (result['wallet'] != null) {
          wallet = WalletModel.fromJson(result['wallet']);
        }
        if (result['transactions'] != null) {
          transactions = (result['transactions'] as List)
              .map((json) => TransactionModel.fromJson(json))
              .toList();
        }
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      Fluttertoast.showToast(msg: 'Error loading wallet');
    }
  }

  Future<void> _requestWithdrawal() async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Funds'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available Balance: \$${wallet?.balance.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Invalid amount';
                  }
                  if (amount > (wallet?.balance ?? 0)) {
                    return 'Insufficient balance';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff14A800),
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (result == true && amountController.text.isNotEmpty) {
      setState(() => withdrawing = true);

      final amount = double.parse(amountController.text);
      final response = widget.userRole == 'client'
          ? await ApiService.requestWithdrawal(amount)
          : await ApiService.requestFreelancerWithdrawal(amount);

      setState(() => withdrawing = false);

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: '✅ Withdrawal request submitted');
        _loadWallet();
      } else if (response['requiresOnboarding'] == true) {
        Fluttertoast.showToast(msg: 'Please complete Stripe account setup');
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Error');
      }
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.arrow_downward,
            label: 'Withdraw',
            color: Colors.orange,
            onTap: _requestWithdrawal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.shopping_bag,
            label: 'Boost',
            color: Colors.purple,
            onTap: () {
              Navigator.pushNamed(context, '/features/shop');
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.history,
            label: 'History',
            color: Colors.blue,
            onTap: () {
              // TODO: Show transaction history
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${wallet!.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBalanceStat(
                'Pending',
                '\$${wallet!.pendingBalance.toStringAsFixed(2)}',
                Colors.white70,
              ),
              _buildBalanceStat(
                'Earned',
                '\$${wallet!.totalEarned.toStringAsFixed(2)}',
                Colors.white70,
              ),
              _buildBalanceStat(
                'Withdrawn',
                '\$${wallet!.totalWithdrawn.toStringAsFixed(2)}',
                Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsSection() {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length > 10 ? 10 : transactions.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tx.typeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(tx.typeIcon, style: const TextStyle(fontSize: 20)),
              ),
              title: Text(
                tx.typeText,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                tx.description ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${tx.amount >= 0 ? '+' : ''}\$${tx.amount.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tx.type == 'withdraw' ? Colors.red : Colors.green,
                    ),
                  ),
                  Text(
                    _formatDate(tx.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          },
        ),
        if (transactions.length > 10)
          TextButton(
            onPressed: () {
              // TODO: Show all transactions
            },
            child: const Text('View All'),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadWallet),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : wallet == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No wallet found',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadWallet,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                    _buildTransactionsSection(),
                  ],
                ),
              ),
            ),
    );
  }
}
