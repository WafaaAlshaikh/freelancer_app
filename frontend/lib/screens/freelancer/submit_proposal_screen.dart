// screens/freelancer/submit_proposal_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freelancer_platform/models/usage_limits_model.dart';
import '../../models/project_model.dart';
import '../../services/api_service.dart';
import '../../services/draft_local_storage.dart';
import '../../widgets/milestone_editor.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SubmitProposalScreen extends StatefulWidget {
  final Project project;
  final Map<String, dynamic>? smartPricing;
  const SubmitProposalScreen({
    super.key,
    required this.project,
    this.smartPricing,
  });

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> {
  final _formKey = GlobalKey<FormState>();
  final priceController = TextEditingController();
  final deliveryController = TextEditingController();
  final messageController = TextEditingController();
  List<Map<String, dynamic>> milestones = [];

  bool loading = false;
  double? calculatedPrice;

  bool loadingPricing = false;
  Map<String, dynamic>? smartPricing;
  bool showSmartPricing = false;

  bool loadingMilestones = false;
  Map<String, dynamic>? projectAnalysis;
  bool showAIMilestones = false;
  bool _checkingLimits = false;

  Timer? _proposalDraftTimer;
  DateTime? _proposalDraftSavedAt;
  bool _ignoreProposalDraftListeners = false;

  @override
  void initState() {
    super.initState();
    priceController.text = widget.project.budget?.toStringAsFixed(0) ?? '';
    deliveryController.text = widget.project.duration?.toString() ?? '';
    priceController.addListener(_scheduleProposalDraftSave);
    deliveryController.addListener(_scheduleProposalDraftSave);
    messageController.addListener(_scheduleProposalDraftSave);

    if (widget.smartPricing != null) {
      smartPricing = widget.smartPricing;
      showSmartPricing = true;

      final recommendedPrice = widget.smartPricing!['recommended_price'];
      if (recommendedPrice != null) {
        priceController.text = recommendedPrice.toStringAsFixed(0);
        calculatedPrice = recommendedPrice.toDouble();
      }
    }
    _loadAllAIData();
  }

  Future<void> _loadAllAIData() async {
    await Future.wait([_loadSmartPricing(), _loadProjectAnalysis()]);
    if (!mounted) return;
    await _restoreProposalDraftIfAny();
  }

  void _scheduleProposalDraftSave() {
    if (_ignoreProposalDraftListeners) return;
    final id = widget.project.id;
    if (id == null) return;
    _proposalDraftTimer?.cancel();
    _proposalDraftTimer = Timer(const Duration(milliseconds: 1300), () {
      _persistProposalDraft(id);
    });
  }

  Future<void> _persistProposalDraft(int projectId) async {
    if (_ignoreProposalDraftListeners) return;
    final price = priceController.text.trim();
    final del = deliveryController.text.trim();
    final msg = messageController.text.trim();
    if (price.isEmpty && del.isEmpty && msg.isEmpty && milestones.isEmpty) {
      return;
    }
    await DraftLocalStorage.saveProposalDraft(projectId, {
      'price': price,
      'delivery': del,
      'message': msg,
      'milestones': milestones
          .map((m) => Map<String, dynamic>.from(m))
          .toList(),
    });
    if (mounted) setState(() => _proposalDraftSavedAt = DateTime.now());
  }

  Future<void> _restoreProposalDraftIfAny() async {
    final id = widget.project.id;
    if (id == null) return;
    final d = await DraftLocalStorage.getProposalDraft(id);
    if (d == null || !mounted) return;

    _ignoreProposalDraftListeners = true;
    setState(() {
      final p = d['price']?.toString();
      if (p != null && p.isNotEmpty) priceController.text = p;
      final del = d['delivery']?.toString();
      if (del != null && del.isNotEmpty) deliveryController.text = del;
      final msg = d['message']?.toString();
      if (msg != null && msg.isNotEmpty) messageController.text = msg;
      final ms = DraftLocalStorage.milestonesFromJson(d['milestones']);
      if (ms.isNotEmpty) milestones = ms;
    });
    _ignoreProposalDraftListeners = false;

    if (mounted) {
      Fluttertoast.showToast(
        msg: 'Restored your saved proposal draft',
        backgroundColor: Colors.teal,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _loadSmartPricing() async {
    if (widget.project.id == null) return;

    setState(() => loadingPricing = true);

    try {
      final response = await ApiService.getSmartPricing(widget.project.id!);
      print('📊 Smart pricing response: $response');

      if (response['success'] == true && response['pricing'] != null) {
        setState(() {
          smartPricing = response['pricing'];
          showSmartPricing = true;
          loadingPricing = false;
        });
      } else {
        setState(() => loadingPricing = false);
      }
    } catch (e) {
      print('❌ Error loading smart pricing: $e');
      setState(() => loadingPricing = false);
    }
  }

  Future<void> _loadProjectAnalysis() async {
    if (widget.project.id == null) return;

    setState(() => loadingMilestones = true);

    try {
      print('🔍 Calling analyzeProject with:');
      print('  title: ${widget.project.title}');
      print('  description: ${widget.project.description}');
      print('  budget: ${widget.project.budget}');

      final response = await ApiService.analyzeProject(
        title: widget.project.title ?? '',
        description: widget.project.description ?? '',
        category: widget.project.category,
        skills: widget.project.skills,
        budget: widget.project.budget,
      );

      print('📊 Raw response from API: $response');
      print('📊 Response type: ${response.runtimeType}');
      print('📊 Response keys: ${response.keys}');

      if (response.isEmpty) {
        print('⚠️ Empty response from API, using default milestones');
        setState(() {
          loadingMilestones = false;
          showAIMilestones = false;
        });
        _initDefaultMilestones();
        return;
      }

      final milestones = response['suggested_milestones'];
      print('📊 Suggested milestones: $milestones');
      print('📊 Milestones count: ${milestones?.length ?? 0}');

      if (milestones != null && milestones.isNotEmpty) {
        print('✅ Applying ${milestones.length} milestones from API');
        setState(() {
          projectAnalysis = response;
          showAIMilestones = true;
          loadingMilestones = false;
        });
        _applyAIMilestones(milestones);
      } else {
        print('⚠️ No milestones in response, using default');
        setState(() {
          loadingMilestones = false;
          showAIMilestones = false;
        });
        _initDefaultMilestones();
      }
    } catch (e, stacktrace) {
      print('❌ Error loading project analysis: $e');
      print('❌ Stacktrace: $stacktrace');
      setState(() => loadingMilestones = false);
      _initDefaultMilestones();
    }
  }

  void _applyAIMilestones(List<dynamic> aiMilestones) {
    final price =
        double.tryParse(priceController.text) ?? widget.project.budget ?? 1000;

    milestones = aiMilestones.map((m) {
      return {
        'title': m['title'] ?? 'Milestone',
        'description': m['description'] ?? '',
        'amount': price * (m['percentage'] / 100),
        'percentage': m['percentage'] ?? 0,
        'due_date': _calculateDueDate(m['percentage'] ?? 0, price),
        'status': 'pending',
      };
    }).toList();

    setState(() {});
  }

  String _calculateDueDate(double percentage, double price) {
    final totalDays =
        int.tryParse(deliveryController.text) ?? widget.project.duration ?? 21;

    int daysOffset;
    if (percentage <= 20) {
      daysOffset = (totalDays * 0.2).round();
    } else if (percentage <= 50) {
      daysOffset = (totalDays * 0.5).round();
    } else {
      daysOffset = totalDays;
    }

    return DateTime.now().add(Duration(days: daysOffset)).toIso8601String();
  }

  void _initDefaultMilestones() {
    final price =
        double.tryParse(priceController.text) ?? widget.project.budget ?? 1000;
    final totalDays =
        int.tryParse(deliveryController.text) ?? widget.project.duration ?? 21;

    milestones = [
      {
        'title': 'Project Setup & Planning',
        'description':
            'Initial setup, requirements analysis, and architecture design',
        'amount': price * 0.2,
        'percentage': 20,
        'due_date': DateTime.now()
            .add(Duration(days: (totalDays * 0.2).round()))
            .toIso8601String(),
        'status': 'pending',
      },
      {
        'title': 'Core Development',
        'description': 'Main features implementation',
        'amount': price * 0.5,
        'percentage': 50,
        'due_date': DateTime.now()
            .add(Duration(days: (totalDays * 0.6).round()))
            .toIso8601String(),
        'status': 'pending',
      },
      {
        'title': 'Testing & Final Delivery',
        'description': 'QA testing, bug fixes, and final deployment',
        'amount': price * 0.3,
        'percentage': 30,
        'due_date': DateTime.now()
            .add(Duration(days: totalDays))
            .toIso8601String(),
        'status': 'pending',
      },
    ];
    setState(() {});
  }

  void _applySmartPricing() {
    if (smartPricing == null) return;

    final recommendedPrice = smartPricing!['recommended_price'];
    if (recommendedPrice != null) {
      setState(() {
        priceController.text = recommendedPrice.toStringAsFixed(0);
        calculatedPrice = recommendedPrice.toDouble();
      });

      if (milestones.isNotEmpty) {
        _updateMilestonesAmounts(recommendedPrice.toDouble());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ AI recommended price applied!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAIMilestonesDialog() {
    if (projectAnalysis == null ||
        projectAnalysis!['suggested_milestones'] == null)
      return;

    final aiMilestones = projectAnalysis!['suggested_milestones'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.orange),
            SizedBox(width: 8),
            Text("AI Suggested Milestones"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Based on your project analysis, here are recommended milestones:",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...List.generate(aiMilestones.length, (index) {
                final m = aiMilestones[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              m['title'] ?? 'Milestone',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${m['percentage']}%",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m['description'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyAIMilestones(aiMilestones);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "✅ AI milestones applied! You can edit them below.",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Apply Milestones"),
          ),
        ],
      ),
    );
  }

  void _updateMilestonesAmounts(double totalAmount) {
    for (int i = 0; i < milestones.length; i++) {
      final percentage = milestones[i]['percentage'] ?? 0;
      milestones[i]['amount'] = totalAmount * percentage / 100;
    }
    setState(() {});
  }

  void _updateMilestonesDueDates(int totalDays) {
    for (int i = 0; i < milestones.length; i++) {
      final percentage = milestones[i]['percentage'] ?? 0;
      int daysOffset;
      if (percentage <= 20) {
        daysOffset = (totalDays * 0.2).round();
      } else if (percentage <= 50) {
        daysOffset = (totalDays * 0.5).round();
      } else {
        daysOffset = totalDays;
      }
      final dueDate = DateTime.now().add(Duration(days: daysOffset));
      milestones[i]['due_date'] = dueDate.toIso8601String();
    }
    setState(() {});
  }

  double _calculateTotalAmount() {
    double total = 0;
    for (var milestone in milestones) {
      total += milestone['amount'] ?? 0;
    }
    return total;
  }

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;

    final totalMilestones = _calculateTotalAmount();
    final price = double.parse(priceController.text);

    if (milestones.isNotEmpty && (totalMilestones - price).abs() > 0.01) {
      Fluttertoast.showToast(
        msg:
            'Total milestone amounts (\$${totalMilestones.toStringAsFixed(0)}) '
            'does not match your price (\$${price.toStringAsFixed(0)})',
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => loading = true);
    setState(() => _checkingLimits = true);
    final usageResponse = await ApiService.getUserUsage();
    setState(() => _checkingLimits = false);

    if (usageResponse['usage'] != null) {
      final usage = UsageLimits.fromJson(usageResponse['usage']);
      if (!usage.canSubmitProposal) {
        Fluttertoast.showToast(
          msg:
              'You have reached your proposal limit. Please upgrade to submit more proposals.',
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
        );
        return;
      }
    }

    try {
      final result = await ApiService.submitProposal(
        projectId: widget.project.id!,
        price: price,
        deliveryTime: int.parse(deliveryController.text),
        proposalText: messageController.text,
        milestones: milestones,
      );

      if (result['proposal'] != null) {
        await DraftLocalStorage.clearProposalDraft(widget.project.id!);
        Fluttertoast.showToast(
          msg: "✅ Proposal submitted successfully!",
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? "Error submitting proposal",
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit Proposal"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_proposalDraftSavedAt != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  'Draft saved',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.teal.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (loadingPricing || loadingMilestones)
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.save_outlined,
                      size: 18,
                      color: Colors.teal.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Proposal autosaves on this device while you edit.',
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          "You're applying for:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.project.title ?? 'Untitled Project',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.project.description ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Budget: \$${widget.project.budget?.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Duration: ${widget.project.duration} days',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (showSmartPricing && smartPricing != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade50, Colors.orange.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.amber, Colors.orange],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "AI Smart Pricing",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Recommended Price",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "\$${smartPricing!['recommended_price']?.toStringAsFixed(0) ?? '?'}",
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Hourly Rate",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "\$${smartPricing!['recommended_hourly_rate']?.toStringAsFixed(0) ?? '?'}/hr",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Est. Hours",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${smartPricing!['estimated_hours'] ?? '?'} hrs",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Icon(
                            Icons.analytics,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Confidence: ${smartPricing!['confidence_score'] ?? 85}%",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          if (smartPricing!['justification'] != null)
                            Flexible(
                              child: Text(
                                smartPricing!['justification'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _applySmartPricing,
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text("Use Recommended Price"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (showAIMilestones &&
                  projectAnalysis != null &&
                  projectAnalysis!['suggested_milestones'] != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.teal.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.green, Colors.teal],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "AI Milestone Suggestions",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Based on project analysis, here are suggested milestones:",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        (projectAnalysis!['suggested_milestones'] as List)
                            .take(2)
                            .length,
                        (index) {
                          final m =
                              projectAnalysis!['suggested_milestones'][index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m['title'] ?? 'Milestone',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        m['description'] ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${m['percentage']}%",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if ((projectAnalysis!['suggested_milestones'] as List)
                              .length >
                          2)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "+ ${(projectAnalysis!['suggested_milestones'] as List).length - 2} more milestones",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showAIMilestonesDialog,
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text("View & Apply AI Milestones"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal,
                            side: const BorderSide(color: Colors.teal),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              const Text(
                "Your Proposal",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Fill in the details below to submit your proposal",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              const Text(
                "Your Price (\$)",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.attach_money),
                  hintText: "Enter your proposed price",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  suffix: Text(
                    'USD',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    calculatedPrice = double.tryParse(value);
                    if (calculatedPrice != null && milestones.isNotEmpty) {
                      _updateMilestonesAmounts(calculatedPrice!);
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid price';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              const Text(
                "Delivery Time (days)",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: deliveryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.access_time),
                  hintText: "How many days you need?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  suffix: Text(
                    'days',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                onChanged: (value) {
                  final days = int.tryParse(value);
                  if (days != null && milestones.isNotEmpty) {
                    _updateMilestonesDueDates(days);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter delivery time';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  if (int.parse(value) <= 0) {
                    return 'Delivery time must be greater than 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Text(
                    "Payment Milestones",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  if (showAIMilestones)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: Colors.teal,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "AI Generated",
                            style: TextStyle(fontSize: 10, color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Define the project phases and payment schedule",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),

              MilestoneEditor(
                milestones: milestones,
                onChanged: (newMilestones) {
                  setState(() {
                    milestones = newMilestones;
                  });
                  _scheduleProposalDraftSave();
                },
              ),

              const SizedBox(height: 16),

              const Text(
                "Cover Letter",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: messageController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText:
                      "Explain why you're the best candidate for this project...\n"
                      "- Your relevant experience\n"
                      "- How you'll approach the project\n"
                      "- Any questions you have",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please write a cover letter';
                  }
                  if (value.length < 50) {
                    return 'Cover letter should be at least 50 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${messageController.text.length}/5000',
                  style: TextStyle(
                    color: messageController.text.length >= 5000
                        ? Colors.red
                        : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (calculatedPrice != null && widget.project.budget != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: calculatedPrice! <= widget.project.budget!
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        calculatedPrice! <= widget.project.budget!
                            ? Icons.thumb_up
                            : Icons.warning,
                        color: calculatedPrice! <= widget.project.budget!
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          calculatedPrice! <= widget.project.budget!
                              ? 'Your price is within the project budget'
                              : 'Your price is above the project budget. Make sure to justify this in your cover letter.',
                          style: TextStyle(
                            color: calculatedPrice! <= widget.project.budget!
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (milestones.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Schedule Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...milestones.asMap().entries.map((entry) {
                        final index = entry.key;
                        final milestone = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  milestone['title'] ?? 'Milestone',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                '\$${milestone['amount']?.toStringAsFixed(0) ?? '0'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${_calculateTotalAmount().toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : _submitProposal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff14A800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Proposal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  'By submitting, you agree to our Terms of Service',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _proposalDraftTimer?.cancel();
    priceController.removeListener(_scheduleProposalDraftSave);
    deliveryController.removeListener(_scheduleProposalDraftSave);
    messageController.removeListener(_scheduleProposalDraftSave);
    priceController.dispose();
    deliveryController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
