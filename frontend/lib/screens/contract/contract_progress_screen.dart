// lib/screens/contract/contract_progress_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../models/contract_model.dart';
import '../../services/api_service.dart';
import '../freelancer/work_submission_screen.dart';
import '../../theme/app_theme.dart';

class ContractProgressScreen extends StatefulWidget {
  final int contractId;
  final String userRole;

  const ContractProgressScreen({
    super.key,
    required this.contractId,
    required this.userRole,
  });

  @override
  State<ContractProgressScreen> createState() => _ContractProgressScreenState();
}

class _ContractProgressScreenState extends State<ContractProgressScreen> {
  Map<String, dynamic>? _progress;
  Contract? _contract;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load(context);
      }
    });
  }

  Future<void> _load(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prog = await ApiService.getContractProgress(widget.contractId);
      if (prog['success'] != true) {
        if (mounted) {
          setState(() {
            _error = prog['message']?.toString() ?? t.couldNotLoadProgress;
            _loading = false;
          });
        }
        return;
      }
      final raw = await ApiService.getContract(widget.contractId);
      if (raw['message'] != null && raw['id'] == null) {
        if (mounted) {
          setState(() {
            _progress = Map<String, dynamic>.from(prog);
            _loading = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _progress = Map<String, dynamic>.from(prog);
          _contract = Contract.fromJson(Map<String, dynamic>.from(raw));
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _approveMilestone(BuildContext context, int index) async {
    final t = AppLocalizations.of(context)!;
    final r = await ApiService.approveMilestone(
      contractId: widget.contractId,
      milestoneIndex: index,
    );
    if (mounted) {
      if (r['milestone'] != null || r['message'] != null) {
        Fluttertoast.showToast(
          msg: r['message']?.toString() ?? t.milestoneUpdated,
        );
        _load(context);
      } else {
        Fluttertoast.showToast(
          msg: r['message']?.toString() ?? t.couldNotApproveMilestone,
        );
      }
    }
  }

  Future<void> _approveWork(BuildContext context, int submissionId) async {
    final t = AppLocalizations.of(context)!;
    final r = await ApiService.approveWork(submissionId);
    if (!mounted) return;
    if (r['success'] == true || r['submission'] != null) {
      Fluttertoast.showToast(msg: t.workApproved);
      _load(context);
    } else {
      Fluttertoast.showToast(msg: r['message']?.toString() ?? t.approvalFailed);
    }
  }

  Future<void> _promptRevision(BuildContext context, int submissionId) async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          t.requestRevision,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: t.whatShouldBeChanged,
            hintStyle: TextStyle(color: AppColors.gray),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel, style: TextStyle(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.send),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    final r = await ApiService.requestRevision(
      submissionId: submissionId,
      revisionMessage: ctrl.text.trim(),
    );
    if (!mounted) return;
    if (r['success'] == true) {
      Fluttertoast.showToast(msg: t.revisionRequested);
      _load(context);
    } else {
      Fluttertoast.showToast(msg: r['message']?.toString() ?? t.requestFailed);
    }
  }

  Future<void> _addSubmissionToPortfolio(
    BuildContext context,
    int submissionId,
  ) async {
    final t = AppLocalizations.of(context)!;
    final r = await ApiService.createPortfolioFromSubmission(submissionId);
    if (!mounted) return;
    if (r['success'] == true || r['portfolio'] != null) {
      Fluttertoast.showToast(
        msg: r['message']?.toString() ?? t.addedToPortfolio,
      );
    } else {
      Fluttertoast.showToast(
        msg: r['message']?.toString() ?? t.couldNotAddToPortfolio,
      );
    }
  }

  Future<void> _addMilestoneToPortfolio(
    BuildContext context,
    int milestoneIndex,
  ) async {
    final t = AppLocalizations.of(context)!;
    final r = await ApiService.createPortfolioFromContractMilestone(
      contractId: widget.contractId,
      milestoneIndex: milestoneIndex,
    );
    if (!mounted) return;
    Fluttertoast.showToast(
      msg:
          r['message']?.toString() ??
          ((r['success'] == true)
              ? t.addedToPortfolio
              : t.couldNotAddToPortfolio),
    );
  }

  void _openSubmitDeliverable(Map<String, dynamic> milestone) {
    if (_contract == null) return;
    final idx = milestone['index'] as int? ?? 0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkSubmissionScreen(
          contract: _contract!,
          milestoneIndex: idx,
          milestone: Map<String, dynamic>.from(milestone),
        ),
      ),
    ).then((_) => _load(context));
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'approved':
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.contractProgress),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
            onPressed: () => _load(context),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.danger),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _load(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      child: Text(t.retry),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _load(context),
              color: theme.colorScheme.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildCommissionCard(),
                  const SizedBox(height: 16),
                  _buildPendingSection(),
                  const SizedBox(height: 16),
                  _buildMilestonesSection(),
                  const SizedBox(height: 16),
                  _buildSubmissionsSection(),
                  const SizedBox(height: 16),
                  _buildTimelineSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final project = _progress?['project'] as Map<String, dynamic>?;
    final c = _progress?['contract'] as Map<String, dynamic>?;
    final title =
        project?['title']?.toString() ?? t.contractNumber(widget.contractId);
    final escrow = c?['escrow_status']?.toString() ?? '';
    final pool = c?['escrow_pool'];

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text('${t.you}: ${widget.userRole}'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(color: theme.colorScheme.primary),
                ),
                Chip(
                  label: Text('${t.escrow}: $escrow'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                  labelStyle: TextStyle(color: theme.colorScheme.secondary),
                ),
                if (pool != null)
                  Chip(
                    label: Text('${t.pool}: \$${_fmtMoney(pool)}'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.infoBg,
                    labelStyle: const TextStyle(color: AppColors.info),
                  ),
              ],
            ),
            if (c?['coupon_code'] != null &&
                (c?['coupon_code']?.toString().isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Text(
                '${t.coupon} ${c!['coupon_code']}: -${t.dollar}${_fmtMoney(c['coupon_discount_amount'])}',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionCard() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cp = _progress?['commission_preview'] as Map<String, dynamic>?;
    if (cp == null) return const SizedBox.shrink();
    final rate = cp['rate_percent'];
    final fee = cp['estimated_fee_on_release'] ?? cp['estimated_fee'];
    final note = cp['note']?.toString() ?? '';

    return Card(
      color: AppColors.infoBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.percent, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Text(
                  t.commissionPreview,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${t.planRateIndicative}: ${rate ?? '—'}% · ${t.estPlatformFeeOnRelease}: ${t.dollar}${_fmtMoney(fee)}',
              style: TextStyle(fontSize: 13, color: AppColors.info),
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(note, style: TextStyle(fontSize: 12, color: AppColors.info)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSection() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final list = _progress?['pending_actions'] as List<dynamic>? ?? [];

    if (list.isEmpty) {
      return Card(
        color: theme.cardColor,
        child: ListTile(
          leading: Icon(
            Icons.check_circle_outline,
            color: theme.colorScheme.secondary,
          ),
          title: Text(
            t.noPendingSteps,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          subtitle: Text(t.upToDateOnMilestones),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.yourNextSteps,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...list.map((raw) {
          final a = Map<String, dynamic>.from(raw as Map);
          final type = a['type']?.toString() ?? '';
          return Card(
            color: theme.cardColor,
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pendingTitle(type, a),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: _pendingButtons(type, a)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _pendingTitle(String type, Map<String, dynamic> a) {
    final t = AppLocalizations.of(context)!;
    final title = a['title']?.toString() ?? '';
    switch (type) {
      case 'approve_milestone':
        return '${t.approveMilestone}: $title';
      case 'review_submission':
        return '${t.reviewSubmission}: $title';
      case 'submit_deliverable':
        return '${t.submitDeliverable}: $title';
      default:
        return title.isNotEmpty ? title : type;
    }
  }

  List<Widget> _pendingButtons(String type, Map<String, dynamic> a) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    switch (type) {
      case 'approve_milestone':
        final idx = a['milestoneIndex'] as int? ?? 0;
        return [
          ElevatedButton(
            onPressed: () => _approveMilestone(context, idx),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            child: Text(t.approveAndRelease),
          ),
        ];
      case 'review_submission':
        final sid = a['submissionId'];
        final id = sid is int ? sid : int.tryParse(sid.toString()) ?? 0;
        return [
          ElevatedButton(
            onPressed: id > 0 ? () => _approveWork(context, id) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
            ),
            child: Text(t.approveWork),
          ),
          OutlinedButton(
            onPressed: id > 0 ? () => _promptRevision(context, id) : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.primary),
            ),
            child: Text(t.requestRevision),
          ),
        ];
      case 'submit_deliverable':
        final milestones = _progress?['milestones'] as List<dynamic>? ?? [];
        final idx = a['milestoneIndex'] as int? ?? 0;
        Map<String, dynamic> m = {};
        if (idx < milestones.length) {
          m = Map<String, dynamic>.from(milestones[idx] as Map);
          m['index'] = idx;
        } else {
          m = {'index': idx, 'title': a['title']};
        }
        return [
          ElevatedButton(
            onPressed: _contract != null
                ? () => _openSubmitDeliverable(m)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            child: Text(t.submitDeliverable),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildSubmissionsSection() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final subs = _progress?['submissions'] as List<dynamic>? ?? [];
    final milestones = _progress?['milestones'] as List<dynamic>? ?? [];
    final contract = _progress?['contract'] as Map<String, dynamic>?;
    final contractStatus = contract?['status']?.toString() ?? '';
    final approvedMilestoneOnly = milestones.asMap().entries.where((e) {
      final m = Map<String, dynamic>.from(e.value as Map);
      final st = m['status']?.toString() ?? '';
      return st == 'approved' || st == 'completed';
    }).toList();

    if (subs.isEmpty && approvedMilestoneOnly.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.deliverables,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...subs.map((raw) {
          final s = Map<String, dynamic>.from(raw as Map);
          final st = s['status']?.toString() ?? '';
          final milestoneIndexRaw = s['milestone_index'];
          final milestoneIndex = milestoneIndexRaw is int
              ? milestoneIndexRaw
              : int.tryParse(milestoneIndexRaw?.toString() ?? '');
          String milestoneStatus = '';
          if (milestoneIndex != null &&
              milestoneIndex >= 0 &&
              milestoneIndex < milestones.length) {
            final m = Map<String, dynamic>.from(
              milestones[milestoneIndex] as Map,
            );
            milestoneStatus = m['status']?.toString() ?? '';
          }
          final canAddToPortfolio =
              widget.userRole == 'freelancer' &&
              (st == 'approved' ||
                  contractStatus == 'completed' ||
                  milestoneStatus == 'approved' ||
                  milestoneStatus == 'completed');
          return Card(
            color: theme.cardColor,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                s['title']?.toString() ?? t.submission,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              subtitle: Text(
                '$st · ${t.milestone} ${s['milestone_index'] ?? '—'}',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              trailing: canAddToPortfolio
                  ? TextButton.icon(
                      onPressed: () {
                        final sid = s['id'];
                        final id = sid is int
                            ? sid
                            : int.tryParse(sid.toString()) ?? 0;
                        if (id > 0) _addSubmissionToPortfolio(context, id);
                      },
                      icon: Icon(
                        Icons.add_box_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        t.addToPortfolio,
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    )
                  : null,
            ),
          );
        }),
        if (subs.isEmpty && widget.userRole == 'freelancer') ...[
          ...approvedMilestoneOnly.map((entry) {
            final idx = entry.key;
            final m = Map<String, dynamic>.from(entry.value as Map);
            return Card(
              color: theme.cardColor,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  m['title']?.toString() ?? '${t.milestone} ${idx + 1}',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                subtitle: Text(
                  '${(m['status'] ?? 'approved').toString()} · ${t.milestone} $idx',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                trailing: TextButton.icon(
                  onPressed: () => _addMilestoneToPortfolio(context, idx),
                  icon: Icon(
                    Icons.add_box_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    t.addToPortfolio,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildMilestonesSection() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final milestones = _progress?['milestones'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.milestones,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...milestones.asMap().entries.map((e) {
          final m = Map<String, dynamic>.from(e.value as Map);
          final st = m['status']?.toString() ?? 'pending';
          final amt = m['amount'];
          final statusColor = _statusColor(st);

          return Card(
            color: theme.cardColor,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.15),
                child: Text(
                  '${m['index'] ?? e.key}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                m['title']?.toString() ?? t.milestone,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              subtitle: Text(
                '${st.toUpperCase()}${amt != null ? ' · ${t.dollar}${_fmtMoney(amt)}' : ''}',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimelineSection() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final items = _progress?['timeline'] as List<dynamic>? ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.recentActivity,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.take(15).map((raw) {
          final item = Map<String, dynamic>.from(raw as Map);
          final at = item['at']?.toString() ?? '';
          final label = item['label']?.toString() ?? '';
          return ListTile(
            dense: true,
            leading: Icon(
              Icons.history,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            ),
            subtitle: Text(
              at,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: AppColors.gray,
              ),
            ),
          );
        }),
      ],
    );
  }

  String _fmtMoney(dynamic v) {
    if (v == null) return '0.00';
    double n;
    if (v is double) {
      n = v;
    } else if (v is int) {
      n = v.toDouble();
    } else {
      n = double.tryParse(v.toString()) ?? 0;
    }
    return n.toStringAsFixed(2);
  }
}
