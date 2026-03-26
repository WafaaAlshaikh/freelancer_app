// lib/models/contract_model.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'project_model.dart';
import 'user_model.dart';

class Contract {
  final int? id;
  final int? freelancerId;
  final int? clientId;
  final int? projectId;
  final double? agreedAmount;
  final String? contractDocument;
  final bool? termsAgreed;
  final DateTime? clientSignedAt;
  final DateTime? freelancerSignedAt;
  final DateTime? signedAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final String? terms;
  final List<Map<String, dynamic>>? milestones;
  final String? paymentStatus;
  final String? paymentMethod;
  final String? escrowId;
  final String? escrowStatus;
  final double? releasedAmount;
  final String? clientReview;
  final String? freelancerReview;
  final int? clientRating;
  final int? freelancerRating;
  final Project? project;
  final User? client;
  final User? freelancer;
  final String? githubRepo;
  final String? githubBranch;
  final List<Map<String, dynamic>>? reminders;
  final Map<String, dynamic>? milestoneProgress;

  Contract({
    this.id,
    this.freelancerId,
    this.clientId,
    this.projectId,
    this.agreedAmount,
    this.contractDocument,
    this.termsAgreed,
    this.clientSignedAt,
    this.freelancerSignedAt,
    this.signedAt,
    this.startDate,
    this.endDate,
    this.status,
    this.terms,
    this.milestones,
    this.paymentStatus,
    this.paymentMethod,
    this.escrowId,
    this.escrowStatus,
    this.releasedAmount,
    this.clientReview,
    this.freelancerReview,
    this.clientRating,
    this.freelancerRating,
    this.project,
    this.client,
    this.freelancer,
    this.githubRepo,
    this.githubBranch,
    this.reminders,
    this.milestoneProgress,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    print('📥 Contract fromJson: $json');
    
    double parseToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    List<Map<String, dynamic>> parseMilestones(dynamic data) {
      print('🔍 Raw milestones: $data');
      print('🔍 Milestones type: ${data.runtimeType}');
      
      if (data == null) return [];
      
      if (data is List) {
        return data.map((e) {
          if (e is Map) {
            return Map<String, dynamic>.from(e);
          }
          return <String, dynamic>{};
        }).toList();
      }
      
      if (data is String && data.isNotEmpty) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is List) {
            return parsed.map((e) => Map<String, dynamic>.from(e)).toList();
          }
        } catch (e) {
          print('Error parsing milestones: $e');
        }
      }
      
      return [];
    }

    List<Map<String, dynamic>> parseReminders(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      if (data is String && data.isNotEmpty) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is List) {
            return parsed.map((e) => Map<String, dynamic>.from(e)).toList();
          }
        } catch (e) {}
      }
      return [];
    }

    Map<String, dynamic> parseMilestoneProgress(dynamic data) {
      if (data == null) return {};
      if (data is Map) return Map<String, dynamic>.from(data);
      if (data is String && data.isNotEmpty) {
        try {
          return jsonDecode(data);
        } catch (e) {}
      }
      return {};
    }

    return Contract(
      id: json['id'],
      freelancerId: json['FreelancerId'],
      clientId: json['ClientId'],
      projectId: json['ProjectId'],
      agreedAmount: parseToDouble(json['agreed_amount']),
      contractDocument: json['contract_document'],
      termsAgreed: json['terms_agreed'],
      clientSignedAt: json['client_signed_at'] != null 
          ? DateTime.parse(json['client_signed_at']) 
          : null,
      freelancerSignedAt: json['freelancer_signed_at'] != null 
          ? DateTime.parse(json['freelancer_signed_at']) 
          : null,
      signedAt: json['signed_at'] != null 
          ? DateTime.parse(json['signed_at']) 
          : null,
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date']) 
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date']) 
          : null,
      status: json['status'],
      terms: json['terms'],
      milestones: parseMilestones(json['milestones']),
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
      escrowId: json['escrow_id'],
      escrowStatus: json['escrow_status'],
      releasedAmount: parseToDouble(json['released_amount']),
      clientReview: json['client_review'],
      freelancerReview: json['freelancer_review'],
      clientRating: json['client_rating'],
      freelancerRating: json['freelancer_rating'],
      project: json['Project'] != null 
          ? Project.fromJson(json['Project']) 
          : null,
      client: json['client'] != null 
          ? User.fromJson(json['client']) 
          : null,
      freelancer: json['freelancer'] != null 
          ? User.fromJson(json['freelancer']) 
          : null,
      githubRepo: json['github_repo'],
      githubBranch: json['github_branch'],
      reminders: parseReminders(json['reminders']),
      milestoneProgress: parseMilestoneProgress(json['milestone_progress']),
    );
  }

  String get statusText {
    switch (status) {
      case 'draft':
        return 'Awaiting Signatures';
      case 'pending_client':
        return 'Waiting for Client';
      case 'pending_freelancer':
        return 'Waiting for Freelancer';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'disputed':
        return 'Disputed';
      default:
        return status ?? 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'draft':
      case 'pending_client':
      case 'pending_freelancer':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'disputed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool get isSignedByBoth {
    return clientSignedAt != null && freelancerSignedAt != null;
  }

  bool get isActive {
    return status == 'active';
  }

  bool get isCompleted {
    return status == 'completed';
  }

  double get totalProgress {
    if (milestones == null || milestones!.isEmpty) return 0.0;
    final total = milestones!.length;
    final completed = milestones!.where((m) => m['status'] == 'completed').length;
    return total > 0 ? completed / total : 0.0;
  }

  Map<String, dynamic>? get nextMilestone {
    if (milestones == null) return null;
    try {
      return milestones!.firstWhere(
        (m) => m['status'] != 'completed',
        orElse: () => {},
      );
    } catch (e) {
      return null;
    }
  }
}