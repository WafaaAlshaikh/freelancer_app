// lib/models/reminder_model.dart
class Reminder {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final DateTime createdAt;
  final bool completed;
  final DateTime? completedAt;

  Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    required this.createdAt,
    required this.completed,
    this.completedAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      createdAt: DateTime.parse(json['createdAt']),
      completed: json['completed'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}