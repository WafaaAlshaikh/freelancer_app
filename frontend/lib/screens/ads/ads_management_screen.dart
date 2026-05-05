import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/ad_banner.dart';
import 'create_ad_campaign_screen.dart';
import 'payment_screen.dart';

class AdsManagementScreen extends StatefulWidget {
  const AdsManagementScreen({super.key});

  @override
  State<AdsManagementScreen> createState() => _AdsManagementScreenState();
}

class _AdsManagementScreenState extends State<AdsManagementScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _campaigns = [];
  bool _loading = true;
  String _filter = 'all';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCampaigns();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getMyAdCampaigns(status: _filter);
      setState(() {
        _campaigns = response['campaigns'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading campaigns: $e')));
    }
  }

  Future<void> _pauseCampaign(int id) async {
    final response = await ApiService.pauseAdCampaign(id);
    if (response['success'] == true) {
      _loadCampaigns();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campaign paused'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _activateCampaign(int id) async {
    final response = await ApiService.activateAdCampaign(id);
    if (response['success'] == true) {
      _loadCampaigns();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campaign activated'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (response['requiresPayment'] == true) {
      final campaign = _campaigns.firstWhere((c) => c['id'] == id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdPaymentScreen(
            campaignId: id,
            amount: _toDouble(campaign['total_budget']),
            campaignName: campaign['name'],
          ),
        ),
      ).then((_) => _loadCampaigns());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to activate'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'paused':
        return 'Paused';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'draft':
        return 'Draft';
      default:
        return status;
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Ad Campaigns'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateAdCampaignScreen()),
            ).then((_) => _loadCampaigns()),
            tooltip: 'New Campaign',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCampaigns,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purple,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey,
          onTap: (index) {
            setState(() {
              if (index == 0)
                _filter = 'all';
              else if (index == 1)
                _filter = 'active';
              else
                _filter = 'completed';
              _loadCampaigns();
            });
          },
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Active', icon: Icon(Icons.play_circle)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _campaigns.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _campaigns.length,
              itemBuilder: (_, i) => _buildCampaignCard(_campaigns[i]),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No ad campaigns yet', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Create your first campaign to reach more clients'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              print('🖱️ Create Campaign button pressed');
              Navigator.pushNamed(
                context,
                '/create-ad-campaign',
              ).then((_) => _loadCampaigns());
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Campaign'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(dynamic campaign) {
    final statusColor = _getStatusColor(campaign['status']);
    final spent = _toDouble(campaign['spent_amount']);
    final budget = _toDouble(campaign['total_budget']);
    final progress = budget > 0 ? spent / budget : 0.0;
    final startDate = campaign['start_date'] != null
        ? DateFormat(
            'MMM d, yyyy',
          ).format(DateTime.parse(campaign['start_date']))
        : 'N/A';
    final endDate = campaign['end_date'] != null
        ? DateFormat('MMM d, yyyy').format(DateTime.parse(campaign['end_date']))
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        campaign['ad_type'] ?? 'banner',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(campaign['status']),
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip(Icons.visibility, '${campaign['impressions'] ?? 0}'),
                const SizedBox(width: 8),
                _infoChip(Icons.touch_app, '${campaign['clicks'] ?? 0}'),
                const SizedBox(width: 8),
                _infoChip(
                  Icons.attach_money,
                  campaign['pricing_model']?.toUpperCase() ?? 'CPC',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip(
                  Icons.calendar_today,
                  '$startDate - $endDate',
                  small: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: \$${spent.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Budget: \$${budget.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (campaign['status'] == 'draft')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _activateCampaign(campaign['id']),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Activate & Pay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            if (campaign['status'] == 'active')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pauseCampaign(campaign['id']),
                      icon: const Icon(Icons.pause, size: 16),
                      label: const Text('Pause'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showStatsDialog(campaign),
                      icon: const Icon(Icons.bar_chart, size: 16),
                      label: const Text('Stats'),
                    ),
                  ),
                ],
              ),
            if (campaign['status'] == 'paused')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _activateCampaign(campaign['id']),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 12 : 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: small ? 10 : 11)),
        ],
      ),
    );
  }

  void _showStatsDialog(dynamic campaign) {
    final ctr = campaign['clicks'] ?? 0;
    final impr = campaign['impressions'] ?? 0;
    final ctrPercent = impr > 0 ? (ctr / impr * 100).toStringAsFixed(2) : '0';
    final spent = (campaign['spent_amount'] ?? 0).toDouble();
    final avgCpc = ctr > 0 ? spent / ctr : 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.bar_chart, color: Colors.purple),
            const SizedBox(width: 8),
            Text(campaign['name']),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statRow('Impressions', impr.toString()),
            const Divider(),
            _statRow('Clicks', ctr.toString()),
            const Divider(),
            _statRow('CTR', '$ctrPercent%'),
            const Divider(),
            _statRow('Total Spent', '\$${spent.toStringAsFixed(2)}'),
            const Divider(),
            _statRow('Avg CPC', '\$${avgCpc.toStringAsFixed(3)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
