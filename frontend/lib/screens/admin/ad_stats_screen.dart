import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';

class AdStatsScreen extends StatefulWidget {
  const AdStatsScreen({super.key});

  @override
  State<AdStatsScreen> createState() => _AdStatsScreenState();
}

class _AdStatsScreenState extends State<AdStatsScreen> {
  Map<String, dynamic> _stats = {};
  List<dynamic> _campaigns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final revenueStats = await ApiService.getAdRevenueStats();
      final campaigns = await ApiService.getMyAdCampaigns();
      setState(() {
        _stats = revenueStats['stats'] ?? {};
        _campaigns = campaigns['campaigns'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Ad Revenue Stats'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatsGrid(),
                  const SizedBox(height: 16),
                  _buildCampaignsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    final totalRevenue = (_stats['total_ad_revenue'] ?? 0).toDouble();
    final activeCampaigns = _stats['active_campaigns'] ?? 0;
    final totalSpend = (_stats['total_campaign_spend'] ?? 0).toDouble();
    final commissionRate = (_stats['platform_commission_rate'] ?? 0.2) * 100;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statCard(
          'Total Ad Revenue',
          '\$${totalRevenue.toStringAsFixed(2)}',
          Icons.monetization_on,
          Colors.green,
        ),
        _statCard(
          'Active Campaigns',
          activeCampaigns.toString(),
          Icons.campaign,
          Colors.blue,
        ),
        _statCard(
          'Total Ad Spend',
          '\$${totalSpend.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.orange,
        ),
        _statCard(
          'Platform Commission',
          '${commissionRate.toStringAsFixed(0)}%',
          Icons.percent,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Recent Campaigns',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          if (_campaigns.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No campaigns yet')),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _campaigns.length > 10 ? 10 : _campaigns.length,
              itemBuilder: (_, i) => _campaignRow(_campaigns[i]),
            ),
        ],
      ),
    );
  }

  Widget _campaignRow(dynamic campaign) {
    final revenue = (campaign['spent_amount'] ?? 0) * 0.2;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: campaign['status'] == 'active'
            ? Colors.green
            : Colors.grey,
        child: Icon(Icons.campaign, size: 16, color: Colors.white),
      ),
      title: Text(campaign['name']),
      subtitle: Text(
        '${campaign['clicks'] ?? 0} clicks · ${campaign['impressions'] ?? 0} impressions',
      ),
      trailing: Text(
        '\$${revenue.toStringAsFixed(2)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }
}
