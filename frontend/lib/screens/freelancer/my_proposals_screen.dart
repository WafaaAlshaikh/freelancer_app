// screens/freelancer/my_proposals_screen.dart

import 'package:flutter/material.dart';
import '../../models/proposal_model.dart';
import '../../models/usage_limits_model.dart';
import '../../services/api_service.dart';
import 'project_details_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

class MyProposalsScreen extends StatefulWidget {
  const MyProposalsScreen({super.key});

  @override
  State<MyProposalsScreen> createState() => _MyProposalsScreenState();
}

class _MyProposalsScreenState extends State<MyProposalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Proposal> proposals = [];
  List<Proposal> pendingProposals = [];
  List<Proposal> acceptedProposals = [];
  List<Proposal> rejectedProposals = [];

  bool loading = true;
  bool _loadingUsage = true;
  UsageLimits? _usage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchProposals();
    _loadUsage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsage() async {
    setState(() => _loadingUsage = true);
    try {
      final response = await ApiService.getUserUsage();
      if (response['usage'] != null) {
        setState(() {
          _usage = UsageLimits.fromJson(response['usage']);
          _loadingUsage = false;
        });
      } else {
        setState(() => _loadingUsage = false);
      }
    } catch (e) {
      print('Error loading usage: $e');
      setState(() => _loadingUsage = false);
    }
  }

  Future<void> fetchProposals() async {
    setState(() => loading = true);

    try {
      final data = await ApiService.getMyProposals();

      setState(() {
        proposals = data.map((json) => Proposal.fromJson(json)).toList();

        pendingProposals = proposals
            .where((p) => p.status == 'pending')
            .toList();
        acceptedProposals = proposals
            .where((p) => p.status == 'accepted')
            .toList();
        rejectedProposals = proposals
            .where((p) => p.status == 'rejected')
            .toList();

        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      Fluttertoast.showToast(msg: "Error loading proposals");
    }
  }

  Widget _buildProposalsLimitIndicator() {
    if (_loadingUsage || _usage == null) return const SizedBox.shrink();
    if (_usage!.proposalsLimit == null) return const SizedBox.shrink();

    final percentage = _usage!.proposalsProgress;
    final remaining = _usage!.remainingProposals;
    final isLimitReached = remaining <= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLimitReached
            ? Colors.red.shade50
            : AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLimitReached
              ? Colors.red.shade200
              : AppColors.accent.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.production_quantity_limits,
                    size: 18,
                    color: isLimitReached ? Colors.red : AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Proposals This Month',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isLimitReached ? Colors.red : AppColors.accent,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLimitReached
                      ? Colors.red.withOpacity(0.1)
                      : AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_usage!.proposalsUsed} / ${_usage!.proposalsLimit}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isLimitReached ? Colors.red : AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                isLimitReached ? Colors.red : AppColors.accent,
              ),
              minHeight: 6,
            ),
          ),
          if (isLimitReached)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning,
                      size: 14,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have reached your proposal limit. Upgrade to submit more.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/subscription/plans');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Upgrade',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (remaining <= 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '✨ You have $remaining proposal${remaining > 1 ? 's' : ''} remaining this month.',
                style: TextStyle(fontSize: 11, color: AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'PENDING';
        break;
      case 'accepted':
        statusColor = AppColors.green;
        statusIcon = Icons.check_circle;
        statusText = 'ACCEPTED';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'REJECTED';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildProposalCard(Proposal proposal) {
    final statusColor = _getStatusColor(proposal.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (proposal.project != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProjectDetailsScreen(projectId: proposal.project!.id!),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        proposal.project?.title ?? 'Unknown Project',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2B55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(proposal.status),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.accent, AppColors.accentLight],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.transparent,
                        backgroundImage:
                            proposal.project?.client?.avatar != null &&
                                proposal.project!.client!.avatar!.isNotEmpty
                            ? NetworkImage(proposal.project!.client!.avatar!)
                            : null,
                        child:
                            proposal.project?.client?.avatar == null ||
                                proposal.project!.client!.avatar!.isEmpty
                            ? Text(
                                proposal.project?.client?.name?[0]
                                        .toUpperCase() ??
                                    'C',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            proposal.project?.client?.name ?? 'Unknown Client',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(proposal.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proposal.proposalText ?? 'No message provided',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    size: 14,
                                    color: AppColors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '\$${proposal.price?.toStringAsFixed(0) ?? '0'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${proposal.deliveryTime} days',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (proposal.status == 'accepted' && proposal.project != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/contract',
                          arguments: {
                            'contractId': proposal.contractId,
                            'userRole': 'freelancer',
                          },
                        );
                      },
                      icon: const Icon(
                        Icons.work_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Start Working",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return AppColors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildProposalsList(List<Proposal> proposalsList) {
    if (proposalsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 40,
                color: AppColors.accent.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "No proposals in this category",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchProposals,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: proposalsList.length,
        itemBuilder: (context, index) {
          final proposal = proposalsList[index];
          return _buildProposalCard(proposal);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: const Text(
          "My Proposals",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2B55),
          ),
        ),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.cardBg,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              labelColor: Color(0xFF2D2B55),
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: "All (${proposals.length})"),
                Tab(text: "Pending (${pendingProposals.length})"),
                Tab(text: "Accepted (${acceptedProposals.length})"),
                Tab(text: "Rejected (${rejectedProposals.length})"),
              ],
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(
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
                  Text(
                    "Loading proposals...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : proposals.isEmpty
          ? Center(
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
                      Icons.send_outlined,
                      size: 50,
                      color: AppColors.accent.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No Proposals Yet",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2B55),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Browse projects and submit your first proposal",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/projects');
                    },
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text("Find Projects"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildProposalsLimitIndicator(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProposalsList(proposals),
                      _buildProposalsList(pendingProposals),
                      _buildProposalsList(acceptedProposals),
                      _buildProposalsList(rejectedProposals),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
