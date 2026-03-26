// lib/models/milestone_model.dart
import 'dart:ui';

import 'package:flutter/material.dart';

class Milestone {
  final String title;
  final String description;
  final double amount;
  final DateTime dueDate;
  final String status;
  final double progress;
  final DateTime? completedAt;

  Milestone({
    required this.title,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.progress = 0,
    this.completedAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      title: json['title'],
      description: json['description'],
      amount: json['amount'].toDouble(),
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'],
      progress: json['progress']?.toDouble() ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Color get statusColor {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.access_time;
      default:
        return Icons.radio_button_unchecked;
    }
  }
}