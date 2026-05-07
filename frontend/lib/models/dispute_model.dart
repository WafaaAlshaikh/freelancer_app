import 'package:flutter/material.dart';

class Dispute {
  final int? id;  
  final int? contractId;  
  final int? clientId; 
  final int? freelancerId;  
  final String initiatedBy;
  final String title;
  final String description;
  final String status;
  final List<String> evidenceFiles;
  final String? adminNotes;
  final String? resolution;
  final double? refundAmount;
  final DateTime? decisionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Contract? contract;
  final User? client;
  final User? freelancer;

  Dispute({
    this.id,  
    this.contractId,  
    this.clientId,  
    this.freelancerId,  
    required this.initiatedBy,
    required this.title,
    required this.description,
    required this.status,
    required this.evidenceFiles,
    this.adminNotes,
    this.resolution,
    this.refundAmount,
    this.decisionDate,
    required this.createdAt,
    required this.updatedAt,
    this.contract,
    this.client,
    this.freelancer,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) {
    return Dispute(
      id: json['id'] as int?,
      contractId: json['ContractId'] as int?,
      clientId: json['ClientId'] as int?,
      freelancerId: json['FreelancerId'] as int?,
      initiatedBy: json['InitiatedBy'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      evidenceFiles: json['evidence_files'] != null
          ? List<String>.from(json['evidence_files'])
          : [],
      adminNotes: json['admin_notes'],
      resolution: json['resolution'],
      refundAmount: json['refund_amount'] != null
          ? double.tryParse(json['refund_amount'].toString())
          : null,
      decisionDate: json['decision_date'] != null
          ? DateTime.tryParse(json['decision_date'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      contract: json['Contract'] != null
          ? Contract.fromJson(json['Contract'])
          : null,
      client: json['client'] != null ? User.fromJson(json['client']) : null,
      freelancer: json['freelancer'] != null
          ? User.fromJson(json['freelancer'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ContractId': contractId,
      'ClientId': clientId,
      'FreelancerId': freelancerId,
      'InitiatedBy': initiatedBy,
      'title': title,
      'description': description,
      'status': status,
      'evidence_files': evidenceFiles,
      'admin_notes': adminNotes,
      'resolution': resolution,
      'refund_amount': refundAmount,
      'decision_date': decisionDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'Contract': contract?.toJson(),
      'client': client?.toJson(),
      'freelancer': freelancer?.toJson(),
    };
  }
}

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
  final Project? project;
  final User? client;
  final User? freelancer;

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
    this.project,
    this.client,
    this.freelancer,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] as int?,
      freelancerId: json['FreelancerId'] as int?,
      clientId: json['ClientId'] as int?,
      projectId: json['ProjectId'] as int?,
      agreedAmount: json['agreed_amount'] != null
          ? double.tryParse(json['agreed_amount'].toString())
          : null,
      contractDocument: json['contract_document'],
      termsAgreed: json['terms_agreed'] ?? false,
      clientSignedAt: json['client_signed_at'] != null
          ? DateTime.tryParse(json['client_signed_at'])
          : null,
      freelancerSignedAt: json['freelancer_signed_at'] != null
          ? DateTime.tryParse(json['freelancer_signed_at'])
          : null,
      signedAt: json['signed_at'] != null
          ? DateTime.tryParse(json['signed_at'])
          : null,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      project: json['Project'] != null
          ? Project.fromJson(json['Project'])
          : null,
      client: json['client'] != null ? User.fromJson(json['client']) : null,
      freelancer: json['freelancer'] != null
          ? User.fromJson(json['freelancer'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'FreelancerId': freelancerId,
      'ClientId': clientId,
      'ProjectId': projectId,
      'agreed_amount': agreedAmount,
      'contract_document': contractDocument,
      'terms_agreed': termsAgreed,
      'client_signed_at': clientSignedAt?.toIso8601String(),
      'freelancer_signed_at': freelancerSignedAt?.toIso8601String(),
      'signed_at': signedAt?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'Project': project?.toJson(),
      'client': client?.toJson(),
      'freelancer': freelancer?.toJson(),
    };
  }
}

class Project {
  final int? id;
  final String? title;
  final String? description;
  final int? userId;
  final String? status;
  final double? budget;
  final DateTime? deadline;
  final DateTime? createdAt;

  Project({
    this.id,
    this.title,
    this.description,
    this.userId,
    this.status,
    this.budget,
    this.deadline,
    this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int?,
      title: json['title'],
      description: json['description'],
      userId: json['UserId'] as int?,
      status: json['status'],
      budget: json['budget'] != null
          ? double.tryParse(json['budget'].toString())
          : null,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'UserId': userId,
      'status': status,
      'budget': budget,
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class User {
  final int? id;
  final String? name;
  final String? email;
  final String? role;
  final bool? isVerifiedUser;
  final String? accountStatus;
  final DateTime? createdAt;

  User({
    this.id,
    this.name,
    this.email,
    this.role,
    this.isVerifiedUser,
    this.accountStatus,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      name: json['name'],
      email: json['email'],
      role: json['role'],
      isVerifiedUser: json['is_verified'] ?? false,
      accountStatus: json['account_status'] ?? 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_verified': isVerifiedUser,
      'account_status': accountStatus,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get displayRole {
    switch (role) {
      case 'client':
        return 'Client';
      case 'freelancer':
        return 'Freelancer';
      case 'admin':
        return 'Admin';
      default:
        return role ?? 'Unknown';
    }
  }

  Color get roleColor {
    switch (role) {
      case 'client':
        return Colors.blue;
      case 'freelancer':
        return Colors.green;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}