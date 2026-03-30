// lib/models/user_model.dart
import 'dart:ui';

import 'package:flutter/material.dart';

class User {
  final int? id;
  final String? name;
  final String? email;
  final String? role;
  final String? avatar;
  final bool? isVerified; 
  final String? accountStatus;  
  final DateTime? createdAt;
  final DateTime? lastSeen;
  final String? location;
  final String? phone;

  User({
    this.id,
    this.name,
    this.email,
    this.role,
    this.avatar,
    this.isVerified,
    this.accountStatus,
    this.createdAt,
    this.lastSeen,
    this.location,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('📥 User.fromJson: $json');
    
    return User(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
      avatar: json['avatar']?.toString(),
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      accountStatus: json['account_status']?.toString() ?? json['accountStatus']?.toString() ?? 'active',
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) 
          : null,
      lastSeen: json['last_seen'] != null 
          ? DateTime.tryParse(json['last_seen'].toString()) 
          : null,
      location: json['location']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar': avatar,
      'is_verified': isVerified,
      'account_status': accountStatus,
      'createdAt': createdAt?.toIso8601String(),
      'last_seen': lastSeen?.toIso8601String(),
      'location': location,
      'phone': phone,
    };
  }
  
  bool get isActive => accountStatus == 'active';
  bool get isSuspended => accountStatus == 'suspended';
  bool get isVerifiedUser => isVerified == true;
  String get displayRole => role == 'freelancer' ? 'Freelancer' : role == 'client' ? 'Client' : 'User';
  Color get roleColor => role == 'freelancer' ? Colors.blue : role == 'client' ? Colors.green : Colors.grey;
}