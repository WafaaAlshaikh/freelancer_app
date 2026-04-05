// lib/models/usage_limits_model.dart
class UsageLimits {
  final int proposalsUsed;
  final int? proposalsLimit;
  final int activeProjectsUsed;
  final int? activeProjectsLimit;

  UsageLimits({
    required this.proposalsUsed,
    this.proposalsLimit,
    required this.activeProjectsUsed,
    this.activeProjectsLimit,
  });

  factory UsageLimits.fromJson(Map<String, dynamic> json) {
    return UsageLimits(
      proposalsUsed: json['proposals_used'] ?? 0,
      proposalsLimit: json['proposals_limit'],
      activeProjectsUsed: json['active_projects_used'] ?? 0,
      activeProjectsLimit: json['active_projects_limit'],
    );
  }

  double get proposalsProgress {
    if (proposalsLimit == null) return 0;
    return proposalsUsed / proposalsLimit!;
  }

  double get activeProjectsProgress {
    if (activeProjectsLimit == null) return 0;
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
}
