// screens/client/project_details_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/project_model.dart';
import '../../models/proposal_model.dart';
import 'project_proposals_screen.dart';
import 'edit_project_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
      Fluttertoast.showToast(msg: "Error loading project details");
    }
  }

  Future<void> _deleteProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Project"),
        content: const Text("Are you sure you want to delete this project?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Details"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
            ),
          if (project?.status == 'open')
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteProject,
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : project == null
              ? const Center(child: Text("Project not found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: project!.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: project!.statusColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              project!.status == 'open'
                                  ? Icons.folder_open
                                  : project!.status == 'in_progress'
                                      ? Icons.engineering
                                      : Icons.check_circle,
                              color: project!.statusColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Status: ${project!.statusText}",
                                    style: TextStyle(
                                      color: project!.statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (project!.status == 'open')
                                    const Text(
                                      "Accepting proposals",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  if (project!.status == 'in_progress')
                                    const Text(
                                      "Project in progress",
                                      style: TextStyle(fontSize: 12),
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
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text("Complete"),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project!.title ?? 'Untitled',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Posted: ${_formatDate(project!.createdAt)}",
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.remove_red_eye,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${project!.views ?? 0} views",
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      icon: Icons.attach_money,
                                      label: "Budget",
                                      value: "\$${project!.budget?.toStringAsFixed(0)}",
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInfoCard(
                                      icon: Icons.access_time,
                                      label: "Duration",
                                      value: "${project!.duration} days",
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (project!.category != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    project!.category!,
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                ),
                              const SizedBox(height: 16),

                              const Text(
                                "Description",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                project!.description ?? 'No description',
                                style: const TextStyle(height: 1.5),
                              ),

                              if (project!.skills != null && project!.skills!.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    const Text(
                                      "Required Skills",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: project!.skills!
                                          .map((skill) => Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  skill,
                                                  style: TextStyle(
                                                      color: Colors.blue.shade700),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (project!.status == 'open' || project!.status == 'in_progress')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Proposals (${proposals.length})",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: proposals.isNotEmpty
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ProjectProposalsScreen(
                                                projectId: project!.id!,
                                              ),
                                            ),
                                          ).then((_) => fetchProjectDetails());
                                        }
                                      : null,
                                  child: const Text("View All"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (proposals.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.inbox,
                                        size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      "No proposals yet",
                                      style: TextStyle(color: Colors.grey.shade600),
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
                                  return _buildProposalCard(proposal);
                                },
                              ),
                          ],
                        ),

                      if (contract != null)
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.description,
                                      color: Colors.green.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Contract Details",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Add contract details here
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
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

  Widget _buildProposalCard(Proposal proposal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blueGrey.shade300,
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
                      proposal.freelancer?.name ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (proposal.freelancerProfile?.title != null)
                      Text(
                        proposal.freelancerProfile!.title!,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(proposal.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  proposal.status?.toUpperCase() ?? 'PENDING',
                  style: TextStyle(
                    color: _getStatusColor(proposal.status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            proposal.proposalText ?? 'No message',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.attach_money, size: 16, color: Colors.green.shade700),
              const SizedBox(width: 4),
              Text(
                '\$${proposal.price?.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 4),
              Text(
                '${proposal.deliveryTime} days',
                style: TextStyle(color: Colors.blue.shade700),
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
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
}