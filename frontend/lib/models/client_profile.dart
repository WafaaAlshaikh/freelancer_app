// lib/models/client_profile.dart
import 'dart:convert';

class ClientProfile {
  final int? id;
  final int? userId;

  final String? companyName;
  final String? companySize;
  final String? companyWebsite;
  final String? industry;
  final String? companyDescription;
  final String? companyLogo;
  final int? foundedYear;
  final String? companyType;

  final String? tagline;
  final String? bio;
  final String? location;
  final String? country;
  final String? timezone;
  final String? phone;

  final List<String>? preferredSkills;
  final List<String>? hiringFor;
  final String? preferredContractType;
  final double? budgetRangeMin;
  final double? budgetRangeMax;
  final double? avgProjectBudget;

  final double? totalSpent;
  final int? totalProjects;
  final int? activeContracts;
  final int? completedContracts;
  final int? cancelledContracts;
  final int? hireRate;
  final int? avgContractDuration;
  final double? repeatHireRate;

  final double? clientRating;
  final int? totalReviewsReceived;
  final int? paymentVerificationScore;

  final bool? paymentVerified;
  final bool? idVerified;
  final bool? companyVerified;
  final String? verificationLevel;

  final String? linkedin;
  final String? twitter;
  final String? facebook;
  final String? instagram;

  final List<String>? preferredCommunicationMethods;
  final int? responseTimePreference;
  final List<String>? meetingAvailability;

  final List<String>? projectManagementTools;
  final List<String>? teamCollaborationTools;

  final int? profileViews;
  final int? jobsPosted;
  final int? invitationsSent;
  final int? applicationsReceived;

  final String? preferredFreelancerLevel;
  final String? preferredLocationType;

  final List<Map<String, dynamic>>? badges;
  final bool? isTopClient;
  final bool? isFeaturedClient;

  final int? profileStrength;
  final int? profileCompletionPercentage;

  final DateTime? lastProfileUpdate;
  final DateTime? memberSince;

  ClientProfile({
    this.id,
    this.userId,
    this.companyName,
    this.companySize,
    this.companyWebsite,
    this.industry,
    this.companyDescription,
    this.companyLogo,
    this.foundedYear,
    this.companyType,
    this.tagline,
    this.bio,
    this.location,
    this.country,
    this.timezone,
    this.phone,
    this.preferredSkills,
    this.hiringFor,
    this.preferredContractType,
    this.budgetRangeMin,
    this.budgetRangeMax,
    this.avgProjectBudget,
    this.totalSpent,
    this.totalProjects,
    this.activeContracts,
    this.completedContracts,
    this.cancelledContracts,
    this.hireRate,
    this.avgContractDuration,
    this.repeatHireRate,
    this.clientRating,
    this.totalReviewsReceived,
    this.paymentVerificationScore,
    this.paymentVerified,
    this.idVerified,
    this.companyVerified,
    this.verificationLevel,
    this.linkedin,
    this.twitter,
    this.facebook,
    this.instagram,
    this.preferredCommunicationMethods,
    this.responseTimePreference,
    this.meetingAvailability,
    this.projectManagementTools,
    this.teamCollaborationTools,
    this.profileViews,
    this.jobsPosted,
    this.invitationsSent,
    this.applicationsReceived,
    this.preferredFreelancerLevel,
    this.preferredLocationType,
    this.badges,
    this.isTopClient,
    this.isFeaturedClient,
    this.profileStrength,
    this.profileCompletionPercentage,
    this.lastProfileUpdate,
    this.memberSince,
  });

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    print('📥 ClientProfile.fromJson: $json');

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

    return ClientProfile(
      id: json['id'],
      userId: json['user_id'] ?? json['UserId'],
      companyName: json['company_name'],
      companySize: json['company_size'],
      companyWebsite: json['company_website'],
      industry: json['industry'],
      companyDescription: json['company_description'],
      companyLogo: json['company_logo'],
      foundedYear: json['founded_year'],
      companyType: json['company_type'],
      tagline: json['tagline'],
      bio: json['bio'],
      location: json['location'],
      country: json['country'],
      timezone: json['timezone'],
      phone: json['phone'],
      preferredSkills: parseStringList(json['preferred_skills']),
      hiringFor: parseStringList(json['hiring_for']),
      preferredContractType: json['preferred_contract_type'],
      budgetRangeMin: json['budget_range_min']?.toDouble(),
      budgetRangeMax: json['budget_range_max']?.toDouble(),
      avgProjectBudget: json['avg_project_budget']?.toDouble(),
      totalSpent: json['total_spent']?.toDouble(),
      totalProjects: json['total_projects'],
      activeContracts: json['active_contracts'],
      completedContracts: json['completed_contracts'],
      cancelledContracts: json['cancelled_contracts'],
      hireRate: json['hire_rate'],
      avgContractDuration: json['avg_contract_duration'],
      repeatHireRate: json['repeat_hire_rate']?.toDouble(),
      clientRating: json['client_rating']?.toDouble(),
      totalReviewsReceived: json['total_reviews_received'],
      paymentVerificationScore: json['payment_verification_score'],
      paymentVerified: json['payment_verified'],
      idVerified: json['id_verified'],
      companyVerified: json['company_verified'],
      verificationLevel: json['verification_level'],
      linkedin: json['linkedin'],
      twitter: json['twitter'],
      facebook: json['facebook'],
      instagram: json['instagram'],
      preferredCommunicationMethods: parseStringList(
        json['preferred_communication_methods'],
      ),
      responseTimePreference: json['response_time_preference'],
      meetingAvailability: parseStringList(json['meeting_availability']),
      projectManagementTools: parseStringList(json['project_management_tools']),
      teamCollaborationTools: parseStringList(json['team_collaboration_tools']),
      profileViews: json['profile_views'],
      jobsPosted: json['jobs_posted'],
      invitationsSent: json['invitations_sent'],
      applicationsReceived: json['applications_received'],
      preferredFreelancerLevel: json['preferred_freelancer_level'],
      preferredLocationType: json['preferred_location_type'],
      badges: parseMapList(json['badges']),
      isTopClient: json['is_top_client'],
      isFeaturedClient: json['is_featured_client'],
      profileStrength: json['profile_strength'],
      profileCompletionPercentage: json['profile_completion_percentage'],
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
      'company_name': companyName,
      'company_size': companySize,
      'company_website': companyWebsite,
      'industry': industry,
      'company_description': companyDescription,
      'company_logo': companyLogo,
      'founded_year': foundedYear,
      'company_type': companyType,
      'tagline': tagline,
      'bio': bio,
      'location': location,
      'country': country,
      'timezone': timezone,
      'phone': phone,
      'preferred_skills': preferredSkills,
      'hiring_for': hiringFor,
      'preferred_contract_type': preferredContractType,
      'budget_range_min': budgetRangeMin,
      'budget_range_max': budgetRangeMax,
      'avg_project_budget': avgProjectBudget,
      'total_spent': totalSpent,
      'total_projects': totalProjects,
      'active_contracts': activeContracts,
      'completed_contracts': completedContracts,
      'cancelled_contracts': cancelledContracts,
      'hire_rate': hireRate,
      'avg_contract_duration': avgContractDuration,
      'repeat_hire_rate': repeatHireRate,
      'client_rating': clientRating,
      'total_reviews_received': totalReviewsReceived,
      'payment_verification_score': paymentVerificationScore,
      'payment_verified': paymentVerified,
      'id_verified': idVerified,
      'company_verified': companyVerified,
      'verification_level': verificationLevel,
      'linkedin': linkedin,
      'twitter': twitter,
      'facebook': facebook,
      'instagram': instagram,
      'preferred_communication_methods': preferredCommunicationMethods,
      'response_time_preference': responseTimePreference,
      'meeting_availability': meetingAvailability,
      'project_management_tools': projectManagementTools,
      'team_collaboration_tools': teamCollaborationTools,
      'profile_views': profileViews,
      'jobs_posted': jobsPosted,
      'invitations_sent': invitationsSent,
      'applications_received': applicationsReceived,
      'preferred_freelancer_level': preferredFreelancerLevel,
      'preferred_location_type': preferredLocationType,
      'badges': badges,
      'is_top_client': isTopClient,
      'is_featured_client': isFeaturedClient,
      'profile_strength': profileStrength,
      'profile_completion_percentage': profileCompletionPercentage,
      'last_profile_update': lastProfileUpdate?.toIso8601String(),
      'member_since': memberSince?.toIso8601String(),
    };
  }
}
