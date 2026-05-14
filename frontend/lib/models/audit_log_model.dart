import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';

class AuditLog {
  final int id;
  final int adminId;
  final String adminName;
  final String action;
  final String targetType;
  final int? targetId;
  final String? targetName;
  final Map<String, dynamic> changes;
  final String? ipAddress;
  final String severity;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.action,
    required this.targetType,
    this.targetId,
    this.targetName,
    required this.changes,
    this.ipAddress,
    required this.severity,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      adminId: json['admin_id'],
      adminName: json['admin_name'] ?? '',
      action: json['action'] ?? '',
      targetType: json['target_type'] ?? '',
      targetId: json['target_id'],
      targetName: json['target_name'],
      changes: json['changes'] is Map
          ? json['changes']
          : (json['changes'] is String ? jsonDecode(json['changes']) : {}),
      ipAddress: json['ip_address'],
      severity: json['severity'] ?? 'low',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get actionLabel {
    switch (action) {
      case 'create':
        return 'Created';
      case 'update':
        return 'Updated';
      case 'delete':
        return 'Deleted';
      case 'suspend':
        return 'Suspended';
      case 'activate':
        return 'Activated';
      case 'verify':
        return 'Verified';
      case 'export':
        return 'Exported';
      default:
        return action;
    }
  }

  Color get severityColor {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
