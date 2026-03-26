// lib/models/freelancer_profile.dart
import 'dart:convert';

class FreelancerProfile {
  final int? id;
  final int? userId;
  final String? title;
  final double? rating;
  final int? experienceYears;
  final List<String>? skills;
  final String? location;
  final double? hourlyRate;

  FreelancerProfile({
    this.id,
    this.userId,
    this.title,
    this.rating,
    this.experienceYears,
    this.skills,
    this.location,
    this.hourlyRate,
  });

  factory FreelancerProfile.fromJson(Map<String, dynamic> json) {
    print('📥 FreelancerProfile.fromJson: $json'); 

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

    return FreelancerProfile(
      id: json['id'],
      userId: json['UserId'],
      title: json['title'],
      rating: json['rating']?.toDouble(),
      experienceYears: json['experience_years'],
      skills: parseSkills(json['skills']),
      location: json['location'],
      hourlyRate: json['hourly_rate']?.toDouble(),
    );
  }
}