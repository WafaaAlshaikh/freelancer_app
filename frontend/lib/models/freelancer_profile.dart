// lib/models/freelancer_profile.dart
import 'dart:convert';

class FreelancerProfile {
  final int? id;
  final int? userId;

  final String? title;
  final String? bio;
  final String? tagline;

  final List<String>? skills;
  final List<String>? topSkills;
  final int? experienceYears;
  final double? hourlyRate;
  final String? availability;
  final int? weeklyHours;

  final double? rating;
  final int? totalReviews;
  final int? completedProjectsCount;
  final double? totalEarnings;
  final int? jobSuccessScore;
  final int? responseTime;
  final double? onTimeDeliveryRate;
  final double? onBudgetRate;
  final double? repeatHireRate;

  final String? location;
  final String? locationCoordinates;
  final String? timezone;
  final List<Map<String, dynamic>>? languages;

  final List<Map<String, dynamic>>? education;
  final List<Map<String, dynamic>>? certifications;
  final List<Map<String, dynamic>>? workExperience;

  final int? portfolioItemsCount;
  final String? videoIntroUrl;
  final String? cvUrl;
  final String? cvText;

  final Map<String, dynamic>? socialLinks;
  final String? website;
  final String? github;
  final String? linkedin;
  final String? behance;
  final String? dribbble;
  final String? stackoverflow;

  final bool? isAvailable;
  final bool? isFeatured;
  final bool? isTopRated;
  final bool? isRisingTalent;
  final bool? isVerified;

  final int? profileStrength;
  final int? profileCompletionPercentage;

  final List<String>? categories;
  final List<String>? subcategories;
  final List<String>? specialization;

  final int? profileViews;
  final int? searchAppearances;
  final int? invitationsSent;
  final int? invitationsAccepted;

  final List<String>? preferredProjectTypes;
  final List<String>? preferredProjectSizes;
  final double? minProjectBudget;

  final int? teamSize;
  final bool? isAgency;
  final int? agencyId;

  final List<String>? skillsVerified;
  final List<Map<String, dynamic>>? testScores;

  final List<String>? preferredCommunicationChannels;
  final double? responseRate;

  final List<Map<String, dynamic>>? badges;
  final List<Map<String, dynamic>>? achievements;

  final DateTime? lastProfileUpdate;
  final DateTime? memberSince;

  FreelancerProfile({
    this.id,
    this.userId,
    this.title,
    this.bio,
    this.tagline,
    this.skills,
    this.topSkills,
    this.experienceYears,
    this.hourlyRate,
    this.availability,
    this.weeklyHours,
    this.rating,
    this.totalReviews,
    this.completedProjectsCount,
    this.totalEarnings,
    this.jobSuccessScore,
    this.responseTime,
    this.onTimeDeliveryRate,
    this.onBudgetRate,
    this.repeatHireRate,
    this.location,
    this.locationCoordinates,
    this.timezone,
    this.languages,
    this.education,
    this.certifications,
    this.workExperience,
    this.portfolioItemsCount,
    this.videoIntroUrl,
    this.cvUrl,
    this.cvText,
    this.socialLinks,
    this.website,
    this.github,
    this.linkedin,
    this.behance,
    this.dribbble,
    this.stackoverflow,
    this.isAvailable,
    this.isFeatured,
    this.isTopRated,
    this.isRisingTalent,
    this.isVerified,
    this.profileStrength,
    this.profileCompletionPercentage,
    this.categories,
    this.subcategories,
    this.specialization,
    this.profileViews,
    this.searchAppearances,
    this.invitationsSent,
    this.invitationsAccepted,
    this.preferredProjectTypes,
    this.preferredProjectSizes,
    this.minProjectBudget,
    this.teamSize,
    this.isAgency,
    this.agencyId,
    this.skillsVerified,
    this.testScores,
    this.preferredCommunicationChannels,
    this.responseRate,
    this.badges,
    this.achievements,
    this.lastProfileUpdate,
    this.memberSince,
  });

  factory FreelancerProfile.fromJson(Map<String, dynamic> json) {
    print('📥 FreelancerProfile.fromJson: $json');

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
        } catch (e) {}
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

    Map<String, dynamic> parseMap(dynamic data) {
      if (data == null) return {};
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is Map) {
            return Map<String, dynamic>.from(parsed);
          }
        } catch (e) {}
      }
      return {};
    }

    return FreelancerProfile(
      id: json['id'],
      userId: json['user_id'] ?? json['UserId'],
      title: json['title'],
      bio: json['bio'],
      tagline: json['tagline'],
      skills: parseStringList(json['skills']),
      topSkills: parseStringList(json['top_skills']),
      experienceYears: json['experience_years'],
      hourlyRate: json['hourly_rate']?.toDouble(),
      availability: json['availability'],
      weeklyHours: json['weekly_hours'],
      rating: json['rating']?.toDouble(),
      totalReviews: json['total_reviews'],
      completedProjectsCount: json['completed_projects_count'],
      totalEarnings: json['total_earnings']?.toDouble(),
      jobSuccessScore: json['job_success_score'],
      responseTime: json['response_time'],
      onTimeDeliveryRate: json['on_time_delivery_rate']?.toDouble(),
      onBudgetRate: json['on_budget_rate']?.toDouble(),
      repeatHireRate: json['repeat_hire_rate']?.toDouble(),
      location: json['location'],
      locationCoordinates: json['location_coordinates'],
      timezone: json['timezone'],
      languages: parseMapList(json['languages']),
      education: parseMapList(json['education']),
      certifications: parseMapList(json['certifications']),
      workExperience: parseMapList(json['work_experience']),
      portfolioItemsCount: json['portfolio_items_count'],
      videoIntroUrl: json['video_intro_url'],
      cvUrl: json['cv_url'],
      cvText: json['cv_text'],
      socialLinks: parseMap(json['social_links']),
      website: json['website'],
      github: json['github'],
      linkedin: json['linkedin'],
      behance: json['behance'],
      dribbble: json['dribbble'],
      stackoverflow: json['stackoverflow'],
      isAvailable: json['is_available'],
      isFeatured: json['is_featured'],
      isTopRated: json['is_top_rated'],
      isRisingTalent: json['is_rising_talent'],
      isVerified: json['is_verified'],
      profileStrength: json['profile_strength'],
      profileCompletionPercentage: json['profile_completion_percentage'],
      categories: parseStringList(json['categories']),
      subcategories: parseStringList(json['subcategories']),
      specialization: parseStringList(json['specialization']),
      profileViews: json['profile_views'],
      searchAppearances: json['search_appearances'],
      invitationsSent: json['invitations_sent'],
      invitationsAccepted: json['invitations_accepted'],
      preferredProjectTypes: parseStringList(json['preferred_project_types']),
      preferredProjectSizes: parseStringList(json['preferred_project_sizes']),
      minProjectBudget: json['min_project_budget']?.toDouble(),
      teamSize: json['team_size'],
      isAgency: json['is_agency'],
      agencyId: json['agency_id'],
      skillsVerified: parseStringList(json['skills_verified']),
      testScores: parseMapList(json['test_scores']),
      preferredCommunicationChannels: parseStringList(
        json['preferred_communication_channels'],
      ),
      responseRate: json['response_rate']?.toDouble(),
      badges: parseMapList(json['badges']),
      achievements: parseMapList(json['achievements']),
      lastProfileUpdate: json['last_profile_update'] != null
          ? DateTime.tryParse(json['last_profile_update'])
          : null,
      memberSince: json['member_since'] != null
          ? DateTime.tryParse(json['member_since'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'bio': bio,
      'tagline': tagline,
      'skills': skills,
      'top_skills': topSkills,
      'experience_years': experienceYears,
      'hourly_rate': hourlyRate,
      'availability': availability,
      'weekly_hours': weeklyHours,
      'rating': rating,
      'total_reviews': totalReviews,
      'completed_projects_count': completedProjectsCount,
      'total_earnings': totalEarnings,
      'job_success_score': jobSuccessScore,
      'response_time': responseTime,
      'on_time_delivery_rate': onTimeDeliveryRate,
      'on_budget_rate': onBudgetRate,
      'repeat_hire_rate': repeatHireRate,
      'location': location,
      'location_coordinates': locationCoordinates,
      'timezone': timezone,
      'languages': languages,
      'education': education,
      'certifications': certifications,
      'work_experience': workExperience,
      'portfolio_items_count': portfolioItemsCount,
      'video_intro_url': videoIntroUrl,
      'cv_url': cvUrl,
      'cv_text': cvText,
      'social_links': socialLinks,
      'website': website,
      'github': github,
      'linkedin': linkedin,
      'behance': behance,
      'dribbble': dribbble,
      'stackoverflow': stackoverflow,
      'is_available': isAvailable,
      'is_featured': isFeatured,
      'is_top_rated': isTopRated,
      'is_rising_talent': isRisingTalent,
      'is_verified': isVerified,
      'profile_strength': profileStrength,
      'profile_completion_percentage': profileCompletionPercentage,
      'categories': categories,
      'subcategories': subcategories,
      'specialization': specialization,
      'profile_views': profileViews,
      'search_appearances': searchAppearances,
      'invitations_sent': invitationsSent,
      'invitations_accepted': invitationsAccepted,
      'preferred_project_types': preferredProjectTypes,
      'preferred_project_sizes': preferredProjectSizes,
      'min_project_budget': minProjectBudget,
      'team_size': teamSize,
      'is_agency': isAgency,
      'agency_id': agencyId,
      'skills_verified': skillsVerified,
      'test_scores': testScores,
      'preferred_communication_channels': preferredCommunicationChannels,
      'response_rate': responseRate,
      'badges': badges,
      'achievements': achievements,
      'last_profile_update': lastProfileUpdate?.toIso8601String(),
      'member_since': memberSince?.toIso8601String(),
    };
  }
}
