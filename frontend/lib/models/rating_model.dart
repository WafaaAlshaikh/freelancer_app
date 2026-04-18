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
  final int? qualityRating;
  final int? communicationRating;
  final int? deadlineRating;
  final bool isVerifiedPurchase;
  final bool isAnonymous;
  final List<String>? helpfulVotes;
  final String? reply;
  final DateTime? repliedAt;
  final List<String>? images;
  final String? videoUrl;
  
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
    this.qualityRating,
    this.communicationRating,
    this.deadlineRating,
    this.isVerifiedPurchase = true,
    this.isAnonymous = false,
    this.helpfulVotes,
    this.reply,
    this.repliedAt,
    this.images,
    this.videoUrl,
    this.fromUser,
    this.contract,
  });

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }
    return 0;
  }

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: _toInt(json['id']),
      contractId: _toInt(json['contractId']),
      fromUserId: _toInt(json['fromUserId']),
      toUserId: _toInt(json['toUserId']),
      rating: _toInt(json['rating']),
      comment: json['comment'],
      role: json['role'] ?? 'client',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      qualityRating: json['qualityRating'] != null ? _toInt(json['qualityRating']) : null,
      communicationRating: json['communicationRating'] != null ? _toInt(json['communicationRating']) : null,
      deadlineRating: json['deadlineRating'] != null ? _toInt(json['deadlineRating']) : null,
      isVerifiedPurchase: json['isVerifiedPurchase'] ?? true,
      isAnonymous: json['isAnonymous'] ?? false,
      helpfulVotes: json['helpfulVotes'] != null 
          ? List<String>.from(json['helpfulVotes']) 
          : null,
      reply: json['reply'],
      repliedAt: json['repliedAt'] != null 
          ? DateTime.parse(json['repliedAt']) 
          : null,
      images: json['images'] != null 
          ? List<String>.from(json['images']) 
          : null,
      videoUrl: json['videoUrl'],
      fromUser: json['fromUser'],
      contract: json['Contract'],
    );
  }

  Map<String, dynamic> toJson() => {
    'contractId': contractId,
    'rating': rating,
    'comment': comment,
    'qualityRating': qualityRating,
    'communicationRating': communicationRating,
    'deadlineRating': deadlineRating,
    'isAnonymous': isAnonymous,
  };

  double get averageRating {
    final ratings = [qualityRating, communicationRating, deadlineRating]
        .whereType<int>()
        .toList();
    if (ratings.isEmpty) return rating.toDouble();
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  String get roleIcon => role == 'client' ? '👤' : '💼';
  String get roleLabel => role == 'client' ? 'Client' : 'Freelancer';
  
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays > 30) return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  bool get canReply => reply == null || reply!.isEmpty;
  int get helpfulCount => helpfulVotes?.length ?? 0;
}


class RatingStats {
  final int total;
  final double average;
  final Map<int, int> distribution;
  final Map<String, double>? categoryAverages;
  final Map<String, dynamic>? monthlyStats;

  RatingStats({
    required this.total,
    required this.average,
    required this.distribution,
    this.categoryAverages,
    this.monthlyStats,
  });

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0.0;
  }

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    final distributionMap = <int, int>{};
    final rawDistribution = json['distribution'] as Map? ?? {};
    for (var entry in rawDistribution.entries) {
      final key = _toInt(entry.key);
      final value = _toInt(entry.value);
      distributionMap[key] = value;
    }

    return RatingStats(
      total: _toInt(json['total']),
      average: _toDouble(json['average']),
      distribution: distributionMap,
      categoryAverages: json['categoryAverages'] != null 
          ? Map<String, double>.from(json['categoryAverages']) 
          : null,
      monthlyStats: json['monthlyStats'],
    );
  }

  int get positiveCount => (distribution[4] ?? 0) + (distribution[5] ?? 0);
  int get neutralCount => distribution[3] ?? 0;
  int get negativeCount => (distribution[1] ?? 0) + (distribution[2] ?? 0);
  
  double get positiveRate => total > 0 ? positiveCount / total * 100 : 0;
  double get neutralRate => total > 0 ? neutralCount / total * 100 : 0;
  double get negativeRate => total > 0 ? negativeCount / total * 100 : 0;
}