// screens/client/project_proposals_screen.dart
import 'package:flutter/material.dart';
import 'package:freelancer_platform/models/project_model.dart';
import 'package:freelancer_platform/models/usage_limits_model.dart';
import 'package:freelancer_platform/models/user_model.dart';
import 'package:freelancer_platform/screens/client/sow_generator_screen.dart';
import '../../services/api_service.dart';
import '../../models/proposal_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../interview/interviews_screen.dart';
import 'compare_freelancers_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class ProjectProposalsScreen extends StatefulWidget {
  final int projectId;
  const ProjectProposalsScreen({super.key, required this.projectId});

  @override
  State<ProjectProposalsScreen> createState() => _ProjectProposalsScreenState();
}

class _ProjectProposalsScreenState extends State<ProjectProposalsScreen> {
  List<Proposal> proposals = [];
  List<Map<String, dynamic>> suggestedFreelancers = [];
  bool loading = true;
  bool loadingSuggestions = true;
  bool _isSendingInterview = false;
  bool _loadingSuggestions = false;
  bool _isProcessing = false;
  bool _isGeneratingSOW = false;
  UsageLimits? _usage;

  @override
  void initState() {
    super.initState();
    fetchProposals();
    fetchSuggestedFreelancers();
    _loadUsage();
  }

  bool _isDarkMode() {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Future<void> _loadUsage() async {
    final r = await ApiService.getUserUsage();
    if (!mounted) return;
    if (r['success'] == true && r['usage'] != null) {
      setState(() {
        _usage = UsageLimits.fromJson(Map<String, dynamic>.from(r['usage']));
      });
    }
  }

  bool _consumeInterviewLimit(Map<String, dynamic> result, AppLocalizations t) {
    if (result['error']?.toString() == 'interview_limit') {
      Fluttertoast.showToast(
        msg: result['message']?.toString() ?? t.interviewLimitReached,
        backgroundColor: AppColors.danger,
        timeInSecForIosWeb: 5,
      );
      _loadUsage();
      return true;
    }
    return false;
  }

  Widget _interviewUsageStrip(AppLocalizations t) {
    final u = _usage;
    final isDark = _isDarkMode();
    if (u == null || !u.hasInterviewLimit) return const SizedBox.shrink();
    final rem = u.interviewsRemaining;
    final lim = u.interviewsLimit;
    if (rem == null || lim == null) return const SizedBox.shrink();

    final isLow = rem <= 2;
    final isZero = rem <= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isLow
            ? (isDark
                  ? AppColors.warningBg.withOpacity(0.2)
                  : AppColors.warningBg)
            : (isDark ? AppColors.darkSurface : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isZero
              ? AppColors.danger.withOpacity(0.3)
              : AppColors.accent.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.interpreter_mode,
            color: isZero ? AppColors.danger : AppColors.accent,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isZero
                  ? t.noInterviewInvitationsLeft(lim)
                  : t.interviewInvitationsLeft(rem, lim),
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
              ),
            ),
          ),
          if (isLow)
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/subscription/plans'),
              child: Text(t.upgrade, style: TextStyle(color: AppColors.accent)),
            ),
        ],
      ),
    );
  }

  Future<void> fetchProposals() async {
    setState(() => loading = true);
    final data = await ApiService.getProjectProposals(widget.projectId);
    setState(() {
      proposals = data.map((json) => Proposal.fromJson(json)).toList();
      loading = false;
    });
  }

  Future<void> fetchSuggestedFreelancers() async {
    setState(() => loadingSuggestions = true);
    final result = await ApiService.getSuggestedFreelancers(widget.projectId);
    setState(() {
      if (result['success'] == true && result['suggestions'] != null) {
        suggestedFreelancers = List<Map<String, dynamic>>.from(
          result['suggestions'],
        );
      }
      loadingSuggestions = false;
    });
  }

  Future<void> handleProposalStatus(
    int proposalId,
    String status,
    AppLocalizations t,
  ) async {
    setState(() => _isProcessing = true);

    try {
      final result = await ApiService.updateProposalStatus(
        proposalId: proposalId,
        status: status,
      );

      if (result['success'] == true || result['proposal'] != null) {
        Fluttertoast.showToast(msg: t.proposalStatusUpdated(status));

        if (status == 'accepted' && result['contract'] != null) {
          final contractId = result['contract']['id'];
          await _handleAcceptedProposal(proposalId, contractId, t);
        } else {
          fetchProposals();
          fetchSuggestedFreelancers();
        }
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? t.errorUpdatingProposal,
          backgroundColor: AppColors.danger,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: '${t.error}: $e',
        backgroundColor: AppColors.danger,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleAcceptedProposal(
    int proposalId,
    int contractId,
    AppLocalizations t,
  ) async {
    try {
      final proposalsData = await ApiService.getProjectProposals(
        widget.projectId,
      );
      final proposalJson = proposalsData.firstWhere(
        (p) => p['id'] == proposalId,
        orElse: () => null,
      );

      if (proposalJson == null) throw Exception(t.proposalDataNotFound);

      final proposal = Proposal.fromJson(proposalJson);

      Project? projectData;
      User? freelancerData;

      if (proposal.project != null) {
        projectData = proposal.project;
      } else if (proposal.projectId != null) {
        final projectResponse = await ApiService.getProjectById(
          proposal.projectId!,
        );
        if (projectResponse['project'] != null) {
          projectData = Project.fromJson(projectResponse['project']);
        }
      }

      if (projectData == null) {
        final projectResponse = await ApiService.getProjectById(
          widget.projectId,
        );
        if (projectResponse['project'] != null) {
          projectData = Project.fromJson(projectResponse['project']);
        }
      }

      if (proposal.freelancer != null) {
        freelancerData = proposal.freelancer;
      } else if (proposal.userId != null) {
        final freelancerResponse = await ApiService.getFreelancerPublicProfile(
          proposal.userId!,
        );
        if (freelancerResponse['user'] != null) {
          freelancerData = User.fromJson(freelancerResponse['user']);
        }
      }

      if (projectData == null || freelancerData == null) {
        throw Exception(t.missingProjectOrFreelancerData);
      }

      final completeProposal = Proposal(
        id: proposal.id,
        projectId: proposal.projectId,
        userId: proposal.userId,
        price: proposal.price,
        deliveryTime: proposal.deliveryTime,
        proposalText: proposal.proposalText,
        status: proposal.status,
        createdAt: proposal.createdAt,
        project: projectData,
        freelancer: freelancerData,
        freelancerProfile: proposal.freelancerProfile,
        milestones: proposal.milestones,
        contractId: proposal.contractId,
      );

      await _navigateToSOWGenerator(completeProposal, contractId, t);
    } catch (e) {
      Fluttertoast.showToast(
        msg: '${t.error}: $e',
        backgroundColor: AppColors.danger,
      );
    }
  }

  Future<void> _navigateToSOWGenerator(
    Proposal proposal,
    int contractId,
    AppLocalizations t,
  ) async {
    if (proposal.project == null ||
        proposal.freelancer == null ||
        proposal.price == null) {
      Fluttertoast.showToast(
        msg: t.missingProjectOrFreelancerData,
        backgroundColor: AppColors.danger,
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SOWGeneratorScreen(
          project: proposal.project!,
          freelancer: proposal.freelancer!,
          agreedAmount: proposal.price!,
          contractId: contractId,
          proposalId: proposal.id!,
        ),
      ),
    );

    if (result == true) {
      Navigator.pushNamed(
        context,
        '/contract',
        arguments: {'contractId': contractId, 'userRole': 'client'},
      );
    }
  }

  Color _getMatchColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.info;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.projectProposals,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? AppColors.darkTextPrimary : Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? AppColors.primaryDark : Colors.grey.shade200,
            height: 1,
          ),
        ),
        actions: [
          if (suggestedFreelancers.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.compare_arrows, color: AppColors.accent),
              onSelected: (value) {
                if (value == 'compare') {
                  final freelancerIds = suggestedFreelancers
                      .map((f) => f['id'] as int)
                      .toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompareFreelancersScreen(
                        projectId: widget.projectId,
                        freelancerIds: freelancerIds,
                      ),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'compare',
                  child: Row(
                    children: [
                      Icon(Icons.compare_arrows, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text(t.compareFreelancers),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : Colors.grey.shade600,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _interviewUsageStrip(t)),

                if (!loadingSuggestions && suggestedFreelancers.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildSuggestedFreelancersSection(t, isDark),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          t.proposals,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${proposals.length}',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (proposals.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState(t, isDark))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _buildProposalCard(proposals[index], t, isDark),
                      ),
                      childCount: proposals.length,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSuggestedFreelancersSection(AppLocalizations t, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  t.aiRecommendedFreelancers,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: suggestedFreelancers.length,
              itemBuilder: (context, index) {
                final f = suggestedFreelancers[index];
                return _buildSuggestedFreelancerCard(f, t, isDark);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSuggestedFreelancerCard(
    Map<String, dynamic> f,
    AppLocalizations t,
    bool isDark,
  ) {
    final matchScore = f['matchScore'] ?? 0;
    final matchColor = _getMatchColor(matchScore);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: matchColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: matchColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: matchColor),
                  const SizedBox(width: 4),
                  Text(
                    '${matchScore}% ${t.match}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: matchColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isDark
                          ? AppColors.primaryDark
                          : Colors.blueGrey.shade100,
                      backgroundImage: f['avatar'] != null
                          ? NetworkImage('http://localhost:5000${f['avatar']}')
                          : null,
                      child: f['avatar'] == null
                          ? Text(
                              f['name']?[0].toUpperCase() ?? 'F',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f['name'] ?? t.unknown,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.dark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (f['title'] != null)
                            Text(
                              f['title'],
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (f['skills'] != null)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (f['skills'] as List)
                        .take(3)
                        .map(
                          (skill) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              skill,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const Spacer(),
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.star,
                      value:
                          (f['rating'] as double?)?.toStringAsFixed(1) ?? '0.0',
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.work_outline,
                      value: '${f['experience'] ?? 0} ${t.years}',
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Fluttertoast.showToast(
                        msg: '${t.invitationSent} ${f['name']}',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: BorderSide(color: AppColors.success),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      t.inviteToProject,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations t, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inbox,
          size: 80,
          color: isDark ? AppColors.darkTextHint : Colors.grey.shade300,
        ),
        const SizedBox(height: 16),
        Text(
          t.noProposalsYet,
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.whenFreelancersSubmitProposals,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? AppColors.darkTextHint : Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(
    Proposal proposal,
    AppLocalizations t,
    bool isDark,
  ) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (proposal.status) {
      case 'pending':
        statusColor = AppColors.warning;
        statusText = t.pending;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'accepted':
        statusColor = AppColors.success;
        statusText = t.accepted;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = AppColors.danger;
        statusText = t.rejected;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.gray;
        statusText = proposal.status ?? t.unknown;
        statusIcon = Icons.help;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: proposal.status == 'accepted'
                  ? AppColors.successBg.withOpacity(isDark ? 0.15 : 1)
                  : proposal.status == 'rejected'
                  ? AppColors.dangerBg.withOpacity(isDark ? 0.15 : 1)
                  : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isDark
                          ? AppColors.primaryDark
                          : Colors.blueGrey.shade100,
                      backgroundImage: proposal.freelancer?.avatar != null
                          ? NetworkImage(proposal.freelancer!.avatar!)
                          : null,
                      child: proposal.freelancer?.avatar == null
                          ? Text(
                              proposal.freelancer?.name?[0].toUpperCase() ??
                                  'F',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            proposal.freelancer?.name ?? t.unknown,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.dark,
                            ),
                          ),
                          if (proposal.freelancerProfile?.title != null)
                            Text(
                              proposal.freelancerProfile!.title!,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : Colors.grey.shade600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildInfoChip(
                                icon: Icons.star,
                                value:
                                    proposal.freelancerProfile?.rating
                                        ?.toStringAsFixed(1) ??
                                    '0.0',
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                icon: Icons.work_outline,
                                value:
                                    '${proposal.freelancerProfile?.experienceYears ?? 0} ${t.years}',
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (proposal.status == 'pending') ...[
                  const SizedBox(height: 16),
                  _buildActionButtons(proposal, t, isDark),
                ],
              ],
            ),
          ),
          _buildProposalContent(proposal, t, isDark, statusColor),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    Proposal proposal,
    AppLocalizations t,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/negotiation', arguments: proposal);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.info,
              side: BorderSide(color: AppColors.info),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.handshake, size: 18),
                const SizedBox(width: 8),
                Text(t.negotiate),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'manual') {
                _showInterviewTimePicker(proposal, t);
              } else if (value == 'smart') {
                _sendSmartInterviewInvitation(proposal, t);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.interpreter_mode,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.interview,
                    style: const TextStyle(color: AppColors.primaryDark),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.primaryDark,
                  ),
                ],
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'manual',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: AppColors.info),
                    const SizedBox(width: 8),
                    Text(t.manualChooseTimes),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'smart',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(t.smartAIOptimized),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => handleProposalStatus(proposal.id!, 'accepted', t),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 18),
                SizedBox(width: 8),
                Text("Accept"),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => handleProposalStatus(proposal.id!, 'rejected', t),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, size: 18),
                SizedBox(width: 8),
                Text("Reject"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProposalContent(
    Proposal proposal,
    AppLocalizations t,
    bool isDark,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              proposal.proposalText ?? t.noDescriptionProvided,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successBg.withOpacity(isDark ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.budget,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 18,
                            color: AppColors.success,
                          ),
                          Text(
                            '\$${proposal.price?.toStringAsFixed(0) ?? '0'}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg.withOpacity(isDark ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.delivery,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${proposal.deliveryTime ?? 0} ${t.days}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (proposal.status == 'accepted') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingSOW
                        ? null
                        : () => _showSOWGenerator(proposal),
                    icon: _isGeneratingSOW
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.description, size: 18),
                    label: Text(_isGeneratingSOW ? t.creating : t.generateSOW),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Fluttertoast.showToast(msg: t.viewContractComingSoon);
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: Text(t.viewContract),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: BorderSide(color: AppColors.info),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successBg.withOpacity(isDark ? 0.15 : 1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.proposalAccepted,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          t.contractCreatedMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (proposal.status == 'rejected')
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerBg.withOpacity(isDark ? 0.15 : 1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppColors.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.proposalRejected,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                        Text(
                          t.proposalRejectedMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.danger.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showSOWGenerator(Proposal proposal) async {
    setState(() => _isGeneratingSOW = true);
    final t = AppLocalizations.of(context)!;

    try {
      Project? projectData;
      User? freelancerData;

      final actualProjectId = proposal.projectId ?? widget.projectId;
      final projectResponse = await ApiService.getProjectById(actualProjectId);

      if (projectResponse['project'] != null) {
        projectData = Project.fromJson(projectResponse['project']);
      } else {
        final allProjects = await ApiService.getMyProjects2();
        final foundProject = allProjects.firstWhere(
          (p) => p['id'] == actualProjectId,
          orElse: () => null,
        );
        if (foundProject != null) projectData = Project.fromJson(foundProject);
      }

      if (proposal.freelancer != null) {
        freelancerData = proposal.freelancer;
      } else if (proposal.userId != null) {
        final freelancerResponse = await ApiService.getFreelancerPublicProfile(
          proposal.userId!,
        );
        if (freelancerResponse['user'] != null) {
          freelancerData = User.fromJson(freelancerResponse['user']);
        }
      }

      if (projectData == null || freelancerData == null)
        throw Exception(t.missingProjectOrFreelancerData);

      final contractResult = await ApiService.createContractDirectly(
        proposalId: proposal.id!,
        agreedAmount: proposal.price ?? 0,
        milestones: proposal.milestones,
      );

      if (contractResult['success'] == true &&
          contractResult['contract'] != null) {
        final contractId = contractResult['contract']['id'];
        setState(() => _isGeneratingSOW = false);

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SOWGeneratorScreen(
              project: projectData!,
              freelancer: freelancerData!,
              agreedAmount: proposal.price!,
              contractId: contractId,
              proposalId: proposal.id!,
            ),
          ),
        );

        if (result == true) {
          Navigator.pushNamed(
            context,
            '/contract',
            arguments: {'contractId': contractId, 'userRole': 'client'},
          );
        }
      } else {
        setState(() => _isGeneratingSOW = false);
        Fluttertoast.showToast(
          msg: contractResult['message'] ?? t.failedToCreateContract,
          backgroundColor: AppColors.danger,
        );
      }
    } catch (e) {
      setState(() => _isGeneratingSOW = false);
      Fluttertoast.showToast(
        msg: '${t.error}: $e',
        backgroundColor: AppColors.danger,
      );
    }
  }

  Future<void> _sendSmartInterviewInvitation(
    Proposal proposal,
    AppLocalizations t,
  ) async {
    setState(() => _isSendingInterview = true);

    final result = await ApiService.createSmartInterviewInvitation(
      proposalId: proposal.id!,
      message: t.aiInterviewInvitationMessage,
      durationMinutes: 30,
    );

    setState(() => _isSendingInterview = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(
        msg: t.smartInterviewInvitationSent,
        backgroundColor: AppColors.accent,
      );
      final suggestedTimes = result['suggestedTimes'] as List?;
      if (suggestedTimes != null && suggestedTimes.isNotEmpty) {
        _showSuggestedTimesDialog(suggestedTimes, t);
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InterviewsScreen()),
      );
    } else {
      if (!_consumeInterviewLimit(Map<String, dynamic>.from(result), t)) {
        Fluttertoast.showToast(
          msg: result['message'] ?? t.errorSendingInvitation,
          backgroundColor: AppColors.danger,
        );
      }
    }
  }

  void _showSuggestedTimesDialog(List<dynamic> times, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(t.aiSuggestedTimesSent),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.aiTimesSentDescription,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...times.map((time) {
              final dateTime = DateTime.parse(time.toString());
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(dateTime, t),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.gotIt),
          ),
        ],
      ),
    );
  }

  Future<void> _showInterviewTimePicker(
    Proposal proposal,
    AppLocalizations t,
  ) async {
    final List<DateTime> selectedTimes = [];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.calendar_month, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(t.scheduleInterview),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.selectPreferredTimes,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ...selectedTimes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final time = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDateTime(time, t),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () =>
                                setState(() => selectedTimes.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (selectedTimes.length < 3)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 2),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 10, minute: 0),
                          );
                          if (time != null) {
                            final fullDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            setState(() => selectedTimes.add(fullDateTime));
                          }
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: Text(t.addTime),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBg,
                        foregroundColor: AppColors.accent,
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: t.optionalMessageHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t.cancel),
              ),
              ElevatedButton(
                onPressed: selectedTimes.isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                child: Text(t.sendInvitation),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && selectedTimes.isNotEmpty) {
      await _sendInterviewInvitation(proposal, selectedTimes, t);
    }
  }

  Future<void> _sendInterviewInvitation(
    Proposal proposal,
    List<DateTime> times,
    AppLocalizations t,
  ) async {
    setState(() => _isSendingInterview = true);

    final result = await ApiService.createInterviewInvitation(
      proposalId: proposal.id!,
      suggestedTimes: times,
      message: t.interviewInvitationMessage,
      durationMinutes: 30,
    );

    setState(() => _isSendingInterview = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: t.interviewInvitationSent);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InterviewsScreen()),
      );
    } else {
      if (!_consumeInterviewLimit(Map<String, dynamic>.from(result), t)) {
        Fluttertoast.showToast(
          msg: result['message'] ?? t.errorSendingInvitation,
          backgroundColor: AppColors.danger,
        );
      }
    }
  }

  String _formatDateTime(DateTime date, AppLocalizations t) {
    return '${date.day}/${date.month}/${date.year} ${t.at} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
