// ========== Response Models ==========
import 'package:freelancer_platform/models/project_model.dart';

class SearchResponse {
  final bool success;
  final List<Project> projects;
  final int total;
  final int page;
  final int totalPages;

  SearchResponse({
    required this.success,
    required this.projects,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      success: json['success'] ?? false,
      projects:
          (json['projects'] as List?)
              ?.map((p) => Project.fromJson(p))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
