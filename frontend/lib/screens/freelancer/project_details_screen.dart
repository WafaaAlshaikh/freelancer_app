// screens/freelancer/project_details_screen.dart

import 'package:flutter/material.dart';
import 'package:freelancer_platform/models/usage_limits_model.dart';
import '../../models/project_model.dart';
import '../../services/api_service.dart';
import 'submit_proposal_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  Project? project;
  bool loading = true;
  bool hasSubmitted = false;
  int? _contractId;
  bool _loadingContract = false;

  bool loadingPricing = false;
  Map<String, dynamic>? smartPricing;
  bool showSmartPricing = false;
  UsageLimits? _usage;
  bool _isFavorite = false;

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await ApiService.removeFromFavorites(widget.projectId);
        setState(() => _isFavorite = false);
        Fluttertoast.showToast(msg: 'Removed from favorites');
      } else {
        await ApiService.addToFavorites(widget.projectId);
        setState(() => _isFavorite = true);
        Fluttertoast.showToast(msg: 'Added to favorites');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> _checkIfFavorite() async {
    try {
      final isFav = await ApiService.isProjectFavorite(widget.projectId);
      setState(() => _isFavorite = isFav);
    } catch (e) {
      print('Error checking favorite: $e');
    }
  }

  Future<void> _loadUsage() async {
    final response = await ApiService.getUserUsage();
    if (response['success'] && response['usage'] != null) {
      setState(() {
        _usage = UsageLimits.fromJson(response['usage']);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProjectDetails();
    checkExistingProposal();
    _loadSmartPricing();
    _loadUsage();
    _checkIfFavorite();
    _loadContractLink();
  }

  Future<void> _loadContractLink() async {
    setState(() => _loadingContract = true);
    try {
      final r = await ApiService.getFreelancerProjectContract(widget.projectId);
      if (!mounted) return;
      final c = r['contract'];
      final id = (c is Map) ? c['id'] : null;
      final parsed = id is int ? id : int.tryParse(id?.toString() ?? '');
      setState(() {
        _contractId = (parsed != null && parsed > 0) ? parsed : null;
        _loadingContract = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingContract = false);
    }
  }

  Future<void> _loadSmartPricing() async {
    if (widget.projectId == null) return;

    setState(() => loadingPricing = true);

    try {
      final response = await ApiService.getSmartPricing(widget.projectId);
      print('📊 Smart pricing response: $response');

      if (response['success'] == true && response['pricing'] != null) {
        setState(() {
          smartPricing = response['pricing'];
          showSmartPricing = true;
          loadingPricing = false;
        });
      } else {
        setState(() => loadingPricing = false);
      }
    } catch (e) {
      print('❌ Error loading smart pricing: $e');
      setState(() => loadingPricing = false);
    }
  }

  Future<void> fetchProjectDetails() async {
    if (!mounted) return;

    try {
      print('📥 Fetching project details for ID: ${widget.projectId}');
      final data = await ApiService.getProjectById(widget.projectId);
      print('📦 Response: $data');

      if (!mounted) return;

      setState(() {
        final rawProject = data['project'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['project'] as Map)
            : Map<String, dynamic>.from(data);
        project = Project.fromJson(rawProject);
        loading = false;
      });
    } catch (e) {
      print('❌ Error loading project details: $e');
      if (!mounted) return;
      setState(() => loading = false);
      Fluttertoast.showToast(msg: "Error loading project details");
    }
  }

  Future<void> checkExistingProposal() async {
    if (!mounted) return;

    try {
      final proposals = await ApiService.getMyProposals();
      if (!mounted) return;

      final existing = proposals.any((p) => p['ProjectId'] == widget.projectId);
      setState(() {
        hasSubmitted = existing;
      });
    } catch (e) {
      print('Error checking proposal: $e');
    }
  }

  String _getAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) return '';
    if (avatar.startsWith('http')) return avatar;
    return 'http://localhost:5000$avatar';
  }

  void _navigateToSubmitProposal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SubmitProposalScreen(project: project!, smartPricing: smartPricing),
      ),
    ).then((submitted) {
      if (submitted == true) {
        setState(() => hasSubmitted = true);
        Fluttertoast.showToast(msg: "Proposal submitted successfully!");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasContract = _contractId != null && _contractId! > 0;
    final isOpen = project?.status == 'open';
    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Details"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: () => _toggleFavorite(),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/ai-chat',
                arguments: {'projectId': widget.projectId},
              );
            },
            tooltip: 'AI Assistant',
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project!.title ?? 'Untitled',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                project!.client?.name ?? 'Unknown Client',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.access_time,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(project!.createdAt),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.attach_money,
                            label: 'Budget',
                            value: '\$${project!.budget?.toStringAsFixed(0)}',
                            color: Colors.green,
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.access_time,
                            label: 'Duration',
                            value: '${project!.duration} days',
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (showSmartPricing && smartPricing != null)
                    if (isOpen)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade50,
                              Colors.orange.shade50,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.amber, Colors.orange],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "AI Smart Pricing Analysis",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Recommended Price",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "\$${smartPricing!['recommended_price']?.toStringAsFixed(0) ?? '?'}",
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Hourly Rate",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "\$${smartPricing!['recommended_hourly_rate']?.toStringAsFixed(0) ?? '?'}/hr",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Est. Hours",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${smartPricing!['estimated_hours'] ?? '?'} hrs",
                                        style: const TextStyle(
                                          fontSize: 20,
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
                                const Icon(
                                  Icons.analytics,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Confidence: ${smartPricing!['confidence_score'] ?? 85}%",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Spacer(),
                                if (smartPricing!['justification'] != null)
                                  Flexible(
                                    child: Text(
                                      smartPricing!['justification'],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            if (smartPricing!['pricing_breakdown'] != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    _buildBreakdownRow(
                                      "Base Rate",
                                      "\$${smartPricing!['pricing_breakdown']['base_rate']?.toStringAsFixed(0) ?? '?'}/hr",
                                    ),
                                    _buildBreakdownRow(
                                      "Complexity",
                                      "+${((smartPricing!['pricing_breakdown']['complexity_multiplier'] ?? 1) - 1) * 100}%",
                                    ),
                                    _buildBreakdownRow(
                                      "Experience",
                                      "+${((smartPricing!['pricing_breakdown']['experience_multiplier'] ?? 1) - 1) * 100}%",
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

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
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            project!.description ?? 'No description',
                            style: const TextStyle(height: 1.6, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (project!.skills != null && project!.skills!.isNotEmpty)
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
                            const Text(
                              'Required Skills',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: project!.skills!.map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    skill,
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
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
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: project!.client?.avatar != null
                                ? NetworkImage(
                                    _getAvatarUrl(project!.client!.avatar),
                                  )
                                : null,
                            child: project!.client?.avatar == null
                                ? Text(
                                    project!.client?.name?[0].toUpperCase() ??
                                        'C',
                                    style: const TextStyle(
                                      fontSize: 24,
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
                                const Text(
                                  'Client',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  project!.client?.name ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  project!.client?.email ?? 'No email',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  if (isOpen &&
                      _usage != null &&
                      _usage!.proposalsLimit != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Proposals remaining this month: ${_usage!.remainingProposals}',
                      style: TextStyle(
                        color: _usage!.remainingProposals <= 0
                            ? Colors.red
                            : Colors.green,
                        fontSize: 12,
                      ),
                    ),
                    if (_usage!.remainingProposals <= 0)
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/subscription/plans'),
                        child: const Text('Upgrade to send more proposals'),
                      ),
                  ],

                  if (hasContract)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _loadingContract
                            ? null
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  '/contract',
                                  arguments: {
                                    'contractId': _contractId,
                                    'userRole': 'freelancer',
                                  },
                                );
                              },
                        icon: _loadingContract
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.description_outlined),
                        label: const Text(
                          'Open Contract',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else if (!hasSubmitted && isOpen)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToSubmitProposal,
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text(
                          'Submit Proposal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff14A800),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else if (isOpen && hasSubmitted)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'You have already submitted a proposal for this project',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!isOpen)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              hasContract
                                  ? 'This project is ${project!.statusText}. Your workspace is in the contract.'
                                  : 'This project is ${project!.statusText}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }
}
