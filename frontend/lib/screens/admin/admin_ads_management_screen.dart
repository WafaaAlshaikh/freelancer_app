// screens/admin/admin_ads_management_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart' as AppTheme;

class AdminAdsManagementScreen extends StatefulWidget {
  const AdminAdsManagementScreen({super.key});

  @override
  State<AdminAdsManagementScreen> createState() =>
      _AdminAdsManagementScreenState();
}

class _AdminAdsManagementScreenState extends State<AdminAdsManagementScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _campaigns = [];
  bool _loading = true;
  String _selectedStatus = 'all';
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCampaigns = 0;
  Map<String, dynamic> _stats = {};
  late TabController _tabController;
  int _selectedTab = 0;

  Map<String, dynamic> _analytics = {};
  bool _loadingAnalytics = false;

  String _status = 'all';
  String _budgetRange = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  String _tempStatus = 'all';
  String _tempBudgetRange = 'all';
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _selectedTab = _tabController.index;
        });
        if (_selectedTab == 1) {
          _loadAnalytics();
        }
      }
    });
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadCampaigns();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    if (!mounted) return;
    setState(() => _loading = true);
    _fadeController.reset();
    try {
      final response = await ApiService.adminGetAllCampaigns(
        status: _status,
        search: _searchQuery,
        page: _currentPage,
        startDate: _startDate?.toIso8601String(),
        endDate: _endDate?.toIso8601String(),
        budgetRange: _budgetRange,
      );

      if (!mounted) return;

      setState(() {
        _campaigns = List<Map<String, dynamic>>.from(
          response['campaigns'] ?? [],
        );
        _totalPages = response['totalPages'] ?? 1;
        _totalCampaigns = response['total'] ?? 0;
        _stats = response['stats'] ?? {};
        _loading = false;
      });
      _fadeController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(msg: '${t?.errorLoadingCampaigns}: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    setState(() => _loadingAnalytics = true);
    try {
      final response = await ApiService.adminGetAdAnalytics();
      if (mounted && response['success'] == true) {
        setState(() {
          _analytics = response['analytics'] ?? {};
          _loadingAnalytics = false;
        });
      } else if (mounted) {
        setState(() => _loadingAnalytics = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAnalytics = false);
      }
      debugPrint('Error loading analytics: $e');
    }
  }

  Future<void> _changeCampaignStatus(
    int campaignId,
    String newStatus, {
    String? reason,
  }) async {
    final t = AppLocalizations.of(context);
    try {
      final response = await ApiService.adminChangeCampaignStatus(
        campaignId,
        newStatus,
        reason: reason,
      );

      if (response['success'] == true) {
        Fluttertoast.showToast(
          msg: t?.statusChangedTo(newStatus) ?? 'Status changed to $newStatus',
        );
        _loadCampaigns();
        if (_selectedTab == 1) _loadAnalytics();
      } else {
        Fluttertoast.showToast(
          msg:
              response['message'] ??
              t?.failedToChangeStatus ??
              'Failed to change status',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t?.error}: $e');
    }
  }

  Future<void> _deleteCampaign(int campaignId, String campaignName) async {
    final t = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t?.deleteCampaign ?? 'Delete Campaign',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          t?.deleteCampaignConfirmation(campaignName) ??
              'Are you sure you want to delete "$campaignName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(t?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.adminDeleteCampaign(campaignId);
      if (response['success'] == true) {
        Fluttertoast.showToast(
          msg: t?.campaignDeleted ?? 'Campaign deleted successfully',
        );
        _loadCampaigns();
        if (_selectedTab == 1) _loadAnalytics();
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? t?.failedToDelete ?? 'Failed to delete',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t?.error}: $e');
    }
  }

  void _showEditDialog(Map<String, dynamic> campaign) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
        backgroundColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B88FF), Color(0xFF5B58E2)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              t?.editCampaign ?? 'Edit Campaign',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  nameCtrl,
                  t?.campaignName ?? 'Campaign Name',
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  budgetCtrl,
                  t?.totalBudget ?? 'Total Budget',
                  isDark,
                  isNumber: true,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  dailyBudgetCtrl,
                  t?.dailyBudget ?? 'Daily Budget',
                  isDark,
                  isNumber: true,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  cpcCtrl,
                  t?.costPerClick ?? 'Cost Per Click',
                  isDark,
                  isNumber: true,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  cpmCtrl,
                  t?.costPerImpression ?? 'Cost Per Impression',
                  isDark,
                  isNumber: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t?.cancel ?? 'Cancel'),
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
                if (!mounted) return;
                Navigator.pop(ctx);
                Fluttertoast.showToast(
                  msg: t?.campaignUpdated ?? 'Campaign updated',
                );
                _loadCampaigns();
              } else {
                Fluttertoast.showToast(
                  msg:
                      response['message'] ?? t?.updateFailed ?? 'Update failed',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(t?.saveChanges ?? 'Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool isDark, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade300,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF5B58E2)),
        ),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(
        color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
      ),
    );
  }

  void _showStatusDialog(Map<String, dynamic> campaign) {
    final t = AppLocalizations.of(context);
    final currentStatus = campaign['status'];
    final possibleStatuses = ['active', 'paused', 'completed', 'cancelled'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t?.changeStatus ?? 'Change Status',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: possibleStatuses.map((status) {
            return ListTile(
              leading: Radio<String>(
                value: status,
                groupValue: currentStatus,
                onChanged: (value) {
                  Navigator.pop(ctx);
                  _changeCampaignStatus(campaign['id'], status);
                },
                activeColor: _getStatusColor(status),
              ),
              title: Text(_getStatusText(status, t)),
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
            child: Text(t?.close ?? 'Close'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF14A800);
      case 'paused':
        return const Color(0xFFF59E0B);
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'draft':
        return Colors.grey;
      case 'pending_approval':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, AppLocalizations? t) {
    switch (status) {
      case 'active':
        return t?.active ?? 'Active';
      case 'paused':
        return t?.paused ?? 'Paused';
      case 'completed':
        return t?.completed ?? 'Completed';
      case 'cancelled':
        return t?.cancelled ?? 'Cancelled';
      case 'draft':
        return t?.draft ?? 'Draft';
      case 'pending_approval':
        return t?.pendingApproval ?? 'Pending Approval';
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

  int get _activeFilterCount {
    int count = 0;
    if (_status != 'all') count++;
    if (_budgetRange != 'all') count++;
    if (_startDate != null || _endDate != null) count++;
    return count;
  }

  void _openFiltersDialog(AppLocalizations t, bool isDark) {
    _tempStatus = _status;
    _tempBudgetRange = _budgetRange;
    _tempStartDate = _startDate;
    _tempEndDate = _endDate;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => _CampaignFiltersDialog(
        isDark: isDark,
        initialStatus: _tempStatus,
        initialBudgetRange: _tempBudgetRange,
        initialStartDate: _tempStartDate,
        initialEndDate: _tempEndDate,
        onApply: (status, budget, start, end) {
          setState(() {
            _status = status;
            _budgetRange = budget;
            _startDate = start;
            _endDate = end;
            _currentPage = 1;
          });
          _loadCampaigns();
        },
        onReset: () {
          setState(() {
            _status = 'all';
            _budgetRange = 'all';
            _startDate = null;
            _endDate = null;
            _currentPage = 1;
          });
          _loadCampaigns();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.AppColors.darkBackground
          : const Color(0xFFF0F2F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(t, isDark, theme),
            _buildSearchAndFilterBar(t, isDark, theme),
            _buildStatsBar(t, isDark),
            _buildTabBar(t, isDark),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildCampaignsList(t, isDark),
                  _buildAnalyticsTab(t, isDark),
                  _buildStatsTab(t, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(AppLocalizations t, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.campaignsManagement,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                ),
              ),
              Text(
                '$_totalCampaigns ${t.campaigns}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const Spacer(),
          _IconBtn(
            icon: Icons.ios_share_rounded,
            tooltip: 'Export CSV',
            isDark: isDark,
            onTap: _exportCampaigns,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(
    AppLocalizations t,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.AppColors.darkCard
                    : const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppTheme.AppColors.grayDark
                      : Colors.grey.shade200,
                ),
              ),
              child: TextField(
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white
                      : AppTheme.AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: t.searchCampaigns,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) {
                  _searchQuery = v;
                  _currentPage = 1;
                  _loadCampaigns();
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _openFiltersDialog(t, isDark),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _activeFilterCount > 0
                    ? theme.colorScheme.primary
                    : (isDark
                          ? AppTheme.AppColors.darkCard
                          : const Color(0xFFF5F6FA)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _activeFilterCount > 0
                      ? theme.colorScheme.primary
                      : (isDark
                            ? AppTheme.AppColors.grayDark
                            : Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: _activeFilterCount > 0
                        ? Colors.white
                        : (isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade600),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _activeFilterCount > 0
                          ? Colors.white
                          : (isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700),
                    ),
                  ),
                  if (_activeFilterCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$_activeFilterCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(AppLocalizations t, bool isDark) {
    final activeCount = _stats['active_campaigns'] ?? 0;
    final pausedCount = _stats['paused_campaigns'] ?? 0;
    final completedCount = _stats['completed_campaigns'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatPill(
            label: 'Active',
            count: activeCount,
            color: const Color(0xFF14A800),
            isDark: isDark,
          ),
          _StatPill(
            label: 'Paused',
            count: pausedCount,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          _StatPill(
            label: 'Completed',
            count: completedCount,
            color: Colors.blue,
            isDark: isDark,
          ),
          if (_loading) ...[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: theme.colorScheme.primary,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: isDark ? Colors.grey.shade500 : Colors.grey,
        tabs: const [
          Tab(text: 'Campaigns', icon: Icon(Icons.campaign)),
          Tab(text: 'Analytics', icon: Icon(Icons.bar_chart)),
          Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
        ],
      ),
    );
  }

  Widget _buildCampaignsList(AppLocalizations t, bool isDark) {
    if (_loading && _campaigns.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (_campaigns.isEmpty) {
      return _buildEmpty(t, isDark);
    }

    return Column(
      children: [
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _campaigns.length,
              itemBuilder: (_, i) =>
                  _buildCampaignCard(_campaigns[i], t, isDark),
            ),
          ),
        ),
        if (_totalPages > 1) _buildPagination(t, isDark),
      ],
    );
  }

  Widget _buildCampaignCard(
    Map<String, dynamic> campaign,
    AppLocalizations t,
    bool isDark,
  ) {
    final theme = Theme.of(context);
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

    final advertiserName = advertiser['name']?.toString() ?? t.unknown;
    final truncatedAdvertiser = advertiserName.length > 12
        ? '${advertiserName.substring(0, 12)}...'
        : advertiserName;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor, statusColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.campaign,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  campaign['name'] ?? 'Unnamed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1A1B3E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _statusChip(
                                _getStatusText(status, t),
                                statusColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 14,
                            runSpacing: 4,
                            children: [
                              _MetaItem(
                                icon: Icons.person_outline_rounded,
                                text: truncatedAdvertiser,
                                isDark: isDark,
                              ),
                              _MetaItem(
                                icon: Icons.attach_money_rounded,
                                text: '\$${budget.toStringAsFixed(0)}',
                                isDark: isDark,
                                bold: true,
                              ),
                              _MetaItem(
                                icon: Icons.touch_app,
                                text: '$ctr% CTR',
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.AppColors.darkSurface
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.AppColors.grayDark
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 15,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: isDark
                          ? AppTheme.AppColors.darkSurface
                          : Colors.white,
                      enableFeedback: true,
                      tooltip: '',
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditDialog(campaign);
                        } else if (value == 'status') {
                          _showStatusDialog(campaign);
                        } else if (value == 'delete') {
                          _deleteCampaign(
                            campaign['id'],
                            campaign['name'] ?? t.campaign,
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 10),
                              Text('Edit', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(Icons.tune, size: 16),
                              SizedBox(width: 10),
                              Text(
                                'Change Status',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red.shade400,
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                          backgroundColor: isDark
                              ? AppTheme.AppColors.grayDark
                              : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations t, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.AppColors.darkCard
                  : const Color(0xFFF0F2F8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.campaign_outlined,
              size: 44,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.noCampaignsFound,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(
            Icons.chevron_left_rounded,
            _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadCampaigns();
                  }
                : null,
            isDark,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.AppColors.darkCard
                  : const Color(0xFFF0F2F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page $_currentPage of $_totalPages',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1B3E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _pageBtn(
            Icons.chevron_right_rounded,
            _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadCampaigns();
                  }
                : null,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback? onTap, bool isDark) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isEnabled
              ? theme.colorScheme.primary.withOpacity(0.1)
              : (isDark ? AppTheme.AppColors.darkCard : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEnabled
                ? theme.colorScheme.primary.withOpacity(0.2)
                : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled
              ? theme.colorScheme.primary
              : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
        ),
      ),
    );
  }

  Future<void> _exportCampaigns() async {
    final t = AppLocalizations.of(context);
    try {
      final csvData = <List<String>>[];
      csvData.add([
        'Campaign Name',
        'Advertiser',
        'Status',
        'Budget',
        'Spent',
        'Impressions',
        'Clicks',
        'CTR',
        'Created Date',
      ]);

      for (var campaign in _campaigns) {
        final advertiser = campaign['advertiser'] ?? {};
        final impressions = campaign['impressions'] ?? 0;
        final clicks = campaign['clicks'] ?? 0;
        final ctr = impressions > 0
            ? (clicks / impressions * 100).toStringAsFixed(2)
            : '0';

        csvData.add([
          campaign['name']?.toString() ?? '',
          advertiser['name']?.toString() ?? '',
          campaign['status']?.toString() ?? '',
          '\$${campaign['total_budget'] ?? 0}',
          '\$${campaign['spent_amount'] ?? 0}',
          impressions.toString(),
          clicks.toString(),
          '$ctr%',
          campaign['createdAt'] != null
              ? DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).format(DateTime.parse(campaign['createdAt']))
              : '',
        ]);
      }

      Fluttertoast.showToast(
        msg: 'Export started: ${_campaigns.length} campaigns',
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Export failed: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Widget _buildAnalyticsTab(AppLocalizations t, bool isDark) {
    final theme = Theme.of(context);

    if (_loadingAnalytics) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    final summary = _convertToMapString(_analytics['summary']) ?? {};
    final typeStats = _convertToListOfMaps(_analytics['type_stats']) ?? [];
    final topAdvertisers =
        _convertToListOfMaps(_analytics['top_advertisers']) ?? [];
    final dailyStats = _convertToListOfMaps(_analytics['daily_stats']) ?? [];

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
    }

    final dates = chartData.keys.toList()..sort();
    final impressionsData = dates
        .map((d) => chartData[d]!['impressions']!.toDouble())
        .toList();
    final clicksData = dates
        .map((d) => chartData[d]!['clicks']!.toDouble())
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.keyPerformanceIndicators,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _kpiCard(
                t.totalRevenue,
                '\$${_toDouble(summary['total_revenue']).toStringAsFixed(0)}',
                Icons.monetization_on,
                const Color(0xFF14A800),
                '+12%',
                isDark,
              ),
              _kpiCard(
                t.platformCommission,
                '\$${_toDouble(summary['platform_commission']).toStringAsFixed(0)}',
                Icons.percent,
                const Color(0xFFF59E0B),
                '+8%',
                isDark,
              ),
              _kpiCard(
                t.activeCampaignsCount,
                summary['active_campaigns']?.toString() ?? '0',
                Icons.play_circle,
                theme.colorScheme.primary,
                '${(summary['active_campaigns'] ?? 0) * 100 ~/ (summary['total_campaigns'] ?? 1)}%',
                isDark,
              ),
              _kpiCard(
                t.ctrAverage,
                '${_computeAvgCTR(typeStats).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.blue,
                '+2.3%',
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppTheme.AppColors.grayDark
                    : Colors.grey.shade100,
              ),
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
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.show_chart,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.dailyPerformanceTrends,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: _buildLineChart(
                    dates,
                    impressionsData,
                    clicksData,
                    isDark,
                    t,
                  ),
                ),
                const SizedBox(height: 16),
                _buildChartLegend(isDark, t),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppTheme.AppColors.grayDark
                    : Colors.grey.shade100,
              ),
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
                    Text(
                      t.performanceByAdType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildPieChart(typeStats, isDark, t),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildTypeStatsTable(typeStats, t, isDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppTheme.AppColors.grayDark
                    : Colors.grey.shade100,
              ),
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
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.leaderboard,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.topAdvertisers,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: _buildBarChart(topAdvertisers, isDark, t),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildTopAdvertisersTable(topAdvertisers, t, isDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildMetricsGrid(summary, t, isDark),
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

  Map<String, dynamic>? _convertToMapString(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.fromEntries(
        data.entries.map(
          (entry) => MapEntry(entry.key.toString(), entry.value),
        ),
      );
    }
    return null;
  }

  List<Map<String, dynamic>> _convertToListOfMaps(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) return item;
        if (item is Map) {
          return Map<String, dynamic>.fromEntries(
            item.entries.map(
              (entry) => MapEntry(entry.key.toString(), entry.value),
            ),
          );
        }
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  Widget _kpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      ? const Color(0xFF14A800).withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
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
                      color: trend.startsWith('+')
                          ? const Color(0xFF14A800)
                          : Colors.red,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: trend.startsWith('+')
                            ? const Color(0xFF14A800)
                            : Colors.red,
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
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
    bool isDark,
    dynamic t,
  ) {
    if (dates.isEmpty) {
      return Center(
        child: Text(
          t?.noDataAvailable ?? 'No data available',
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      );
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
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
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
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
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
          border: Border.all(
            color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
          ),
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
            dotData: const FlDotData(show: false),
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
            color: const Color(0xFF14A800),
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF14A800).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(bool isDark, AppLocalizations t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.blue, t.impressions ?? 'Impressions', isDark),
        const SizedBox(width: 16),
        _legendItem(const Color(0xFF14A800), t.clicks ?? 'Clicks', isDark),
      ],
    );
  }

  Widget _legendItem(Color color, String label, bool isDark) {
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
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(List typeStats, bool isDark, dynamic t) {
    final theme = Theme.of(context);
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
      return Center(
        child: Text(
          t?.noDataAvailable ?? 'No data available',
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      );
    }

    final total = data.fold(0.0, (sum, item) => sum + item['value']);
    final colors = [
      Colors.blue,
      const Color(0xFF14A800),
      const Color(0xFFF59E0B),
      theme.colorScheme.primary,
      Colors.purple,
    ];

    return PieChart(
      PieChartData(
        sections: List.generate(data.length, (i) {
          final percentage = ((data[i]['value'] / total) * 100);
          final title = '${percentage.toStringAsFixed(0)}%';
          return PieChartSectionData(
            color: colors[i % colors.length],
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

  Widget _buildBarChart(List topAdvertisers, bool isDark, dynamic t) {
    if (topAdvertisers.isEmpty) {
      return Center(
        child: Text(
          t?.noDataAvailable ?? 'No data available',
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      );
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
                  final name = top5[value.toInt()]['name']?.toString() ?? '?';
                  final shortName = name.length > 3
                      ? name.substring(0, 3)
                      : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      shortName,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
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
                color: const Color(0xFFF59E0B),
                width: 30,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTypeStatsTable(List typeStats, AppLocalizations t, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.resolveWith<Color>(
          (states) =>
              isDark ? AppTheme.AppColors.darkSurface : const Color(0xFFF0F2F8),
        ),
        columns: [
          const DataColumn(
            label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const DataColumn(
            label: Text(
              'Impressions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const DataColumn(
            label: Text(
              'Clicks',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const DataColumn(
            label: Text('CTR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const DataColumn(
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

  Widget _buildTopAdvertisersTable(
    List topAdvertisers,
    AppLocalizations t,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.resolveWith<Color>(
          (states) =>
              isDark ? AppTheme.AppColors.darkSurface : const Color(0xFFF0F2F8),
        ),
        columns: [
          const DataColumn(
            label: Text(
              'Advertiser',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const DataColumn(
            label: Text(
              'Campaigns',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const DataColumn(
            label: Text(
              'Total Spent',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const DataColumn(
            label: Text(
              'Commission',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: topAdvertisers.take(10).map((adv) {
          return DataRow(
            cells: [
              DataCell(Text(adv['name']?.toString() ?? 'Unknown')),
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

  Widget _buildMetricsGrid(
    Map<String, dynamic> summary,
    AppLocalizations t,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            t.additionalMetrics,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metricChip(
                t.avgCtr,
                '${_computeAvgCTR(_analytics['type_stats'] ?? []).toStringAsFixed(2)}%',
                Icons.trending_up,
                isDark,
              ),
              const SizedBox(width: 12),
              _metricChip(t.estRoi, '250%', Icons.trending_up, isDark),
              const SizedBox(width: 12),
              _metricChip(t.conversionRate, '3.2%', Icons.analytics, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, IconData icon, bool isDark) {
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

  Widget _buildStatsTab(AppLocalizations t, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppTheme.AppColors.grayDark
                    : Colors.grey.shade100,
              ),
            ),
            child: Column(
              children: [
                _statListItem(
                  t.totalCampaigns,
                  _stats['total_campaigns']?.toString() ?? '0',
                  Icons.campaign,
                  Colors.purple,
                  isDark,
                ),
                _statListItem(
                  t.activeCampaigns,
                  _stats['active_campaigns']?.toString() ?? '0',
                  Icons.play_circle,
                  const Color(0xFF14A800),
                  isDark,
                ),
                _statListItem(
                  t.pausedCampaigns,
                  _stats['paused_campaigns']?.toString() ?? '0',
                  Icons.pause,
                  const Color(0xFFF59E0B),
                  isDark,
                ),
                _statListItem(
                  t.completedCampaigns,
                  _stats['completed_campaigns']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.blue,
                  isDark,
                ),
                _statListItem(
                  t.draftCampaigns,
                  _stats['draft_campaigns']?.toString() ?? '0',
                  Icons.edit_note,
                  Colors.grey,
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppTheme.AppColors.grayDark
                    : Colors.grey.shade100,
              ),
            ),
            child: Column(
              children: [
                _statListItem(
                  t.totalImpressions,
                  _stats['total_impressions']?.toString() ?? '0',
                  Icons.visibility,
                  Colors.blue,
                  isDark,
                ),
                _statListItem(
                  t.totalClicks,
                  _stats['total_clicks']?.toString() ?? '0',
                  Icons.touch_app,
                  const Color(0xFF14A800),
                  isDark,
                ),
                _statListItem(
                  t.clickThroughRate,
                  '${_stats['click_through_rate'] ?? 0}%',
                  Icons.trending_up,
                  const Color(0xFFF59E0B),
                  isDark,
                ),
                _statListItem(
                  t.totalSpend,
                  '\$${(_stats['total_spent'] ?? 0).toDouble().toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.red,
                  isDark,
                ),
                _statListItem(
                  t.totalBudgetSum,
                  '\$${(_stats['total_budget'] ?? 0).toDouble().toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Colors.teal,
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if ((_stats['pending_payments'] ?? 0) > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
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
                        Text(
                          t.pendingPayments,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_stats['pending_payments']} ${t.campaignsWaitingForPayment}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.warning_amber, color: Color(0xFFF59E0B)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statListItem(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
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
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
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

class _CampaignFiltersDialog extends StatefulWidget {
  final bool isDark;
  final String initialStatus;
  final String initialBudgetRange;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final void Function(
    String status,
    String budget,
    DateTime? start,
    DateTime? end,
  )
  onApply;
  final VoidCallback onReset;

  const _CampaignFiltersDialog({
    required this.isDark,
    required this.initialStatus,
    required this.initialBudgetRange,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_CampaignFiltersDialog> createState() => _CampaignFiltersDialogState();
}

class _CampaignFiltersDialogState extends State<_CampaignFiltersDialog> {
  late String _status;
  late String _budgetRange;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _budgetRange = widget.initialBudgetRange;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.AppColors.darkCard
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _sectionLabel('Status', isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip('All', 'all', _status, theme, isDark),
                _filterChip('Active', 'active', _status, theme, isDark),
                _filterChip('Paused', 'paused', _status, theme, isDark),
                _filterChip('Completed', 'completed', _status, theme, isDark),
                _filterChip('Cancelled', 'cancelled', _status, theme, isDark),
                _filterChip('Draft', 'draft', _status, theme, isDark),
              ],
            ),
            const SizedBox(height: 18),
            _sectionLabel('Budget Range', isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip('All', 'all', _budgetRange, theme, isDark),
                _filterChip('\$0–100', '0-100', _budgetRange, theme, isDark),
                _filterChip(
                  '\$100–500',
                  '100-500',
                  _budgetRange,
                  theme,
                  isDark,
                ),
                _filterChip(
                  '\$500–1K',
                  '500-1000',
                  _budgetRange,
                  theme,
                  isDark,
                ),
                _filterChip(
                  '\$1K–5K',
                  '1000-5000',
                  _budgetRange,
                  theme,
                  isDark,
                ),
                _filterChip('\$5K+', '5000+', _budgetRange, theme, isDark),
              ],
            ),
            const SizedBox(height: 18),
            _sectionLabel('Date Range', isDark),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DatePickerBtn(
                    isDark: isDark,
                    label: 'Start Date',
                    date: _startDate,
                    onTap: () => _pickDate(true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '→',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                Expanded(
                  child: _DatePickerBtn(
                    isDark: isDark,
                    label: 'End Date',
                    date: _endDate,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onReset();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onApply(
                        _status,
                        _budgetRange,
                        _startDate,
                        _endDate,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.w700),
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

  Widget _sectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _filterChip(
    String label,
    String value,
    String selected,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == 'All') {
            _status = value;
          } else if (label.contains('\$')) {
            _budgetRange = value;
          } else {
            _status = value;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark
                    ? AppTheme.AppColors.darkCard
                    : const Color(0xFFF5F6FA)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? _startDate ?? DateTime.now()
          : _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.AppColors.darkCard : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final bool bold;

  const _MetaItem({
    required this.icon,
    required this.text,
    required this.isDark,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  const _StatPill({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerBtn extends StatelessWidget {
  final bool isDark;
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerBtn({
    required this.isDark,
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: hasDate
              ? theme.colorScheme.primary.withOpacity(0.06)
              : (isDark
                    ? AppTheme.AppColors.darkCard
                    : const Color(0xFFF5F6FA)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDate
                ? theme.colorScheme.primary.withOpacity(0.3)
                : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 14,
              color: hasDate ? theme.colorScheme.primary : Colors.grey.shade400,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasDate ? DateFormat('MMM dd, yyyy').format(date!) : label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                  color: hasDate
                      ? (isDark ? Colors.white : const Color(0xFF1A1B3E))
                      : Colors.grey.shade400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
