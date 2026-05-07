// lib/screens/admin/users_management_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';

const _kAccent = Color(0xFF5B58E2);
const _kAccentLight = Color(0xFF8B88FF);
const _kGreen = Color(0xFF14A800);
const _kPageBg = Color(0xFFF0F2F8);

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});
  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<User> users = [];
  bool loading = true;
  String selectedRole = 'all';
  String selectedStatus = 'all';
  String searchQuery = '';
  int currentPage = 1;
  int totalPages = 1;
  final int pageSize = 20;
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
    _loadUsers();
  }

  @override
  void dispose() {
    _newUserNameController.dispose();
    _newUserEmailController.dispose();
    super.dispose();
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
      );

      print('🔍 Response: $response');
      print('🔑 Token: ${ApiService.token}');
      setState(() {
        users = (response['users'] as List)
            .map((json) => User.fromJson(json))
            .toList();
        totalPages = response['totalPages'] ?? 1;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      Fluttertoast.showToast(msg: 'Error loading users: $e');
    }
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create new user'),
              content: Form(
                key: _createUserFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _newUserNameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newUserEmailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                          ).hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newUserPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone (optional)',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newUserNationalIdController,
                        decoration: const InputDecoration(
                          labelText: 'National ID (optional)',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _roleSelectionChip('client', 'Client', setState),
                          _roleSelectionChip(
                            'freelancer',
                            'Freelancer',
                            setState,
                          ),
                          _roleSelectionChip('admin', 'Admin', setState),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_newUserRole == 'freelancer') ...[
                        TextFormField(
                          controller: _newUserHourlyRateController,
                          decoration: const InputDecoration(
                            labelText: 'Hourly Rate (optional)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newUserSkillsController,
                          decoration: const InputDecoration(
                            labelText: 'Skills (optional, comma separated)',
                          ),
                        ),
                      ],
                      if (_newUserRole == 'client') ...[
                        TextFormField(
                          controller: _newUserClientTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Client Type (optional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newUserCompanyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Company Name (optional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newUserCommercialRegisterController,
                          decoration: const InputDecoration(
                            labelText: 'Commercial Register Number (optional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newUserTaxNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Tax Number (optional)',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _creatingUser ? null : _createUser,
                  child: _creatingUser
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createUser() async {
    if (!_createUserFormKey.currentState!.validate()) return;

    final name = _newUserNameController.text.trim();
    final email = _newUserEmailController.text.trim();
    final phone = _newUserPhoneController.text.trim();
    final nationalId = _newUserNationalIdController.text.trim();
    final hourlyRate = _newUserHourlyRateController.text.trim();
    final skills = _newUserSkillsController.text.trim();
    final clientType = _newUserClientTypeController.text.trim();
    final companyName = _newUserCompanyNameController.text.trim();
    final commercialRegister = _newUserCommercialRegisterController.text.trim();
    final taxNumber = _newUserTaxNumberController.text.trim();

    setState(() => _creatingUser = true);
    try {
      final response = await ApiService.createAdminUser(
        name: name,
        email: email,
        role: _newUserRole,
        phone: phone.isNotEmpty ? phone : null,
        nationalId: nationalId.isNotEmpty ? nationalId : null,
        hourlyRate: hourlyRate.isNotEmpty ? double.tryParse(hourlyRate) : null,
        skills: skills.isNotEmpty
            ? skills
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList()
            : null,
        clientType: clientType.isNotEmpty ? clientType : null,
        companyName: companyName.isNotEmpty ? companyName : null,
        commercialRegisterNumber: commercialRegister.isNotEmpty
            ? commercialRegister
            : null,
        taxNumber: taxNumber.isNotEmpty ? taxNumber : null,
      );

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: 'User created. Password sent by email.');
        Navigator.of(context).pop();
        _loadUsers();
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? 'Failed to create user',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error creating user: $e');
    } finally {
      if (mounted) setState(() => _creatingUser = false);
    }
  }

  Widget _roleSelectionChip(
    String roleValue,
    String label, [
    StateSetter? setState,
  ]) {
    final selected = _newUserRole == roleValue;
    return GestureDetector(
      onTap: () {
        if (setState != null) {
          setState(() => _newUserRole = roleValue);
        } else {
          setState?.call(() => _newUserRole = roleValue);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kAccent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _kAccent : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Future<void> _updateUserStatus(int userId, String status) async {
    try {
      await ApiService.updateUserStatus(userId, status);
      Fluttertoast.showToast(
        msg:
            'User ${status == 'active' ? 'activated' : 'suspended'} successfully',
      );
      _loadUsers();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> _verifyUser(int userId, bool verify) async {
    try {
      await ApiService.verifyUser(userId, verify);
      Fluttertoast.showToast(
        msg: verify ? 'User verified successfully' : 'Verification removed',
      );
      _loadUsers();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> _resendAccountEmail(int userId) async {
    try {
      final response = await ApiService.resendAccountEmail(userId);
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: 'Account email resent successfully');
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? 'Failed to resend email',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error resending email: $e');
    }
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Users',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1B3E),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton.icon(
                      onPressed: _showCreateUserDialog,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Add User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _kPageBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email...',
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
                    searchQuery = v;
                    currentPage = 1;
                    _loadUsers();
                  },
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _label('Role:'),
                    _filterChip(
                      'All',
                      selectedRole == 'all',
                      () => _setRole('all'),
                    ),
                    _filterChip(
                      'Freelancer',
                      selectedRole == 'freelancer',
                      () => _setRole('freelancer'),
                    ),
                    _filterChip(
                      'Client',
                      selectedRole == 'client',
                      () => _setRole('client'),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 12),
                    _label('Status:'),
                    _filterChip(
                      'All',
                      selectedStatus == 'all',
                      () => _setStatus('all'),
                    ),
                    _filterChip(
                      'Active',
                      selectedStatus == 'active',
                      () => _setStatus('active'),
                    ),
                    _filterChip(
                      'Suspended',
                      selectedStatus == 'suspended',
                      () => _setStatus('suspended'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: _kPageBg,
          child: Row(
            children: [
              Text(
                '${users.length} users',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B3E),
                ),
              ),
              if (loading) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kAccent,
                  ),
                ),
              ],
            ],
          ),
        ),

        Expanded(
          child: loading && users.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _kAccent))
              : users.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: users.length,
                  itemBuilder: (_, i) => _buildUserCard(users[i]),
                ),
        ),

        if (totalPages > 1) _buildPagination(),
      ],
    );
  }

  void _setRole(String r) {
    setState(() {
      selectedRole = r;
      currentPage = 1;
    });
    _loadUsers();
  }

  void _setStatus(String s) {
    setState(() {
      selectedStatus = s;
      currentPage = 1;
    });
    _loadUsers();
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF888888),
      ),
    ),
  );

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
              ? [
                  BoxShadow(
                    color: _kAccent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
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

  Widget _buildUserCard(User user) {
    final isSuspended = user.accountStatus == 'suspended';
    final initials = (user.name?.isNotEmpty == true)
        ? user.name![0].toUpperCase()
        : '?';
    final isVerified = user.isVerifiedUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _kAccent,
              backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                  ? NetworkImage(user.avatar!)
                  : null,
              child: (user.avatar == null || user.avatar!.isEmpty)
                  ? Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            if (isVerified)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: _kGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isSuspended
                      ? Colors.grey.shade400
                      : const Color(0xFF1A1B3E),
                  decoration: isSuspended ? TextDecoration.lineThrough : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _roleBadge(user),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email ?? 'No email',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _statusBadge(isSuspended),
                if (user.createdAt != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.access_time,
                    size: 11,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _formatDate(user.createdAt!),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                if (isSuspended)
                  _updateUserStatus(user.id!, 'active');
                else
                  _updateUserStatus(user.id!, 'suspended');
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSuspended
                      ? _kGreen.withOpacity(0.1)
                      : Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSuspended
                        ? _kGreen.withOpacity(0.2)
                        : Colors.red.withOpacity(0.15),
                  ),
                ),
                child: Icon(
                  isSuspended ? Icons.check_circle_outline : Icons.block,
                  size: 16,
                  color: isSuspended ? _kGreen : Colors.red.shade400,
                ),
              ),
            ),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(
                  Icons.more_vert,
                  size: 16,
                  color: Color(0xFF888888),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'verify')
                  _verifyUser(user.id!, !user.isVerifiedUser);
                else if (value == 'suspend' && !isSuspended)
                  _updateUserStatus(user.id!, 'suspended');
                else if (value == 'activate' && isSuspended)
                  _updateUserStatus(user.id!, 'active');
                else if (value == 'view')
                  Navigator.pushNamed(
                    context,
                    '/admin/user-details',
                    arguments: {'userId': user.id},
                  );
                else if (value == 'resend')
                  _resendAccountEmail(user.id!);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: _menuItem(
                    Icons.visibility_outlined,
                    'View Profile',
                    Colors.grey.shade700,
                  ),
                ),
                PopupMenuItem(
                  value: 'resend',
                  child: _menuItem(
                    Icons.email_outlined,
                    'Resend Account Email',
                    Colors.blue,
                  ),
                ),
                PopupMenuItem(
                  value: 'verify',
                  child: _menuItem(
                    isVerified ? Icons.verified : Icons.verified_user_outlined,
                    isVerified ? 'Remove Verification' : 'Verify User',
                    isVerified ? Colors.orange : _kGreen,
                  ),
                ),
                if (!isSuspended)
                  PopupMenuItem(
                    value: 'suspend',
                    child: _menuItem(
                      Icons.block_outlined,
                      'Suspend User',
                      Colors.red,
                    ),
                  ),
                if (isSuspended)
                  PopupMenuItem(
                    value: 'activate',
                    child: _menuItem(
                      Icons.check_circle_outline,
                      'Activate User',
                      _kGreen,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }

  Widget _roleBadge(User user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: user.roleColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        user.displayRole,
        style: TextStyle(
          fontSize: 10,
          color: user.roleColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statusBadge(bool suspended) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: suspended
            ? Colors.red.withOpacity(0.1)
            : _kGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        suspended ? 'Suspended' : 'Active',
        style: TextStyle(
          fontSize: 10,
          color: suspended ? Colors.red.shade700 : _kGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: _kPageBg, shape: BoxShape.circle),
            child: Icon(
              Icons.people_outline,
              size: 40,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search or filter',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
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
          _paginationBtn(
            Icons.chevron_left,
            currentPage > 1
                ? () {
                    setState(() => currentPage--);
                    _loadUsers();
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
              'Page $currentPage of $totalPages',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1B3E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _paginationBtn(
            Icons.chevron_right,
            currentPage < totalPages
                ? () {
                    setState(() => currentPage++);
                    _loadUsers();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _paginationBtn(IconData icon, VoidCallback? onTap) {
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

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Today';
  }
}
