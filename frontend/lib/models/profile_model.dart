// lib/models/profile_model.dart
class Profile {
  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final String? role;
  final DateTime createdAt;

  Profile({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.role,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      role: json['role'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'role': role,
    'created_at': createdAt.toIso8601String(),
  };
}