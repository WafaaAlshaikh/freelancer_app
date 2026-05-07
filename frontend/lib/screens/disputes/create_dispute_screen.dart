// screens/disputes/create_dispute_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart' as AppTheme;
import '../../widgets/primary_button.dart';

class CreateDisputeScreen extends StatefulWidget {
  final int contractId;

  const CreateDisputeScreen({Key? key, required this.contractId})
    : super(key: key);

  @override
  State<CreateDisputeScreen> createState() => _CreateDisputeScreenState();
}

class _CreateDisputeScreenState extends State<CreateDisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _evidenceFiles = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitDispute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.createDispute(
        contractId: widget.contractId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        evidenceFiles: _evidenceFiles,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t?.disputeSubmittedSuccess ??
                  'Dispute submitted successfully. It will be reviewed by admin.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ??
                  'An error occurred while submitting the dispute',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t?.connectionError ?? 'Connection error. Please try again.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImportantNotesSection() {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final notes = [
      t?.disputeNote1 ?? 'Dispute will be reviewed by admin team',
      t?.disputeNote2 ?? 'Please provide clear and reliable evidence',
      t?.disputeNote3 ?? 'Dispute resolution may take several days',
      t?.disputeNote4 ?? 'All parties will be notified of final decision',
    ];

    final bgColor = isDark
        ? AppTheme.AppColors.darkSurface.withOpacity(0.5)
        : AppTheme.AppColors.lightInfoBg;

    final borderColor = isDark
        ? AppTheme.AppColors.darkBorder
        : AppTheme.AppColors.lightInfoBorder;

    final textColor = isDark
        ? AppTheme.AppColors.darkTextSecondary
        : AppTheme.AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                t?.importantNotes ?? 'Important Notes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t?.createDispute ?? 'Create Dispute',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? AppTheme.AppColors.darkSurface
            : AppTheme.AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  t?.disputeInstruction ??
                      'Please provide clear details about the dispute',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.AppColors.darkTextSecondary
                        : AppTheme.AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: t?.disputeTitleHint ?? 'Dispute title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t?.titleRequired ?? 'Please enter dispute title';
                  }
                  if (value.trim().length < 5) {
                    return t?.titleTooShort ??
                        'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText:
                      t?.disputeDescriptionHint ??
                      'Please explain the issue in detail',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t?.descriptionRequired ??
                        'Please enter dispute description';
                  }
                  if (value.trim().length < 20) {
                    return t?.descriptionTooShort ??
                        'Description must be at least 20 characters';
                  }
                  return null;
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t?.evidenceAttachments ?? 'Evidence Attachments',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : AppTheme.AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.AppColors.darkCard
                      : AppTheme.AppColors.lightCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.AppColors.darkBorder
                        : AppTheme.AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 24,
                      color: theme.colorScheme.primary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t?.uploadEvidenceHint ??
                            'Upload images, documents or screenshots (coming soon)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.AppColors.darkTextSecondary
                              : AppTheme.AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildImportantNotesSection(),
              const SizedBox(height: 32),

              PrimaryButton(
                text: t?.submitDispute ?? 'Submit Dispute',
                onPressed: _submitDispute,
                loading: _isLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
