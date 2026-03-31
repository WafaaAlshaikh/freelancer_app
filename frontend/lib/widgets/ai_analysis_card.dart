// frontend/lib/widgets/ai_analysis_card.dart

import 'package:flutter/material.dart';

class AIAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> analysis;
  final Function(String, dynamic) onApplySuggestion;

  const AIAnalysisCard({
    super.key,
    required this.analysis,
    required this.onApplySuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.blue],
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
                "AI Analysis",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildAnalysisRow(
            label: "Difficulty",
            value: analysis['difficulty_level']?.toUpperCase() ?? 'N/A',
            icon: Icons.speed,
            color: _getDifficultyColor(analysis['difficulty_level']),
          ),

          const SizedBox(height: 12),

          if (analysis['price_range'] != null) ...[
            _buildPriceRange(analysis['price_range']),
            const SizedBox(height: 12),
          ],

          _buildAnalysisRow(
            label: "Est. Duration",
            value: "${analysis['estimated_duration_days'] ?? '?'} days",
            icon: Icons.calendar_today,
            color: Colors.orange,
          ),

          const SizedBox(height: 12),

          if (analysis['complexity_factors'] != null &&
              analysis['complexity_factors'].isNotEmpty) ...[
            const Text(
              "Complexity Factors:",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List<String>.from(analysis['complexity_factors']).map((
                factor,
              ) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(factor, style: const TextStyle(fontSize: 11)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          if (analysis['suggested_milestones'] != null) ...[
            const Text(
              "Suggested Milestones:",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            ...List.from(analysis['suggested_milestones']).take(2).map((
              milestone,
            ) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 12, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        milestone['title'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      "${milestone['percentage']}%",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (analysis['suggested_milestones'].length > 2)
              const Text(
                "...",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (analysis['price_range']?['recommended'] != null) {
                      onApplySuggestion(
                        'budget',
                        analysis['price_range']['recommended'],
                      );
                    }
                    if (analysis['estimated_duration_days'] != null) {
                      onApplySuggestion(
                        'duration',
                        analysis['estimated_duration_days'],
                      );
                    }
                    if (analysis['suggested_milestones'] != null) {
                      onApplySuggestion(
                        'milestones',
                        analysis['suggested_milestones'],
                      );
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("AI suggestions applied!"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text("Apply Suggestions"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(color: Colors.purple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRange(Map range) {
    final min = range['min']?.toStringAsFixed(0) ?? '?';
    final max = range['max']?.toStringAsFixed(0) ?? '?';
    final recommended = range['recommended']?.toStringAsFixed(0) ?? '?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Suggested Price Range:",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("\$$min", style: const TextStyle(fontSize: 14)),
                  const Text("–", style: TextStyle(fontSize: 14)),
                  Text("\$$max", style: const TextStyle(fontSize: 14)),
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
                      "Recommended: \$$recommended",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value:
                    (double.parse(recommended) - double.parse(min)) /
                    (double.parse(max) - double.parse(min)),
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(Colors.green),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'expert':
        return Colors.red;
      case 'enterprise':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
