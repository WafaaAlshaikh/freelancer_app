// lib/models/proposal_model.dart
import 'dart:convert';

import 'project_model.dart';
import 'user_model.dart';
import 'freelancer_profile.dart';

class Proposal {
  final int? id;
  final int? projectId;
  final int? userId;
  final double? price;
  final int? deliveryTime;
  final String? proposalText;
  final String? status;
  final DateTime? createdAt;
  final Project? project;
  final User? freelancer;
  final FreelancerProfile? freelancerProfile;
  final List<Map<String, dynamic>>? milestones;
  final int? contractId;

  Proposal({
    this.id,
    this.projectId,
    this.userId,
    this.price,
    this.deliveryTime,
    this.proposalText,
    this.status,
    this.createdAt,
    this.project,
    this.freelancer,
    this.freelancerProfile,
    this.milestones,
    this.contractId,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    print('📥 Proposal.fromJson: $json');

    List<String> parseSkills(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      }
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is List) {
            return parsed.map((e) => e.toString()).toList();
          }
        } catch (e) {}
        return data.split(',').map((s) => s.trim()).toList();
      }
      return [];
    }

    List<Map<String, dynamic>> parseMilestones(dynamic data) {
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

    Project? project;
    if (json['project'] != null) {
      try {
        project = Project.fromJson(json['project']);
      } catch (e) {
        print('⚠️ Error parsing project: $e');
      }
    }

    User? freelancer;
    if (json['freelancer'] != null) {
      try {
        freelancer = User.fromJson(json['freelancer']);
      } catch (e) {
        print('⚠️ Error parsing freelancer: $e');
      }
    }

    FreelancerProfile? freelancerProfile;
    if (json['profile'] != null) {
      try {
        freelancerProfile = FreelancerProfile.fromJson(json['profile']);
      } catch (e) {
        print('⚠️ Error parsing freelancer profile: $e');
      }
    }

    return Proposal(
      id: json['id'],
      projectId: json['ProjectId'],
      userId: json['UserId'],
      price: _parseDouble(json['price']),
      deliveryTime: json['delivery_time'] is int
          ? json['delivery_time']
          : int.tryParse(json['delivery_time']?.toString() ?? '0'),
      proposalText: json['proposal_text'],
      status: json['status'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      project: project,
      freelancer: freelancer,
      freelancerProfile: freelancerProfile,
      milestones: parseMilestones(json['milestones']),
      contractId: json['contractId'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
