// screens/disputes/dispute_details_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/dispute_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart' as AppTheme;
import '../../widgets/primary_button.dart';
import '../contract/contract_screen.dart';

class DisputeDetailsScreen extends StatefulWidget {
  final Dispute dispute;

  const DisputeDetailsScreen({Key? key, required this.dispute})
      : super(key: key);

  @override
  State<DisputeDetailsScreen> createState() => _DisputeDetailsScreenState();
}

class _DisputeDetailsScreenState extends State<DisputeDetailsScreen> {
  Dispute? _dispute;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dispute = widget.dispute;
    _loadDisputeDetails();
  }

  Future<void> _loadDisputeDetails() async {
    try {
      final response = await ApiService.getUserDisputeDetails(_dispute!.id!);

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _dispute = Dispute.fromJson(response['dispute']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? t?.errorLoadingDetails ?? 'Error loading details'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t?.connectionError ?? 'Connection error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getStatusColor(String status, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'under_review':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return isDark ? Colors.grey.shade600 : Colors.grey;
    }
  }

  String _getStatusText(String status, AppLocalizations t) {
    switch (status) {
      case 'pending':
        return t.disputeStatusPending;
      case 'under_review':
        return t.disputeStatusUnderReview;
      case 'resolved':
        return t.disputeStatusResolved;
      case 'rejected':
        return t.disputeStatusRejected;
      default:
        return status;
    }
  }

  String _getStatusDescription(String status, AppLocalizations t) {
    switch (status) {
      case 'pending':
        return t.disputeStatusPendingDesc;
      case 'under_review':
        return t.disputeStatusUnderReviewDesc;
      case 'resolved':
        return t.disputeStatusResolvedDesc;
      case 'rejected':
        return t.disputeStatusRejectedDesc;
      default:
        return '';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'under_review':
        return Icons.search;
      case 'resolved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Widget _buildStatusHeader() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor(_dispute!.status, context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(_dispute!.status),
            color: statusColor,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(_dispute!.status, t),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(_dispute!.status, t),
                  style: TextStyle(
                    color: statusColor.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: isDark ? Colors.grey.shade200 : AppTheme.AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.AppColors.darkBorder : Colors.grey.shade200,
        ),
      ),
      child: Text(
        _dispute!.description,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: isDark ? Colors.grey.shade300 : AppTheme.AppColors.lightTextPrimary,
        ),
      ),
    );
  }

  Widget _buildEvidenceFiles() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _dispute!.evidenceFiles.map((file) {
        final fileName = file.split('/').last;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.AppColors.darkSurface
                : theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppTheme.AppColors.darkBorder
                  : theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                fileName.length > 30 ? '${fileName.substring(0, 27)}...' : fileName,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade300 : AppTheme.AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResolutionSection() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final isResolved = _dispute!.status == 'resolved';
    final isRejected = _dispute!.status == 'rejected';

    final bgColor = isResolved
        ? (isDark ? Colors.green.withOpacity(0.1) : Colors.green.shade50)
        : (isRejected
            ? (isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50)
            : null);

    final borderColor = isResolved
        ? (isDark ? Colors.green.withOpacity(0.3) : Colors.green.shade200)
        : (isRejected
            ? (isDark ? Colors.red.withOpacity(0.3) : Colors.red.shade200)
            : null);

    final textColor = isResolved
        ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
        : (isRejected
            ? (isDark ? Colors.red.shade300 : Colors.red.shade800)
            : null);

    final icon = isResolved ? Icons.check_circle : Icons.cancel;
    final title = isResolved ? t.disputeResolved : t.disputeRejected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _dispute!.resolution!,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (_dispute!.refundAmount != null && _dispute!.refundAmount! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.3) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor ?? Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: textColor,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${t.refundAmount}: ${_dispute!.refundAmount!.toStringAsFixed(2)} ${t.currency}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToContractDetails(int contractId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractScreen(
          contractId: contractId,
          userRole: 'admin',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            t.disputeDetails,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark
              ? AppTheme.AppColors.darkSurface
              : AppTheme.AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_dispute == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            t.disputeDetails,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark
              ? AppTheme.AppColors.darkSurface
              : AppTheme.AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            t.disputeNotFound,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.disputeDetails,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? AppTheme.AppColors.darkSurface
            : AppTheme.AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDisputeDetails,
            tooltip: t.refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDisputeDetails,
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(),
              const SizedBox(height: 20),

              _buildInfoCard(t.disputeInfo, [
                _buildInfoRow(t.disputeId, '#${_dispute!.id}'),
                _buildInfoRow(t.disputeTitle, _dispute!.title),
                _buildInfoRow(t.createdAt, _formatDate(_dispute!.createdAt)),
                // ignore: unnecessary_null_comparison
                if (_dispute!.updatedAt != null)
                  _buildInfoRow(t.lastUpdated, _formatDate(_dispute!.updatedAt)),
              ]),
              const SizedBox(height: 16),

              if (_dispute!.contract != null) ...[
                _buildInfoCard(t.contractInfo, [
                  _buildInfoRow(t.contractId, '#${_dispute!.contract!.id}'),
                  _buildInfoRow(
                    t.projectTitle,
                    _dispute!.contract!.project?.title ?? t.notSpecified,
                  ),
                  _buildInfoRow(
                    t.client,
                    _dispute!.contract!.client?.name ?? t.notSpecified,
                  ),
                  _buildInfoRow(
                    t.freelancer,
                    _dispute!.contract!.freelancer?.name ?? t.notSpecified,
                  ),
                  _buildInfoRow(
                    t.contractAmount,
                    '${_dispute!.contract!.agreedAmount?.toStringAsFixed(2) ?? '0.00'} ${t.currency}',
                  ),
                ]),
                const SizedBox(height: 16),
                Center(
                  child: PrimaryButton(
                    text: t.viewContractDetails,
                    onPressed: () => _navigateToContractDetails(_dispute!.contract!.id!),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _buildInfoCard(t.disputeDescription, [
                _buildDescriptionSection(),
              ]),
              const SizedBox(height: 16),

              if (_dispute!.evidenceFiles.isNotEmpty) ...[
                _buildInfoCard(t.evidenceFiles, [
                  _buildEvidenceFiles(),
                ]),
                const SizedBox(height: 16),
              ],

              if ((_dispute!.status == 'resolved' || _dispute!.status == 'rejected') &&
                  _dispute!.resolution != null &&
                  _dispute!.resolution!.isNotEmpty)
                _buildResolutionSection(),
            ],
          ),
        ),
      ),
    );
  }
}