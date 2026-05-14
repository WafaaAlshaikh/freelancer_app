// lib/screens/admin/users_management_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelancer_platform/screens/client/freelancer_profile_preview_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart' as AppTheme;

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen>
    with SingleTickerProviderStateMixin {
  List<User> users = [];
  bool loading = true;
  String selectedRole = 'all';
  String selectedStatus = 'all';
  String searchQuery = '';
  int currentPage = 1;
  int totalPages = 1;
  final int pageSize = 20;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  int totalUsers = 0;
  int activeUsers = 0;
  int freelancersCount = 0;
  int suspendedCount = 0;

  DateTime? _fromDate;
  DateTime? _toDate;

  late TabController _tabController;
  final List<String> _roles = ['all', 'freelancer', 'client', 'admin'];

  final GlobalKey<FormState> _createUserFormKey = GlobalKey<FormState>();
  final TextEditingController _newUserNameController = TextEditingController();
  final TextEditingController _newUserEmailController = TextEditingController();
  final TextEditingController _newUserPhoneController = TextEditingController();
  final TextEditingController _newUserNationalIdController =
      TextEditingController();
  final TextEditingController _newUserHourlyRateController =
      TextEditingController();
  final TextEditingController _newUserSkillsController =
      TextEditingController();
  final TextEditingController _newUserClientTypeController =
      TextEditingController();
  final TextEditingController _newUserCompanyNameController =
      TextEditingController();
  final TextEditingController _newUserCommercialRegisterController =
      TextEditingController();
  final TextEditingController _newUserTaxNumberController =
      TextEditingController();
  String _newUserRole = 'client';
  bool _creatingUser = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roles.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          selectedRole = _roles[_tabController.index];
          currentPage = 1;
        });
        _loadUsers();
      }
    });
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newUserNameController.dispose();
    _newUserEmailController.dispose();
    _newUserPhoneController.dispose();
    _newUserNationalIdController.dispose();
    _newUserHourlyRateController.dispose();
    _newUserSkillsController.dispose();
    _newUserClientTypeController.dispose();
    _newUserCompanyNameController.dispose();
    _newUserCommercialRegisterController.dispose();
    _newUserTaxNumberController.dispose();
    super.dispose();
  }

  String _formatDateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Today';
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ApiService.getUserStats();
      if (!mounted) return;
      setState(() {
        totalUsers = stats['totalUsers'] ?? 0;
        activeUsers = stats['activeUsers'] ?? 0;
        freelancersCount = stats['freelancersCount'] ?? 0;
        suspendedCount = stats['suspendedCount'] ?? 0;
      });
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _loadUsers() async {
    setState(() => loading = true);
    try {
      final response = await ApiService.getAdminUsers(
        role: selectedRole,
        status: selectedStatus,
        search: searchQuery,
        page: currentPage,
        limit: pageSize,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      print('========== API RESPONSE ==========');
      print(response);
      print('Keys: ${response.keys}');
      print('totalUsers: ${response['totalUsers']}');
      print('activeUsers: ${response['activeUsers']}');
      print('freelancersCount: ${response['freelancersCount']}');
      print('suspendedCount: ${response['suspendedCount']}');
      print('==================================');

      if (!mounted) return;
      setState(() {
        users = (response['users'] as List)
            .map((json) => User.fromJson(json))
            .toList();
        totalPages = response['totalPages'] ?? 1;
        totalUsers =
            response['totalUsers'] ?? response['total'] ?? users.length;
        activeUsers =
            response['activeUsers'] ??
            users.where((u) => u.accountStatus == 'active').length;
        freelancersCount =
            response['freelancersCount'] ??
            users.where((u) => u.role == 'freelancer').length;
        suspendedCount =
            response['suspendedCount'] ??
            users.where((u) => u.accountStatus == 'suspended').length;

        print(
          '📊 Stats after update: total=$totalUsers, active=$activeUsers, freelancers=$freelancersCount, suspended=$suspendedCount',
        );

        loading = false;
      });
    } catch (e) {
      print('❌ Load users error: $e');
      if (!mounted) return;
      setState(() => loading = false);
      Fluttertoast.showToast(
        msg: '${AppLocalizations.of(context)?.errorLoadingUsers}: $e',
      );
    }
  }

  Widget _datePickerThemeWrapper(BuildContext context, Widget? child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: isDark
            ? ColorScheme.dark(
                primary: AppTheme.AppColors.primary,
                onPrimary: Colors.white,
                surface: AppTheme.AppColors.darkSurface,
                onSurface: Colors.white,
              )
            : ColorScheme.light(
                primary: AppTheme.AppColors.primary,
                onPrimary: Colors.white,
                onSurface: const Color(0xFF1A1B3E),
              ),
        dialogBackgroundColor: isDark
            ? AppTheme.AppColors.darkCard
            : Colors.white,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.AppColors.primary,
          ),
        ),
      ),
      child: child!,
    );
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: _toDate ?? DateTime.now(),
      builder: _datePickerThemeWrapper,
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = null;
        currentPage = 1;
      });
      _loadUsers();
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? (_fromDate ?? DateTime.now()),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: _datePickerThemeWrapper,
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
        currentPage = 1;
      });
      _loadUsers();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      currentPage = 1;
    });
    _loadUsers();
  }

  Future<void> _updateUserStatus(int userId, String status) async {
    try {
      await ApiService.updateUserStatus(userId, status);
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(
        msg: status == 'active'
            ? (t?.userActivated ?? 'User activated')
            : (t?.userSuspended ?? 'User suspended'),
      );
      _loadUsers();
    } catch (e) {
      Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.error}: $e');
    }
  }

  Future<void> _verifyUser(int userId, bool verify) async {
    try {
      await ApiService.verifyUser(userId, verify);
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(
        msg: verify
            ? (t?.userVerified ?? 'User verified')
            : (t?.verificationRemoved ?? 'Verification removed'),
      );
      _loadUsers();
    } catch (e) {
      Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.error}: $e');
    }
  }

  Future<void> _resendAccountEmail(int userId) async {
    try {
      final response = await ApiService.resendAccountEmail(userId);
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(
        msg: response['success'] == true
            ? (t?.accountEmailResent ?? 'Email resent')
            : (response['message'] ??
                  t?.failedToResendEmail ??
                  'Failed to resend email'),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.error}: $e');
    }
  }

  void _setStatus(String s) {
    setState(() {
      selectedStatus = s;
      currentPage = 1;
    });
    _loadUsers();
  }

  Future<void> _showCreateUserDialog() async {
    _newUserRole = 'client';
    _newUserNameController.clear();
    _newUserEmailController.clear();
    _newUserPhoneController.clear();
    _newUserNationalIdController.clear();
    _newUserHourlyRateController.clear();
    _newUserSkillsController.clear();
    _newUserClientTypeController.clear();
    _newUserCompanyNameController.clear();
    _newUserCommercialRegisterController.clear();
    _newUserTaxNumberController.clear();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            AppLocalizations.of(context)?.createNewUser ?? 'Create new user',
          ),
          content: Form(
            key: _createUserFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: _newUserNameController,
                    label: AppLocalizations.of(context)?.name ?? 'Name',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? (AppLocalizations.of(context)?.nameRequired ??
                              'Required')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _newUserEmailController,
                    label: AppLocalizations.of(context)?.email ?? 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return AppLocalizations.of(context)?.emailRequired ??
                            'Required';
                      if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(v))
                        return AppLocalizations.of(context)?.enterValidEmail ??
                            'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _newUserPhoneController,
                    label:
                        AppLocalizations.of(context)?.phoneOptional ??
                        'Phone (optional)',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _newUserNationalIdController,
                    label:
                        AppLocalizations.of(context)?.nationalIdOptional ??
                        'National ID (optional)',
                  ),
                  const SizedBox(height: 14),
                  _buildRoleSelection(setDialogState),
                  const SizedBox(height: 14),
                  if (_newUserRole == 'freelancer') ...[
                    _buildTextField(
                      controller: _newUserHourlyRateController,
                      label:
                          AppLocalizations.of(context)?.hourlyRateOptional ??
                          'Hourly Rate (optional)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _newUserSkillsController,
                      label:
                          AppLocalizations.of(context)?.skillsOptional ??
                          'Skills (comma separated)',
                    ),
                  ],
                  if (_newUserRole == 'client') ...[
                    _buildTextField(
                      controller: _newUserClientTypeController,
                      label:
                          AppLocalizations.of(context)?.clientTypeOptional ??
                          'Client Type (optional)',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _newUserCompanyNameController,
                      label:
                          AppLocalizations.of(context)?.companyNameOptional ??
                          'Company Name (optional)',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _newUserCommercialRegisterController,
                      label:
                          AppLocalizations.of(
                            context,
                          )?.commercialRegisterOptional ??
                          'Commercial Register (optional)',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _newUserTaxNumberController,
                      label:
                          AppLocalizations.of(context)?.taxNumberOptional ??
                          'Tax Number (optional)',
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: _creatingUser ? null : _createUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.AppColors.primary,
              ),
              child: _creatingUser
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(AppLocalizations.of(context)?.create ?? 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createUser() async {
    if (!_createUserFormKey.currentState!.validate()) return;
    setState(() => _creatingUser = true);
    try {
      final response = await ApiService.createAdminUser(
        name: _newUserNameController.text.trim(),
        email: _newUserEmailController.text.trim(),
        role: _newUserRole,
        phone: _newUserPhoneController.text.trim().isNotEmpty
            ? _newUserPhoneController.text.trim()
            : null,
        nationalId: _newUserNationalIdController.text.trim().isNotEmpty
            ? _newUserNationalIdController.text.trim()
            : null,
        hourlyRate: _newUserHourlyRateController.text.trim().isNotEmpty
            ? double.tryParse(_newUserHourlyRateController.text.trim())
            : null,
        skills: _newUserSkillsController.text.trim().isNotEmpty
            ? _newUserSkillsController.text
                  .trim()
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList()
            : null,
        clientType: _newUserClientTypeController.text.trim().isNotEmpty
            ? _newUserClientTypeController.text.trim()
            : null,
        companyName: _newUserCompanyNameController.text.trim().isNotEmpty
            ? _newUserCompanyNameController.text.trim()
            : null,
        commercialRegisterNumber:
            _newUserCommercialRegisterController.text.trim().isNotEmpty
            ? _newUserCommercialRegisterController.text.trim()
            : null,
        taxNumber: _newUserTaxNumberController.text.trim().isNotEmpty
            ? _newUserTaxNumberController.text.trim()
            : null,
      );
      if (!mounted) return;
      if (response['success'] == true) {
        Fluttertoast.showToast(
          msg:
              AppLocalizations.of(context)?.userCreated ??
              'User created. Password sent by email.',
        );
        Navigator.of(context).pop();
        _loadUsers();
      } else {
        Fluttertoast.showToast(
          msg:
              response['message'] ??
              AppLocalizations.of(context)?.failedToCreateUser ??
              'Failed to create user',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.error}: $e');
    } finally {
      if (mounted) setState(() => _creatingUser = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? AppTheme.AppColors.grayDark
                : AppTheme.AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppTheme.AppColors.accent,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection(StateSetter setState) {
    final t = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _roleChip(
          'client',
          t?.client ?? 'Client',
          _newUserRole == 'client',
          setState,
        ),
        _roleChip(
          'freelancer',
          t?.freelancer ?? 'Freelancer',
          _newUserRole == 'freelancer',
          setState,
        ),
        _roleChip('admin', 'Admin', _newUserRole == 'admin', setState),
      ],
    );
  }

  Widget _roleChip(
    String value,
    String label,
    bool selected,
    StateSetter setState,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _newUserRole = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : (isDark ? AppTheme.AppColors.darkCard : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : Colors.black87),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.AppColors.darkBackground
          : const Color(0xFFF5F6FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(t, isDark),
          _buildStatCards(isDark),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTabsAndDateRow(t, isDark),
                  _buildSearchAndStatusRow(t, isDark),
                  Expanded(
                    child: loading && users.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : users.isEmpty
                        ? _buildEmptyState(t, isDark)
                        : _buildDataTable(t, isDark),
                  ),
                  if (totalPages > 1) _buildPagination(t, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(AppLocalizations t, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: ElevatedButton.icon(
              onPressed: _showCreateUserDialog,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: Text(t.addUser),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          _statCard(
            isDark: isDark,
            icon: Icons.people_rounded,
            iconBg: const Color(0xFFEEEDFE),
            iconColor: const Color(0xFF534AB7),
            accentColor: const Color(0xFF7F77DD),
            label: 'Total Users',
            value: totalUsers.toString(),
          ),
          const SizedBox(width: 12),
          _statCard(
            isDark: isDark,
            icon: Icons.check_circle_rounded,
            iconBg: const Color(0xFFE1F5EE),
            iconColor: const Color(0xFF0F6E56),
            accentColor: const Color(0xFF1D9E75),
            label: 'Active',
            value: activeUsers.toString(),
          ),
          const SizedBox(width: 12),
          _statCard(
            isDark: isDark,
            icon: Icons.work_rounded,
            iconBg: const Color(0xFFFAECE7),
            iconColor: const Color(0xFF993C1D),
            accentColor: const Color(0xFFD85A30),
            label: 'Freelancers',
            value: freelancersCount.toString(),
          ),
          const SizedBox(width: 12),
          _statCard(
            isDark: isDark,
            icon: Icons.block_rounded,
            iconBg: const Color(0xFFFCEBEB),
            iconColor: const Color(0xFFA32D2D),
            accentColor: const Color(0xFFE24B4A),
            label: 'Suspended',
            value: suspendedCount.toString(),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required bool isDark,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color accentColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade100,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? iconColor.withOpacity(0.15) : iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isDark ? iconColor.withOpacity(0.9) : iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1B3E),
                        ),
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
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
    );
  }

  Widget _buildTabsAndDateRow(AppLocalizations t, bool isDark) {
    final tabLabels = [t.allUsers, t.freelancer, t.client, 'Admin'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppTheme.AppColors.primary,
              unselectedLabelColor: isDark
                  ? Colors.grey.shade400
                  : Colors.grey.shade500,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: AppTheme.AppColors.primary,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: tabLabels.map((l) => Tab(text: l)).toList(),
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dateBtn(
                date: _fromDate,
                hint: t.from ?? 'From',
                onTap: _pickFromDate,
                isDark: isDark,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  t.to ?? 'To',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ),
              _dateBtn(
                date: _toDate,
                hint: t.to ?? 'To',
                onTap: _pickToDate,
                isDark: isDark,
              ),
              if (_fromDate != null || _toDate != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _clearDateFilter,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateBtn({
    required DateTime? date,
    required String hint,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final bool isSet = date != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: isSet
              ? AppTheme.AppColors.primary.withOpacity(0.08)
              : (isDark
                    ? AppTheme.AppColors.darkSurface
                    : const Color(0xFFF5F6FA)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSet
                ? AppTheme.AppColors.primary.withOpacity(0.35)
                : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 12,
              color: isSet
                  ? AppTheme.AppColors.primary
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
            ),
            const SizedBox(width: 5),
            Text(
              isSet ? _formatDateLabel(date!) : hint,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSet
                    ? AppTheme.AppColors.primary
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndStatusRow(AppLocalizations t, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.AppColors.darkSurface
                    : const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(10),
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
                  hintText: t.searchByNameOrEmail,
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) {
                  searchQuery = v;
                  currentPage = 1;
                  _loadUsers();
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          _statusChip(
            t.allUsers,
            selectedStatus == 'all',
            () => _setStatus('all'),
            isDark,
          ),
          const SizedBox(width: 6),
          _statusChip(
            t.active,
            selectedStatus == 'active',
            () => _setStatus('active'),
            isDark,
          ),
          const SizedBox(width: 6),
          _statusChip(
            t.suspended,
            selectedStatus == 'suspended',
            () => _setStatus('suspended'),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
    String label,
    bool selected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.AppColors.primary
              : (isDark ? AppTheme.AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.AppColors.primary
                : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTableAlternative(AppLocalizations t, bool isDark) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: index.isEven
                ? (isDark ? AppTheme.AppColors.darkSurface : Colors.white)
                : (isDark
                      ? AppTheme.AppColors.darkCard.withOpacity(0.4)
                      : const Color(0xFFFAFAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppTheme.AppColors.grayDark
                  : Colors.grey.shade100,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.AppColors.primary,
                    backgroundImage:
                        (user.avatar != null && user.avatar!.isNotEmpty)
                        ? NetworkImage(user.avatar!)
                        : null,
                    child: (user.avatar == null || user.avatar!.isEmpty)
                        ? Text(
                            user.name?[0].toUpperCase() ?? '?',
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name ?? 'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1B3E),
                          ),
                        ),
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: user.accountStatus == 'suspended'
                          ? Colors.red.withOpacity(0.1)
                          : const Color(0xFF14A800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      user.accountStatus == 'suspended'
                          ? t.suspended
                          : t.active,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: user.accountStatus == 'suspended'
                            ? Colors.red.shade600
                            : const Color(0xFF14A800),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Role: ${user.displayRole}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Phone: ${user.phone ?? '—'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Joined: ${user.createdAt != null ? _formatDate(user.createdAt!) : '—'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _actionBtn(
                        icon: user.accountStatus == 'suspended'
                            ? Icons.check_circle_outline_rounded
                            : Icons.block_rounded,
                        color: user.accountStatus == 'suspended'
                            ? const Color(0xFF14A800)
                            : Colors.red.shade400,
                        bg: user.accountStatus == 'suspended'
                            ? const Color(0xFF14A800).withOpacity(0.1)
                            : Colors.red.withOpacity(0.08),
                        onTap: () => _updateUserStatus(
                          user.id!,
                          user.accountStatus == 'suspended'
                              ? 'active'
                              : 'suspended',
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'view':
                              if (user.role == 'freelancer') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FreelancerProfilePreviewScreen(
                                          freelancerId: user.id!,
                                          projectId: null,
                                        ),
                                  ),
                                );
                              } else {
                                _showUserInfoDialog(user);
                              }
                              break;
                            case 'verify':
                              _verifyUser(user.id!, !user.isVerifiedUser);
                              break;
                            case 'resend':
                              _resendAccountEmail(user.id!);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Text('View Profile'),
                          ),
                          const PopupMenuItem(
                            value: 'verify',
                            child: Text('Verify User'),
                          ),
                          const PopupMenuItem(
                            value: 'resend',
                            child: Text('Resend Email'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUserInfoDialog(User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name ?? 'User Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Email', user.email ?? 'N/A'),
            _infoRow('Role', user.displayRole),
            _infoRow('Status', user.accountStatus ?? 'N/A'),
            _infoRow('Verified', user.isVerifiedUser ? 'Yes' : 'No'),
            _infoRow('Phone', user.phone ?? 'N/A'),
            _infoRow(
              'Joined',
              user.createdAt != null
                  ? '${user.createdAt!.year}-${user.createdAt!.month}-${user.createdAt!.day}'
                  : 'N/A',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildDataTable(AppLocalizations t, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          child: Column(
            children: [
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _verticalScrollController,
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    scrollDirection: Axis.vertical,
                    child: Scrollbar(
                      thumbVisibility: true,
                      controller: _horizontalScrollController,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 48,
                          dataRowMinHeight: 60,
                          dataRowMaxHeight: 80,
                          horizontalMargin: 16,
                          columnSpacing: 24,
                          dividerThickness: 0.5,
                          headingRowColor: WidgetStateProperty.all(
                            isDark
                                ? AppTheme.AppColors.darkSurface
                                : const Color(0xFFF8F9FC),
                          ),
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: isDark
                                  ? AppTheme.AppColors.grayDark.withOpacity(0.5)
                                  : Colors.grey.shade200,
                              width: 0.5,
                            ),
                          ),
                          columns: [
                            const DataColumn(
                              label: Text(
                                '#',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                t.name ?? 'Name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                t.role ?? 'Role',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                t.status ?? 'Status',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                t.joinedDate ?? 'Joined',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                t.phone ?? 'Phone',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                t.actions ?? 'Actions',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          rows: users.asMap().entries.map((entry) {
                            final user = entry.value;
                            final index = entry.key;
                            final isSuspended =
                                user.accountStatus == 'suspended';
                            final isVerified = user.isVerifiedUser;
                            final roleColor = user.roleColor;
                            final initials = (user.name?.isNotEmpty == true)
                                ? user.name![0].toUpperCase()
                                : '?';
                            final avatarUrl = user.avatar;

                            return DataRow(
                              color: WidgetStateProperty.resolveWith<Color?>((
                                states,
                              ) {
                                if (states.contains(WidgetState.hovered)) {
                                  return isDark
                                      ? Colors.white.withOpacity(0.03)
                                      : Colors.grey.shade50;
                                }
                                return index.isEven
                                    ? (isDark
                                          ? AppTheme.AppColors.darkCard
                                          : Colors.white)
                                    : (isDark
                                          ? AppTheme.AppColors.darkSurface
                                                .withOpacity(0.4)
                                          : const Color(0xFFFAFAFC));
                              }),
                              cells: [
                                DataCell(
                                  Text(
                                    '${(currentPage - 1) * pageSize + index + 1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 220,
                                    child: Row(
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor:
                                                  AppTheme.AppColors.primary,
                                              backgroundImage:
                                                  (avatarUrl != null &&
                                                      avatarUrl.isNotEmpty)
                                                  ? NetworkImage(avatarUrl)
                                                  : null,
                                              child:
                                                  (avatarUrl == null ||
                                                      avatarUrl.isEmpty)
                                                  ? Text(
                                                      initials,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            if (isVerified)
                                              Positioned(
                                                right: -2,
                                                bottom: -2,
                                                child: Container(
                                                  width: 14,
                                                  height: 14,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color(
                                                          0xFF14A800,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.check,
                                                    size: 9,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                user.name ?? 'Unknown',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSuspended
                                                      ? Colors.grey.shade400
                                                      : (isDark
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF1A1B3E,
                                                              )),
                                                  decoration: isSuspended
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                user.email ?? '',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? Colors.grey.shade500
                                                      : Colors.grey.shade600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: roleColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      user.displayRole,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: roleColor,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSuspended
                                          ? Colors.red.withOpacity(0.1)
                                          : const Color(
                                              0xFF14A800,
                                            ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSuspended
                                                ? Colors.red.shade500
                                                : const Color(0xFF14A800),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isSuspended ? t.suspended : t.active,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isSuspended
                                                ? Colors.red.shade600
                                                : const Color(0xFF14A800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    user.createdAt != null
                                        ? _formatDate(user.createdAt!)
                                        : '—',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    user.phone ?? '—',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _actionBtn(
                                        icon: isSuspended
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.block_rounded,
                                        color: isSuspended
                                            ? const Color(0xFF14A800)
                                            : Colors.red.shade400,
                                        bg: isSuspended
                                            ? const Color(
                                                0xFF14A800,
                                              ).withOpacity(0.1)
                                            : Colors.red.withOpacity(0.08),
                                        onTap: () => _updateUserStatus(
                                          user.id!,
                                          isSuspended ? 'active' : 'suspended',
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      PopupMenuButton<String>(
                                        tooltip: '',
                                        padding: EdgeInsets.zero,
                                        icon: _actionBtn(
                                          icon: Icons.more_vert_rounded,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                          bg: isDark
                                              ? AppTheme.AppColors.darkSurface
                                              : Colors.grey.shade50,
                                          onTap: null,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        color: isDark
                                            ? AppTheme.AppColors.darkSurface
                                            : Colors.white,
                                        elevation: 4,
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'view':
                                              if (user.role == 'freelancer') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        FreelancerProfilePreviewScreen(
                                                          freelancerId:
                                                              user.id!,
                                                          projectId: null,
                                                        ),
                                                  ),
                                                );
                                              } else {
                                                _showUserInfoDialog(user);
                                              }
                                              break;
                                            case 'verify':
                                              _verifyUser(
                                                user.id!,
                                                !isVerified,
                                              );
                                              break;
                                            case 'resend':
                                              _resendAccountEmail(user.id!);
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          _popupItem(
                                            Icons.visibility_outlined,
                                            t.viewProfile,
                                            isDark,
                                            value: 'view',
                                          ),
                                          _popupItem(
                                            Icons.email_outlined,
                                            t.resendAccountEmail,
                                            isDark,
                                            color: Colors.blue,
                                            value: 'resend',
                                          ),
                                          _popupItem(
                                            isVerified
                                                ? Icons.verified
                                                : Icons.verified_user_outlined,
                                            isVerified
                                                ? t.removeVerification
                                                : t.verifyUser,
                                            isDark,
                                            color: isVerified
                                                ? Colors.orange
                                                : const Color(0xFF14A800),
                                            value: 'verify',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DataColumn _col(String label, bool isDark, {bool numeric = false}) {
    return DataColumn(
      numeric: numeric,
      label: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  DataRow _buildDataRow(User user, int index, AppLocalizations t, bool isDark) {
    final isSuspended = user.accountStatus == 'suspended';
    final isVerified = user.isVerifiedUser;
    final roleColor = user.roleColor;
    final initials = (user.name?.isNotEmpty == true)
        ? user.name![0].toUpperCase()
        : '?';
    final avatarUrl = user.avatar;

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50;
        }
        return index.isEven
            ? (isDark ? AppTheme.AppColors.darkCard : Colors.white)
            : (isDark
                  ? AppTheme.AppColors.darkSurface.withOpacity(0.4)
                  : const Color(0xFFFAFAFC));
      }),
      cells: [
        DataCell(
          Text(
            '${(currentPage - 1) * pageSize + index + 1}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),
        ),

        DataCell(
          SizedBox(
            width: 200,
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.AppColors.primary,
                      backgroundImage:
                          (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            )
                          : null,
                    ),
                    if (isVerified)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF14A800),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.name ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSuspended
                              ? Colors.grey.shade400
                              : (isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1B3E)),
                          decoration: isSuspended
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.email ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              user.displayRole,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: roleColor,
              ),
            ),
          ),
        ),

        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSuspended
                  ? Colors.red.withOpacity(0.1)
                  : const Color(0xFF14A800).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSuspended
                        ? Colors.red.shade500
                        : const Color(0xFF14A800),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isSuspended ? t.suspended : t.active,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSuspended
                        ? Colors.red.shade600
                        : const Color(0xFF14A800),
                  ),
                ),
              ],
            ),
          ),
        ),

        DataCell(
          Text(
            user.createdAt != null ? _formatDate(user.createdAt!) : '—',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
        ),

        DataCell(
          Text(
            user.phone ?? '—',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
        ),

        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionBtn(
                icon: isSuspended
                    ? Icons.check_circle_outline_rounded
                    : Icons.block_rounded,
                color: isSuspended
                    ? const Color(0xFF14A800)
                    : Colors.red.shade400,
                bg: isSuspended
                    ? const Color(0xFF14A800).withOpacity(0.1)
                    : Colors.red.withOpacity(0.08),
                onTap: () => _updateUserStatus(
                  user.id!,
                  isSuspended ? 'active' : 'suspended',
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                tooltip: '',
                padding: EdgeInsets.zero,
                icon: _actionBtn(
                  icon: Icons.more_vert_rounded,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  bg: isDark
                      ? AppTheme.AppColors.darkSurface
                      : Colors.grey.shade50,
                  onTap: null,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
                elevation: 4,
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      Navigator.pushNamed(
                        context,
                        '/admin/user-details',
                        arguments: {'userId': user.id},
                      );
                      break;
                    case 'verify':
                      _verifyUser(user.id!, !isVerified);
                      break;
                    case 'suspend':
                      _updateUserStatus(user.id!, 'suspended');
                      break;
                    case 'activate':
                      _updateUserStatus(user.id!, 'active');
                      break;
                    case 'resend':
                      _resendAccountEmail(user.id!);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  _popupItem(
                    Icons.visibility_outlined,
                    t.viewProfile,
                    isDark,
                    value: 'view',
                  ),
                  _popupItem(
                    Icons.email_outlined,
                    t.resendAccountEmail,
                    isDark,
                    color: Colors.blue,
                    value: 'resend',
                  ),
                  _popupItem(
                    isVerified ? Icons.verified : Icons.verified_user_outlined,
                    isVerified ? t.removeVerification : t.verifyUser,
                    isDark,
                    color: isVerified ? Colors.orange : const Color(0xFF14A800),
                    value: 'verify',
                  ),
                  if (!isSuspended)
                    _popupItem(
                      Icons.block_outlined,
                      t.suspendUser,
                      isDark,
                      color: Colors.red,
                      value: 'suspend',
                    ),
                  if (isSuspended)
                    _popupItem(
                      Icons.check_circle_outline,
                      t.activateUser,
                      isDark,
                      color: const Color(0xFF14A800),
                      value: 'activate',
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  PopupMenuItem<String> _popupItem(
    IconData icon,
    String label,
    bool isDark, {
    Color? color,
    required String value,
  }) {
    final defaultColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 15, color: color ?? defaultColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: color ?? defaultColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations t, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.AppColors.darkSurface
                  : const Color(0xFFF0F2F8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 36,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.noUsersFound,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.tryAdjustingFilters,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(AppLocalizations t, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${t.page} $currentPage ${t.ofWord} $totalPages',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          Row(
            children: [
              _pageBtn(
                icon: Icons.chevron_left_rounded,
                enabled: currentPage > 1,
                onTap: () {
                  setState(() => currentPage--);
                  _loadUsers();
                },
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _pageBtn(
                icon: Icons.chevron_right_rounded,
                enabled: currentPage < totalPages,
                onTap: () {
                  setState(() => currentPage++);
                  _loadUsers();
                },
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? AppTheme.AppColors.primary.withOpacity(0.1)
              : (isDark
                    ? AppTheme.AppColors.darkSurface
                    : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? AppTheme.AppColors.primary.withOpacity(0.2)
                : (isDark ? AppTheme.AppColors.grayDark : Colors.grey.shade200),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppTheme.AppColors.primary
              : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
        ),
      ),
    );
  }
}
