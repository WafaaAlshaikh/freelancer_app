// screens/freelancer/my_proposals_screen.dart
import 'package:flutter/material.dart';
import '../../models/proposal_model.dart';
import '../../services/api_service.dart';
import 'project_details_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchProposals();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Proposals"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xff14A800),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: "All (${proposals.length})"),
            Tab(text: "Pending (${pendingProposals.length})"),
            Tab(text: "Accepted (${acceptedProposals.length})"),
            Tab(text: "Rejected (${rejectedProposals.length})"),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : proposals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "No proposals yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Browse projects and submit your first proposal",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/projects');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff14A800),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text("Find Projects"),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProposalsList(proposals),
                _buildProposalsList(pendingProposals),
                _buildProposalsList(acceptedProposals),
                _buildProposalsList(rejectedProposals),
              ],
            ),
    );
  }

  Widget _buildProposalsList(List<Proposal> proposalsList) {
    if (proposalsList.isEmpty) {
      return Center(
        child: Text(
          "No proposals in this category",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchProposals,
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

  Widget _buildProposalCard(Proposal proposal) {
    Color statusColor;
    IconData statusIcon;

    switch (proposal.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        borderRadius: BorderRadius.circular(12),
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
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          proposal.status?.toUpperCase() ?? 'UNKNOWN',
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

              const SizedBox(height: 12),

              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: proposal.project?.client?.avatar != null
                        ? NetworkImage(proposal.project!.client!.avatar!)
                        : null,
                    child: proposal.project?.client?.avatar == null
                        ? Text(
                            proposal.project?.client?.name?[0].toUpperCase() ??
                                'C',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proposal.project?.client?.name ?? 'Unknown Client',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _formatDate(proposal.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal.proposalText ?? 'No message',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '\$${proposal.price?.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${proposal.deliveryTime} days',
                                style: TextStyle(color: Colors.blue.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (proposal.status == 'accepted' && proposal.project != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
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
                          icon: const Icon(Icons.work, size: 18),
                          label: const Text("Start Project"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xff14A800),
                            side: const BorderSide(color: Color(0xff14A800)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
