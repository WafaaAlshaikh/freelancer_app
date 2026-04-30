// screens/workspace/connect_github_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.connectGithubRepository),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.connectGithubDescription,
                      style: TextStyle(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              t.repositoryUrl,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _repoController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'https://github.com/username/repo',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                prefixIcon: Icon(Icons.link, color: theme.colorScheme.primary),
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
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.repositoryUrlExample,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              t.branchOptional,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _branchController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'main',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.call_split,
                  color: theme.colorScheme.primary,
                ),
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
                    : Text(
                        t.connectRepository,
                        style: const TextStyle(
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
    final t = AppLocalizations.of(context)!;
    if (_repoController.text.isEmpty) {
      Fluttertoast.showToast(msg: t.pleaseEnterRepositoryUrl);
      return;
    }

    final repoUrl = _repoController.text.trim();
    if (!repoUrl.contains('github.com')) {
      Fluttertoast.showToast(msg: t.pleaseEnterValidGithubUrl);
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
      Fluttertoast.showToast(msg: t.repositoryConnected);
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? t.error);
    }
  }

  @override
  void dispose() {
    _repoController.dispose();
    _branchController.dispose();
    super.dispose();
  }
}
