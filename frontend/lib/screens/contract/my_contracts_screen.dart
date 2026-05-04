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
  List<Contract> filteredContracts = [];
  bool loading = true;
  String selectedFilter = 'all';

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
      _applyFilter();
      loading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      switch (selectedFilter) {
        case 'active':
          filteredContracts = contracts
              .where((c) => c.status == 'active')
              .toList();
          break;
        case 'draft':
          filteredContracts = contracts
              .where((c) => c.status == 'draft')
              .toList();
          break;
        case 'completed':
          filteredContracts = contracts
              .where((c) => c.status == 'completed')
              .toList();
          break;
        case 'signed':
          filteredContracts = contracts.where((c) => c.isSignedByBoth).toList();
          break;
        default:
          filteredContracts = List.from(contracts);
      }
    });
  }

  int _getFilteredCount() {
    return filteredContracts.length;
  }

  List<Map<String, dynamic>> _getFilters(AppLocalizations t) {
    return [
      {'value': 'all', 'icon': Icons.list, 'label': t.all},
      {'value': 'active', 'icon': Icons.play_circle, 'label': t.active},
      {'value': 'draft', 'icon': Icons.edit, 'label': t.draft},
      {'value': 'completed', 'icon': Icons.check_circle, 'label': t.completed},
      {'value': 'signed', 'icon': Icons.verified, 'label': t.signed},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filters = _getFilters(t);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: t.back,
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        title: Text(
          widget.userRole == 'client' ? t.myContracts : t.activeProjects,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
            onPressed: fetchContracts,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(filters),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_getFilteredCount()} ${t.contracts}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                if (selectedFilter != 'all')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedFilter = 'all';
                        _applyFilter();
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      t.clearFilter,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : filteredContracts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getEmptyStateIcon(),
                          size: 64,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getEmptyStateMessage(t),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (selectedFilter != 'all')
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  selectedFilter = 'all';
                                  _applyFilter();
                                });
                              },
                              child: Text(t.showAllContracts),
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredContracts.length,
                    itemBuilder: (context, index) {
                      final contract = filteredContracts[index];
                      return _buildContractCard(contract);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<Map<String, dynamic>> filters) {
    final theme = Theme.of(context);

    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text(filter['label']),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              avatar: Icon(
                filter['icon'],
                size: 18,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              backgroundColor: theme.cardColor,
              selectedColor: theme.colorScheme.primary,
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.2),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              onSelected: (selected) {
                setState(() {
                  selectedFilter = filter['value'];
                  _applyFilter();
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildContractCard(Contract contract) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
                    : contract.status == 'completed'
                    ? Icons.verified
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract.statusText,
                  style: TextStyle(color: contract.statusColor),
                ),
                const SizedBox(height: 2),
                Text(
                  "${t.dollar}${contract.agreedAmount?.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: contract.isSignedByBoth
                    ? theme.colorScheme.secondary.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getSignatureStatus(contract),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: contract.isSignedByBoth
                      ? theme.colorScheme.secondary
                      : AppColors.warning,
                ),
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

  IconData _getEmptyStateIcon() {
    switch (selectedFilter) {
      case 'active':
        return Icons.play_circle_outline;
      case 'draft':
        return Icons.edit_note;
      case 'completed':
        return Icons.check_circle_outline;
      case 'signed':
        return Icons.assignment_turned_in;
      default:
        return Icons.description;
    }
  }

  String _getEmptyStateMessage(AppLocalizations t) {
    switch (selectedFilter) {
      case 'active':
        return t.noActiveContracts ?? 'لا توجد عقود نشطة';
      case 'draft':
        return t.noDraftContracts ?? 'لا توجد مسودات عقود';
      case 'completed':
        return t.noCompletedContracts ?? 'لا توجد عقود مكتملة';
      case 'signed':
        return t.noSignedContracts ?? 'لا توجد عقود موقعة';
      default:
        return t.noContractsYet;
    }
  }
}
