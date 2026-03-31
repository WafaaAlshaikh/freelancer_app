// frontend/lib/screens/client/create_project_screen.dart - تحديث كامل

import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
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
      Fluttertoast.showToast(msg: "✅ Project created successfully");
      Navigator.pop(context, true);
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
    titleController.removeListener(_debounceAnalysis);
    descriptionController.removeListener(_debounceAnalysis);
    titleController.dispose();
    descriptionController.dispose();
    budgetController.dispose();
    durationController.dispose();
    categoryController.dispose();
    super.dispose();
  }
}
