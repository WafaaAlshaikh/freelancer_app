// lib/models/calendar_event.dart
import 'dart:ui';

import 'package:flutter/material.dart';

class CalendarEvent {
  final String id;
  final String title;
  final DateTime date;
  final String type;
  final int contractId;
  final String? projectTitle;
  final String? status;
  final double? progress;
  final bool? completed;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.contractId,
    this.projectTitle,
    this.status,
    this.progress,
    this.completed,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      contractId: json['contractId'],
      projectTitle: json['projectTitle'],
      status: json['status'],
      progress: json['progress']?.toDouble(),
      completed: json['completed'],
    );
  }

  Color get color {
    if (type == 'milestone') {
      if (status == 'completed') return Colors.green;
      if (status == 'in_progress') return Colors.blue;
      return Colors.orange;
    } else {
      return completed == true ? Colors.green : Colors.purple;
    }
  }
}