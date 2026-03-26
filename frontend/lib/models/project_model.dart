// models/project_model.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'user_model.dart';

class Project {
  int? id;
  String? title;
  String? description;
  double? budget;
  int? duration;
  String? category;
  List<String>? skills;
  String? status;
  int? userId;
  int? views;
  int? proposalsCount;
  DateTime? createdAt;
  DateTime? updatedAt;
  User? client;
  List<dynamic>? attachments;
  int? matchScore; 
  bool? hasApplied; 

  Project({
    this.id,
    this.title,
    this.description,
    this.budget,
    this.duration,
    this.category,
    this.skills,
    this.status,
    this.userId,
    this.views,
    this.proposalsCount,
    this.createdAt,
    this.updatedAt,
    this.client,
    this.attachments,
    this.matchScore,
    this.hasApplied,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    List<String> skillsList = [];
    if (json['skills'] != null) {
      if (json['skills'] is List) {
        skillsList = List<String>.from(json['skills']);
      } else if (json['skills'] is String) {
        try {
          final decoded = jsonDecode(json['skills']);
          if (decoded is List) {
            skillsList = List<String>.from(decoded);
          }
        } catch (e) {
          print('Error parsing skills: $e');
        }
      }
    }

    return Project(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      budget: json['budget']?.toDouble(),
      duration: json['duration'],
      category: json['category'],
      skills: skillsList,
      status: json['status'],
      userId: json['UserId'],
      views: json['views'],
      proposalsCount: json['proposalsCount'] ?? json['proposals_count'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      client: json['User'] != null ? User.fromJson(json['User']) : null,
      attachments: json['attachments'] != null 
          ? (json['attachments'] is List ? json['attachments'] : [])
          : [],
      matchScore: json['matchScore'],
      hasApplied: json['hasApplied'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'budget': budget,
      'duration': duration,
      'category': category,
      'skills': skills,
      'status': status,
      'UserId': userId,
      'User': client?.toJson(),
    };
  }

  double get completionPercentage {
    if (status == 'completed') return 1.0;
    if (status == 'in_progress') return 0.5;
    if (status == 'open') return 0.0;
    return 0.0;
  }

  Color get statusColor {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  Color get matchScoreColor {
    if (matchScore == null) return Colors.grey;
    if (matchScore! >= 80) return Colors.green;
    if (matchScore! >= 60) return Colors.orange;
    return Colors.blue;
  }

  String get statusText {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status ?? 'Unknown';
    }
  }
}