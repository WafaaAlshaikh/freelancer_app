// screens/contract/my_contracts_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/contract_model.dart';
import '../../services/api_service.dart';
import '../freelancer/work_submission_screen.dart';
import '../../theme/app_theme.dart';

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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.userRole == 'client' ? t.myContracts : t.activeProjects,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
            onPressed: fetchContracts,
          ),
        ],
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : contracts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.noContractsYet,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 16,
                    ),
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
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
              contract.project?.title ?? t.untitledProject,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract.statusText,
                  style: TextStyle(color: contract.statusColor),
                ),
                Text(
                  "${t.dollar}${contract.agreedAmount?.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
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
                color: contract.isSignedByBoth
                    ? theme.colorScheme.secondary
                    : AppColors.warning,
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                label: Text(t.submitFinalWork),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
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
          Divider(color: theme.dividerColor),
          const SizedBox(height: 8),
          Text(
            t.submitWorkForMilestones,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
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
                      label: Text('${t.submit}: ${milestone['title']}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.infoBg,
                        foregroundColor: AppColors.info,
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
    final t = AppLocalizations.of(context);
    if (contract.isSignedByBoth) return t?.signed ?? 'Signed ✓';
    if (widget.userRole == 'client') {
      return contract.clientSignedAt != null
          ? (t?.waitingForFreelancer ?? 'Waiting for Freelancer')
          : (t?.signNow ?? 'Sign Now');
    } else {
      return contract.freelancerSignedAt != null
          ? (t?.waitingForClient ?? 'Waiting for Client')
          : (t?.signNow ?? 'Sign Now');
    }
  }
}
