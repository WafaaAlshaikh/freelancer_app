// lib/models/rating_model.dart
class Rating {
  final int id;
  final int contractId;
  final int fromUserId;
  final int toUserId;
  final int rating;
  final String? comment;
  final String role; 
  final DateTime createdAt;
  final DateTime updatedAt;
  
  final Map<String, dynamic>? fromUser;
  final Map<String, dynamic>? contract;

  Rating({
    required this.id,
    required this.contractId,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    this.comment,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.fromUser,
    this.contract,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'],
      contractId: json['contractId'],
      fromUserId: json['fromUserId'],
      toUserId: json['toUserId'],
      rating: json['rating'],
      comment: json['comment'],
      role: json['role'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      fromUser: json['fromUser'],
      contract: json['Contract'],
    );
  }

  Map<String, dynamic> toJson() => {
    'contractId': contractId,
    'rating': rating,
    'comment': comment,
  };
}

class RatingStats {
  final int total;
  final double average;
  final Map<int, int> distribution;

  RatingStats({
    required this.total,
    required this.average,
    required this.distribution,
  });

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    return RatingStats(
      total: json['total'] ?? 0,
      average: (json['average'] ?? 0).toDouble(),
      distribution: Map<int, int>.from(json['distribution'] ?? {}),
    );
  }
}