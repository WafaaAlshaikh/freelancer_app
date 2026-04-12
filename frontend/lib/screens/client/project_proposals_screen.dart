// screens/client/project_proposals_screen.dart
import 'package:flutter/material.dart';
import 'package:freelancer_platform/models/project_model.dart';
import 'package:freelancer_platform/models/user_model.dart';
import 'package:freelancer_platform/screens/client/sow_generator_screen.dart';
import '../../services/api_service.dart';
import '../../models/proposal_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../interview/interviews_screen.dart';
import 'compare_freelancers_screen.dart';

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

  @override
  void initState() {
    super.initState();
    fetchProposals();
    fetchSuggestedFreelancers();
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

  Future<void> handleProposalStatus(int proposalId, String status) async {
    setState(() => _isProcessing = true);

    try {
      final result = await ApiService.updateProposalStatus(
        proposalId: proposalId,
        status: status,
      );

      print('📦 Update proposal status result: $result');

      if (result['success'] == true || result['proposal'] != null) {
        Fluttertoast.showToast(msg: "✅ Proposal $status successfully");

        if (status == 'accepted' && result['contract'] != null) {
          final contractId = result['contract']['id'];
          print('✅ Contract ID received: $contractId');

          final proposalsData = await ApiService.getProjectProposals(
            widget.projectId,
          );
          final proposalJson = proposalsData.firstWhere(
            (p) => p['id'] == proposalId,
            orElse: () => null,
          );

          if (proposalJson == null) {
            throw Exception('Proposal data not found');
          }

          final proposal = Proposal.fromJson(proposalJson);

          Project? projectData;

          if (proposal.project != null) {
            projectData = proposal.project;
            print('✅ Project found in proposal: ${projectData!.title}');
          }

          if (projectData == null && proposal.projectId != null) {
            print(
              '📡 Fetching project from API with ID: ${proposal.projectId}',
            );
            final projectResponse = await ApiService.getProjectById(
              proposal.projectId!,
            );
            print('📦 Project response: $projectResponse');

            if (projectResponse['project'] != null) {
              projectData = Project.fromJson(projectResponse['project']);
              print('✅ Project fetched from API: ${projectData.title}');
            } else if (projectResponse != null &&
                projectResponse['id'] != null) {
              projectData = Project.fromJson(projectResponse);
              print('✅ Project fetched directly: ${projectData.title}');
            }
          }

          if (projectData == null) {
            print(
              '📡 Fetching project from API with widget ID: ${widget.projectId}',
            );
            final projectResponse = await ApiService.getProjectById(
              widget.projectId,
            );

            if (projectResponse['project'] != null) {
              projectData = Project.fromJson(projectResponse['project']);
            } else if (projectResponse != null &&
                projectResponse['id'] != null) {
              projectData = Project.fromJson(projectResponse);
            }
          }

          if (projectData == null) {
            print('📡 Fetching project from projects list');
            final allProjects = await ApiService.getMyProjects2();
            final foundProject = allProjects.firstWhere(
              (p) => p['id'] == (proposal.projectId ?? widget.projectId),
              orElse: () => null,
            );

            if (foundProject != null) {
              projectData = Project.fromJson(foundProject);
              print('✅ Project found in projects list: ${projectData.title}');
            }
          }

          if (projectData == null) {
            print('❌ All attempts to fetch project failed!');
            print('   proposal.projectId: ${proposal.projectId}');
            print('   widget.projectId: ${widget.projectId}');
            throw Exception('Project data not found after multiple attempts');
          }

          User? freelancerData = proposal.freelancer;

          if (freelancerData == null && proposal.userId != null) {
            print('📡 Fetching freelancer data for ID: ${proposal.userId}');
            final freelancerResponse =
                await ApiService.getFreelancerPublicProfile(proposal.userId!);

            if (freelancerResponse['user'] != null) {
              freelancerData = User.fromJson(freelancerResponse['user']);
            } else if (freelancerResponse != null &&
                freelancerResponse['id'] != null) {
              freelancerData = User.fromJson(freelancerResponse);
            }
          }

          if (freelancerData == null) {
            print('⚠️ Could not fetch freelancer data, creating placeholder');
            freelancerData = User(
              id: proposal.userId ?? 0,
              name: proposal.freelancer?.name ?? 'Freelancer',
              email: '',
              avatar: null,
            );
          }

          print('✅ Final project: ${projectData.title}');
          print('✅ Final freelancer: ${freelancerData.name}');

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

          await _navigateToSOWGenerator(completeProposal, contractId);
        } else {
          fetchProposals();
          fetchSuggestedFreelancers();
        }
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Error updating proposal',
          backgroundColor: Colors.red,
        );
      }
    } catch (e, stacktrace) {
      print('❌ Error in handleProposalStatus: $e');
      print('📚 Stacktrace: $stacktrace');
      Fluttertoast.showToast(msg: 'Error: $e', backgroundColor: Colors.red);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _showSOWGeneratorWithContract(
    int proposalId,
    int contractId,
  ) async {
    final proposals = await ApiService.getProjectProposals(widget.projectId);
    final proposal = proposals.firstWhere(
      (p) => p['id'] == proposalId,
      orElse: () => null,
    );

    if (proposal == null) {
      Fluttertoast.showToast(msg: 'Proposal data not found');
      return;
    }

    final proposalObj = Proposal.fromJson(proposal);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SOWGeneratorScreen(
          project: proposalObj.project!,
          freelancer: proposalObj.freelancer!,
          agreedAmount: proposalObj.price!,
          contractId: contractId,
          proposalId: proposalObj.id!,
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
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.blue;
  }

  void _showSOWGenerator(Proposal proposal) async {
    setState(() => _isGeneratingSOW = true);

    try {
      print('🎯 Creating contract for proposal: ${proposal.id}');
      print('🔍 Project ID from widget: ${widget.projectId}');
      print('🔍 Proposal projectId: ${proposal.projectId}');

      Project projectData;
      User freelancerData;

      final actualProjectId = proposal.projectId ?? widget.projectId;
      print('🔍 Using project ID: $actualProjectId');

      print('📡 Fetching project data from API...');
      final projectResponse = await ApiService.getProjectById(actualProjectId);
      print('📦 Project response: $projectResponse');

      if (projectResponse['project'] == null) {
        print('⚠️ Project not found, trying alternative method...');
        final allProjects = await ApiService.getMyProjects2();
        final foundProject = allProjects.firstWhere(
          (p) => p['id'] == actualProjectId,
          orElse: () => null,
        );

        if (foundProject != null) {
          projectData = Project.fromJson(foundProject);
        } else {
          throw Exception('Project data not found for ID: $actualProjectId');
        }
      } else {
        projectData = Project.fromJson(projectResponse['project']);
      }

      print('✅ Project loaded: ${projectData.title}');

      if (proposal.freelancer != null) {
        freelancerData = proposal.freelancer!;
        print('✅ Using existing freelancer data: ${freelancerData.name}');
      } else {
        print('📡 Fetching freelancer data from API...');
        final freelancerResponse = await ApiService.getFreelancerPublicProfile(
          proposal.userId!,
        );
        if (freelancerResponse['user'] != null) {
          freelancerData = User.fromJson(freelancerResponse['user']);
        } else {
          freelancerData = User(
            id: proposal.userId!,
            name: proposal.freelancer?.name ?? 'Freelancer',
            email: '',
            avatar: null,
          );
        }
      }

      print('✅ Freelancer: ${freelancerData.name}');

      final contractResult = await ApiService.createContractDirectly(
        proposalId: proposal.id!,
        agreedAmount: proposal.price ?? 0,
        milestones: proposal.milestones,
      );

      print('📦 Contract result: $contractResult');

      if (contractResult['success'] == true &&
          contractResult['contract'] != null) {
        final contractId = contractResult['contract']['id'];
        print('✅ Contract created with ID: $contractId');

        setState(() => _isGeneratingSOW = false);

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SOWGeneratorScreen(
              project: projectData,
              freelancer: freelancerData,
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
          msg: contractResult['message'] ?? 'Failed to create contract',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      print('❌ Error in _showSOWGenerator: $e');
      setState(() => _isGeneratingSOW = false);
      Fluttertoast.showToast(msg: 'Error: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _navigateToSOWGenerator(
    Proposal proposal,
    int contractId,
  ) async {
    if (proposal.project == null) {
      Fluttertoast.showToast(
        msg: 'Project data is missing. Please refresh and try again.',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (proposal.freelancer == null) {
      Fluttertoast.showToast(
        msg: 'Freelancer data is missing. Please refresh and try again.',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (proposal.price == null) {
      Fluttertoast.showToast(
        msg: 'Price data is missing. Please refresh and try again.',
        backgroundColor: Colors.red,
      );
      return;
    }

    print('✅ Navigating to SOW Generator with:');
    print('   Project: ${proposal.project!.title}');
    print('   Freelancer: ${proposal.freelancer!.name}');
    print('   Price: ${proposal.price}');
    print('   ContractId: $contractId');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Project Proposals",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
        actions: [
          if (suggestedFreelancers.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.compare_arrows, color: Colors.purple),
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
                const PopupMenuItem(
                  value: 'compare',
                  child: Row(
                    children: [
                      Icon(Icons.compare_arrows, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Compare Freelancers'),
                    ],
                  ),
                ),
              ],
            ),

          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                if (!loadingSuggestions && suggestedFreelancers.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
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
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: Colors.amber.shade700,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "AI Recommended Freelancers",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: suggestedFreelancers.length,
                              itemBuilder: (context, index) {
                                final f = suggestedFreelancers[index];
                                return Container(
                                  width: 260,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getMatchColor(
                                              f['matchScore'] ?? 0,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: _getMatchColor(
                                                f['matchScore'] ?? 0,
                                              ).withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.auto_awesome,
                                                size: 12,
                                                color: _getMatchColor(
                                                  f['matchScore'] ?? 0,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${f['matchScore'] ?? 0}% Match',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getMatchColor(
                                                    f['matchScore'] ?? 0,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 28,
                                                  backgroundColor:
                                                      Colors.blueGrey.shade100,
                                                  backgroundImage:
                                                      f['avatar'] != null
                                                      ? NetworkImage(
                                                          'http://localhost:5000${f['avatar']}',
                                                        )
                                                      : null,
                                                  child: f['avatar'] == null
                                                      ? Text(
                                                          f['name']?[0]
                                                                  .toUpperCase() ??
                                                              'F',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        f['name'] ?? 'Unknown',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      if (f['title'] != null)
                                                        Text(
                                                          f['title'],
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors
                                                                .grey
                                                                .shade600,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
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
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 3,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .blue
                                                              .shade50,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          skill,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors
                                                                .blue
                                                                .shade700,
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
                                                      f['rating']
                                                          ?.toStringAsFixed(
                                                            1,
                                                          ) ??
                                                      '0.0',
                                                  color: Colors.amber,
                                                ),
                                                const SizedBox(width: 12),
                                                _buildStatChip(
                                                  icon: Icons.work_outline,
                                                  value:
                                                      '${f['experience'] ?? 0} yrs',
                                                  color: Colors.blue,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),

                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton(
                                                onPressed: () {
                                                  // TODO: Invite freelancer
                                                  Fluttertoast.showToast(
                                                    msg:
                                                        "Invitation sent to ${f['name']}",
                                                  );
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(
                                                    0xff14A800,
                                                  ),
                                                  side: const BorderSide(
                                                    color: Color(0xff14A800),
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                ),
                                                child: const Text(
                                                  "Invite to Project",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          "Proposals",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${proposals.length}',
                            style: TextStyle(
                              color: Colors.blue.shade700,
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
                  SliverFillRemaining(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No proposals yet",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "When freelancers submit proposals,\nthey will appear here",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _buildProposalCard(proposals[index]),
                      ),
                      childCount: proposals.length,
                    ),
                  ),
              ],
            ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendSmartInterviewInvitation(Proposal proposal) async {
    setState(() => _isSendingInterview = true);

    final result = await ApiService.createSmartInterviewInvitation(
      proposalId: proposal.id!,
      message:
          'AI has analyzed availability and suggested optimal times. Please select the time that works best for you.',
      durationMinutes: 30,
    );

    setState(() => _isSendingInterview = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(
        msg:
            '✅ Smart interview invitation sent to freelancer! They will select a time.',
        backgroundColor: Colors.purple,
        textColor: Colors.white,
        timeInSecForIosWeb: 4,
      );

      final suggestedTimes = result['suggestedTimes'] as List?;
      if (suggestedTimes != null && suggestedTimes.isNotEmpty) {
        _showSuggestedTimesDialog(suggestedTimes);
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InterviewsScreen()),
      );
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Error sending smart invitation',
        backgroundColor: Colors.red,
      );
    }
  }

  void _showSuggestedTimesDialog(List<dynamic> times) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple),
            SizedBox(width: 8),
            Text('AI Suggested Times Sent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'The following AI-optimized times have been sent to the freelancer.\nThey will select one that works for them.',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...times.map((time) {
              final dateTime = DateTime.parse(time.toString());
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(dateTime),
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
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendGroupInterviewInvitation(Proposal proposal) async {
    final List<int> selectedFreelancers = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Select Freelancers for Group Interview'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: suggestedFreelancers.length,
                itemBuilder: (context, index) {
                  final f = suggestedFreelancers[index];
                  return CheckboxListTile(
                    value: selectedFreelancers.contains(f['id']),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selectedFreelancers.add(f['id']);
                        } else {
                          selectedFreelancers.remove(f['id']);
                        }
                      });
                    },
                    title: Text(f['name']),
                    subtitle: Text('${f['matchScore']}% match'),
                    secondary: CircleAvatar(
                      backgroundImage: f['avatar'] != null
                          ? NetworkImage(f['avatar'])
                          : null,
                      child: f['avatar'] == null ? Text(f['name'][0]) : null,
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _createGroupInterview(proposal, selectedFreelancers);
                },
                child: Text(
                  'Send to ${selectedFreelancers.length} freelancers',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<DateTime>> _selectMultipleTimes() async {
    final List<DateTime> selectedTimes = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Select Interview Times'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select 1-3 preferred times for the interview',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  ...selectedTimes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final time = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDateTime(time),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                selectedTimes.removeAt(index);
                              });
                            },
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
                            setState(() {
                              selectedTimes.add(fullDateTime);
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Time'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade100,
                        foregroundColor: Colors.purple,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedTimes.isEmpty
                    ? null
                    : () => Navigator.pop(context, selectedTimes),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text('Send Invitations'),
              ),
            ],
          );
        },
      ),
    );

    return selectedTimes;
  }

  Future<void> _createGroupInterview(
    Proposal proposal,
    List<int> freelancerIds,
  ) async {
    final times = await _selectMultipleTimes();
    if (times.isEmpty) return;

    final result = await ApiService.createGroupInterviewInvitation(
      proposalId: proposal.id!,
      freelancerIds: freelancerIds,
      suggestedTimes: times,
      message: 'Group interview for project "${proposal.project?.title}"',
      durationMinutes: 45,
    );

    if (result['success'] == true) {
      Fluttertoast.showToast(
        msg: 'Group invitations sent to ${freelancerIds.length} freelancers',
        backgroundColor: Colors.purple,
      );
    }
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

  void _showInterviewTimePicker(Proposal proposal) async {
    final List<DateTime> selectedTimes = [];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.purple),
                SizedBox(width: 8),
                Text('Schedule Interview'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select 1-3 preferred times for the interview',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  ...selectedTimes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final time = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDateTime(time),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                selectedTimes.removeAt(index);
                              });
                            },
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
                            setState(() {
                              selectedTimes.add(fullDateTime);
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Time'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade100,
                        foregroundColor: Colors.purple,
                      ),
                    ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Add a message for the freelancer (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedTimes.isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text('Send Invitation'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && selectedTimes.isNotEmpty) {
      await _sendInterviewInvitation(proposal, selectedTimes);
    }
  }

  Future<void> _sendInterviewInvitation(
    Proposal proposal,
    List<DateTime> times,
  ) async {
    setState(() => _isSendingInterview = true);

    final result = await ApiService.createInterviewInvitation(
      proposalId: proposal.id!,
      suggestedTimes: times,
      message:
          'I would like to interview you for this project. Please select a time that works for you.',
      durationMinutes: 30,
    );

    setState(() => _isSendingInterview = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(
        msg: '✅ Interview invitation sent with ${times.length} time options!',
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InterviewsScreen()),
      );
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Error sending invitation',
      );
    }
  }

  Future<void> _showSmartTimeSuggestions(Proposal proposal) async {
    setState(() => _loadingSuggestions = true);

    final suggestions = await ApiService.getTimeSuggestions(
      proposalId: proposal.id!,
      freelancerId: proposal.userId!,
    );

    setState(() => _loadingSuggestions = false);

    if (suggestions.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No smart suggestions available. Using manual selection.',
        backgroundColor: Colors.orange,
      );
      _showInterviewTimePicker(proposal);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple),
            SizedBox(width: 8),
            Text('AI Time Suggestions'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'AI analyzed availability and suggests these optimal times:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...suggestions.map((time) {
                return ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.purple),
                  title: Text(_formatDateTime(time)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _sendInterviewWithTime(proposal, [time]);
                  },
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showInterviewTimePicker(proposal);
            },
            child: const Text('Manual Selection'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInterviewWithTime(
    Proposal proposal,
    List<DateTime> times,
  ) async {
    setState(() => _isSendingInterview = true);

    final result = await ApiService.createInterviewInvitation(
      proposalId: proposal.id!,
      suggestedTimes: times,
      message: 'AI-suggested interview time based on availability.',
      durationMinutes: 30,
    );

    setState(() => _isSendingInterview = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: '✅ Interview invitation sent!');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InterviewsScreen()),
      );
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Error sending invitation',
      );
    }
  }

  Widget _buildProposalCard(Proposal proposal) {
    print('🔍 Building proposal card for: ${proposal.id}');
    print('🔍 Proposal status: ${proposal.status}');
    print('🔍 Is pending: ${proposal.status == 'pending'}');

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (proposal.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'Accepted';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = proposal.status ?? 'Unknown';
        statusIcon = Icons.help;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  ? Colors.green.shade50
                  : proposal.status == 'rejected'
                  ? Colors.red.shade50
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
                      backgroundColor: Colors.blueGrey.shade100,
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
                            proposal.freelancer?.name ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (proposal.freelancerProfile?.title != null)
                            Text(
                              proposal.freelancerProfile!.title!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
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
                                    '${proposal.freelancerProfile?.experienceYears ?? 0} yrs',
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/negotiation',
                              arguments: proposal,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.handshake, size: 18),
                              SizedBox(width: 8),
                              Text("Negotiate"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'manual') {
                              _showInterviewTimePicker(proposal);
                            } else if (value == 'smart') {
                              _sendSmartInterviewInvitation(proposal);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.interpreter_mode,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Interview",
                                  style: TextStyle(color: Colors.white),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'manual',
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 18),
                                  SizedBox(width: 8),
                                  Text('Manual (Choose Times)'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'smart',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 18,
                                    color: Colors.purple,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Smart (AI Optimized)'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              handleProposalStatus(proposal.id!, 'accepted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
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
                          onPressed: () =>
                              handleProposalStatus(proposal.id!, 'rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
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
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    proposal.proposalText ?? 'No description provided',
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Budget",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  size: 18,
                                  color: Colors.green.shade700,
                                ),
                                Text(
                                  '\$${proposal.price?.toStringAsFixed(0) ?? '0'}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
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
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Delivery",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${proposal.deliveryTime ?? 0} days',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
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

                if (proposal.status == 'accepted')
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGeneratingSOW
                                ? null
                                : () => _showSOWGenerator(proposal),
                            icon: _isGeneratingSOW
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.description, size: 18),
                            label: Text(
                              _isGeneratingSOW ? 'Creating...' : 'Generate SOW',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
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
                              print(
                                '👁️ View Contract clicked for proposal: ${proposal.id}',
                              );
                              // TODO: جلب contractId من الـ API
                              Fluttertoast.showToast(
                                msg: 'View Contract - Coming Soon',
                              );
                            },
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text('View Contract'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (proposal.status == 'accepted')
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Proposal Accepted",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                "A contract has been created. You can now communicate with the freelancer.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                if (proposal.status == 'rejected')
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Proposal Rejected",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                "This proposal has been rejected. You can still contact the freelancer if needed.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
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
}
