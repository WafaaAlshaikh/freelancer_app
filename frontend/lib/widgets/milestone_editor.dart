// lib/widgets/milestone_editor.dart
import 'package:flutter/material.dart';

class MilestoneEditor extends StatefulWidget {
  final List<Map<String, dynamic>> milestones;
  final Function(List<Map<String, dynamic>>) onChanged;

  const MilestoneEditor({
    super.key,
    required this.milestones,
    required this.onChanged,
  });

  @override
  State<MilestoneEditor> createState() => _MilestoneEditorState();
}

class _MilestoneEditorState extends State<MilestoneEditor> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.milestones.asMap().entries.map((entry) {
          final index = entry.key;
          final milestone = entry.value;
          return _buildMilestoneCard(milestone, index);
        }),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _addMilestone,
          icon: const Icon(Icons.add),
          label: const Text('Add Milestone'),
        ),
      ],
    );
  }

  Widget _buildMilestoneCard(Map<String, dynamic> milestone, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: milestone['title'],
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      milestone['title'] = value;
                      widget.onChanged(widget.milestones);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: milestone['amount']?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      milestone['amount'] = double.tryParse(value) ?? 0;
                      widget.onChanged(widget.milestones);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: milestone['description'],
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                milestone['description'] = value;
                widget.onChanged(widget.milestones);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: milestone['due_date']?.split('T')[0],
                    decoration: const InputDecoration(
                      labelText: 'Due Date',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        milestone['due_date'] = date.toIso8601String();
                        widget.onChanged(widget.milestones);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    widget.milestones.removeAt(index);
                    widget.onChanged(widget.milestones);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addMilestone() {
    widget.milestones.add({
      'title': 'New Milestone',
      'description': '',
      'amount': 0,
      'due_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    });
    widget.onChanged(widget.milestones);
  }
}