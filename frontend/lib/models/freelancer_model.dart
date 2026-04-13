// models/freelancer_model.dart
import 'dart:convert';

class FreelancerProfile {
  int? id;
  String? name;
  String? tagline;
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
  final bool? isFeatured;
  final DateTime? featuredUntil;

  final String? website;
  final String? github;
  final String? linkedin;
  final String? behance;
  final double? totalEarnings;
  final int? jobSuccessScore;
  final int? responseTime;
  String? availability;
  int? weeklyHours;

  FreelancerProfile({
    this.id,
    this.name,
    this.tagline,
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
    this.availability,
    this.weeklyHours,
    this.isFeatured = false,
    this.featuredUntil,
  });

  factory FreelancerProfile.fromJson(Map<String, dynamic> json) {
    print('📥 FreelancerProfile.fromJson: $json');

    double? toDoubleSafe(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    }

    int? toIntSafe(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    List<String> parseStringList(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        if (data.isNotEmpty && data[0] is Map) {
          return data
              .map(
                (e) =>
                    e['name']?.toString() ??
                    e['title']?.toString() ??
                    e.toString(),
              )
              .toList();
        }
        return data.map((e) => e.toString()).toList();
      }
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is List) {
            if (parsed.isNotEmpty && parsed[0] is Map) {
              return parsed
                  .map(
                    (e) =>
                        e['name']?.toString() ??
                        e['title']?.toString() ??
                        e.toString(),
                  )
                  .toList();
            }
            return parsed.map((e) => e.toString()).toList();
          }
        } catch (e) {
          // ignore
        }
        return data.split(',').map((s) => s.trim()).toList();
      }
      return [];
    }

    List<Map<String, dynamic>> parseMapList(dynamic data) {
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

    List<String> parseSkills(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        if (data.isNotEmpty && data[0] is Map) {
          return data
              .map(
                (e) =>
                    e['name']?.toString() ??
                    e['skill']?.toString() ??
                    e.toString(),
              )
              .toList();
        }
        return data.map((e) => e.toString()).toList();
      }
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is List) {
            if (parsed.isNotEmpty && parsed[0] is Map) {
              return parsed
                  .map(
                    (e) =>
                        e['name']?.toString() ??
                        e['skill']?.toString() ??
                        e.toString(),
                  )
                  .toList();
            }
            return parsed.map((e) => e.toString()).toList();
          }
        } catch (e) {
          // ignore
        }
        return data.split(',').map((s) => s.trim()).toList();
      }
      return [];
    }

    return FreelancerProfile(
      id: json['id'],
      name: json['name'],
      tagline: json['tagline']?.toString(),
      title: json['title'],
      bio: json['bio'],
      location: json['location'],
      locationCoordinates: json['location_coordinates'],
      experienceYears: toIntSafe(json['experience_years']),
      rating: toDoubleSafe(json['rating']) ?? 0.0,
      avatar: json['avatar'],
      email: json['email'],
      skills: parseSkills(json['skills']),
      languages: parseStringList(json['languages']),
      education: parseMapList(json['education']),
      certifications: parseMapList(json['certifications']),
      cvUrl: json['cv_url'],
      isAvailable: json['is_available'] ?? true,
      hourlyRate: toDoubleSafe(json['hourly_rate']),
      completedProjectsCount: toIntSafe(json['completed_projects_count']) ?? 0,
      website: json['website'],
      github: json['github'],
      linkedin: json['linkedin'],
      behance: json['behance'],
      totalEarnings: toDoubleSafe(json['total_earnings']),
      jobSuccessScore: toIntSafe(json['job_success_score']),
      responseTime: toIntSafe(json['response_time']),
      availability: json['availability']?.toString(),
      weeklyHours: toIntSafe(json['weekly_hours']),
      isFeatured: json['is_featured'] as bool? ?? false,
      featuredUntil: json['featured_until'] != null
          ? DateTime.tryParse(json['featured_until'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'tagline': tagline,
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
    'availability': availability,
    'weekly_hours': weeklyHours,
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
