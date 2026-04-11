import 'package:flutter/material.dart';
import 'package:freelancer_platform/models/project_model.dart';
import 'package:freelancer_platform/models/proposal_model.dart';
import 'package:freelancer_platform/models/user_model.dart';

class InterviewInvitation {
  final int id;
  final int proposalId;
  final int clientId;
  final int freelancerId;
  final int projectId;
  final String status;
  final List<DateTime> suggestedTimes;
  final DateTime? selectedTime;
  final String? meetingLink;
  final String? message;
  final String? responseMessage;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final String? meetingNotes;
  final String? feedback;
  final String? rescheduleReason;
  final int durationMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  final Proposal? proposal;
  final Project? project;
  final User? client;
  final User? freelancer;
  final DateTime? completedAt;
  final int? rating;
  final String? review;
  final int? responseTimeHours;
  int? feedbackRating;
  String? feedbackComment;
  String? feedbackImprovements;
  bool? feedbackWouldHireAgain;

  InterviewInvitation({
    required this.id,
    required this.proposalId,
    required this.clientId,
    required this.freelancerId,
    required this.projectId,
    required this.status,
    required this.suggestedTimes,
    this.selectedTime,
    this.meetingLink,
    this.message,
    this.responseMessage,
    required this.expiresAt,
    this.respondedAt,
    this.meetingNotes,
    this.feedback,
    this.rescheduleReason,
    this.durationMinutes = 30,
    required this.createdAt,
    required this.updatedAt,
    this.proposal,
    this.project,
    this.client,
    this.freelancer,
    this.completedAt,
    this.rating,
    this.review,
    this.responseTimeHours,
    this.feedbackRating,
    this.feedbackComment,
    this.feedbackImprovements,
    this.feedbackWouldHireAgain,
  });

  factory InterviewInvitation.fromJson(Map<String, dynamic> json) {
    List<DateTime> parseSuggestedTimes(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((t) => DateTime.parse(t)).toList();
      }
      return [];
    }

    return InterviewInvitation(
      id: json['id'],
      proposalId: json['proposal_id'],
      clientId: json['client_id'],
      freelancerId: json['freelancer_id'],
      projectId: json['project_id'],
      status: json['status'] ?? 'pending',
      suggestedTimes: parseSuggestedTimes(json['suggested_times']),
      selectedTime: json['selected_time'] != null
          ? DateTime.parse(json['selected_time'])
          : null,
      meetingLink: json['meeting_link'],
      message: json['message'],
      responseMessage: json['response_message'],
      expiresAt: DateTime.parse(json['expires_at']),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'])
          : null,
      meetingNotes: json['meeting_notes'],
      feedback: json['feedback'],
      rescheduleReason: json['reschedule_reason'],
      durationMinutes: json['duration_minutes'] ?? 30,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      proposal: json['Proposal'] != null
          ? Proposal.fromJson(json['Proposal'])
          : null,
      project: json['Project'] != null
          ? Project.fromJson(json['Project'])
          : null,
      feedbackRating: json['feedback_rating'],
      feedbackComment: json['feedback_comment'],
      feedbackImprovements: json['feedback_improvements'],
      feedbackWouldHireAgain: json['feedback_would_hire_again'],

      client: json['client'] != null ? User.fromJson(json['client']) : null,
      freelancer: json['freelancer'] != null
          ? User.fromJson(json['freelancer'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      rating: json['rating'],
      review: json['review'],
      responseTimeHours: json['response_time_hours'],
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isExpired => status == 'expired';
  bool get isCompleted => status == 'completed';
  bool get isRescheduled => status == 'rescheduled';

  bool get isExpiredByDate => DateTime.now().isAfter(expiresAt) && isPending;

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending Response';
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      case 'expired':
        return 'Expired';
      case 'completed':
        return 'Completed';
      case 'rescheduled':
        return 'Rescheduled';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      case 'completed':
        return Colors.blue;
      case 'rescheduled':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'accepted':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      case 'expired':
        return Icons.timer_off;
      case 'completed':
        return Icons.verified;
      case 'rescheduled':
        return Icons.update;
      default:
        return Icons.help;
    }
  }

  String get formattedSelectedTime {
    if (selectedTime == null) return 'Not scheduled';
    return _formatDateTime(selectedTime!);
  }

  String get formattedExpiryDate {
    return _formatDateTime(expiresAt);
  }

  String get daysRemaining {
    final days = expiresAt.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    return '$days days remaining';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class InterviewStats {
  final int total;
  final int pending;
  final int accepted;
  final int completed;
  final int declined;
  final int expired;

  InterviewStats({
    this.total = 0,
    this.pending = 0,
    this.accepted = 0,
    this.completed = 0,
    this.declined = 0,
    this.expired = 0,
  });

  factory InterviewStats.fromJson(Map<String, dynamic> json) {
    return InterviewStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      accepted: json['accepted'] ?? 0,
      completed: json['completed'] ?? 0,
      declined: json['declined'] ?? 0,
      expired: json['expired'] ?? 0,
    );
  }
}
