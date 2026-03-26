// screens/workspace/connect_github_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

class ConnectGithubScreen extends StatefulWidget {
  final int contractId;

  const ConnectGithubScreen({super.key, required this.contractId});

  @override
  State<ConnectGithubScreen> createState() => _ConnectGithubScreenState();
}

class _ConnectGithubScreenState extends State<ConnectGithubScreen> {
  final _repoController = TextEditingController();
  final _branchController = TextEditingController(text: 'main');
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect GitHub Repository'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Connect your GitHub repository to track commits and show your progress to the client.',
                      style: TextStyle(color: Colors.blue.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Repository URL',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _repoController,
              decoration: InputDecoration(
                hintText: 'https://github.com/username/repo',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Example: https://github.com/flutter/flutter',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 16),

            const Text(
              'Branch (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _branchController,
              decoration: InputDecoration(
                hintText: 'main',
                prefixIcon: const Icon(Icons.call_split),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _connect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Connect Repository',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connect() async {
    if (_repoController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter repository URL');
      return;
    }

    final repoUrl = _repoController.text.trim();
    if (!repoUrl.contains('github.com')) {
      Fluttertoast.showToast(msg: 'Please enter a valid GitHub URL');
      return;
    }

    setState(() => _loading = true);

    final result = await ApiService.connectGithubRepo(
      contractId: widget.contractId,
      repoUrl: _repoController.text,
      branch: _branchController.text,
    );

    setState(() => _loading = false);

    if (result['repo'] != null) {
      Fluttertoast.showToast(msg: '✅ Repository connected');
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? 'Error');
    }
  }

  @override
  void dispose() {
    _repoController.dispose();
    _branchController.dispose();
    super.dispose();
  }
}
