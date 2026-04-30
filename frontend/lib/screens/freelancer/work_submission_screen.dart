import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../models/contract_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class WorkSubmissionScreen extends StatefulWidget {
  final Contract contract;
  final int? milestoneIndex;
  final Map<String, dynamic>? milestone;

  const WorkSubmissionScreen({
    super.key,
    required this.contract,
    this.milestoneIndex,
    this.milestone,
  });

  @override
  State<WorkSubmissionScreen> createState() => _WorkSubmissionScreenState();
}

class _WorkSubmissionScreenState extends State<WorkSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();

  List<File> _selectedFiles = [];

  List<Map<String, dynamic>> _selectedWebFiles = [];

  List<String> _links = [];
  bool _loading = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.milestone != null) {
      _titleController.text = 'Submit: ${widget.milestone!['title']}';
    } else {
      _titleController.text =
          'Work Submission for ${widget.contract.project?.title}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'zip',
        'rar',
        'jpg',
        'png',
        'mp4',
      ],
    );

    if (result != null) {
      if (kIsWeb) {
        setState(() {
          for (final file in result.files) {
            _selectedWebFiles.add({'name': file.name, 'bytes': file.bytes});
          }
        });
      } else {
        setState(() {
          _selectedFiles.addAll(
            result.paths.map((path) => File(path!)).toList(),
          );
        });
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      if (kIsWeb) {
        _selectedWebFiles.removeAt(index);
      } else {
        _selectedFiles.removeAt(index);
      }
    });
  }

  void _addLink() {
    if (_linkController.text.trim().isNotEmpty) {
      setState(() {
        _links.add(_linkController.text.trim());
        _linkController.clear();
      });
    }
  }

  void _removeLink(int index) {
    setState(() {
      _links.removeAt(index);
    });
  }

  Future<List<String>> _uploadFiles() async {
    final t = AppLocalizations.of(context)!;
    if (_selectedFiles.isEmpty && _selectedWebFiles.isEmpty && _links.isEmpty) {
      Fluttertoast.showToast(msg: t.pleaseAddAtLeastOneFileOrLink);
      return [];
    }

    setState(() => _uploading = true);
    final List<String> uploadedUrls = [];

    if (kIsWeb) {
      for (final fileData in _selectedWebFiles) {
        try {
          final url = await ApiService.uploadWorkFileBytes(
            fileData['bytes'],
            fileData['name'],
          );
          if (url != null) {
            uploadedUrls.add(url);
          }
        } catch (e) {
          print('Error uploading file: $e');
        }
      }
    } else {
      for (final file in _selectedFiles) {
        try {
          final bytes = await file.readAsBytes();
          final fileName = file.path.split('/').last;
          final url = await ApiService.uploadWorkFile(bytes, fileName);
          if (url != null) {
            uploadedUrls.add(url);
          }
        } catch (e) {
          print('Error uploading file: $e');
        }
      }
    }

    setState(() => _uploading = false);
    return uploadedUrls;
  }

  Future<void> _submitWork() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final List<String> fileUrls = await _uploadFiles();

      final response = await ApiService.submitWork(
        contractId: widget.contract.id!,
        milestoneIndex: widget.milestoneIndex,
        title: _titleController.text,
        description: _descriptionController.text,
        files: fileUrls,
        links: _links,
      );

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: t.workSubmittedSuccess);
        Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? t.errorSubmittingWork,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.error}: $e');
    } finally {
      setState(() => _loading = false);
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
        title: Text(t.submitWork),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.submittingWorkFor(
                          widget.contract.project?.title ?? '',
                        ),
                        style: TextStyle(color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: t.submissionTitle,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : Colors.grey.shade50,
                ),
                validator: (value) =>
                    value?.isEmpty == true ? t.pleaseEnterTitle : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: t.description,
                  hintText: t.describeYourWork,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : Colors.grey.shade50,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                t.files,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              if (kIsWeb && _selectedWebFiles.isNotEmpty) ...[
                ..._selectedWebFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final fileData = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileData['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          onPressed: () => _removeFile(index),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],

              if (!kIsWeb && _selectedFiles.isNotEmpty) ...[
                ..._selectedFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.path.split('/').last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          onPressed: () => _removeFile(index),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],

              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.attach_file),
                  label: Text(t.addFiles),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkSurface
                        : Colors.grey.shade200,
                    foregroundColor: theme.colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                t.links,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _linkController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurface
                            : Colors.grey.shade50,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _addLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_links.isNotEmpty) ...[
                ..._links.asMap().entries.map((entry) {
                  final index = entry.key;
                  final link = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.link, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            link,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          onPressed: () => _removeLink(index),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submitWork,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          t.submitWork,
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
      ),
    );
  }
}
