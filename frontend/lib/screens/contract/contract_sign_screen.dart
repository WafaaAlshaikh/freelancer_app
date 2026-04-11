// frontend/lib/screens/contract/contract_sign_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_service.dart';
import '../../utils/pdf_viewer.dart';

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
    requestCode();

    if (widget.sowData != null) {
      _sowHtml = widget.sowData!['sow'];
    }
  }

  Future<void> requestCode() async {
    setState(() => loading = true);

    final result = await ApiService.requestSignCode(widget.contractId);

    setState(() {
      loading = false;
      codeSent = true;
    });

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: "✅ Verification code sent");
      startTimer();
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? "Error");
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

  Future<void> verifyAndSign() async {
    if (codeController.text.length != 6) {
      Fluttertoast.showToast(msg: "❌ Code must be 6 digits");
      return;
    }

    setState(() => loading = true);

    final result = await ApiService.verifyAndSign(
      widget.contractId,
      codeController.text,
    );

    setState(() => loading = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: "✅ Contract signed successfully");

      if (_sowHtml != null && widget.sowData != null) {
        await _generateAndDownloadSOWPDF();
      }

      Navigator.pop(context, true);
    } else {
      setState(() => attempts++);
      Fluttertoast.showToast(msg: result['message'] ?? "❌ Invalid code");

      if (attempts >= 5) {
        Fluttertoast.showToast(msg: "❌ Max attempts. Request new code");
        setState(() {
          codeSent = false;
          attempts = 0;
        });
      }
    }
  }

  Future<void> _generateAndDownloadSOWPDF() async {
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

        _showPDFOptions();
      }
    } catch (e) {
      setState(() => _downloadingPDF = false);
      Fluttertoast.showToast(msg: 'Error generating PDF: $e');
    }
  }

  void _showPDFOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('View PDF'),
              onTap: () {
                Navigator.pop(context);
                if (_sowPdfUrl != null) {
                  PDFViewer.openPDF(_sowPdfUrl!);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.blue),
              title: const Text('Download PDF'),
              onTap: () {
                Navigator.pop(context);
                _downloadPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('Share PDF'),
              onTap: () {
                Navigator.pop(context);
                _sharePDF();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPDF() async {
    if (_sowPdfUrl == null) return;

    try {
      Fluttertoast.showToast(msg: 'Downloading PDF...');
      // TODO: تنفيذ تحميل PDF
      // يمكن استخدام dio أو http client لتحميل الملف
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error downloading PDF: $e');
    }
  }

  Future<void> _sharePDF() async {
    if (_sowPdfUrl == null) return;

    try {
      await Share.share(
        'Contract signed successfully! View the SOW document: ${_sowPdfUrl}',
        subject: 'Contract SOW Document',
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error sharing: $e');
    }
  }

  void _toggleSOWPreview() {
    setState(() => _showSOWPreview = !_showSOWPreview);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Contract"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_sowHtml != null)
            IconButton(
              icon: Icon(
                _showSOWPreview ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: _toggleSOWPreview,
              tooltip: 'Preview SOW',
            ),
        ],
      ),
      body: _showSOWPreview && _sowHtml != null
          ? _buildSOWPreview()
          : _buildSignForm(),
    );
  }

  Widget _buildSignForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.security, size: 64, color: Colors.green.shade700),
          ),

          const SizedBox(height: 24),

          const Text(
            "Electronic Contract Signing",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          const Text(
            "A verification code has been sent to your email",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),

          const SizedBox(height: 32),

          TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            maxLength: 6,
            decoration: InputDecoration(
              hintText: "000000",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              counterText: "",
            ),
          ),

          const SizedBox(height: 16),

          Text(
            "Code valid for: ${(secondsRemaining / 60).floor()}:${(secondsRemaining % 60).toString().padLeft(2, '0')}",
            style: TextStyle(
              color: secondsRemaining < 60 ? Colors.red : Colors.grey,
            ),
          ),

          const SizedBox(height: 24),

          if (_downloadingPDF)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Generating PDF document...'),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: loading ? null : verifyAndSign,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff14A800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Confirm Signature",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: secondsRemaining > 0 ? null : requestCode,
            child: Text(
              secondsRemaining > 0
                  ? "Wait ${secondsRemaining}s to resend"
                  : "Resend Code",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOWPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
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
                      const Text(
                        'AI-Generated SOW',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      Text(
                        'This document was generated by AI and is legally binding',
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
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Statement of Work Preview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please review the document before signing',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('SOW content will appear here\n(HTML rendering)'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }
}
