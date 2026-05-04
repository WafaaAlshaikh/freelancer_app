class OfferModel {
  final int id;
  final int clientId;
  final String clientName;
  final String? clientAvatar;
  final int projectId;
  final String projectTitle;
  final double? amount;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? viewedAt;

  OfferModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientAvatar,
    required this.projectId,
    required this.projectTitle,
    this.amount,
    required this.message,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.viewedAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing offer: $json');

    final client = json['client'] as Map<String, dynamic>?;
    final project = json['project'] as Map<String, dynamic>?;

    double? amount;
    if (json['amount'] != null) {
      if (json['amount'] is num) {
        amount = (json['amount'] as num).toDouble();
      } else if (json['amount'] is String) {
        amount = double.tryParse(json['amount'] as String);
      }
    }

    return OfferModel(
      id: json['id'] ?? 0,
      clientId: json['clientId'] ?? json['client_id'] ?? client?['id'] ?? 0,
      clientName: client?['name'] ?? json['clientName'] ?? 'Client',
      clientAvatar: client?['avatar'] ?? json['clientAvatar'],
      projectId: json['projectId'] ?? json['project_id'] ?? project?['id'] ?? 0,
      projectTitle: project?['title'] ?? json['projectTitle'] ?? 'Project',
      amount: amount,
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at']) ??
          DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
      viewedAt: json['viewedAt'] != null
          ? DateTime.tryParse(json['viewedAt'])
          : null,
    );
  }
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isExpired =>
      status == 'expired' ||
      (expiresAt != null && expiresAt!.isBefore(DateTime.now()));
}
