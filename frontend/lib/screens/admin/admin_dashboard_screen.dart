// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/admin_stats.dart';
import '../../services/api_service.dart';
import 'users_management_screen.dart';
// import 'projects_management_screen.dart';
// import 'contracts_management_screen.dart';
import 'settings_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6F8),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null && stats?.totalUsers == 0
          ? _buildErrorWidget()
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.selected,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people),
                      selectedIcon: Icon(Icons.people),
                      label: Text('Users'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.work),
                      selectedIcon: Icon(Icons.work),
                      label: Text('Projects'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.description),
                      selectedIcon: Icon(Icons.description),
                      label: Text('Contracts'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _buildContent()),
              ],
            ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Failed to load dashboard data',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff14A800),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const UsersManagementScreen();
      // case 2:
      //   return const ProjectsManagementScreen();
      // case 3:
      //   return const ContractsManagementScreen();
      case 2:
        return const AdminSettingsScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff14A800), Color(0xff0F7A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 30,
                    color: Color(0xff14A800),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome, Admin!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Here\'s what\'s happening on your platform today',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getCurrentDate(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 1000 ? 5 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Total Users',
                stats!.totalUsers.toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Freelancers',
                stats!.totalFreelancers.toString(),
                Icons.work,
                Colors.green,
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
                Icons.folder,
                Colors.purple,
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
                Colors.green,
              ),
              _buildStatCard(
                'Pending Projects',
                stats!.pendingProjects.toString(),
                Icons.pending,
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
                Colors.green,
              ),
              _buildStatCard(
                'Disputes',
                stats!.pendingDisputes.toString(),
                Icons.warning,
                Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (monthlyStats.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Growth',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: const FlTitlesData(show: true),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: monthlyStats.asMap().entries.map((entry) {
                              final users =
                                  entry.value['users'] ??
                                  entry.value['freelancers'] ??
                                  0;
                              return FlSpot(
                                entry.key.toDouble(),
                                users.toDouble(),
                              );
                            }).toList(),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'No chart data available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}
