// lib/models/user_model.dart
class User {
  final int? id;
  final String? name;
  final String? email;
  final String? role;
  final String? avatar;

  User({
    this.id,
    this.name,
    this.email,
    this.role,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('📥 User.fromJson: $json');

    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar': avatar,
    };
  }
}