// lib/screens/admin/users_management_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUsers();
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

  Future<void> _updateUserStatus(int userId, String status) async {
    try {
      await ApiService.updateUserStatus(userId, status);
      Fluttertoast.showToast(
        msg:
            'User status updated to ${status == 'active' ? 'Active' : 'Suspended'}',
      );
      _loadUsers();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error updating status: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    searchQuery = value;
                    currentPage = 1;
                    _loadUsers();
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Roles', selectedRole == 'all', () {
                        setState(() => selectedRole = 'all');
                        currentPage = 1;
                        _loadUsers();
                      }),
                      _buildFilterChip(
                        'Freelancer',
                        selectedRole == 'freelancer',
                        () {
                          setState(() => selectedRole = 'freelancer');
                          currentPage = 1;
                          _loadUsers();
                        },
                      ),
                      _buildFilterChip('Client', selectedRole == 'client', () {
                        setState(() => selectedRole = 'client');
                        currentPage = 1;
                        _loadUsers();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'All Status',
                        selectedStatus == 'all',
                        () {
                          setState(() => selectedStatus = 'all');
                          currentPage = 1;
                          _loadUsers();
                        },
                      ),
                      _buildFilterChip(
                        'Active',
                        selectedStatus == 'active',
                        () {
                          setState(() => selectedStatus = 'active');
                          currentPage = 1;
                          _loadUsers();
                        },
                      ),
                      _buildFilterChip(
                        'Suspended',
                        selectedStatus == 'suspended',
                        () {
                          setState(() => selectedStatus = 'suspended');
                          currentPage = 1;
                          _loadUsers();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? const Center(child: Text('No users found'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildUserCard(user);
                    },
                  ),
                ),
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: currentPage > 1
                              ? () {
                                  currentPage--;
                                  _loadUsers();
                                }
                              : null,
                        ),
                        Text('Page $currentPage of $totalPages'),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: currentPage < totalPages
                              ? () {
                                  currentPage++;
                                  _loadUsers();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey.shade100,
        selectedColor: const Color(0xff14A800).withOpacity(0.2),
        checkmarkColor: const Color(0xff14A800),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final isSuspended = user.accountStatus == 'suspended';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
              ? NetworkImage(user.avatar!)
              : null,
          child: user.avatar == null || user.avatar!.isEmpty
              ? Text(
                  user.name?.isNotEmpty == true
                      ? user.name![0].toUpperCase()
                      : '?',
                )
              : null,
        ),
        title: Text(
          user.name ?? 'Unknown',
          style: TextStyle(
            decoration: isSuspended ? TextDecoration.lineThrough : null,
            color: isSuspended ? Colors.grey : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email ?? 'No email',
              style: TextStyle(
                color: isSuspended
                    ? Colors.grey.shade600
                    : Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: user.roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.displayRole,
                    style: TextStyle(
                      fontSize: 10,
                      color: user.roleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: user.isVerifiedUser
                        ? Colors.green.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isVerifiedUser ? 'Verified' : 'Unverified',
                    style: TextStyle(
                      fontSize: 10,
                      color: user.isVerifiedUser ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (user.accountStatus != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSuspended
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isSuspended ? 'Suspended' : 'Active',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSuspended ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            if (user.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Joined: ${_formatDate(user.createdAt!)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'verify') {
              _verifyUser(user.id!, !user.isVerifiedUser);
            } else if (value == 'suspend' && !isSuspended) {
              _updateUserStatus(user.id!, 'suspended');
            } else if (value == 'activate' && isSuspended) {
              _updateUserStatus(user.id!, 'active');
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'verify',
              child: Row(
                children: [
                  Icon(
                    user.isVerifiedUser ? Icons.verified : Icons.verified_user,
                    color: user.isVerifiedUser ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.isVerifiedUser ? 'Remove Verification' : 'Verify User',
                  ),
                ],
              ),
            ),
            if (!isSuspended)
              const PopupMenuItem(
                value: 'suspend',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Suspend User', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            if (isSuspended)
              const PopupMenuItem(
                value: 'activate',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Activate User',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/admin/user-details',
            arguments: {'userId': user.id},
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Today';
    }
  }
}
