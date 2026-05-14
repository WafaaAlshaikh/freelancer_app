// screens/admin/projects_management_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart' as AppTheme;

class ProjectsManagementScreen extends StatefulWidget {
  const ProjectsManagementScreen({super.key});

  @override
  State<ProjectsManagementScreen> createState() =>
      _ProjectsManagementScreenState();
}

class _ProjectsManagementScreenState extends State<ProjectsManagementScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _projects = [];
  bool _loading = true;
  String _status = 'all';
  String _category = 'all';
  String _budgetRange = 'all';
  String _search = '';
  int _currentPage = 1;
  int _totalPages = 1;
  DateTime? _startDate;
  DateTime? _endDate;

  String _tempStatus = 'all';
  String _tempCategory = 'all';
  String _tempBudgetRange = 'all';
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadProjects();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    _fadeController.reset();
    try {
      final response = await ApiService.getAdminProjects(
        status: _status,
        category: _category,
        search: _search,
        page: _currentPage,
        startDate: _startDate?.toIso8601String(),
        endDate: _endDate?.toIso8601String(),
        budgetRange: _budgetRange,
      );
      if (!mounted) return;
      setState(() {
        _projects = List<Map<String, dynamic>>.from(
          response['projects'] as List? ?? [],
        );
        _totalPages = response['totalPages'] ?? 1;
        _loading = false;
      });
      _fadeController.forward();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(
        msg: t?.failedToLoadProjects ?? 'Failed to load projects',
      );
    }
  }

  Future<void> _deleteProject(int projectId) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t?.deleteProject ?? 'Delete Project',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          t?.deleteProjectConfirmation ??
              'This action cannot be undone. Are you sure?',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(t?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await ApiService.deleteAdminProject(projectId);
    if (res['success'] == true) {
      Fluttertoast.showToast(msg: t?.projectDeleted ?? 'Project deleted');
      _loadProjects();
    } else {
      Fluttertoast.showToast(
        msg: res['message']?.toString() ?? t?.deleteFailed ?? 'Delete failed',
      );
    }
  }

  int get _activeFilterCount {
    int count = 0;
    if (_status != 'all') count++;
    if (_category != 'all') count++;
    if (_budgetRange != 'all') count++;
    if (_startDate != null || _endDate != null) count++;
    return count;
  }

  void _openFiltersDialog(AppLocalizations t, bool isDark) {
    _tempStatus = _status;
    _tempCategory = _category;
    _tempBudgetRange = _budgetRange;
    _tempStartDate = _startDate;
    _tempEndDate = _endDate;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => _FiltersDialog(
        isDark: isDark,
        initialStatus: _tempStatus,
        initialCategory: _tempCategory,
        initialBudgetRange: _tempBudgetRange,
        initialStartDate: _tempStartDate,
        initialEndDate: _tempEndDate,
        onApply: (status, category, budget, start, end) {
          setState(() {
            _status = status;
            _category = category;
            _budgetRange = budget;
            _startDate = start;
            _endDate = end;
            _currentPage = 1;
          });
          _loadProjects();
        },
        onReset: () {
          setState(() {
            _status = 'all';
            _category = 'all';
            _budgetRange = 'all';
            _startDate = null;
            _endDate = null;
            _currentPage = 1;
          });
          _loadProjects();
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
            Expanded(
              child: _loading && _projects.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : _projects.isEmpty
                  ? _buildEmpty(t, isDark)
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _projects.length,
                        itemBuilder: (_, i) =>
                            _buildProjectCard(_projects[i], t, isDark),
                      ),
                    ),
            ),
            if (_totalPages > 1) _buildPagination(t, isDark),
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
            child: const Icon(
              Icons.work_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.projectsManagement,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1B3E),
                ),
              ),
              Text(
                '${_projects.length} ${t.projects}',
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
            onTap: _exportProjects,
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
                  hintText: t.searchProjects,
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
                  _search = v;
                  _currentPage = 1;
                  _loadProjects();
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
    final openCount = _projects.where((p) => p['status'] == 'open').length;
    final inProgressCount = _projects
        .where((p) => p['status'] == 'in_progress')
        .length;
    final completedCount = _projects
        .where((p) => p['status'] == 'completed')
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _StatPill(
            label: 'Open',
            count: openCount,
            color: const Color(0xFF14A800),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _StatPill(
            label: 'In Progress',
            count: inProgressCount,
            color: const Color(0xFF0EA5E9),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _StatPill(
            label: 'Done',
            count: completedCount,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          if (_loading) ...[
            const SizedBox(width: 8),
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

  Widget _buildProjectCard(
    Map<String, dynamic> p,
    AppLocalizations t,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final client = Map<String, dynamic>.from(p['client'] ?? {});
    final status = p['status']?.toString() ?? 'open';
    final colors = _getStatusColors(status);
    final label = _getStatusLabel(status, t);
    final budget = p['budget'] ?? 0;
    final createdAt = p['createdAt'] != null
        ? DateFormat(
            'MMM dd, yyyy',
          ).format(DateTime.tryParse(p['createdAt']) ?? DateTime.now())
        : null;

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
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
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
                              p['title']?.toString() ?? t.untitledProject,
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
                          _statusChip(label, colors),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _MetaItem(
                            icon: Icons.person_outline_rounded,
                            text: client['name']?.toString() ?? t.notAvailable,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 14),
                          _MetaItem(
                            icon: Icons.attach_money_rounded,
                            text: '\$${budget.toString()}',
                            isDark: isDark,
                            bold: true,
                          ),
                          if (createdAt != null) ...[
                            const SizedBox(width: 14),
                            _MetaItem(
                              icon: Icons.calendar_today_outlined,
                              text: createdAt,
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Container(
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
                  color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
                  onSelected: (value) {
                    if (value == 'delete') {
                      final id = p['id'] as int?;
                      if (id != null) _deleteProject(id);
                    }
                  },
                  itemBuilder: (_) => [
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
                            t.delete,
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
              Icons.work_outline_rounded,
              size: 44,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.noProjectsFound,
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
                    _loadProjects();
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
              '${t.page} $_currentPage ${t.ofWord} $_totalPages',
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
                    _loadProjects();
                  }
                : null,
            isDark,
          ),
        ],
      ),
    );
  }

  List<Color> _getStatusColors(String status) {
    switch (status) {
      case 'open':
        return [const Color(0xFF14A800), const Color(0xFF0A6E00)];
      case 'in_progress':
        return [const Color(0xFF0EA5E9), const Color(0xFF0369A1)];
      case 'completed':
        return [const Color(0xFF10B981), const Color(0xFF047857)];
      case 'cancelled':
        return [const Color(0xFFEF4444), const Color(0xFFB91C1C)];
      default:
        return [Colors.grey, Colors.grey.shade700];
    }
  }

  String _getStatusLabel(String status, AppLocalizations t) {
    switch (status) {
      case 'open':
        return t.open;
      case 'in_progress':
        return t.inProgress;
      case 'completed':
        return t.completed;
      case 'cancelled':
        return t.cancelled;
      default:
        return status;
    }
  }

  Widget _statusChip(String label, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: colors.first.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.first.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colors.first,
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

  Future<void> _exportProjects() async {
    final t = AppLocalizations.of(context);
    try {
      final csvData = <List<String>>[];
      csvData.add([
        'Project ID',
        'Title',
        'Client',
        'Category',
        'Status',
        'Budget',
        'Created Date',
        'Updated Date',
      ]);

      for (var project in _projects) {
        final client = project['client'] ?? {};
        csvData.add([
          project['id']?.toString() ?? '',
          project['title']?.toString() ?? '',
          client['name']?.toString() ?? '',
          project['category']?.toString() ?? '',
          project['status']?.toString() ?? '',
          '\$${project['budget'] ?? 0}',
          project['createdAt'] != null
              ? DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).format(DateTime.parse(project['createdAt']))
              : '',
          project['updatedAt'] != null
              ? DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).format(DateTime.parse(project['updatedAt']))
              : '',
        ]);
      }

      Fluttertoast.showToast(
        msg:
            '${t?.exportStarted ?? 'Export started'}: ${_projects.length} projects',
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: '${t?.exportFailed ?? 'Export failed'}: $e',
        backgroundColor: Colors.red,
      );
    }
  }
}

class _FiltersDialog extends StatefulWidget {
  final bool isDark;
  final String initialStatus;
  final String initialCategory;
  final String initialBudgetRange;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final void Function(
    String status,
    String category,
    String budget,
    DateTime? start,
    DateTime? end,
  )
  onApply;
  final VoidCallback onReset;

  const _FiltersDialog({
    required this.isDark,
    required this.initialStatus,
    required this.initialCategory,
    required this.initialBudgetRange,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<_FiltersDialog> {
  late String _status;
  late String _category;
  late String _budgetRange;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _category = widget.initialCategory;
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
            _buildChipGroup(
              options: const [
                ('all', 'All'),
                ('open', 'Open'),
                ('in_progress', 'In Progress'),
                ('completed', 'Completed'),
                ('cancelled', 'Cancelled'),
              ],
              selected: _status,
              onSelect: (v) => setState(() => _status = v),
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 18),

            _sectionLabel('Category', isDark),
            const SizedBox(height: 8),
            _buildChipGroup(
              options: const [
                ('all', 'All'),
                ('web_development', 'Web Dev'),
                ('mobile_development', 'Mobile'),
                ('design', 'Design'),
                ('writing', 'Writing'),
                ('marketing', 'Marketing'),
                ('other', 'Other'),
              ],
              selected: _category,
              onSelect: (v) => setState(() => _category = v),
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 18),

            _sectionLabel('Budget Range', isDark),
            const SizedBox(height: 8),
            _buildChipGroup(
              options: const [
                ('all', 'All'),
                ('0-100', '\$0–100'),
                ('100-500', '\$100–500'),
                ('500-1000', '\$500–1K'),
                ('1000-5000', '\$1K–5K'),
                ('5000+', '\$5K+'),
              ],
              selected: _budgetRange,
              onSelect: (v) => setState(() => _budgetRange = v),
              theme: theme,
              isDark: isDark,
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
                        _category,
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

  Widget _buildChipGroup({
    required List<(String, String)> options,
    required String selected,
    required void Function(String) onSelect,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt.$1;
        return GestureDetector(
          onTap: () => onSelect(opt.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
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
                    : (isDark
                          ? AppTheme.AppColors.grayDark
                          : Colors.grey.shade200),
              ),
            ),
            child: Text(
              opt.$2,
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
      }).toList(),
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
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.AppColors.darkCard : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? AppTheme.AppColors.grayDark
                  : Colors.grey.shade200,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
          ),
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
