// lib/models/usage_limits_model.dart
class UsageLimits {
  final int proposalsUsed;
  final int? proposalsLimit;
  final int activeProjectsUsed;
  final int? activeProjectsLimit;
  final int? interviewsUsed;
  final int? interviewsLimit;
  final int? interviewsRemaining;
  final String? planSlug;
  final String? planName;

  UsageLimits({
    required this.proposalsUsed,
    this.proposalsLimit,
    required this.activeProjectsUsed,
    this.activeProjectsLimit,
    this.interviewsUsed,
    this.interviewsLimit,
    this.interviewsRemaining,
    this.planSlug,
    this.planName,
  });

  factory UsageLimits.fromJson(Map<String, dynamic> json) {
    return UsageLimits(
      proposalsUsed: json['proposals_used'] ?? 0,
      proposalsLimit: json['proposals_limit'],
      activeProjectsUsed: json['active_projects_used'] ?? 0,
      activeProjectsLimit: json['active_projects_limit'],
      interviewsUsed: json['interviews_used'],
      interviewsLimit: json['interviews_limit'],
      interviewsRemaining: json['interviews_remaining'],
      planSlug: json['plan_slug']?.toString(),
      planName: json['plan_name']?.toString(),
    );
  }

  double get proposalsProgress {
    if (proposalsLimit == null || proposalsLimit == 0) return 0;
    return proposalsUsed / proposalsLimit!;
  }

  double get activeProjectsProgress {
    if (activeProjectsLimit == null || activeProjectsLimit == 0) return 0;
    return activeProjectsUsed / activeProjectsLimit!;
  }

  int get remainingProposals {
    if (proposalsLimit == null) return -1;
    return proposalsLimit! - proposalsUsed;
  }

  int get remainingActiveProjects {
    if (activeProjectsLimit == null) return -1;
    return activeProjectsLimit! - activeProjectsUsed;
  }

  bool get canSubmitProposal {
    if (proposalsLimit == null) return true;
    return proposalsUsed < proposalsLimit!;
  }

  bool get canCreateActiveProject {
    if (activeProjectsLimit == null) return true;
    return activeProjectsUsed < activeProjectsLimit!;
  }

  bool get hasInterviewLimit => interviewsLimit != null;

  bool get hasProposalLimit => proposalsLimit != null;

  bool get canScheduleInterview {
    if (interviewsLimit == null) return true;
    final rem = interviewsRemaining;
    if (rem == null) return true;
    return rem > 0;
  }
}
