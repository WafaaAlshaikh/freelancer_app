// frontend/lib/screens/contract/contract_sign_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../utils/pdf_viewer.dart';
import '../../theme/app_theme.dart';

class ContractSignScreen extends StatefulWidget {
  final int contractId;
  final String userRole;
  final Map<String, dynamic>? sowData;

  const ContractSignScreen({
    super.key,
    required this.contractId,
    required this.userRole,
    this.sowData,
  });

  @override
  State<ContractSignScreen> createState() => _ContractSignScreenState();
}

class _ContractSignScreenState extends State<ContractSignScreen> {
  final TextEditingController codeController = TextEditingController();
  bool loading = false;
  bool codeSent = false;
  int secondsRemaining = 600;
  int attempts = 0;

  bool _showSOWPreview = false;
  String? _sowHtml;
  String? _sowPdfUrl;
  bool _downloadingPDF = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        requestCode(context);
      }
    });

    if (widget.sowData != null) {
      _sowHtml = widget.sowData!['sow'];
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> requestCode(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (!mounted) return;

    setState(() => loading = true);

    final result = await ApiService.requestSignCode(widget.contractId);

    if (!mounted) return;

    setState(() {
      loading = false;
      codeSent = true;
    });

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: t.verificationCodeSent);
      startTimer();
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? t.error);
    }
  }

  void startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && secondsRemaining > 0) {
        setState(() => secondsRemaining--);
        startTimer();
      }
    });
  }

  Future<void> verifyAndSign(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (codeController.text.length != 6) {
      Fluttertoast.showToast(msg: t.codeMustBe6Digits);
      return;
    }

    setState(() => loading = true);

    final result = await ApiService.verifyAndSign(
      widget.contractId,
      codeController.text,
    );

    setState(() => loading = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: t.contractSignedSuccess);

      if (_sowHtml != null && widget.sowData != null) {
        await _generateAndDownloadSOWPDF(context);
      }

      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() => attempts++);
      Fluttertoast.showToast(msg: result['message'] ?? t.invalidCode);

      if (attempts >= 5) {
        Fluttertoast.showToast(msg: t.maxAttemptsReached);
        setState(() {
          codeSent = false;
          attempts = 0;
        });
      }
    }
  }

  Future<void> _generateAndDownloadSOWPDF(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    setState(() => _downloadingPDF = true);

    try {
      final pdfUrl = await ApiService.generateSOWPDF(
        contractId: widget.contractId,
        sowData: widget.sowData!,
      );

      if (pdfUrl != null && mounted) {
        setState(() {
          _sowPdfUrl = pdfUrl;
          _downloadingPDF = false;
        });

        _showPDFOptions(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadingPDF = false);
        Fluttertoast.showToast(msg: '${t.errorGeneratingPDF}: $e');
      }
    }
  }

  void _showPDFOptions(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(
                t.viewPDF,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                if (_sowPdfUrl != null) {
                  PDFViewer.openPDF(_sowPdfUrl!);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.blue),
              title: Text(
                t.downloadPDF,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                _downloadPDF(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: Text(
                t.sharePDF,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                _sharePDF(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPDF(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (_sowPdfUrl == null) return;

    try {
      Fluttertoast.showToast(msg: t.downloadingPDF);
      // TODO: تنفيذ تحميل PDF
      // يمكن استخدام dio أو http client لتحميل الملف
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.errorDownloadingPDF}: $e');
    }
  }

  Future<void> _sharePDF(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (_sowPdfUrl == null) return;

    try {
      await Share.share(
        '${t.contractSignedSuccessViewSOW}: $_sowPdfUrl',
        subject: t.contractSOWDocument,
      );
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.errorSharing}: $e');
    }
  }

  void _toggleSOWPreview() {
    setState(() => _showSOWPreview = !_showSOWPreview);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.signContract),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          if (_sowHtml != null)
            IconButton(
              icon: Icon(
                _showSOWPreview ? Icons.visibility_off : Icons.visibility,
                color: theme.iconTheme.color,
              ),
              onPressed: _toggleSOWPreview,
              tooltip: t.previewSOW,
            ),
        ],
      ),
      body: _showSOWPreview && _sowHtml != null
          ? _buildSOWPreview()
          : _buildSignForm(),
    );
  }

  Widget _buildSignForm() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.security,
              size: 64,
              color: theme.colorScheme.secondary,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            t.electronicContractSigning,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            t.verificationCodeSentToEmail,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.gray),
          ),

          const SizedBox(height: 32),

          TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              letterSpacing: 8,
              color: theme.colorScheme.onSurface,
            ),
            maxLength: 6,
            decoration: InputDecoration(
              hintText: "000000",
              hintStyle: TextStyle(color: AppColors.gray),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade50,
              counterText: "",
            ),
          ),

          const SizedBox(height: 16),

          Text(
            '${t.codeValidFor}: ${(secondsRemaining / 60).floor()}:${(secondsRemaining % 60).toString().padLeft(2, '0')}',
            style: TextStyle(
              color: secondsRemaining < 60 ? AppColors.danger : AppColors.gray,
            ),
          ),

          const SizedBox(height: 24),

          if (_downloadingPDF)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    t.generatingPDFDocument,
                    style: TextStyle(color: AppColors.gray),
                  ),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: loading ? null : () => verifyAndSign(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      t.confirmSignature,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: secondsRemaining > 0 ? null : () => requestCode(context),
            child: Text(
              secondsRemaining > 0
                  ? '${t.waitSecondsToResend(secondsRemaining)}'
                  : t.resendCode,
              style: TextStyle(
                color: secondsRemaining > 0
                    ? AppColors.gray
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOWPreview() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.aiGeneratedSOW,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      Text(
                        t.aiGeneratedSOWDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_sowPdfUrl != null)
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    onPressed: () => PDFViewer.openPDF(_sowPdfUrl!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  t.statementOfWorkPreview,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.reviewBeforeSigning,
                  style: TextStyle(color: AppColors.gray),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                t.sowContentWillAppearHere,
                style: TextStyle(color: AppColors.gray),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
