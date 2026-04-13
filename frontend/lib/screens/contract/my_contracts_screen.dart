// screens/contract/my_contracts_screen.dart
import 'package:flutter/material.dart';
import '../../models/contract_model.dart';
import '../../services/api_service.dart';
import '../freelancer/work_submission_screen.dart';

class MyContractsScreen extends StatefulWidget {
  final String userRole;
  const MyContractsScreen({super.key, required this.userRole});

  @override
  State<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends State<MyContractsScreen> {
  List<Contract> contracts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchContracts();
  }

  Future<void> fetchContracts() async {
    setState(() => loading = true);

    final data = await ApiService.getMyContracts(widget.userRole);

    setState(() {
      contracts = data.map((json) => Contract.fromJson(json)).toList();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userRole == 'client' ? "My Contracts" : "Active Projects",
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchContracts,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : contracts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No contracts yet",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contracts.length,
              itemBuilder: (context, index) {
                final contract = contracts[index];
                return _buildContractCard(contract);
              },
            ),
    );
  }

  Widget _buildContractCard(Contract contract) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: contract.statusColor.withOpacity(0.1),
              child: Icon(
                contract.status == 'active'
                    ? Icons.check_circle
                    : contract.status == 'draft'
                    ? Icons.edit
                    : Icons.access_time,
                color: contract.statusColor,
                size: 20,
              ),
            ),
            title: Text(
              contract.project?.title ?? 'Untitled Project',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contract.statusText),
                Text(
                  "\$${contract.agreedAmount?.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            trailing: Text(
              _getSignatureStatus(contract),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: contract.isSignedByBoth ? Colors.green : Colors.orange,
              ),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/contract',
                arguments: {
                  'contractId': contract.id,
                  'userRole': widget.userRole,
                },
              ).then((_) => fetchContracts());
            },
          ),

          if (widget.userRole == 'freelancer' && contract.status == 'active')
            _buildWorkSubmissionButtons(contract),
        ],
      ),
    );
  }

  Widget _buildWorkSubmissionButtons(Contract contract) {
    final hasMilestones =
        contract.milestones != null && contract.milestones!.isNotEmpty;

    if (!hasMilestones) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkSubmissionScreen(contract: contract),
                    ),
                  ).then((_) => fetchContracts());
                },
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Submit Final Work'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff14A800),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final inProgressMilestones = <int, Map<String, dynamic>>{};
    for (var i = 0; i < contract.milestones!.length; i++) {
      final milestone = contract.milestones![i];
      if (milestone['status'] == 'in_progress') {
        inProgressMilestones[i] = milestone;
      }
    }

    if (inProgressMilestones.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Submit Work for Milestones:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...inProgressMilestones.entries.map((entry) {
            final index = entry.key;
            final milestone = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkSubmissionScreen(
                              contract: contract,
                              milestoneIndex: index,
                              milestone: milestone,
                            ),
                          ),
                        ).then((_) => fetchContracts());
                      },
                      icon: const Icon(Icons.work, size: 18),
                      label: Text('Submit: ${milestone['title']}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getSignatureStatus(Contract contract) {
    if (contract.isSignedByBoth) return 'Signed ✓';
    if (widget.userRole == 'client') {
      return contract.clientSignedAt != null
          ? 'Waiting for Freelancer'
          : 'Sign Now';
    } else {
      return contract.freelancerSignedAt != null
          ? 'Waiting for Client'
          : 'Sign Now';
    }
  }
}
