// screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:freelancer_platform/screens/admin/subscription_management_screen.dart';
import '../../models/admin_stats.dart';
import '../../services/api_service.dart';
import 'contracts_management_screen.dart';
import 'projects_management_screen.dart';
import 'users_management_screen.dart';
import 'settings_screen.dart';

class AppColors {
  static const sidebarBg = Color(0xFF2D2B55);
  static const sidebarText = Color(0xFFC8C6E8);
  static const sidebarActive = Color(0xFF5B58E2);
  static const accent = Color(0xFF6C63FF);
  static const accentLight = Color(0xFFA78BFA);
  static const green = Color(0xFF14A800);
  static const pageBg = Color(0xFFF5F6F8);
  static const cardBg = Colors.white;
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTap;

  const _AdminSidebar({required this.selectedIndex, required this.onItemTap});

  static const _items = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Users',
    ),
    _NavItem(
      icon: Icons.work_outline,
      selectedIcon: Icons.work,
      label: 'Projects',
    ),
    _NavItem(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
      label: 'Contracts',
    ),
    _NavItem(
      icon: Icons.subscriptions_outlined,
      selectedIcon: Icons.subscriptions,
      label: 'Subscriptions',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
            indent: 20,
            endIndent: 20,
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                final isActive = selectedIndex == i;
                return GestureDetector(
                  onTap: () => onItemTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.accent.withOpacity(0.25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isActive
                          ? Border(
                              left: const BorderSide(
                                color: AppColors.accentLight,
                                width: 3,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isActive ? item.selectedIcon : item.icon,
                          size: 19,
                          color: isActive
                              ? Colors.white
                              : AppColors.sidebarText,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            color: isActive
                                ? Colors.white
                                : AppColors.sidebarText,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.accentLight,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Super Admin',
                        style: TextStyle(
                          color: AppColors.sidebarText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.logout,
                  color: AppColors.sidebarText.withOpacity(0.6),
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminStats? stats;
  bool loading = true;
  List<Map<String, dynamic>> monthlyStats = [];
  int _selectedIndex = 0;
  int _dashboardTab = 0;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getAdminDashboardStats();
      print('📊 Dashboard response: $response');

      if (response != null && response.isNotEmpty) {
        final statsData = response['stats'] ?? {};
        final monthlyStatsData = response['monthlyStats'] ?? [];

        setState(() {
          stats = AdminStats.fromJson(statsData);
          monthlyStats = List<Map<String, dynamic>>.from(monthlyStatsData);
          loading = false;
        });
      } else {
        setState(() {
          stats = AdminStats(
            totalUsers: 0,
            totalFreelancers: 0,
            totalClients: 0,
            totalProjects: 0,
            totalContracts: 0,
            totalEarnings: 0,
            pendingProjects: 0,
            activeContracts: 0,
            completedContracts: 0,
            pendingDisputes: 0,
          );
          monthlyStats = [];
          loading = false;
          errorMessage = 'No data available';
        });
      }
    } catch (e) {
      print('❌ Error loading stats: $e');
      setState(() {
        loading = false;
        errorMessage = 'Failed to load dashboard data: $e';
        stats = AdminStats(
          totalUsers: 0,
          totalFreelancers: 0,
          totalClients: 0,
          totalProjects: 0,
          totalContracts: 0,
          totalEarnings: 0,
          pendingProjects: 0,
          activeContracts: 0,
          completedContracts: 0,
          pendingDisputes: 0,
        );
        monthlyStats = [];
      });
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up, size: 14, color: Colors.grey.shade400),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2B55),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final titles = [
      'Dashboard',
      'Users',
      'Projects',
      'Contracts',
      'Subscriptions',
      'Settings',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Text(
            titles[_selectedIndex],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2B55),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  _getCurrentDate(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.accent,
              size: 22,
            ),
            tooltip: 'Refresh',
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF2D2B55),
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            errorMessage ?? 'Failed to load dashboard data',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.construction_outlined,
              size: 50,
              color: AppColors.accent.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2B55),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final totalUsers = (stats?.totalUsers ?? 0).toDouble();
    final freelancers = (stats?.totalFreelancers ?? 0).toDouble();
    final clients = (stats?.totalClients ?? 0).toDouble();
    final completedContracts = (stats?.completedContracts ?? 0).toDouble();
    final activeContracts = (stats?.activeContracts ?? 0).toDouble();
    final pendingProjects = (stats?.pendingProjects ?? 0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.sidebarBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()}, Admin! 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Here's what's happening on your platform today",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _bannerChip(
                      Icons.people_alt_outlined,
                      '${stats?.totalUsers ?? 0} Users',
                    ),
                    const SizedBox(height: 6),
                    _bannerChip(
                      Icons.play_circle_outline,
                      '${stats?.activeContracts ?? 0} Active',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2B55),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: _getCrossAxisCount(context),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.35,
            children: [
              _buildStatCard(
                'Total Users',
                stats!.totalUsers.toString(),
                Icons.people_alt,
                Colors.blue,
              ),
              _buildStatCard(
                'Freelancers',
                stats!.totalFreelancers.toString(),
                Icons.work,
                AppColors.green,
              ),
              _buildStatCard(
                'Clients',
                stats!.totalClients.toString(),
                Icons.business,
                Colors.orange,
              ),
              _buildStatCard(
                'Projects',
                stats!.totalProjects.toString(),
                Icons.folder_open,
                AppColors.accent,
              ),
              _buildStatCard(
                'Contracts',
                stats!.totalContracts.toString(),
                Icons.description,
                Colors.teal,
              ),
              _buildStatCard(
                'Earnings',
                '\$${stats!.totalEarnings.toStringAsFixed(0)}',
                Icons.attach_money,
                AppColors.green,
              ),
              _buildStatCard(
                'Pending Projects',
                stats!.pendingProjects.toString(),
                Icons.pending_actions,
                Colors.orange,
              ),
              _buildStatCard(
                'Active Contracts',
                stats!.activeContracts.toString(),
                Icons.play_circle,
                Colors.blue,
              ),
              _buildStatCard(
                'Completed',
                stats!.completedContracts.toString(),
                Icons.check_circle,
                AppColors.green,
              ),
              _buildStatCard(
                'Disputes',
                stats!.pendingDisputes.toString(),
                Icons.warning_amber,
                Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              _insightTabChip('Overview', 0),
              const SizedBox(width: 10),
              _insightTabChip('Performance', 1),
              const SizedBox(width: 10),
              _insightTabChip('Trends', 2),
            ],
          ),
          const SizedBox(height: 14),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _buildDashboardTabPanel(
              totalUsers: totalUsers,
              freelancers: freelancers,
              clients: clients,
              completedContracts: completedContracts,
              activeContracts: activeContracts,
              pendingProjects: pendingProjects,
            ),
          ),

          const SizedBox(height: 28),

          if (monthlyStats.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'User Growth Analytics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2B55),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Total Users',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < monthlyStats.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  monthlyStats[value.toInt()]['month'] ?? '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
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
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
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
                      border: Border.all(color: Colors.grey.shade100, width: 1),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: monthlyStats.asMap().entries.map((entry) {
                          final users =
                              entry.value['users'] ??
                              entry.value['freelancers'] ??
                              0;
                          return FlSpot(entry.key.toDouble(), users.toDouble());
                        }).toList(),
                        isCurved: true,
                        color: AppColors.accent,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: AppColors.accent,
                              ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent.withOpacity(0.15),
                              AppColors.accent.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (!loading)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No chart data available',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _insightTabChip(String label, int index) {
    final selected = _dashboardTab == index;
    return InkWell(
      onTap: () => setState(() => _dashboardTab = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withOpacity(0.14) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.accent : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTabPanel({
    required double totalUsers,
    required double freelancers,
    required double clients,
    required double completedContracts,
    required double activeContracts,
    required double pendingProjects,
  }) {
    if (_dashboardTab == 1) {
      return _buildPerformancePanel(
        completedContracts: completedContracts,
        activeContracts: activeContracts,
        pendingProjects: pendingProjects,
      );
    }

    if (_dashboardTab == 2) {
      return _buildTrendPanel();
    }

    return _buildOverviewPanel(
      totalUsers: totalUsers,
      freelancers: freelancers,
      clients: clients,
    );
  }

  Widget _buildOverviewPanel({
    required double totalUsers,
    required double freelancers,
    required double clients,
  }) {
    final freelancerPct = totalUsers > 0 ? (freelancers / totalUsers) * 100 : 0;
    final clientPct = totalUsers > 0 ? (clients / totalUsers) * 100 : 0;

    return Container(
      key: const ValueKey('overview'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 38,
                sections: [
                  PieChartSectionData(
                    value: freelancers <= 0 ? 0.01 : freelancers,
                    color: AppColors.green,
                    title: '${freelancerPct.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  PieChartSectionData(
                    value: clients <= 0 ? 0.01 : clients,
                    color: AppColors.accent,
                    title: '${clientPct.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Distribution',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _legendRow('Freelancers', AppColors.green, freelancers.toInt()),
                const SizedBox(height: 8),
                _legendRow('Clients', AppColors.accent, clients.toInt()),
                const SizedBox(height: 12),
                Text(
                  'Balanced marketplace with ${totalUsers.toInt()} total accounts.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformancePanel({
    required double completedContracts,
    required double activeContracts,
    required double pendingProjects,
  }) {
    final maxY =
        [
          completedContracts,
          activeContracts,
          pendingProjects,
        ].reduce((a, b) => a > b ? a : b) +
        2;

    return Container(
      key: const ValueKey('performance'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operational Performance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Completed', 'Active', 'Pending'];
                        final i = value.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            i >= 0 && i < labels.length ? labels[i] : '',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: completedContracts,
                        color: AppColors.green,
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: activeContracts,
                        color: AppColors.accent,
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: pendingProjects,
                        color: Colors.orange,
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendPanel() {
    final lastMonth = monthlyStats.isNotEmpty ? monthlyStats.last : {};
    final monthUsers = (lastMonth['users'] ?? lastMonth['freelancers'] ?? 0)
        .toInt();
    final monthRevenue = (lastMonth['earnings'] ?? 0).toDouble();

    return Container(
      key: const ValueKey('trend'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: _microInsightCard(
              title: 'Last Month Users',
              value: monthUsers.toString(),
              icon: Icons.person_add_alt_1,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _microInsightCard(
              title: 'Last Month Revenue',
              value: '\$${monthRevenue.toStringAsFixed(0)}',
              icon: Icons.payments_outlined,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _microInsightCard(
              title: 'Health Score',
              value: _platformHealthScore(),
              icon: Icons.favorite_outline,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _microInsightCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(String label, Color color, int value) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _platformHealthScore() {
    final total = (stats?.totalContracts ?? 0);
    final completed = (stats?.completedContracts ?? 0);
    if (total <= 0) return 'N/A';
    final pct = ((completed / total) * 100).round();
    return '$pct%';
  }

  Widget _bannerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 5;
    if (width > 1100) return 4;
    if (width > 800) return 3;
    return 2;
  }

  Widget _buildContent() {
    if (stats == null && loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.accent,
              ),
            ),
            SizedBox(height: 16),
            Text('Loading dashboard...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const UsersManagementScreen();
      case 2:
        return const ProjectsManagementScreen();
      case 3:
        return const ContractsManagementScreen();
      case 4:
        return const SubscriptionManagementScreen();
      case 5:
        return const AdminSettingsScreen();
      default:
        return _buildDashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null && stats?.totalUsers == 0 && !loading) {
      return Scaffold(
        backgroundColor: AppColors.pageBg,
        body: _buildErrorWidget(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Row(
        children: [
          _AdminSidebar(
            selectedIndex: _selectedIndex,
            onItemTap: (i) => setState(() => _selectedIndex = i),
          ),

          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
