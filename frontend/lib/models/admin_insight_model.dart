import 'package:flutter/material.dart';

class AdminInsight {
  final int id;
  final String type;
  final String title;
  final String description;
  final String severity;
  final String category;
  final Map<String, dynamic> data;
  final String? actionUrl;
  final String? actionText;
  final bool isResolved;
  final DateTime? resolvedAt;
  final int? resolvedBy;
  final DateTime? expiresAt;
  final DateTime createdAt;

  AdminInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    required this.data,
    this.actionUrl,
    this.actionText,
    this.isResolved = false,
    this.resolvedAt,
    this.resolvedBy,
    this.expiresAt,
    required this.createdAt,
  });

  factory AdminInsight.fromJson(Map<String, dynamic> json) {
    return AdminInsight(
      id: json['id'],
      type: json['type'] ?? 'insight',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'info',
      category: json['category'] ?? 'system',
      data: json['data'] is Map ? json['data'] : {},
      actionUrl: json['action_url'],
      actionText: json['action_text'],
      isResolved: json['is_resolved'] ?? false,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      resolvedBy: json['resolved_by'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Color get severityColor {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData get severityIcon {
    switch (severity) {
      case 'critical':
        return Icons.warning_amber_rounded;
      case 'warning':
        return Icons.info_outline_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }
}
