// models/user_model.dart
class User {
  final int? id;
  final String? name;
  final String? email;
  final String? role;
  final String? avatar;

  User({this.id, this.name, this.email, this.role, this.avatar});

  factory User.fromJson(Map<String, dynamic> json) {
    print('📥 User.fromJson: $json');

    return User(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
      avatar: json['avatar']?.toString(),
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
