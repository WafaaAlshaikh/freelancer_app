import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../models/audit_log_model.dart';
import '../../theme/app_theme.dart' as AppTheme;

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  List<AuditLog> _logs = [];
  bool _loading = true;
  String _selectedSeverity = 'all';
  String _selectedAction = 'all';
  DateTimeRange? _dateRange;

  final List<String> _severityOptions = [
    'all',
    'low',
    'medium',
    'high',
    'critical',
  ];
  final List<String> _actionOptions = [
    'all',
    'create',
    'update',
    'delete',
    'suspend',
    'activate',
    'verify',
    'export',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getAuditLogs(
        severity: _selectedSeverity == 'all' ? null : _selectedSeverity,
        action: _selectedAction == 'all' ? null : _selectedAction,
        startDate: _dateRange?.start.toIso8601String(),
        endDate: _dateRange?.end.toIso8601String(),
        limit: 100,
      );
      if (mounted && response['success'] == true) {
        setState(() {
          _logs =
              (response['logs'] as List?)
                  ?.map((l) => AuditLog.fromJson(l))
                  .toList() ??
              [];
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      Fluttertoast.showToast(msg: 'Error loading audit logs: $e');
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.AppColors.darkBackground
          : const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'Audit Logs',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDateRange,
            tooltip: 'Filter by date',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(isDark, theme),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) =>
                        _buildLogCard(_logs[index], isDark),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Severity',
                  _selectedSeverity,
                  _severityOptions,
                  (v) {
                    setState(() => _selectedSeverity = v!);
                    _loadLogs();
                  },
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Action',
                  _selectedAction,
                  _actionOptions,
                  (v) {
                    setState(() => _selectedAction = v!);
                    _loadLogs();
                  },
                  isDark,
                ),
              ),
            ],
          ),
          if (_dateRange != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() => _dateRange = null);
                      _loadLogs();
                    },
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          dropdownColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black87,
          ),
          items: options
              .map(
                (opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt[0].toUpperCase() + opt.substring(1)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLogCard(AuditLog log, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: log.severityColor.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: log.severityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getActionIcon(log.action),
            color: log.severityColor,
            size: 22,
          ),
        ),
        title: Text(
          '${log.adminName} ${log.actionLabel} ${log.targetName ?? log.targetType}',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${log.targetId ?? 'N/A'} • ${log.ipAddress ?? 'Unknown IP'}',
              style: TextStyle(fontSize: 11),
            ),
            Text(
              _formatDate(log.createdAt),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: log.severityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            log.severity.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: log.severityColor,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'suspend':
        return Icons.block_outlined;
      case 'activate':
        return Icons.check_circle_outline;
      case 'verify':
        return Icons.verified_user_outlined;
      case 'export':
        return Icons.download_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu,
            size: 64,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No audit logs found',
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
