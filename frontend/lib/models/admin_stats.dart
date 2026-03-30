// lib/models/admin_stats.dart
class AdminStats {
  final int totalUsers;
  final int totalFreelancers;
  final int totalClients;
  final int totalProjects;
  final int totalContracts;
  final double totalEarnings;
  final int pendingProjects;
  final int activeContracts;
  final int completedContracts;
  final int pendingDisputes;

  AdminStats({
    required this.totalUsers,
    required this.totalFreelancers,
    required this.totalClients,
    required this.totalProjects,
    required this.totalContracts,
    required this.totalEarnings,
    required this.pendingProjects,
    required this.activeContracts,
    required this.completedContracts,
    required this.pendingDisputes,
  });

  factory AdminStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AdminStats(
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
    }
    
    return AdminStats(
      totalUsers: json['totalUsers'] ?? json['total_users'] ?? 0,
      totalFreelancers: json['totalFreelancers'] ?? json['total_freelancers'] ?? 0,
      totalClients: json['totalClients'] ?? json['total_clients'] ?? 0,
      totalProjects: json['totalProjects'] ?? json['total_projects'] ?? 0,
      totalContracts: json['totalContracts'] ?? json['total_contracts'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? json['total_earnings'] ?? 0).toDouble(),
      pendingProjects: json['pendingProjects'] ?? json['pending_projects'] ?? 0,
      activeContracts: json['activeContracts'] ?? json['active_contracts'] ?? 0,
      completedContracts: json['completedContracts'] ?? json['completed_contracts'] ?? 0,
      pendingDisputes: json['pendingDisputes'] ?? json['pending_disputes'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalFreelancers': totalFreelancers,
      'totalClients': totalClients,
      'totalProjects': totalProjects,
      'totalContracts': totalContracts,
      'totalEarnings': totalEarnings,
      'pendingProjects': pendingProjects,
      'activeContracts': activeContracts,
      'completedContracts': completedContracts,
      'pendingDisputes': pendingDisputes,
    };
  }
}