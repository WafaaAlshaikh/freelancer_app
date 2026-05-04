// screens/client/project_details_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/project_model.dart';
import '../../models/proposal_model.dart';
import 'project_proposals_screen.dart';
import 'edit_project_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  Project? project;
  List<Proposal> proposals = [];
  Map<String, dynamic>? contract;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProjectDetails();
  }

  Future<void> fetchProjectDetails() async {
    setState(() => loading = true);

    final result = await ApiService.getProjectById(widget.projectId);

    if (result['project'] != null) {
      setState(() {
        project = Project.fromJson(result['project']);
        if (result['proposals'] != null) {
          proposals = (result['proposals'] as List)
              .map((p) => Proposal.fromJson(p))
              .toList();
        }
        contract = result['contract'];
        loading = false;
      });
    } else {
      setState(() => loading = false);
      final t = AppLocalizations.of(context)!;
      Fluttertoast.showToast(msg: t.errorLoadingProjectDetails);
    }
  }

  Future<void> _deleteProject() async {
    final t = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteProject),
        content: Text(t.deleteProjectConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await ApiService.deleteProject(widget.projectId);
      if (result['message'] != null) {
        Fluttertoast.showToast(msg: result['message']);
        Navigator.pop(context, true);
      }
    }
  }

  bool _isDarkMode() {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.projectDetails),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? AppColors.darkTextPrimary : Colors.black,
        elevation: 0,
        actions: [
          if (project?.status == 'open')
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProjectScreen(project: project!),
                  ),
                ).then((updated) {
                  if (updated == true) fetchProjectDetails();
                });
              },
              tooltip: t.editProfile,
            ),
          if (project?.status == 'open')
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteProject,
              tooltip: t.delete,
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : project == null
          ? Center(child: Text(t.projectNotFound))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(t, isDark),
                  const SizedBox(height: 20),
                  _buildProjectDetailsCard(t, isDark),
                  const SizedBox(height: 20),
                  if (project!.status == 'open' ||
                      project!.status == 'in_progress')
                    _buildProposalsSection(t, isDark),
                  if (contract != null) _buildContractCard(t, isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(AppLocalizations t, bool isDark) {
    final statusColor = _getStatusColorForProject(project!.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(
            project!.status == 'open'
                ? Icons.folder_open
                : project!.status == 'in_progress'
                ? Icons.engineering
                : Icons.check_circle,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${t.projectStatusLabel}: ${_getStatusText(t)}",
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (project!.status == 'open')
                  Text(
                    t.acceptingProposals,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : Colors.grey.shade600,
                    ),
                  ),
                if (project!.status == 'in_progress')
                  Text(
                    t.projectInProgress,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          if (project!.status == 'in_progress')
            ElevatedButton(
              onPressed: () async {
                final result = await ApiService.completeProject(project!.id!);
                if (result['message'] != null) {
                  Fluttertoast.showToast(msg: result['message']);
                  fetchProjectDetails();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: Text(t.completeProject),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectDetailsCard(AppLocalizations t, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.primaryDark : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project!.title ?? t.untitled,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  "${t.posted}: ${_formatDate(project!.createdAt, t)}",
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.remove_red_eye,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  "${project!.views ?? 0} ${t.views}",
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),

            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.attach_money,
                    label: t.budget,
                    value: "\$${project!.budget?.toStringAsFixed(0)}",
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.access_time,
                    label: t.duration,
                    value: "${project!.duration} ${t.days}",
                    color: AppColors.info,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (project!.category != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primaryDark : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  project!.category!,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            Text(
              t.description,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              project!.description ?? t.noDescription,
              style: TextStyle(
                height: 1.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
              ),
            ),

            if (project!.skills != null && project!.skills!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    t.requiredSkills,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: project!.skills!
                        .map(
                          (skill) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              skill,
                              style: TextStyle(color: AppColors.accent),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProposalsSection(AppLocalizations t, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${t.proposals} (${proposals.length})",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
              ),
            ),
            if (proposals.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProjectProposalsScreen(projectId: project!.id!),
                    ),
                  ).then((_) => fetchProjectDetails());
                },
                child: Text(t.viewAll),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (proposals.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.primaryDark : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox,
                  size: 48,
                  color: isDark ? AppColors.darkTextHint : Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  t.noProposalsYet,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: proposals.length > 3 ? 3 : proposals.length,
            itemBuilder: (context, index) {
              final proposal = proposals[index];
              return _buildProposalCard(proposal, isDark, t);
            },
          ),
      ],
    );
  }

  Widget _buildContractCard(AppLocalizations t, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                t.contractDetails,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            t.contractDocumentNotAvailable,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(
    Proposal proposal,
    bool isDark,
    AppLocalizations t,
  ) {
    final statusColor = _getStatusColor(proposal.status);
    final statusText = _getProposalStatusText(proposal.status, t);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.primaryDark : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark
                    ? AppColors.primaryDark
                    : Colors.blueGrey.shade300,
                backgroundImage: proposal.freelancer?.avatar != null
                    ? NetworkImage(proposal.freelancer!.avatar!)
                    : null,
                child: proposal.freelancer?.avatar == null
                    ? Text(
                        proposal.freelancer?.name?[0].toUpperCase() ?? 'F',
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
                      proposal.freelancer?.name ?? t.unknown,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
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
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            proposal.proposalText ?? t.noMessageProvided,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.attach_money, size: 16, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                '\$${proposal.price?.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: AppColors.info),
              const SizedBox(width: 4),
              Text(
                '${proposal.deliveryTime} ${t.days}',
                style: TextStyle(color: AppColors.info),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.gray;
    }
  }

  Color _getStatusColorForProject(String? status) {
    switch (status) {
      case 'open':
        return AppColors.info;
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.gray;
    }
  }

  String _getStatusText(AppLocalizations t) {
    switch (project?.status) {
      case 'open':
        return t.open;
      case 'in_progress':
        return t.inProgress;
      case 'completed':
        return t.completed;
      default:
        return project?.status ?? t.unknown;
    }
  }

  String _getProposalStatusText(String? status, AppLocalizations t) {
    switch (status) {
      case 'pending':
        return t.pending;
      case 'accepted':
        return t.accepted;
      case 'rejected':
        return t.rejected;
      default:
        return t.pending;
    }
  }

  String _formatDate(DateTime? date, AppLocalizations t) {
    if (date == null) return t.unknown;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${t.daysAgo}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${t.hoursAgo}';
    } else {
      return t.justNow;
    }
  }
}
