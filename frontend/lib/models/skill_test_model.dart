// lib/models/skill_test_model.dart
import 'dart:ui';

import 'package:flutter/material.dart';

class SkillTest {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String skillCategory;
  final String difficulty;
  final List<Question> questions;
  final int passingScore;
  final int timeLimitMinutes;
  final int maxAttempts;
  final int? badgeId;
  final bool isActive;
  final int userAttempts;
  final bool userPassed;
  final bool canRetake;
  final Badge? badge;

  SkillTest({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.skillCategory,
    required this.difficulty,
    required this.questions,
    required this.passingScore,
    required this.timeLimitMinutes,
    required this.maxAttempts,
    this.badgeId,
    required this.isActive,
    this.userAttempts = 0,
    this.userPassed = false,
    this.canRetake = false,
    this.badge,
  });

  factory SkillTest.fromJson(Map<String, dynamic> json) {
    return SkillTest(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      skillCategory: json['skill_category'],
      difficulty: json['difficulty'],
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList(),
      passingScore: json['passing_score'],
      timeLimitMinutes: json['time_limit_minutes'],
      maxAttempts: json['max_attempts'],
      badgeId: json['badge_id'],
      isActive: json['is_active'],
      userAttempts: json['user_attempts'] ?? 0,
      userPassed: json['user_passed'] ?? false,
      canRetake: json['can_retake'] ?? false,
      badge: json['Badge'] != null ? Badge.fromJson(json['Badge']) : null,
    );
  }

  String get difficultyText {
    switch (difficulty) {
      case 'beginner': return 'Beginner';
      case 'intermediate': return 'Intermediate';
      case 'advanced': return 'Advanced';
      case 'expert': return 'Expert';
      default: return difficulty;
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case 'beginner': return Colors.green;
      case 'intermediate': return Colors.orange;
      case 'advanced': return Colors.red;
      case 'expert': return Colors.purple;
      default: return Colors.grey;
    }
  }
}

class Question {
  final int id;
  final String text;
  final String type;
  final List<String> options;
  final int points;

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.options,
    required this.points,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['text'],
      type: json['type'],
      options: List<String>.from(json['options'] ?? []),
      points: json['points'] ?? 1,
    );
  }
}

class TestResult {
  final int id;
  final String testName;
  final String skillCategory;
  final int percentage;
  final bool passed;
  final DateTime completedAt;
  final Badge? badge;
  final int attemptNumber;

  TestResult({
    required this.id,
    required this.testName,
    required this.skillCategory,
    required this.percentage,
    required this.passed,
    required this.completedAt,
    this.badge,
    required this.attemptNumber,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'],
      testName: json['test_name'],
      skillCategory: json['skill_category'],
      percentage: json['percentage'],
      passed: json['passed'],
      completedAt: DateTime.parse(json['completed_at']),
      badge: json['badge'] != null ? Badge.fromJson(json['badge']) : null,
      attemptNumber: json['attempt_number'],
    );
  }
}

class Badge {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final String color;
  final String badgeType;

  Badge({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.color,
    required this.badgeType,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      color: json['color'] ?? '#14A800',
      badgeType: json['badge_type'] ?? 'achievement',
    );
  }
}