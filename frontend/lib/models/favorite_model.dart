// ===== frontend/lib/models/favorite_model.dart =====
import 'package:freelancer_platform/models/project_model.dart';

class FavoriteProject {
  final int id;
  final Project project;
  final DateTime addedAt;

  FavoriteProject({
    required this.id,
    required this.project,
    required this.addedAt,
  });

  factory FavoriteProject.fromJson(Map<String, dynamic> json) {
    return FavoriteProject(
      id: json['id'],
      project: Project.fromJson(json['project']),
      addedAt: DateTime.parse(json['addedAt']),
    );
  }
}

class FavoriteResponse {
  final bool success;
  final List<FavoriteProject> favorites;
  final int total;
  final int page;
  final int totalPages;

  FavoriteResponse({
    required this.success,
    required this.favorites,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory FavoriteResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteResponse(
      success: json['success'] ?? false,
      favorites:
          (json['favorites'] as List?)
              ?.map((f) => FavoriteProject.fromJson(f))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
