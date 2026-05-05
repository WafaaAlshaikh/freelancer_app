// lib/screens/admin/admin_ads_management_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

const _kAccent = Color(0xFF5B58E2);
const _kAccentLight = Color(0xFF8B88FF);
const _kGreen = Color(0xFF14A800);
const _kRed = Color(0xFFEF4444);
const _kOrange = Color(0xFFF59E0B);
const _kPageBg = Color(0xFFF0F2F8);

class AdminAdsManagementScreen extends StatefulWidget {
  const AdminAdsManagementScreen({super.key});

  @override
  State<AdminAdsManagementScreen> createState() =>
      _AdminAdsManagementScreenState();
}

class _AdminAdsManagementScreenState extends State<AdminAdsManagementScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _campaigns = [];
  bool _loading = true;
  bool _isMounted = true;
  String _selectedStatus = 'all';
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCampaigns = 0;
  Map<String, dynamic> _stats = {};
  late TabController _tabController;
  int _selectedTab = 0;
  Map<String, List<Map<String, dynamic>>> _dailyStatsData = {};

  Map<String, dynamic> _analytics = {};
  bool _loadingAnalytics = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
      if (_selectedTab == 1) {
        _loadAnalytics();
      }
    });
    _loadCampaigns();
  }

  @override
  void dispose() {
    _isMounted = false;
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.adminGetAllCampaigns(
        status: _selectedStatus,
        search: _searchQuery,
        page: _currentPage,
      );

      setState(() {
        _campaigns = List<Map<String, dynamic>>.from(
          response['campaigns'] ?? [],
        );
        _totalPages = response['totalPages'] ?? 1;
        _totalCampaigns = response['total'] ?? 0;
        _stats = response['stats'] ?? {};
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      Fluttertoast.showToast(msg: 'Error loading campaigns: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    if (!_isMounted) return;
    setState(() => _loadingAnalytics = true);
    try {
      final response = await ApiService.adminGetAdAnalytics();
      if (_isMounted && response['success'] == true) {
        setState(() {
          _analytics = response['analytics'] ?? {};
          _loadingAnalytics = false;
        });
      } else if (_isMounted) {
        setState(() => _loadingAnalytics = false);
      }
    } catch (e) {
      if (_isMounted) {
        setState(() => _loadingAnalytics = false);
      }
      print('Error loading analytics: $e');
    }
  }

  Future<void> _changeCampaignStatus(
    int campaignId,
    String newStatus, {
    String? reason,
  }) async {
    try {
      final response = await ApiService.adminChangeCampaignStatus(
        campaignId,
        newStatus,
        reason: reason,
      );

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: 'Status changed to $newStatus');
        _loadCampaigns();
        if (_selectedTab == 1) _loadAnalytics();
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? 'Failed to change status',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> _deleteCampaign(int campaignId, String campaignName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Campaign',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "$campaignName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.adminDeleteCampaign(campaignId);
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: 'Campaign deleted successfully');
        _loadCampaigns();
        if (_selectedTab == 1) _loadAnalytics();
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Failed to delete');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  void _showEditDialog(Map<String, dynamic> campaign) {
    final nameCtrl = TextEditingController(text: campaign['name']);
    final budgetCtrl = TextEditingController(
      text: campaign['total_budget']?.toString(),
    );
    final dailyBudgetCtrl = TextEditingController(
      text: campaign['daily_budget']?.toString(),
    );
    final cpcCtrl = TextEditingController(
      text: campaign['cost_per_click']?.toString(),
    );
    final cpmCtrl = TextEditingController(
      text: campaign['cost_per_impression']?.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kAccentLight, _kAccent],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'Edit Campaign',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Campaign Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: budgetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Total Budget',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dailyBudgetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Daily Budget',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cpcCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cost Per Click',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cpmCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cost Per Impression',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updateData = {
                'name': nameCtrl.text.trim(),
                'total_budget':
                    double.tryParse(budgetCtrl.text) ??
                    campaign['total_budget'],
                'daily_budget': double.tryParse(dailyBudgetCtrl.text),
                'cost_per_click':
                    double.tryParse(cpcCtrl.text) ?? campaign['cost_per_click'],
                'cost_per_impression':
                    double.tryParse(cpmCtrl.text) ??
                    campaign['cost_per_impression'],
              };

              final response = await ApiService.adminUpdateCampaign(
                campaign['id'],
                updateData,
              );
              if (response['success'] == true) {
                Navigator.pop(ctx);
                Fluttertoast.showToast(msg: 'Campaign updated');
                _loadCampaigns();
              } else {
                Fluttertoast.showToast(
                  msg: response['message'] ?? 'Update failed',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(Map<String, dynamic> campaign) {
    final currentStatus = campaign['status'];
    final possibleStatuses = ['active', 'paused', 'completed', 'cancelled'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Change Status',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: possibleStatuses.map((status) {
            final isSelected = currentStatus == status;
            return ListTile(
              leading: Radio<String>(
                value: status,
                groupValue: currentStatus,
                onChanged: (value) {
                  Navigator.pop(ctx);
                  _changeCampaignStatus(campaign['id'], status!);
                },
                activeColor: _getStatusColor(status),
              ),
              title: Text(_getStatusText(status)),
              trailing: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return _kGreen;
      case 'paused':
        return _kOrange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return _kRed;
      case 'draft':
        return Colors.grey;
      case 'pending_approval':
        return Colors.purple;
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
      case 'pending_approval':
        return 'Pending Approval';
      default:
        return status;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
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
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _kPageBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search campaigns by name...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFAAAAAA),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFFAAAAAA),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) {
                    _searchQuery = v;
                    _currentPage = 1;
                    _loadCampaigns();
                  },
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip('All', 'all'),
                    _buildStatusFilterChip('Active', 'active'),
                    _buildStatusFilterChip('Paused', 'paused'),
                    _buildStatusFilterChip('Completed', 'completed'),
                    _buildStatusFilterChip('Draft', 'draft'),
                    _buildStatusFilterChip('Pending', 'pending_approval'),
                    _buildStatusFilterChip('Cancelled', 'cancelled'),
                  ],
                ),
              ),
            ],
          ),
        ),

        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: _kAccent,
            labelColor: _kAccent,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Campaigns', icon: Icon(Icons.campaign)),
              Tab(text: 'Analytics', icon: Icon(Icons.bar_chart)),
              Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
            ],
          ),
        ),

        Expanded(
          child: IndexedStack(
            index: _selectedTab,
            children: [
              _buildCampaignsList(),
              _buildAnalyticsTab(),
              _buildStatsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilterChip(String label, String value) {
    final selected = _selectedStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = value;
          _currentPage = 1;
        });
        _loadCampaigns();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [_kAccentLight, _kAccent])
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade200,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _kAccent.withOpacity(0.3), blurRadius: 8)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignsList() {
    if (_loading && _campaigns.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _kAccent));
    }

    if (_campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kPageBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.campaign_outlined,
                size: 40,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No campaigns found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _kPageBg,
          child: Row(
            children: [
              _quickStatChip(
                'Total',
                _totalCampaigns.toString(),
                Colors.purple,
              ),
              const SizedBox(width: 12),
              _quickStatChip(
                'Active',
                _stats['active_campaigns']?.toString() ?? '0',
                _kGreen,
              ),
              const SizedBox(width: 12),
              _quickStatChip(
                'Revenue',
                '\$${(_stats['total_spent'] ?? 0).toDouble().toStringAsFixed(0)}',
                _kOrange,
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _campaigns.length,
            itemBuilder: (_, i) => _buildCampaignCard(_campaigns[i]),
          ),
        ),

        if (_totalPages > 1) _buildPagination(),
      ],
    );
  }

  Widget _quickStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final advertiser = campaign['advertiser'] ?? {};
    final status = campaign['status'] ?? 'draft';
    final statusColor = _getStatusColor(status);
    final spent = _toDouble(campaign['spent_amount']);
    final budget = _toDouble(campaign['total_budget']);
    final progress = budget > 0 ? spent / budget : 0.0;
    final impressions = campaign['impressions'] ?? 0;
    final clicks = campaign['clicks'] ?? 0;
    final ctr = impressions > 0
        ? (clicks / impressions * 100).toStringAsFixed(2)
        : '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.campaign, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign['name'] ?? 'Unnamed',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            advertiser['name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.email_outlined,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            advertiser['email'] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _infoChip(Icons.visibility, '$impressions', 'impressions'),
                    const SizedBox(width: 8),
                    _infoChip(Icons.touch_app, '$clicks', 'clicks'),
                    const SizedBox(width: 8),
                    _infoChip(Icons.trending_up, '$ctr%', 'CTR'),
                    const SizedBox(width: 8),
                    _infoChip(
                      Icons.attach_money,
                      campaign['pricing_model']?.toUpperCase() ?? 'CPC',
                      'model',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(campaign['start_date'])} - ${_formatDate(campaign['end_date'])}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _actionButton(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: _kAccent,
                      onTap: () => _showEditDialog(campaign),
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      icon: Icons.tune,
                      label: 'Status',
                      color: _kOrange,
                      onTap: () => _showStatusDialog(campaign),
                    ),
                    const SizedBox(width: 8),
                    if (status == 'active')
                      _actionButton(
                        icon: Icons.pause,
                        label: 'Pause',
                        color: _kOrange,
                        onTap: () =>
                            _changeCampaignStatus(campaign['id'], 'paused'),
                      ),
                    if (status == 'paused')
                      _actionButton(
                        icon: Icons.play_arrow,
                        label: 'Resume',
                        color: _kGreen,
                        onTap: () =>
                            _changeCampaignStatus(campaign['id'], 'active'),
                      ),
                    const Spacer(),
                    _actionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: _kRed,
                      onTap: () => _deleteCampaign(
                        campaign['id'],
                        campaign['name'] ?? 'Campaign',
                      ),
                      isOutlined: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Text(
            ' $label',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: isOutlined ? Border.all(color: color.withOpacity(0.3)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(
            Icons.chevron_left,
            _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadCampaigns();
                  }
                : null,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _kPageBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page $_currentPage / $_totalPages',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          _pageBtn(
            Icons.chevron_right,
            _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadCampaigns();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? _kAccent.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: onTap != null
                ? _kAccent.withOpacity(0.2)
                : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? _kAccent : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_loadingAnalytics) {
      return const Center(child: CircularProgressIndicator(color: _kAccent));
    }

    final summary = _analytics['summary'] ?? {};
    final typeStats = _analytics['type_stats'] ?? [];
    final topAdvertisers = _analytics['top_advertisers'] ?? [];
    final dailyStats = _analytics['daily_stats'] ?? [];

    final Map<String, Map<String, double>> chartData = {};
    for (var stat in dailyStats) {
      final date = stat['date']?.toString() ?? '';
      final type = stat['type'] ?? 'impression';
      final count = _toDouble(stat['count']);

      if (!chartData.containsKey(date)) {
        chartData[date] = {
          'impressions': 0,
          'clicks': 0,
          'conversions': 0,
          'revenue': 0,
        };
      }

      if (type == 'impression') chartData[date]!['impressions'] = count;
      if (type == 'click') chartData[date]!['clicks'] = count;
      if (type == 'conversion') chartData[date]!['conversions'] = count;
      chartData[date]!['revenue'] = _toDouble(stat['revenue']);
    }

    final dates = chartData.keys.toList()..sort();
    final impressionsData = dates
        .map((d) => chartData[d]!['impressions']!.toDouble())
        .toList();
    final clicksData = dates
        .map((d) => chartData[d]!['clicks']!.toDouble())
        .toList();
    final revenueData = dates
        .map((d) => chartData[d]!['revenue']!.toDouble())
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Performance Indicators',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _kpiCard(
                'Total Revenue',
                '\$${_toDouble(summary['total_revenue']).toStringAsFixed(0)}',
                Icons.monetization_on,
                _kGreen,
                '+12%',
              ),
              _kpiCard(
                'Platform Commission',
                '\$${_toDouble(summary['platform_commission']).toStringAsFixed(0)}',
                Icons.percent,
                _kOrange,
                '+8%',
              ),
              _kpiCard(
                'Active Campaigns',
                summary['active_campaigns']?.toString() ?? '0',
                Icons.play_circle,
                _kAccent,
                '${(summary['active_campaigns'] ?? 0) * 100 ~/ (summary['total_campaigns'] ?? 1)}%',
              ),
              _kpiCard(
                'CTR Average',
                '${_computeAvgCTR(typeStats).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.blue,
                '+2.3%',
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.show_chart,
                        color: _kAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Daily Performance Trends',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: _buildLineChart(dates, impressionsData, clicksData),
                ),
                const SizedBox(height: 16),
                _buildChartLegend(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.pie_chart,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Performance by Ad Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(height: 200, child: _buildPieChart(typeStats)),
                const SizedBox(height: 16),
                _buildTypeStatsTable(typeStats),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.leaderboard,
                        color: _kOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Top Advertisers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(height: 250, child: _buildBarChart(topAdvertisers)),
                const SizedBox(height: 16),
                _buildTopAdvertisersTable(topAdvertisers),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildMetricsGrid(summary),
        ],
      ),
    );
  }

  double _computeAvgCTR(List typeStats) {
    if (typeStats.isEmpty) return 0.0;
    double totalCTR = 0;
    int count = 0;
    for (var stat in typeStats) {
      final impressions = _toDouble(stat['total_impressions']);
      final clicks = _toDouble(stat['total_clicks']);
      if (impressions > 0) {
        totalCTR += (clicks / impressions) * 100;
        count++;
      }
    }
    return count > 0 ? totalCTR / count : 0.0;
  }

  Widget _kpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trend.startsWith('+')
                      ? _kGreen.withOpacity(0.1)
                      : _kRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trend.startsWith('+')
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 10,
                      color: trend.startsWith('+') ? _kGreen : _kRed,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: trend.startsWith('+') ? _kGreen : _kRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(
    List<String> dates,
    List<double> impressions,
    List<double> clicks,
  ) {
    if (dates.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dates.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dates[value.toInt()].substring(5, 10),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade200),
        ),
        minX: 0,
        maxX: (dates.length - 1).toDouble(),
        minY: 0,
        maxY: impressions.isEmpty
            ? 10
            : impressions.reduce((a, b) => a > b ? a : b) * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              impressions.length,
              (i) => FlSpot(i.toDouble(), impressions[i]),
            ),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(radius: 4, color: Colors.blue);
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: List.generate(
              clicks.length,
              (i) => FlSpot(i.toDouble(), clicks[i]),
            ),
            isCurved: true,
            color: _kGreen,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(radius: 4, color: _kGreen);
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _kGreen.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots
                  .map(
                    (spot) => LineTooltipItem(
                      '${spot.y.toInt()}',
                      TextStyle(color: spot.bar.color),
                    ),
                  )
                  .toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.blue, 'Impressions'),
        const SizedBox(width: 16),
        _legendItem(_kGreen, 'Clicks'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPieChart(List typeStats) {
    final data = <Map<String, dynamic>>[];
    for (var stat in typeStats) {
      final spent = _toDouble(stat['total_spent']);
      if (spent > 0) {
        data.add({
          'type': stat['ad_type']?.toString().toUpperCase() ?? 'Unknown',
          'value': spent,
        });
      }
    }

    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final total = data.fold(0.0, (sum, item) => sum + item['value']);

    return PieChart(
      PieChartData(
        sections: List.generate(data.length, (i) {
          final percentage = ((data[i]['value'] / total) * 100);
          final title = '${percentage.toStringAsFixed(0)}%';
          return PieChartSectionData(
            color: [
              Colors.blue,
              _kGreen,
              _kOrange,
              _kAccent,
              Colors.purple,
            ][i % 5],
            value: data[i]['value'],
            title: title,
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildBarChart(List topAdvertisers) {
    if (topAdvertisers.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final top5 = topAdvertisers.take(5).toList();
    final maxSpent = top5.fold(
      0.0,
      (max, adv) => _toDouble(adv['total_spent']) > max
          ? _toDouble(adv['total_spent'])
          : max,
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxSpent,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < top5.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      (top5[value.toInt()]['name']?.substring(
                            0,
                            (top5[value.toInt()]['name'].length > 3
                                ? 3
                                : top5[value.toInt()]['name'].length),
                          ) ??
                          '?'),
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 50),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barGroups: List.generate(top5.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: _toDouble(top5[i]['total_spent']),
                color: _kOrange,
                width: 30,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTypeStatsTable(List typeStats) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.resolveWith<Color>(
          (states) => _kPageBg,
        ),
        columns: const [
          DataColumn(
            label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Impressions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Clicks',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('CTR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('Spent', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        rows: typeStats.map((stat) {
          final impressions = _toDouble(stat['total_impressions']);
          final clicks = _toDouble(stat['total_clicks']);
          final ctr = impressions > 0 ? (clicks / impressions) * 100 : 0;
          return DataRow(
            cells: [
              DataCell(
                Text(stat['ad_type']?.toString().toUpperCase() ?? 'Unknown'),
              ),
              DataCell(Text(impressions.toInt().toString())),
              DataCell(Text(clicks.toInt().toString())),
              DataCell(Text('${ctr.toStringAsFixed(2)}%')),
              DataCell(
                Text('\$${_toDouble(stat['total_spent']).toStringAsFixed(2)}'),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopAdvertisersTable(List topAdvertisers) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.resolveWith<Color>(
          (states) => _kPageBg,
        ),
        columns: const [
          DataColumn(
            label: Text(
              'Advertiser',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Campaigns',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Total Spent',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Commission',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: topAdvertisers.take(10).map((adv) {
          return DataRow(
            cells: [
              DataCell(Text(adv['name'] ?? 'Unknown')),
              DataCell(Text(adv['campaign_count']?.toString() ?? '0')),
              DataCell(
                Text('\$${_toDouble(adv['total_spent']).toStringAsFixed(2)}'),
              ),
              DataCell(
                Text(
                  '\$${_toDouble(adv['platform_commission']).toStringAsFixed(2)}',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kAccent, _kAccentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Additional Metrics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metricChip(
                'Avg CTR',
                '${_computeAvgCTR(_analytics['type_stats'] ?? []).toStringAsFixed(2)}%',
                Icons.trending_up,
              ),
              const SizedBox(width: 12),
              _metricChip('Est. ROI', '250%', Icons.trending_up),
              const SizedBox(width: 12),
              _metricChip('Conversion Rate', '3.2%', Icons.analytics),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAdTypeIcon(String? type) {
    switch (type) {
      case 'banner':
        return Icons.web;
      case 'sidebar':
        return Icons.view_sidebar;
      case 'popup':
        return Icons.center_focus_strong;
      case 'video':
        return Icons.videocam;
      default:
        return Icons.campaign;
    }
  }

  Widget _analyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                _statListItem(
                  'Total Campaigns',
                  _stats['total_campaigns']?.toString() ?? '0',
                  Icons.campaign,
                  Colors.purple,
                ),
                _statListItem(
                  'Active Campaigns',
                  _stats['active_campaigns']?.toString() ?? '0',
                  Icons.play_circle,
                  _kGreen,
                ),
                _statListItem(
                  'Paused Campaigns',
                  _stats['paused_campaigns']?.toString() ?? '0',
                  Icons.pause,
                  _kOrange,
                ),
                _statListItem(
                  'Completed Campaigns',
                  _stats['completed_campaigns']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.blue,
                ),
                _statListItem(
                  'Draft Campaigns',
                  _stats['draft_campaigns']?.toString() ?? '0',
                  Icons.edit_note,
                  Colors.grey,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                _statListItem(
                  'Total Impressions',
                  _stats['total_impressions']?.toString() ?? '0',
                  Icons.visibility,
                  Colors.blue,
                ),
                _statListItem(
                  'Total Clicks',
                  _stats['total_clicks']?.toString() ?? '0',
                  Icons.touch_app,
                  _kGreen,
                ),
                _statListItem(
                  'Click-Through Rate',
                  '${_stats['click_through_rate'] ?? 0}%',
                  Icons.trending_up,
                  _kOrange,
                ),
                _statListItem(
                  'Total Spend',
                  '\$${(_stats['total_spent'] ?? 0).toDouble().toStringAsFixed(2)}',
                  Icons.attach_money,
                  _kRed,
                ),
                _statListItem(
                  'Total Budget',
                  '\$${(_stats['total_budget'] ?? 0).toDouble().toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Colors.teal,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if ((_stats['pending_payments'] ?? 0) > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kOrange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payment,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pending Payments',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_stats['pending_payments']} campaigns waiting for payment',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.warning_amber, color: _kOrange),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statListItem(String title, String value, IconData icon, Color color) {
    String displayValue = value;
    if (value.startsWith('\$')) {
      final numValue = _toDouble(value.replaceAll('\$', ''));
      displayValue = '\$${numValue.toStringAsFixed(2)}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
