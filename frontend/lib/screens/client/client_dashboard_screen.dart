// lib/screens/client/client_dashboard_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:freelancer_platform/models/usage_limits_model.dart';
import 'enhanced_client_profile_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freelancer_platform/screens/client/client_profile_screen.dart';
import 'package:lottie/lottie.dart';
import '../../models/contract_model.dart';
import '../../models/project_model.dart';
import '../../models/proposal_model.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../chat/chats_list_screen.dart';
import '../contract/my_contracts_screen.dart';
import '../notifications/notifications_screen.dart';
import 'create_project_screen.dart';
import 'project_proposals_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DashboardOverview {
  final _Stats stats;
  final List<_MonthlyPoint> monthlySpending;
  final List<_StatusSlice> statusBreakdown;
  final List<_ProposalItem> recentProposals;
  final List<_ContractItem> activeContracts;
  final List<NotificationModel> recentActivity;
  final List<_FreelancerChip> topFreelancers;

  DashboardOverview({
    required this.stats,
    required this.monthlySpending,
    required this.statusBreakdown,
    required this.recentProposals,
    required this.activeContracts,
    required this.recentActivity,
    required this.topFreelancers,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> j) =>
      DashboardOverview(
        stats: _Stats.fromJson(j['stats'] ?? {}),
        monthlySpending: ((j['monthlySpending'] ?? []) as List)
            .map((e) => _MonthlyPoint.fromJson(e))
            .toList(),
        statusBreakdown: ((j['statusBreakdown'] ?? []) as List)
            .map((e) => _StatusSlice.fromJson(e))
            .toList(),
        recentProposals: ((j['recentProposals'] ?? []) as List)
            .map((e) => _ProposalItem.fromJson(e))
            .toList(),
        activeContracts: ((j['activeContracts'] ?? []) as List)
            .map((e) => _ContractItem.fromJson(e))
            .toList(),
        recentActivity: ((j['recentActivity'] ?? []) as List)
            .map((e) => NotificationModel.fromJson(e))
            .toList(),
        topFreelancers: ((j['topFreelancers'] ?? []) as List)
            .map((e) => _FreelancerChip.fromJson(e))
            .toList(),
      );
}

class _Stats {
  final int totalProjects, openProjects, inProgressProjects, completedProjects;
  final int totalProposals, pendingProposals, acceptedProposals;
  final double totalSpent, escrowHeld, totalReleased;
  final int proposalAcceptRate;

  _Stats({
    this.totalProjects = 0,
    this.openProjects = 0,
    this.inProgressProjects = 0,
    this.completedProjects = 0,
    this.totalProposals = 0,
    this.pendingProposals = 0,
    this.acceptedProposals = 0,
    this.totalSpent = 0,
    this.escrowHeld = 0,
    this.totalReleased = 0,
    this.proposalAcceptRate = 0,
  });

  factory _Stats.fromJson(Map<String, dynamic> j) => _Stats(
    totalProjects: j['totalProjects'] ?? 0,
    openProjects: j['openProjects'] ?? 0,
    inProgressProjects: j['inProgressProjects'] ?? 0,
    completedProjects: j['completedProjects'] ?? 0,
    totalProposals: j['totalProposals'] ?? 0,
    pendingProposals: j['pendingProposals'] ?? 0,
    acceptedProposals: j['acceptedProposals'] ?? 0,
    totalSpent: _d(j['totalSpent']),
    escrowHeld: _d(j['escrowHeld']),
    totalReleased: _d(j['totalReleased']),
    proposalAcceptRate: j['proposalAcceptRate'] ?? 0,
  );

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(v);
      if (match != null) {
        return double.tryParse(match.group(0)!) ?? 0;
      }
      return double.tryParse(v) ?? 0;
    }
    return double.tryParse(v.toString()) ?? 0;
  }
}

class _MonthlyPoint {
  final String label;
  final double total;
  _MonthlyPoint({required this.label, required this.total});
  factory _MonthlyPoint.fromJson(Map<String, dynamic> j) =>
      _MonthlyPoint(label: j['label'] ?? '', total: _d(j['total']));
  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(v);
      if (match != null) {
        return double.tryParse(match.group(0)!) ?? 0;
      }
      return double.tryParse(v) ?? 0;
    }
    return double.tryParse(v.toString()) ?? 0;
  }
}

class _StatusSlice {
  final String label;
  final int value;
  final String color;
  _StatusSlice({required this.label, required this.value, required this.color});
  factory _StatusSlice.fromJson(Map<String, dynamic> j) => _StatusSlice(
    label: j['label'] ?? '',
    value: j['value'] ?? 0,
    color: j['color'] ?? '#888',
  );
}

class _ProposalItem {
  final int id;
  final String status;
  final double price;
  final int deliveryTime;
  final String proposalText;
  final String? projectTitle;
  final int? projectId;
  final String? freelancerName;
  final String? freelancerAvatar;
  final String? freelancerTitle;
  final double? freelancerRating;
  final List<String> skills;
  UsageLimits? _usage;

  _ProposalItem({
    required this.id,
    required this.status,
    required this.price,
    required this.deliveryTime,
    required this.proposalText,
    this.projectTitle,
    this.projectId,
    this.freelancerName,
    this.freelancerAvatar,
    this.freelancerTitle,
    this.freelancerRating,
    this.skills = const [],
  });

  factory _ProposalItem.fromJson(Map<String, dynamic> j) {
    final fp = j['freelancerProfile'];
    final f = j['freelancer'];
    final p = j['project'];
    List<String> skills = [];
    if (fp?['skills'] is List) {
      skills = (fp!['skills'] as List).map((e) => e.toString()).toList();
    }
    return _ProposalItem(
      id: j['id'] ?? 0,
      status: j['status'] ?? 'pending',
      price: (j['price'] ?? 0).toDouble(),
      deliveryTime: j['deliveryTime'] ?? 0,
      proposalText: j['proposalText'] ?? '',
      projectTitle: p?['title'],
      projectId: p?['id'],
      freelancerName: f?['name'],
      freelancerAvatar: f?['avatar'],
      freelancerTitle: fp?['title'],
      freelancerRating: (fp?['rating'] ?? 0).toDouble(),
      skills: skills,
    );
  }
}

class _ContractItem {
  final int id;
  final String status, escrowStatus;
  final double agreedAmount, releasedAmount;
  final int progress, milestonesTotal, milestonesDone;
  final String? projectTitle, projectCategory;
  final int? projectId;
  final String? freelancerName, freelancerAvatar;
  final String? nextMilestoneTitle;

  _ContractItem({
    required this.id,
    required this.status,
    required this.escrowStatus,
    required this.agreedAmount,
    required this.releasedAmount,
    required this.progress,
    required this.milestonesTotal,
    required this.milestonesDone,
    this.projectTitle,
    this.projectCategory,
    this.projectId,
    this.freelancerName,
    this.freelancerAvatar,
    this.nextMilestoneTitle,
  });

  factory _ContractItem.fromJson(Map<String, dynamic> j) {
    final p = j['project'];
    final f = j['freelancer'];
    final nm = j['nextMilestone'];
    return _ContractItem(
      id: j['id'] ?? 0,
      status: j['status'] ?? '',
      escrowStatus: j['escrowStatus'] ?? 'pending',
      agreedAmount: (j['agreedAmount'] ?? 0).toDouble(),
      releasedAmount: (j['releasedAmount'] ?? 0).toDouble(),
      progress: j['progress'] ?? 0,
      milestonesTotal: j['milestonesTotal'] ?? 0,
      milestonesDone: j['milestonesDone'] ?? 0,
      projectTitle: p?['title'],
      projectCategory: p?['category'],
      projectId: p?['id'],
      freelancerName: f?['name'],
      freelancerAvatar: f?['avatar'],
      nextMilestoneTitle: nm?['title'],
    );
  }
}

class _FreelancerChip {
  final int id;
  final String name;
  final String? avatar;
  final double? rating;
  _FreelancerChip({
    required this.id,
    required this.name,
    this.avatar,
    this.rating,
  });
  factory _FreelancerChip.fromJson(Map<String, dynamic> j) => _FreelancerChip(
    id: j['id'] ?? 0,
    name: j['name'] ?? '',
    avatar: j['avatar'],
    rating: j['rating']?.toDouble(),
  );
}

class _AIFreelancerSuggestion {
  final int id;
  final String name;
  final String? avatar;
  final String? title;
  final double rating;
  final int experience;
  final int matchScore;
  final List<String> skills;

  _AIFreelancerSuggestion({
    required this.id,
    required this.name,
    this.avatar,
    this.title,
    this.rating = 0,
    this.experience = 0,
    this.matchScore = 0,
    this.skills = const [],
  });

  factory _AIFreelancerSuggestion.fromJson(Map<String, dynamic> j) =>
      _AIFreelancerSuggestion(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        avatar: j['avatar'],
        title: j['title'],
        rating: (j['rating'] ?? 0).toDouble(),
        experience: j['experience'] ?? 0,
        matchScore: j['matchScore'] ?? 0,
        skills: (j['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class ClientProfile {
  final int id;
  final String name;
  final String? avatar;
  final String? email;
  final String? company;
  final String? phone;

  ClientProfile({
    required this.id,
    required this.name,
    this.avatar,
    this.email,
    this.company,
    this.phone,
  });

  factory ClientProfile.fromJson(Map<String, dynamic> j) => ClientProfile(
    id: j['id'] ?? 0,
    name: j['name'] ?? 'Client',
    avatar: j['avatar'],
    email: j['email'],
    company: j['company'],
    phone: j['phone'],
  );
}

class SearchDialog extends StatefulWidget {
  final Function(String) onSearch;
  const SearchDialog({super.key, required this.onSearch});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _recentSearches = [
    'Flutter Developer',
    'UI Designer',
    'Backend Developer',
    'Mobile App',
    'Web Development',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search projects, freelancers...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _controller.clear(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onSubmitted: (value) {
                widget.onSearch(value);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return Chip(
                  label: Text(search),
                  onDeleted: () {},
                  deleteIcon: const Icon(Icons.close, size: 14),
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: const TextStyle(fontSize: 12),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard>
    with SingleTickerProviderStateMixin {
  DashboardOverview? _data;
  List<Project> _myProjects = [];
  List<_AIFreelancerSuggestion> _aiSuggestions = [];
  ClientProfile? _clientProfile;
  bool _loading = true;
  bool _loadingProfile = true;
  int _unread = 0;
  int _selectedTab = 0;
  bool _loadingSuggestions = true;
  int _touchedIndex = -1;
  Timer? _refreshTimer;
  UsageLimits? _usage;
  bool _loadingUsage = true;

  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4F46E5);
  static const Color _primaryLight = Color(0xFFEEF2FF);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _info = Color(0xFF3B82F6);
  static const Color _dark = Color(0xFF1F2937);
  static const Color _gray = Color(0xFF6B7280);
  static const Color _lightGray = Color(0xFFF9FAFB);

  Future<void> _loadUsage() async {
    setState(() => _loadingUsage = true);
    try {
      final response = await ApiService.getUserUsage();
      if (response['usage'] != null && mounted) {
        setState(() {
          _usage = UsageLimits.fromJson(response['usage']);
          _loadingUsage = false;
        });
      } else {
        setState(() => _loadingUsage = false);
      }
    } catch (e) {
      print('Error loading usage: $e');
      if (mounted) setState(() => _loadingUsage = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadClientProfile();
    _loadDashboard();
    _loadMyProjects();
    _loadUnread();
    _loadUsage();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadDashboard(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Widget _buildActiveProjectsLimitIndicator() {
    if (_usage == null) return const SizedBox.shrink();
    if (_usage!.activeProjectsLimit == null) return const SizedBox.shrink();

    final remaining = _usage!.remainingActiveProjects;
    final used = _usage!.activeProjectsUsed;
    final limit = _usage!.activeProjectsLimit!;
    final isLimitReached = remaining <= 0;
    final isNearLimit = remaining <= 2 && remaining > 0;

    if (!isLimitReached && !isNearLimit) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLimitReached ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLimitReached ? Colors.red.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isLimitReached
                  ? Colors.red.shade100
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isLimitReached ? Icons.block : Icons.warning,
              size: 20,
              color: isLimitReached ? Colors.red : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLimitReached
                      ? 'Active Projects Limit Reached'
                      : 'Approaching Active Projects Limit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isLimitReached ? Colors.red : Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLimitReached
                      ? 'You have reached the maximum of $limit active projects on your current plan.'
                      : 'You have $remaining project${remaining > 1 ? 's' : ''} remaining out of $limit.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isLimitReached
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                if (isLimitReached) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: used / limit,
                          backgroundColor: Colors.red.shade100,
                          valueColor: const AlwaysStoppedAnimation(Colors.red),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/subscription/plans');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLimitReached
                            ? Colors.red
                            : Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Upgrade Plan',
                        style: TextStyle(
                          fontSize: 13,
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
        ],
      ),
    );
  }

  Future<void> _loadClientProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final response = await ApiService.getClientProfile();
      if (mounted) {
        setState(() {
          _clientProfile = ClientProfile.fromJson(response);
          _loadingProfile = false;
        });
        print('✅ Client profile loaded: ${_clientProfile?.name}');
      }
    } catch (e) {
      print('Error loading client profile: $e');
      try {
        final fallbackResponse = await ApiService.getProfile();
        if (mounted) {
          setState(() {
            _clientProfile = ClientProfile.fromJson(fallbackResponse);
            _loadingProfile = false;
          });
        }
      } catch (e2) {
        if (mounted) setState(() => _loadingProfile = false);
      }
    }
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final json = await ApiService.getClientDashboardOverview();
      if (mounted) {
        final dashboardData = DashboardOverview.fromJson(json);
        setState(() {
          _data = dashboardData;
          _loading = false;
        });
      }
    } catch (e, stack) {
      print('❌ Error loading dashboard: $e');
      if (mounted) setState(() => _loading = false);
      Fluttertoast.showToast(msg: 'Error loading dashboard');
    }
  }

  Future<void> _loadMyProjects() async {
    try {
      final data = await ApiService.getMyProjects2();
      setState(() {
        _myProjects = data
            .map((json) {
              try {
                return Project.fromJson(json);
              } catch (e) {
                return null;
              }
            })
            .whereType<Project>()
            .toList();
      });
      await _loadAISuggestions();
    } catch (e) {
      setState(() => _myProjects = []);
    }
  }

  Future<void> _loadAISuggestions() async {
    setState(() => _loadingSuggestions = true);
    try {
      final openProject = _myProjects.firstWhere(
        (p) => p.status == 'open',
        orElse: () => Project(),
      );

      if (openProject.id != null) {
        final result = await ApiService.getSuggestedFreelancers(
          openProject.id!,
        );
        if (mounted) {
          setState(() {
            final suggestions = result['suggestions'];
            if (suggestions is List) {
              _aiSuggestions = suggestions
                  .map((e) => _AIFreelancerSuggestion.fromJson(e))
                  .toList();
            } else {
              _aiSuggestions = [];
            }
            _loadingSuggestions = false;
          });
        }
      } else {
        if (mounted)
          setState(() {
            _aiSuggestions = [];
            _loadingSuggestions = false;
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _aiSuggestions = [];
          _loadingSuggestions = false;
        });
    }
  }

  Future<void> _loadUnread() async {
    try {
      final r = await ApiService.getUnreadCount();
      if (mounted) setState(() => _unread = r['unreadCount'] ?? 0);
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) return '';
    if (avatar.startsWith('http')) return avatar;
    return 'http://localhost:5000$avatar';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  double _calculateProfileCompletion() {
    int completed = 0;
    int total = 5;

    if (_clientProfile?.name != null && _clientProfile!.name.isNotEmpty)
      completed++;
    if (_clientProfile?.avatar != null && _clientProfile!.avatar!.isNotEmpty)
      completed++;
    if (_clientProfile?.email != null && _clientProfile!.email!.isNotEmpty)
      completed++;
    if (_clientProfile?.company != null && _clientProfile!.company!.isNotEmpty)
      completed++;
    if (_myProjects.isNotEmpty) completed++;

    return total > 0 ? (completed / total * 100) : 0;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'active':
        return _success;
      case 'open':
        return _info;
      case 'pending_freelancer':
      case 'pending_client':
      case 'draft':
        return _warning;
      case 'completed':
        return _success;
      case 'cancelled':
      case 'disputed':
        return _danger;
      default:
        return _gray;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'active':
        return 'Active';
      case 'open':
        return 'Open';
      case 'pending_freelancer':
        return 'Pending';
      case 'pending_client':
        return 'Action Needed';
      case 'draft':
        return 'Draft';
      case 'completed':
        return 'Done';
      case 'cancelled':
        return 'Cancelled';
      default:
        return s;
    }
  }

  Color _getMatchColor(int score) {
    if (score >= 80) return _success;
    if (score >= 60) return _warning;
    return _info;
  }

  Color _hexColor(String hex, {double opacity = 1}) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16)).withOpacity(opacity);
    } catch (_) {
      return _gray;
    }
  }

  BoxDecoration _modernCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClientProfileScreen()),
    ).then((_) {
      _loadClientProfile();
    });
  }

  void _navigateToSettings() {
    // TODO: Navigate to settings screen
  }

  void _navigateToSupport() {
    // TODO: Navigate to support screen
  }

  void _navigateToCreateProject() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
    ).then((_) {
      _loadMyProjects();
      _loadDashboard();
    });
  }

  void _navigateToFindWork() {
    // TODO: Navigate to find work screen
  }

  void _navigateToContracts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyContractsScreen(userRole: 'client'),
      ),
    );
  }

  void _navigateToFreelancers() {
    // TODO: Navigate to freelancers screen
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => SearchDialog(
        onSearch: (query) {
          print('Searching for: $query');
        },
      ),
    );
  }

  void _showMenuDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EnhancedClientProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _navigateToSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                _navigateToSupport();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await ApiService.logout();
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final greeting = _getGreeting();
    final firstName = _clientProfile?.name?.split(' ').first ?? 'User';
    final avatarUrl = _getAvatarUrl(_clientProfile?.avatar);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EnhancedClientProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primary, _primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: avatarUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Center(
                              child: Text(
                                _initials(firstName),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _initials(firstName),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(fontSize: 12, color: _gray),
                    ),
                    Text(
                      firstName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    if (_clientProfile?.email != null)
                      Text(
                        _clientProfile!.email!,
                        style: TextStyle(fontSize: 11, color: _gray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              _buildIconButton(Icons.search, _showSearchDialog),
              const SizedBox(width: 8),
              _buildIconButton(Icons.subscriptions, () {
                Navigator.pushNamed(context, '/subscription/plans');
              }, iconColor: const Color(0xff14A800)),
              const SizedBox(width: 8),
              _buildIconButtonWithBadge(Icons.notifications_none, () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ).then((_) => _loadUnread());
              }, badgeCount: _unread),
              const SizedBox(width: 8),
              _buildIconButton(Icons.more_vert, _showMenuDialog),
              IconButton(
                icon: const Icon(Icons.account_balance_wallet),
                onPressed: () {
                  Navigator.pushNamed(context, '/wallet', arguments: 'client');
                },
                tooltip: 'Wallet',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(
    IconData icon,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: iconColor ?? _gray),
      ),
    );
  }

  Widget _buildIconButtonWithBadge(
    IconData icon,
    VoidCallback onTap, {
    int badgeCount = 0,
  }) {
    return Stack(
      children: [
        _buildIconButton(icon, onTap),
        if (badgeCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _danger,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildQuickAction(
            icon: Icons.add_circle_outline,
            label: 'New Project',
            color: _primary,
            onTap: _navigateToCreateProject,
          ),
          const SizedBox(width: 12),
          _buildQuickAction(
            icon: Icons.person,
            label: 'Profile',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EnhancedClientProfileScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          _buildQuickAction(
            icon: Icons.description_outlined,
            label: 'Contracts',
            color: _warning,
            onTap: _navigateToContracts,
          ),
          const SizedBox(width: 12),
          _buildQuickAction(
            icon: Icons.people_outline,
            label: 'Freelancers',
            color: _success,
            onTap: _navigateToFreelancers,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    final completion = _calculateProfileCompletion();
    if (completion >= 100) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_warning, _warning.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Complete your profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${completion.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Get more projects by completing your profile',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EnhancedClientProfileScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Complete Now',
              style: TextStyle(color: _warning, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatsGrid(_Stats s) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildCompactStatCard(
            label: 'Projects',
            value: '${s.totalProjects}',
            icon: Icons.folder_open,
            color: _primary,
            subtitle: '${s.inProgressProjects} active',
          ),
          const SizedBox(width: 10),
          _buildCompactStatCard(
            label: 'Proposals',
            value: '${s.totalProposals}',
            icon: Icons.send,
            color: _info,
            subtitle: '${s.acceptedProposals} accepted',
          ),
          const SizedBox(width: 10),
          _buildCompactStatCard(
            label: 'Spent',
            value: '\$${s.totalSpent.toStringAsFixed(0)}',
            icon: Icons.payments,
            color: _success,
            subtitle: 'escrow: \$${s.escrowHeld.toStringAsFixed(0)}',
          ),
          const SizedBox(width: 10),
          _buildCompactStatCard(
            label: 'Rate',
            value: '${s.proposalAcceptRate}%',
            icon: Icons.trending_up,
            color: _warning,
            subtitle: 'acceptance',
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: _modernCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, size: 20, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text(
                'Analytics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticItem(
                  label: 'Response Rate',
                  value: '98%',
                  icon: Icons.speed,
                  color: _success,
                ),
              ),
              Expanded(
                child: _buildAnalyticItem(
                  label: 'Avg. Response',
                  value: '2.5h',
                  icon: Icons.access_time,
                  color: _info,
                ),
              ),
              Expanded(
                child: _buildAnalyticItem(
                  label: 'Success Rate',
                  value: '100%',
                  icon: Icons.verified,
                  color: _primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: _gray)),
      ],
    );
  }

  Widget _buildNavigationBar() {
    final tabs = ['Overview', 'Projects', 'Proposals'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Center(
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : _gray,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1)),
      ),
    );
  }

  Widget _buildBody() {
    if (_data == null && _myProjects.isEmpty && !_loading) {
      return _buildEnhancedEmptyState();
    }

    switch (_selectedTab) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildProjectsTab();
      case 2:
        return _buildProposalsTab();
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    final d = _data;
    if (d == null) return const SizedBox();

    return _buildRefreshableBody();
  }

  Widget _buildRefreshableBody() {
    return RefreshIndicator(
      color: _primary,
      onRefresh: () async {
        await Future.wait([
          _loadDashboard(),
          _loadMyProjects(),
          _loadClientProfile(),
          _loadUnread(),
          _loadUsage(),
        ]);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildActiveProjectsLimitIndicator(),
                _buildHeader(),
                _buildQuickActions(),
                if (_calculateProfileCompletion() < 100)
                  _buildProfileCompletionCard(),
                if (_data != null) ...[
                  _buildCompactStatsGrid(_data!.stats),
                  const SizedBox(height: 16),
                  _buildAnalyticsSection(),
                  const SizedBox(height: 8),
                  if (!_loadingSuggestions && _aiSuggestions.isNotEmpty)
                    _buildAISection(),
                  _buildChartsRow(_data!),
                  _buildActiveContracts(),
                  _buildRecentProposals(),
                  _buildActivityFeed(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primary, _primaryDark]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Recommendations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_aiSuggestions.length} freelancers',
                style: TextStyle(fontSize: 12, color: _gray),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _aiSuggestions.length,
            itemBuilder: (context, index) =>
                _buildCompactAICard(_aiSuggestions[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactAICard(_AIFreelancerSuggestion freelancer) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: _modernCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(freelancer.name, freelancer.avatar, 44, _primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      freelancer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      freelancer.title ?? 'Freelancer',
                      style: TextStyle(fontSize: 11, color: _gray),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMatchColor(freelancer.matchScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${freelancer.matchScore}%',
                  style: TextStyle(
                    color: _getMatchColor(freelancer.matchScore),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: freelancer.skills.take(3).map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  skill,
                  style: TextStyle(fontSize: 10, color: _primary),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          const Divider(height: 16),
          Row(
            children: [
              Icon(Icons.star, size: 12, color: _warning),
              const SizedBox(width: 4),
              Text(
                freelancer.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.work, size: 12, color: _gray),
              const SizedBox(width: 4),
              Text(
                '${freelancer.experience}y',
                style: TextStyle(fontSize: 11, color: _gray),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'View',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsRow(DashboardOverview d) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildCompactSpendingChart(d.monthlySpending),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildCompactDonut(d.statusBreakdown)),
        ],
      ),
    );
  }

  Widget _buildCompactSpendingChart(List<_MonthlyPoint> pts) {
    final cleanPts = pts.map((p) {
      if (p.total.isNaN || p.total.isInfinite || p.total < 0) {
        return _MonthlyPoint(label: p.label, total: 0);
      }
      return p;
    }).toList();

    final hasValidData = cleanPts.any((p) => p.total > 0);
    final maxY = hasValidData
        ? cleanPts.map((p) => p.total).reduce(math.max) * 1.2
        : 100.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _modernCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: !hasValidData
                ? Center(
                    child: Text(
                      'No spending data',
                      style: TextStyle(fontSize: 11, color: _gray),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, m) {
                              final i = v.toInt();
                              if (i < 0 || i >= cleanPts.length)
                                return const SizedBox();
                              return Text(
                                cleanPts[i].label,
                                style: TextStyle(fontSize: 8, color: _gray),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(
                        cleanPts.length,
                        (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: cleanPts[i].total.isNaN
                                  ? 0
                                  : cleanPts[i].total,
                              color: _primary,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDonut(List<_StatusSlice> slices) {
    if (slices.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _modernCard(),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 22,
                sections: slices.map((s) {
                  return PieChartSectionData(
                    value: s.value.toDouble(),
                    color: _hexColor(s.color),
                    radius: 32,
                    showTitle: false,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: slices.take(3).map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _hexColor(s.color),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.label,
                          style: TextStyle(fontSize: 10, color: _gray),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${s.value}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveContracts() {
    final contracts = _data?.activeContracts ?? [];
    if (contracts.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSectionHeader('Active Contracts', 'View All', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MyContractsScreen(userRole: 'client'),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        ...contracts
            .take(3)
            .map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCompactContractCard(c),
              ),
            ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCompactContractCard(_ContractItem c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _modernCard(),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(
                c.freelancerName ?? 'F',
                c.freelancerAvatar,
                44,
                _primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.projectTitle ?? 'Project',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      c.freelancerName ?? 'Freelancer',
                      style: TextStyle(fontSize: 11, color: _gray),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(c.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _statusLabel(c.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(c.status),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${c.agreedAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: c.progress / 100,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(_primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${c.progress}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentProposals() {
    final proposals = _data?.recentProposals ?? [];
    if (proposals.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSectionHeader(
            'Recent Proposals',
            'View All',
            () => setState(() => _selectedTab = 2),
          ),
        ),
        const SizedBox(height: 12),
        ...proposals
            .take(3)
            .map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCompactProposalCard(p),
              ),
            ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCompactProposalCard(_ProposalItem p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _modernCard(),
      child: Row(
        children: [
          _buildAvatar(p.freelancerName ?? 'F', p.freelancerAvatar, 44, _info),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.freelancerName ?? 'Freelancer',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '\$${p.price} • ${p.deliveryTime} days',
                  style: TextStyle(fontSize: 11, color: _gray),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: p.status == 'accepted'
                  ? _success.withOpacity(0.1)
                  : _warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p.status == 'accepted' ? 'Accepted' : 'Pending',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: p.status == 'accepted' ? _success : _warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed() {
    final activities = _data?.recentActivity ?? [];
    if (activities.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSectionHeader('Recent Activity'),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: _modernCard(),
          child: Column(
            children: activities.take(4).map((n) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getActivityIcon(n.type),
                        size: 18,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            n.body,
                            style: TextStyle(fontSize: 11, color: _gray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _timeAgo(n.createdAt),
                      style: TextStyle(fontSize: 10, color: _gray),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'proposal_received':
        return Icons.inbox;
      case 'proposal_accepted':
        return Icons.check_circle;
      case 'contract_created':
        return Icons.description;
      case 'contract_signed':
        return Icons.draw;
      case 'milestone_completed':
        return Icons.flag;
      case 'payment_received':
        return Icons.payments;
      case 'payment_released':
        return Icons.send_and_archive;
      case 'message':
        return Icons.chat_bubble;
      case 'new_review':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  Widget _buildProjectsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildProjectStats(),
          const SizedBox(height: 20),
          _buildSectionHeader('All Projects'),
          const SizedBox(height: 12),
          if (_myProjects.isEmpty)
            _buildEnhancedEmptyState()
          else
            ..._myProjects.map((p) => _buildCompactProjectCard(p)),
        ],
      ),
    );
  }

  Widget _buildProjectStats() {
    final stats = _data?.stats;
    return Row(
      children: [
        Expanded(
          child: _buildMiniStat('Open', '${stats?.openProjects ?? 0}', _info),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStat(
            'Active',
            '${stats?.inProgressProjects ?? 0}',
            _warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStat(
            'Done',
            '${stats?.completedProjects ?? 0}',
            _success,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: _modernCard(),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: _gray)),
        ],
      ),
    );
  }

  Widget _buildCompactProjectCard(Project project) {
    Color statusColor;
    String statusText;

    switch (project.status) {
      case 'open':
        statusColor = _info;
        statusText = 'Open';
        break;
      case 'in_progress':
        statusColor = _warning;
        statusText = 'Active';
        break;
      case 'completed':
        statusColor = _success;
        statusText = 'Done';
        break;
      default:
        statusColor = _gray;
        statusText = project.status ?? '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _modernCard(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.title ?? 'Untitled',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project.description ?? '',
            style: TextStyle(fontSize: 11, color: _gray),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.attach_money, size: 12, color: _gray),
              const SizedBox(width: 4),
              Text(
                '\$${project.budget?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 12, color: _gray),
              const SizedBox(width: 4),
              Text(
                '${project.duration ?? 0}d',
                style: TextStyle(fontSize: 12, color: _gray),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProjectProposalsScreen(projectId: project.id!),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProposalsTab() {
    final d = _data;
    final proposals = d?.recentProposals ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildProposalStats(),
          const SizedBox(height: 20),
          _buildSectionHeader('All Proposals'),
          const SizedBox(height: 12),
          if (proposals.isEmpty)
            _buildEnhancedEmptyState()
          else
            ...proposals.map((p) => _buildCompactProposalCard(p)),
        ],
      ),
    );
  }

  Widget _buildProposalStats() {
    final s = _data?.stats;
    return Row(
      children: [
        Expanded(
          child: _buildMiniStat('Total', '${s?.totalProposals ?? 0}', _primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStat(
            'Pending',
            '${s?.pendingProposals ?? 0}',
            _warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_primary, _primaryDark]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${s?.proposalAcceptRate ?? 0}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Accept Rate',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title, [
    String? action,
    VoidCallback? onAction,
  ]) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const Spacer(),
        if (action != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(
    String name,
    String? avatarUrl,
    double size,
    Color color,
  ) {
    final url = _getAvatarUrl(avatarUrl);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: url.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: size * 0.4,
                    height: size * 0.4,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Text(
                    _initials(name),
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                _initials(name),
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  Widget _buildEnhancedEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: _modernCard(),
      child: Column(
        children: [
          Lottie.network(
            'https://assets10.lottiefiles.com/packages/lf20_1a8dx7zj.json',
            width: 120,
            height: 120,
            repeat: true,
          ),
          const SizedBox(height: 16),
          const Text(
            'No projects yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first project to start hiring freelancers',
            style: TextStyle(fontSize: 13, color: _gray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToCreateProject,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
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

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _navigateToCreateProject,
      backgroundColor: _primary,
      elevation: 0,
      mini: true,
      child: const Icon(Icons.add, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      body: SafeArea(
        child: _loading || _loadingProfile
            ? _buildLoadingState()
            : _buildBody(),
      ),
      floatingActionButton: _buildFAB(),
    );
  }
}
