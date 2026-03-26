// screens/freelancer/submit_proposal_screen.dart
import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../services/api_service.dart';
import '../../widgets/milestone_editor.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SubmitProposalScreen extends StatefulWidget {
  final Project project;
  const SubmitProposalScreen({super.key, required this.project});

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

  @override
  void initState() {
    super.initState();
    priceController.text = widget.project.budget?.toStringAsFixed(0) ?? '';
    deliveryController.text = widget.project.duration?.toString() ?? '';
    
    _initDefaultMilestones();
  }
  
  void _initDefaultMilestones() {
    if (widget.project.budget != null && widget.project.budget! > 0) {
      milestones = [
        {
          'title': 'Project Start',
          'description': 'Initial setup and planning',
          'amount': widget.project.budget! * 0.3,
          'percentage': 30,
          'due_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'status': 'pending',
        },
        {
          'title': 'Development Phase',
          'description': 'Core development and implementation',
          'amount': widget.project.budget! * 0.4,
          'percentage': 40,
          'due_date': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
          'status': 'pending',
        },
        {
          'title': 'Final Delivery',
          'description': 'Testing, fixes, and final delivery',
          'amount': widget.project.budget! * 0.3,
          'percentage': 30,
          'due_date': DateTime.now().add(const Duration(days: 21)).toIso8601String(),
          'status': 'pending',
        },
      ];
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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

              const Text(
                "Payment Milestones",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  hintText: "Explain why you're the best candidate for this project...\n"
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
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateMilestonesAmounts(double totalAmount) {
    final percentages = [30, 40, 30];
    for (int i = 0; i < milestones.length && i < percentages.length; i++) {
      milestones[i]['amount'] = totalAmount * percentages[i] / 100;
      milestones[i]['percentage'] = percentages[i];
    }
    setState(() {});
  }

  void _updateMilestonesDueDates(int totalDays) {
    final durations = [7, 14, 21];
    for (int i = 0; i < milestones.length && i < durations.length; i++) {
      final dueDate = DateTime.now().add(Duration(days: durations[i]));
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
        msg: 'Total milestone amounts (\$${totalMilestones.toStringAsFixed(0)}) '
            'does not match your price (\$${price.toStringAsFixed(0)})',
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => loading = true);

    try {
      final result = await ApiService.submitProposal(
        projectId: widget.project.id!,
        price: price,
        deliveryTime: int.parse(deliveryController.text),
        proposalText: messageController.text,
        milestones: milestones, 
      );

      if (result['proposal'] != null) {
        Fluttertoast.showToast(
          msg: "✅ Proposal submitted successfully!",
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Navigator.pop(context, true);
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
  void dispose() {
    priceController.dispose();
    deliveryController.dispose();
    messageController.dispose();
    super.dispose();
  }
}