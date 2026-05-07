import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../utils/constants.dart';
import '../../models/dispute_model.dart';
import '../../services/api_service.dart';

class DisputesManagementScreen extends StatefulWidget {
  const DisputesManagementScreen({super.key});

  @override
  State<DisputesManagementScreen> createState() =>
      _DisputesManagementScreenState();
}

class _DisputesManagementScreenState extends State<DisputesManagementScreen> {
  List<Dispute> disputes = [];
  bool loading = true;
  String selectedStatus = 'all';
  int currentPage = 1;
  int totalPages = 1;
  final int _kAccent = 0xFF5B5BD6;
  final Color _kPageBg = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  Future<void> _loadDisputes() async {
    setState(() => loading = true);
    try {
      final response = await ApiService.getAdminDisputes(
        status: selectedStatus,
        page: currentPage,
      );

      if (response['success'] == true) {
        setState(() {
          disputes = (response['disputes'] as List)
              .map((d) => Dispute.fromJson(d))
              .toList();
          totalPages = response['totalPages'] ?? 1;
          loading = false;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading disputes: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _resolveDispute(
    int disputeId,
    String resolution, {
    double? refundAmount,
    String? adminNotes,
  }) async {
    try {
      final response = await ApiService.resolveDispute(
        disputeId: disputeId,
        resolution: resolution,
        refundAmount: refundAmount,
        adminNotes: adminNotes,
      );

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: 'Dispute resolved successfully');
        _loadDisputes();
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? 'Failed to resolve dispute',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error resolving dispute: $e');
    }
  }

  Future<void> _rejectDispute(int disputeId, String adminNotes) async {
    try {
      final response = await ApiService.rejectDispute(
        disputeId: disputeId,
        adminNotes: adminNotes,
      );

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: 'Dispute rejected successfully');
        _loadDisputes();
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? 'Failed to reject dispute',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error rejecting dispute: $e');
    }
  }

  void _showResolveDialog(Dispute dispute) {
    String resolution = 'no_refund';
    double? refundAmount;
    final TextEditingController notesController = TextEditingController();
    final TextEditingController refundController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Resolve Dispute'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contract: ${dispute.contract?.project?.title ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Initiated by: ${dispute.initiatedBy}'),
                const SizedBox(height: 8),
                Text('Title: ${dispute.title}'),
                const SizedBox(height: 16),
                const Text('Resolution:'),
                DropdownButton<String>(
                  value: resolution,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'full_refund',
                      child: Text('Full Refund to Client'),
                    ),
                    DropdownMenuItem(
                      value: 'partial_refund',
                      child: Text('Partial Refund to Client'),
                    ),
                    DropdownMenuItem(
                      value: 'no_refund',
                      child: Text('No Refund'),
                    ),
                  ],
                  onChanged: (value) => setState(() => resolution = value!),
                ),
                if (resolution == 'partial_refund') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: refundController,
                    decoration: const InputDecoration(
                      labelText: 'Refund Amount',
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => refundAmount = double.tryParse(value),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Notes (optional)',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resolveDispute(
                  dispute.id!,
                  resolution,
                  refundAmount: refundAmount,
                  adminNotes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                );
              },
              child: const Text('Resolve'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(Dispute dispute) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject this dispute?'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectDispute(dispute.id!, notesController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'open':
        color = Colors.orange;
        text = 'Open';
        break;
      case 'resolved':
        color = Colors.green;
        text = 'Resolved';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDisputeCard(Dispute dispute) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dispute.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(dispute.status),
                  ],
                ),
                const SizedBox(height: 8),

                Text(
                  'Contract: ${dispute.contract?.project?.title ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 4),

                Text(
                  'Initiated by: ${dispute.initiatedBy} (${dispute.initiatedBy == 'client' ? dispute.client?.name : dispute.freelancer?.name ?? 'N/A'})',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 4),

                Text(
                  dispute.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(dispute.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (dispute.status == 'open')
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showResolveDialog(dispute),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Resolve'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showRejectDialog(dispute),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showDisputeDetails(dispute),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDisputeDetails(Dispute dispute) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dispute.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${dispute.status}'),
              const SizedBox(height: 8),
              Text('Contract: ${dispute.contract?.project?.title ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Initiated by: ${dispute.initiatedBy}'),
              const SizedBox(height: 8),
              Text('Description:'),
              Text(dispute.description),
              if (dispute.evidenceFiles.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Evidence Files:'),
                ...dispute.evidenceFiles.map((file) => Text('• $file')),
              ],
              if (dispute.resolution != null) ...[
                const SizedBox(height: 12),
                Text('Resolution: ${dispute.resolution}'),
                if (dispute.refundAmount != null)
                  Text('Refund Amount: \$${dispute.refundAmount}'),
                if (dispute.adminNotes != null) ...[
                  const SizedBox(height: 8),
                  const Text('Admin Notes:'),
                  Text(dispute.adminNotes!),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Disputes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1B3E),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _kPageBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Text('Status:'),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedStatus,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'open', child: Text('Open')),
                        DropdownMenuItem(
                          value: 'resolved',
                          child: Text('Resolved'),
                        ),
                        DropdownMenuItem(
                          value: 'rejected',
                          child: Text('Rejected'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => selectedStatus = value!);
                        currentPage = 1;
                        _loadDisputes();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: _kPageBg,
          child: Row(
            children: [
              Text(
                '${disputes.length} disputes',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B3E),
                ),
              ),
              if (loading) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF5B5BD6),
                  ),
                ),
              ],
            ],
          ),
        ),

        Expanded(
          child: loading && disputes.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF5B5BD6)),
                )
              : disputes.isEmpty
              ? const Center(child: Text('No disputes found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: disputes.length,
                  itemBuilder: (_, i) => _buildDisputeCard(disputes[i]),
                ),
        ),

        if (totalPages > 1) _buildPagination(),
      ],
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 1
                ? () {
                    setState(() => currentPage--);
                    _loadDisputes();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Page $currentPage of $totalPages'),
          IconButton(
            onPressed: currentPage < totalPages
                ? () {
                    setState(() => currentPage++);
                    _loadDisputes();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
