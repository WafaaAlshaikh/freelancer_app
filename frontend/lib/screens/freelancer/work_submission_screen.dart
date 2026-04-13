// ===== frontend/lib/screens/freelancer/work_submission_screen.dart =====
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/contract_model.dart';
import '../../services/api_service.dart';

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
      setState(() {
        _selectedFiles.addAll(result.paths.map((path) => File(path!)).toList());
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
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
    if (_selectedFiles.isEmpty && _links.isEmpty) {
      Fluttertoast.showToast(msg: 'Please add at least one file or link');
      return [];
    }

    setState(() => _uploading = true);

    final List<String> uploadedUrls = [];

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

    setState(() => _uploading = false);
    return uploadedUrls;
  }

  Future<void> _submitWork() async {
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
        Fluttertoast.showToast(msg: 'Work submitted successfully!');
        Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? 'Error submitting work',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Work'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Submitting work for: ${widget.contract.project?.title}',
                        style: TextStyle(color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Submission Title',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what you have completed...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Files',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              if (_selectedFiles.isNotEmpty) ...[
                ..._selectedFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.path.split('/').last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
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
                  label: const Text('Add Files'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Links',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _linkController,
                      decoration: const InputDecoration(
                        hintText: 'https://...',
                        border: OutlineInputBorder(),
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
                        backgroundColor: const Color(0xff14A800),
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
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            link,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
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
                    backgroundColor: const Color(0xff14A800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Work',
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
      ),
    );
  }
}
