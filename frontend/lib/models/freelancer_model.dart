// models/freelancer_model.dart
import 'dart:convert';

class FreelancerProfile {
  int? id;
  String? name;
  String? title;
  String? bio;
  String? location;
  String? locationCoordinates;
  int? experienceYears;
  double? rating;
  String? avatar;
  String? email;
  List<String>? skills;
  List<String>? languages;
  List<Map<String, dynamic>>? education;
  List<Map<String, dynamic>>? certifications;
  String? cvUrl;
  bool? isAvailable;
  double? hourlyRate;
  int? completedProjectsCount;

  final String? website;
  final String? github;
  final String? linkedin;
  final String? behance;
  final double? totalEarnings;
  final int? jobSuccessScore;
  final int? responseTime;

  FreelancerProfile({
    this.id,
    this.name,
    this.title,
    this.bio,
    this.location,
    this.locationCoordinates,
    this.experienceYears,
    this.rating,
    this.avatar,
    this.email,
    this.skills,
    this.languages,
    this.education,
    this.certifications,
    this.cvUrl,
    this.isAvailable,
    this.hourlyRate,
    this.completedProjectsCount,
    this.website,
    this.github,
    this.linkedin,
    this.behance,
    this.totalEarnings,
    this.jobSuccessScore,
    this.responseTime,
  });

  factory FreelancerProfile.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic data) {
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
        } catch (e) {
        }
        return data.split(',').map((s) => s.trim()).toList();
      }
      return [];
    }

    List<Map<String, dynamic>> parseEducation(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is List) {
            return parsed.map((e) => Map<String, dynamic>.from(e)).toList();
          }
        } catch (e) {}
      }
      return [];
    }

    List<Map<String, dynamic>> parseCertifications(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is List) {
            return parsed.map((e) => Map<String, dynamic>.from(e)).toList();
          }
        } catch (e) {}
      }
      return [];
    }
    return FreelancerProfile(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      bio: json['bio'],
      location: json['location'],
      locationCoordinates: json['location_coordinates'],
      experienceYears: json['experience_years'],
      rating: (json['rating'] ?? 0).toDouble(),
      avatar: json['avatar'],
      email: json['email'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : [],
      languages: json['languages'] != null ? List<String>.from(json['languages']) : [],
      education: json['education'] != null ? List<Map<String, dynamic>>.from(json['education']) : [],
      certifications: json['certifications'] != null ? List<Map<String, dynamic>>.from(json['certifications']) : [],
      cvUrl: json['cv_url'],
      isAvailable: json['is_available'] ?? true,
      hourlyRate: json['hourly_rate']?.toDouble(),
      completedProjectsCount: json['completed_projects_count'] ?? 0,
      website: json['website'],
      github: json['github'],
      linkedin: json['linkedin'],
      behance: json['behance'],
      totalEarnings: json['total_earnings']?.toDouble(),
      jobSuccessScore: json['job_success_score'],
      responseTime: json['response_time'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'title': title,
    'bio': bio,
    'location': location,
    'location_coordinates': locationCoordinates,
    'experience_years': experienceYears,
    'avatar': avatar,
    'skills': skills,
    'languages': languages,
    'education': education,
    'certifications': certifications,
    'is_available': isAvailable,
    'hourly_rate': hourlyRate,
    'website': website,
      'github': github,
      'linkedin': linkedin,
      'behance': behance,
  };

  double get profileCompletion {
    int completed = 0;
    int total = 7;

    if (name != null && name!.isNotEmpty) completed++;
    if (title != null && title!.isNotEmpty) completed++;
    if (bio != null && bio!.isNotEmpty) completed++;
    if (avatar != null && avatar!.isNotEmpty) completed++;
    if (skills != null && skills!.isNotEmpty) completed++;
    if (location != null && location!.isNotEmpty) completed++;
    if (cvUrl != null && cvUrl!.isNotEmpty) completed++;

    return total > 0 ? (completed / total * 100) : 0;
  }
}