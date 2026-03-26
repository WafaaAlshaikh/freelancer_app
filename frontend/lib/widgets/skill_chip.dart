// lib/widgets/skill_chip.dart
import 'package:flutter/material.dart';

class SkillChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;
  final Color? color;

  const SkillChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (color ?? Colors.blue).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.blue.shade700,
              fontSize: 13,
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDeleted,
              child: Icon(
                Icons.close,
                size: 16,
                color: (color ?? Colors.blue).shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

extension on Color {
  Color? get shade700 => null;
}