// frontend/lib/widgets/milestone_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MilestoneEditor extends StatefulWidget {
  final List<Map<String, dynamic>> milestones;
  final Function(List<Map<String, dynamic>>) onChanged;
  final bool readOnly;
  final double? totalAmount;

  const MilestoneEditor({
    super.key,
    required this.milestones,
    required this.onChanged,
    this.readOnly = false,
    this.totalAmount,
  });

  @override
  State<MilestoneEditor> createState() => _MilestoneEditorState();
}

class _MilestoneEditorState extends State<MilestoneEditor> {
  final List<TextEditingController> _titleControllers = [];
  final List<TextEditingController> _descControllers = [];
  final List<TextEditingController> _amountControllers = [];
  final List<TextEditingController> _percentageControllers = [];
  final List<TextEditingController> _dueDateControllers = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(MilestoneEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.milestones.length != oldWidget.milestones.length) {
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    _titleControllers.clear();
    _descControllers.clear();
    _amountControllers.clear();
    _percentageControllers.clear();
    _dueDateControllers.clear();

    for (var milestone in widget.milestones) {
      _titleControllers.add(TextEditingController(text: milestone['title']));
      _descControllers.add(
        TextEditingController(text: milestone['description']),
      );
      _amountControllers.add(
        TextEditingController(text: milestone['amount']?.toString() ?? '0'),
      );
      _percentageControllers.add(
        TextEditingController(text: milestone['percentage']?.toString() ?? '0'),
      );
      _dueDateControllers.add(
        TextEditingController(text: _formatDate(milestone['due_date'])),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _titleControllers) {
      controller.dispose();
    }
    for (var controller in _descControllers) {
      controller.dispose();
    }
    for (var controller in _amountControllers) {
      controller.dispose();
    }
    for (var controller in _percentageControllers) {
      controller.dispose();
    }
    for (var controller in _dueDateControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Not set';
    try {
      final date = dateValue is DateTime
          ? dateValue
          : DateTime.parse(dateValue.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  double _getTotalPercentage() {
    return widget.milestones.fold<double>(
      0,
      (sum, m) => sum + (m['percentage'] ?? 0),
    );
  }

  double _getTotalAmount() {
    return widget.milestones.fold<double>(
      0,
      (sum, m) => sum + (m['amount'] ?? 0),
    );
  }

  void _updateMilestone(int index) {
    final milestone = widget.milestones[index];

    milestone['title'] = _titleControllers[index].text;
    milestone['description'] = _descControllers[index].text;
    milestone['amount'] = double.tryParse(_amountControllers[index].text) ?? 0;
    milestone['percentage'] =
        double.tryParse(_percentageControllers[index].text) ?? 0;

    widget.onChanged(widget.milestones);
  }

  void _addMilestone() {
    widget.milestones.add({
      'title': 'New Milestone',
      'description': '',
      'amount': 0,
      'percentage': 0,
      'due_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    });
    _initializeControllers();
    widget.onChanged(widget.milestones);
    setState(() {});
  }

  void _removeMilestone(int index) {
    widget.milestones.removeAt(index);
    _initializeControllers();
    widget.onChanged(widget.milestones);
    setState(() {});
  }

  Future<void> _selectDueDate(int index) async {
    final currentDate = widget.milestones[index]['due_date'] != null
        ? DateTime.tryParse(widget.milestones[index]['due_date'].toString())
        : null;

    final date = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      widget.milestones[index]['due_date'] = date.toIso8601String();
      _dueDateControllers[index].text = _formatDate(date);
      widget.onChanged(widget.milestones);
      setState(() {});
    }
  }

  void _autoBalancePercentages() {
    final totalPercentage = _getTotalPercentage();
    if (totalPercentage > 0 && totalPercentage != 100) {
      final factor = 100 / totalPercentage;
      for (var milestone in widget.milestones) {
        milestone['percentage'] = (milestone['percentage'] ?? 0) * factor;
        milestone['amount'] =
            (widget.totalAmount ?? 0) * (milestone['percentage'] / 100);
      }
      _initializeControllers();
      widget.onChanged(widget.milestones);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPercentage = _getTotalPercentage();
    final totalAmount = _getTotalAmount();
    final isBalanced =
        (totalPercentage - 100).abs() < 0.01 &&
        (widget.totalAmount == null ||
            (totalAmount - widget.totalAmount!).abs() < 0.01);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isBalanced ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isBalanced
                  ? Colors.green.shade200
                  : Colors.orange.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isBalanced ? Icons.check_circle : Icons.warning,
                color: isBalanced ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: ${totalPercentage.toStringAsFixed(1)}% | ${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isBalanced
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                    if (!isBalanced)
                      Text(
                        widget.totalAmount != null
                            ? 'Milestones should total 100% and match contract amount'
                            : 'Milestones should total 100%',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isBalanced && widget.totalAmount != null)
                TextButton(
                  onPressed: _autoBalancePercentages,
                  child: const Text('Auto Balance'),
                ),
            ],
          ),
        ),

        ...List.generate(widget.milestones.length, (index) {
          return _buildMilestoneCard(index);
        }),

        if (!widget.readOnly)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: _addMilestone,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Milestone'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xff14A800),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMilestoneCard(int index) {
    final milestone = widget.milestones[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xff14A800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff14A800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _titleControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Milestone Title',
                      border: UnderlineInputBorder(),
                    ),
                    readOnly: widget.readOnly,
                    onChanged: (_) => _updateMilestone(index),
                  ),
                ),
                if (!widget.readOnly)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeMilestone(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descControllers[index],
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: UnderlineInputBorder(),
              ),
              readOnly: widget.readOnly,
              onChanged: (_) => _updateMilestone(index),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _percentageControllers[index],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Percentage (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    readOnly: widget.readOnly,
                    onChanged: (value) {
                      milestone['percentage'] = double.tryParse(value) ?? 0;
                      if (widget.totalAmount != null) {
                        milestone['amount'] =
                            widget.totalAmount! *
                            (milestone['percentage'] / 100);
                        _amountControllers[index].text = milestone['amount']
                            .toStringAsFixed(2);
                      }
                      _updateMilestone(index);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _amountControllers[index],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount (\$)',
                      border: const OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    readOnly: widget.readOnly,
                    onChanged: (value) {
                      milestone['amount'] = double.tryParse(value) ?? 0;
                      if (widget.totalAmount != null &&
                          widget.totalAmount! > 0) {
                        milestone['percentage'] =
                            (milestone['amount'] / widget.totalAmount!) * 100;
                        _percentageControllers[index].text =
                            milestone['percentage'].toStringAsFixed(1);
                      }
                      _updateMilestone(index);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, size: 18),
              title: const Text('Due Date'),
              subtitle: Text(_dueDateControllers[index].text),
              onTap: widget.readOnly ? null : () => _selectDueDate(index),
            ),
          ],
        ),
      ),
    );
  }
}
