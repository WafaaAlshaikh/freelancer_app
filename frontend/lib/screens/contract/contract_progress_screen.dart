// lib/screens/contract/contract_progress_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../models/contract_model.dart';
import '../../services/api_service.dart';
import '../freelancer/work_submission_screen.dart';

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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prog = await ApiService.getContractProgress(widget.contractId);
      if (prog['success'] != true) {
        setState(() {
          _error = prog['message']?.toString() ?? 'Could not load progress';
          _loading = false;
        });
        return;
      }
      final raw = await ApiService.getContract(widget.contractId);
      if (raw['message'] != null && raw['id'] == null) {
        setState(() {
          _progress = Map<String, dynamic>.from(prog);
          _loading = false;
        });
        return;
      }
      setState(() {
        _progress = Map<String, dynamic>.from(prog);
        _contract = Contract.fromJson(Map<String, dynamic>.from(raw));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _approveMilestone(int index) async {
    final r = await ApiService.approveMilestone(
      contractId: widget.contractId,
      milestoneIndex: index,
    );
    if (mounted) {
      if (r['milestone'] != null || r['message'] != null) {
        Fluttertoast.showToast(
          msg: r['message']?.toString() ?? 'Milestone updated',
        );
        _load();
      } else {
        Fluttertoast.showToast(
          msg: r['message']?.toString() ?? 'Could not approve milestone',
        );
      }
    }
  }

  Future<void> _approveWork(int submissionId) async {
    final r = await ApiService.approveWork(submissionId);
    if (!mounted) return;
    if (r['success'] == true || r['submission'] != null) {
      Fluttertoast.showToast(msg: 'Work approved');
      _load();
    } else {
      Fluttertoast.showToast(
        msg: r['message']?.toString() ?? 'Approval failed',
      );
    }
  }

  Future<void> _promptRevision(int submissionId) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request revision'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'What should be changed?',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send'),
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
      Fluttertoast.showToast(msg: 'Revision requested');
      _load();
    } else {
      Fluttertoast.showToast(msg: r['message']?.toString() ?? 'Request failed');
    }
  }

  Future<void> _addSubmissionToPortfolio(int submissionId) async {
    final r = await ApiService.createPortfolioFromSubmission(submissionId);
    if (!mounted) return;
    if (r['success'] == true || r['portfolio'] != null) {
      Fluttertoast.showToast(
        msg: r['message']?.toString() ?? 'Added to portfolio',
      );
    } else {
      Fluttertoast.showToast(
        msg: r['message']?.toString() ?? 'Could not add to portfolio',
      );
    }
  }

  Future<void> _addMilestoneToPortfolio(int milestoneIndex) async {
    final r = await ApiService.createPortfolioFromContractMilestone(
      contractId: widget.contractId,
      milestoneIndex: milestoneIndex,
    );
    if (!mounted) return;
    Fluttertoast.showToast(
      msg:
          r['message']?.toString() ??
          ((r['success'] == true)
              ? 'Added to portfolio'
              : 'Could not add to portfolio'),
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
    ).then((_) => _load());
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract progress'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
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
    final project = _progress?['project'] as Map<String, dynamic>?;
    final c = _progress?['contract'] as Map<String, dynamic>?;
    final title =
        project?['title']?.toString() ?? 'Contract #${widget.contractId}';
    final escrow = c?['escrow_status']?.toString() ?? '';
    final pool = c?['escrow_pool'];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text('You: ${widget.userRole}'),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text('Escrow: $escrow'),
                  visualDensity: VisualDensity.compact,
                ),
                if (pool != null)
                  Chip(
                    label: Text('Pool: \$${_fmtMoney(pool)}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (c?['coupon_code'] != null &&
                (c?['coupon_code']?.toString().isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Text(
                'Coupon ${c!['coupon_code']}: -\$${_fmtMoney(c['coupon_discount_amount'])}',
                style: TextStyle(
                  color: Colors.green.shade700,
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
    final cp = _progress?['commission_preview'] as Map<String, dynamic>?;
    if (cp == null) return const SizedBox.shrink();
    final rate = cp['rate_percent'];
    final fee = cp['estimated_fee_on_release'] ?? cp['estimated_fee'];
    final note = cp['note']?.toString() ?? '';
    return Card(
      color: Colors.indigo.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.percent, color: Colors.indigo.shade800, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Commission preview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Plan rate (indicative): ${rate ?? '—'}% · Est. platform fee on release: \$${_fmtMoney(fee)}',
              style: TextStyle(fontSize: 13, color: Colors.indigo.shade900),
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note,
                style: TextStyle(fontSize: 12, color: Colors.indigo.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSection() {
    final list = _progress?['pending_actions'] as List<dynamic>? ?? [];
    if (list.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.check_circle_outline, color: Colors.green),
          title: const Text('No pending steps'),
          subtitle: const Text(
            'You are up to date on milestones and deliverables.',
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your next steps',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...list.map((raw) {
          final a = Map<String, dynamic>.from(raw as Map);
          final type = a['type']?.toString() ?? '';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pendingTitle(type, a),
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
    final t = a['title']?.toString() ?? '';
    switch (type) {
      case 'approve_milestone':
        return 'Approve milestone: $t';
      case 'review_submission':
        return 'Review submission: $t';
      case 'submit_deliverable':
        return 'Submit deliverable: $t';
      default:
        return t.isNotEmpty ? t : type;
    }
  }

  List<Widget> _pendingButtons(String type, Map<String, dynamic> a) {
    switch (type) {
      case 'approve_milestone':
        final idx = a['milestoneIndex'] as int? ?? 0;
        return [
          ElevatedButton(
            onPressed: () => _approveMilestone(idx),
            child: const Text('Approve & release'),
          ),
        ];
      case 'review_submission':
        final sid = a['submissionId'];
        final id = sid is int ? sid : int.tryParse(sid.toString()) ?? 0;
        return [
          ElevatedButton(
            onPressed: id > 0 ? () => _approveWork(id) : null,
            child: const Text('Approve work'),
          ),
          OutlinedButton(
            onPressed: id > 0 ? () => _promptRevision(id) : null,
            child: const Text('Request revision'),
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
            child: const Text('Submit deliverable'),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildMilestonesSection() {
    final milestones = _progress?['milestones'] as List<dynamic>? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Milestones',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...milestones.asMap().entries.map((e) {
          final m = Map<String, dynamic>.from(e.value as Map);
          final st = m['status']?.toString() ?? 'pending';
          final amt = m['amount'];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor(st).withOpacity(0.15),
                child: Text(
                  '${m['index'] ?? e.key}',
                  style: TextStyle(
                    color: _statusColor(st),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(m['title']?.toString() ?? 'Milestone'),
              subtitle: Text(
                '${st.toUpperCase()}${amt != null ? ' · \$${_fmtMoney(amt)}' : ''}',
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubmissionsSection() {
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
        const Text(
          'Deliverables',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(s['title']?.toString() ?? 'Submission'),
              subtitle: Text('$st · Milestone ${s['milestone_index'] ?? '—'}'),
              trailing: canAddToPortfolio
                  ? TextButton.icon(
                      onPressed: () {
                        final sid = s['id'];
                        final id = sid is int
                            ? sid
                            : int.tryParse(sid.toString()) ?? 0;
                        if (id > 0) _addSubmissionToPortfolio(id);
                      },
                      icon: const Icon(Icons.add_box_outlined, size: 16),
                      label: const Text('Add to Portfolio'),
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
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(m['title']?.toString() ?? 'Milestone ${idx + 1}'),
                subtitle: Text(
                  '${(m['status'] ?? 'approved').toString()} · Milestone $idx',
                ),
                trailing: TextButton.icon(
                  onPressed: () => _addMilestoneToPortfolio(idx),
                  icon: const Icon(Icons.add_box_outlined, size: 16),
                  label: const Text('Add to Portfolio'),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildTimelineSection() {
    final items = _progress?['timeline'] as List<dynamic>? ?? [];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent activity',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.take(15).map((raw) {
          final t = Map<String, dynamic>.from(raw as Map);
          final at = t['at']?.toString() ?? '';
          final label = t['label']?.toString() ?? '';
          return ListTile(
            dense: true,
            leading: const Icon(Icons.history, size: 18),
            title: Text(label, style: const TextStyle(fontSize: 13)),
            subtitle: Text(at, style: const TextStyle(fontSize: 11)),
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
