// lib/models/transaction_model.dart
import 'dart:ui';

import 'package:flutter/material.dart';

class TransactionModel {
  final int id;
  final double amount;
  final String type;
  final String status;
  final String? description;
  final int? referenceId;
  final String? referenceType;
  final DateTime createdAt;
  final DateTime? completedAt;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    this.description,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
    this.completedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'],
      status: json['status'],
      description: json['description'],
      referenceId: json['reference_id'],
      referenceType: json['reference_type'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
    );
  }

  String get typeIcon {
    switch (type) {
      case 'deposit':
        return '💰';
      case 'payment':
        return '💵';
      case 'withdraw':
        return '🏦';
      case 'refund':
        return '↩️';
      case 'fee':
        return '📝';
      default:
        return '💳';
    }
  }

  Color get typeColor {
    switch (type) {
      case 'deposit':
        return Colors.green;
      case 'payment':
        return Colors.blue;
      case 'withdraw':
        return Colors.orange;
      case 'refund':
        return Colors.red;
      case 'fee':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String get typeText {
    switch (type) {
      case 'deposit':
        return 'Deposit';
      case 'payment':
        return 'Payment';
      case 'withdraw':
        return 'Withdrawal';
      case 'refund':
        return 'Refund';
      case 'fee':
        return 'Platform Fee';
      default:
        return type;
    }
  }
}