// frontend/lib/screens/client/create_project_screen.dart - تحديث كامل

import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/project_post_templates.dart';
import '../../services/api_service.dart';
import '../../services/draft_local_storage.dart';
import '../../widgets/ai_analysis_card.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final budgetController = TextEditingController();
  final durationController = TextEditingController();
  final categoryController = TextEditingController();

  List<String> selectedSkills = [];
  bool loading = false;
  bool analyzing = false;
  Map<String, dynamic>? aiAnalysis;
  bool showAIAnalysis = false;

  Timer? _draftSaveTimer;
  DateTime? _draftSavedAt;
  bool _restoringDraft = false;

  final List<String> availableSkills = [
    'Flutter',
    'React',
    'Node.js',
    'Python',
    'UI/UX',
    'Graphic Design',
    'Content Writing',
    'SEO',
    'Marketing',
    'WordPress',
    'PHP',
    'Java',
    'Swift',
    'Django',
    'AWS',
    'Docker',
    'Kubernetes',
    'MongoDB',
    'PostgreSQL',
  ];

  final List<String> categories = [
    'Mobile Development',
    'Web Development',
    'Backend Development',
    'UI/UX Design',
    'Graphic Design',
    'Content Writing',
    'Digital Marketing',
    'DevOps',
    'Database',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    titleController.addListener(_debounceAnalysis);
    descriptionController.addListener(_debounceAnalysis);
    titleController.addListener(_scheduleProjectDraftSave);
    descriptionController.addListener(_scheduleProjectDraftSave);
    budgetController.addListener(_scheduleProjectDraftSave);
    durationController.addListener(_scheduleProjectDraftSave);
    categoryController.addListener(_scheduleProjectDraftSave);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadSavedProjectDraft(),
    );
  }

  Map<String, dynamic> _projectDraftSnapshot() {
    return {
      'title': titleController.text,
      'description': descriptionController.text,
      'budget': budgetController.text,
      'duration': durationController.text,
      'category': categoryController.text,
      'skills': List<String>.from(selectedSkills),
    };
  }

  bool _hasDraftPayload() {
    return titleController.text.trim().isNotEmpty ||
        descriptionController.text.trim().isNotEmpty ||
        budgetController.text.trim().isNotEmpty ||
        selectedSkills.isNotEmpty;
  }

  void _scheduleProjectDraftSave() {
    if (_restoringDraft) return;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 1200), () async {
      if (!mounted || !_hasDraftPayload()) return;
      await DraftLocalStorage.saveProjectCreateDraft(_projectDraftSnapshot());
      if (mounted) setState(() => _draftSavedAt = DateTime.now());
    });
  }

  Future<void> _loadSavedProjectDraft() async {
    final d = await DraftLocalStorage.getProjectCreateDraft();
    if (!mounted || d == null) return;
    if (!DraftLocalStorage.isMeaningfulProjectDraft(d)) return;
    _restoringDraft = true;
    setState(() {
      titleController.text = d['title']?.toString() ?? '';
      descriptionController.text = d['description']?.toString() ?? '';
      budgetController.text = d['budget']?.toString() ?? '';
      durationController.text = d['duration']?.toString() ?? '';
      categoryController.text = d['category']?.toString() ?? '';
      final sk = d['skills'];
      if (sk is List) {
        selectedSkills = sk.map((e) => e.toString()).toList();
      }
    });
    _restoringDraft = false;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Continued from your saved draft'),
        action: SnackBarAction(
          label: 'Clear',
          onPressed: _confirmClearProjectDraft,
        ),
      ),
    );
  }

  void _applyTemplate(ProjectPostTemplate t) {
    setState(() {
      titleController.text = t.title;
      descriptionController.text = t.description;
      categoryController.text = t.category;
      budgetController.text = t.budgetHint;
      durationController.text = t.durationHint;
      selectedSkills = t.skills
          .where((s) => availableSkills.contains(s))
          .toList();
    });
    _scheduleProjectDraftSave();
    _debounceAnalysis();
    Fluttertoast.showToast(msg: 'Template applied — edit and post when ready');
  }

  Future<void> _confirmClearProjectDraft() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear draft?'),
        content: const Text('Remove the saved project draft from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await DraftLocalStorage.clearProjectCreateDraft();
    setState(() {
      titleController.clear();
      descriptionController.clear();
      budgetController.clear();
      durationController.clear();
      categoryController.clear();
      selectedSkills.clear();
      aiAnalysis = null;
      showAIAnalysis = false;
      _draftSavedAt = null;
    });
    Fluttertoast.showToast(msg: 'Draft cleared');
  }

  void _openTemplatesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Project templates',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Prefill fields — still edit before posting.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...ProjectPostTemplates.all.map((t) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(t.name),
                  subtitle: Text(t.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyTemplate(t);
                  },
                ),
              );
            }),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _confirmClearProjectDraft();
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear saved draft'),
            ),
          ],
        ),
      ),
    );
  }

  Timer? _debounceTimer;
  void _debounceAnalysis() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (titleController.text.length > 10 &&
          descriptionController.text.length > 30) {
        _analyzeProject();
      }
    });
  }

  Future<void> _analyzeProject() async {
    if (analyzing) return;

    setState(() {
      analyzing = true;
      showAIAnalysis = false;
    });

    try {
      final analysis = await ApiService.analyzeProject(
        title: titleController.text,
        description: descriptionController.text,
        category: categoryController.text,
        skills: selectedSkills,
        budget: double.tryParse(budgetController.text),
      );

      setState(() {
        aiAnalysis = analysis;
        showAIAnalysis = true;
        analyzing = false;

        if (analysis['price_range']?['recommended'] != null &&
            budgetController.text.isEmpty) {
          budgetController.text = analysis['price_range']['recommended']
              .toString();
        }
        if (analysis['estimated_duration_days'] != null &&
            durationController.text.isEmpty) {
          durationController.text = analysis['estimated_duration_days']
              .toString();
        }
        if (analysis['difficulty_level'] != null &&
            categoryController.text.isEmpty) {}
      });
    } catch (e) {
      setState(() => analyzing = false);
      print('Analysis error: $e');
    }
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final result = await ApiService.createProject(
      title: titleController.text,
      description: descriptionController.text,
      budget: double.parse(budgetController.text),
      duration: int.parse(durationController.text),
      category: categoryController.text.isNotEmpty
          ? categoryController.text
          : 'other',
      skills: selectedSkills,
    );

    setState(() => loading = false);

    if (result['project'] != null) {
      await DraftLocalStorage.clearProjectCreateDraft();
      await DraftLocalStorage.clearPublishReminderSnooze();
      Fluttertoast.showToast(msg: "✅ Project created successfully");
      if (mounted) Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? "Error creating project",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post New Project"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_draftSavedAt != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  'Draft saved',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Templates',
            icon: const Icon(Icons.article_outlined),
            onPressed: _openTemplatesSheet,
          ),
          if (analyzing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Project Details",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Fill in the details below. AI will analyze and suggest improvements.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_done_outlined,
                      size: 18,
                      color: Colors.teal.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your progress is saved automatically on this device.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.teal.shade900,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (showAIAnalysis && aiAnalysis != null)
                AIAnalysisCard(
                  analysis: aiAnalysis!,
                  onApplySuggestion: (key, value) {
                    setState(() {
                      if (key == 'budget')
                        budgetController.text = value.toString();
                      if (key == 'duration')
                        durationController.text = value.toString();
                      if (key == 'milestones') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Suggested milestones added to proposal",
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    });
                  },
                ),

              const SizedBox(height: 16),

              const Text(
                "Project Title",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: "e.g., Build an E-commerce App",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value?.isEmpty == true
                    ? 'Please enter project title'
                    : null,
              ),
              const SizedBox(height: 16),

              const Text(
                "Project Description",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: descriptionController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText:
                      "Describe your project in detail...\n- What do you need?\n- What are your expectations?\n- Any specific requirements?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Please enter description' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Budget (\$)",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: budgetController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixText: '\$ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Required';
                            if (double.tryParse(value!) == null)
                              return 'Invalid number';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Duration (days)",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            suffixText: 'days',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Required';
                            if (int.tryParse(value!) == null)
                              return 'Invalid number';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                "Category",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: categoryController.text.isNotEmpty
                    ? categoryController.text
                    : null,
                hint: const Text("Select a category"),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  setState(() => categoryController.text = value ?? '');
                  _analyzeProject();
                },
              ),
              const SizedBox(height: 16),

              const Text(
                "Required Skills",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableSkills.map((skill) {
                  final isSelected = selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedSkills.add(skill);
                        } else {
                          selectedSkills.remove(skill);
                        }
                      });
                      _analyzeProject();
                      _scheduleProjectDraftSave();
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : _createProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff14A800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Post Project",
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _draftSaveTimer?.cancel();
    titleController.removeListener(_debounceAnalysis);
    descriptionController.removeListener(_debounceAnalysis);
    titleController.removeListener(_scheduleProjectDraftSave);
    descriptionController.removeListener(_scheduleProjectDraftSave);
    budgetController.removeListener(_scheduleProjectDraftSave);
    durationController.removeListener(_scheduleProjectDraftSave);
    categoryController.removeListener(_scheduleProjectDraftSave);
    titleController.dispose();
    descriptionController.dispose();
    budgetController.dispose();
    durationController.dispose();
    categoryController.dispose();
    super.dispose();
  }
}
