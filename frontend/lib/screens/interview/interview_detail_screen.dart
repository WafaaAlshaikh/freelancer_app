// lib/screens/interview/interview_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelancer_platform/models/project_model.dart';
import 'package:freelancer_platform/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/interview_model.dart';
import '../../services/api_service.dart';
import '../../utils/token_storage.dart';
import '../../theme/app_theme.dart';
import 'post_interview_feedback_screen.dart';

class InterviewDetailScreen extends StatefulWidget {
  final InterviewInvitation invitation;

  const InterviewDetailScreen({super.key, required this.invitation});

  @override
  State<InterviewDetailScreen> createState() => _InterviewDetailScreenState();
}

class _InterviewDetailScreenState extends State<InterviewDetailScreen> {
  late InterviewInvitation _invitation;
  String? _userRole;
  bool _loading = false;
  DateTime? _selectedTime;
  final TextEditingController _responseMessageController =
      TextEditingController();
  final TextEditingController _meetingNotesController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _cancelReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _invitation = widget.invitation;
    _loadUserRole();
    if (_invitation.suggestedTimes.length == 1) {
      _selectedTime = _invitation.suggestedTimes.first;
    }
  }

  @override
  void dispose() {
    _responseMessageController.dispose();
    _meetingNotesController.dispose();
    _feedbackController.dispose();
    _cancelReasonController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final result = await ApiService.getInterviewById(_invitation.id);
      if (result['success'] == true && result['invitation'] != null) {
        setState(() {
          _invitation = InterviewInvitation.fromJson(result['invitation']);
        });
      }
    } catch (e) {
      print('Error refreshing interview: $e');
    }
  }

  Future<void> _loadUserRole() async {
    final role = await TokenStorage.getUserRole();
    setState(() => _userRole = role);
  }

  Future<void> _acceptInterview(DateTime selectedTime) async {
    final t = AppLocalizations.of(context)!;
    setState(() => _loading = true);

    final result = await ApiService.respondToInterview(
      invitationId: _invitation.id,
      status: 'accepted',
      selectedTime: selectedTime,
      responseMessage: _responseMessageController.text.isNotEmpty
          ? _responseMessageController.text
          : null,
    );

    setState(() => _loading = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: t.interviewAccepted);
      await _refresh();
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? t.errorAcceptingInterview,
        backgroundColor: AppColors.danger,
      );
    }
  }

  Future<void> _declineInterview() async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          t.declineInterview,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          t.declineInterviewConfirmation,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel, style: TextStyle(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(t.decline),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    final result = await ApiService.respondToInterview(
      invitationId: _invitation.id,
      status: 'declined',
      responseMessage: _responseMessageController.text.isNotEmpty
          ? _responseMessageController.text
          : null,
    );

    setState(() => _loading = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: t.interviewDeclined);
      await _refresh();
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? t.errorDecliningInterview,
        backgroundColor: AppColors.danger,
      );
    }
  }

  Future<void> _rescheduleInterview() async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final DateTime? newTime = await showDatePicker(
      context: context,
      initialDate:
          _invitation.selectedTime ??
          DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: t.selectDate,
      cancelText: t.cancel,
      confirmText: t.ok,
    );

    if (newTime == null) return;

    final TimeOfDay? newTimeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: t.selectTime,
      cancelText: t.cancel,
      confirmText: t.ok,
    );

    if (newTimeOfDay == null) return;

    final fullDateTime = DateTime(
      newTime.year,
      newTime.month,
      newTime.day,
      newTimeOfDay.hour,
      newTimeOfDay.minute,
    );

    final reason = await _showReasonDialog(t.reasonForRescheduling);

    if (reason == null) return;

    setState(() => _loading = true);

    final result = await ApiService.rescheduleInterview(
      invitationId: _invitation.id,
      newTime: fullDateTime,
      reason: reason,
    );

    setState(() => _loading = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: t.interviewRescheduled);
      await _refresh();
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? t.errorRescheduling,
        backgroundColor: AppColors.danger,
      );
    }
  }

  Future<void> _cancelInterview() async {
    final t = AppLocalizations.of(context)!;
    final reason = await _showReasonDialog(t.reasonForCancellation);

    if (reason == null) return;

    setState(() => _loading = true);

    final result = await ApiService.cancelInterview(
      invitationId: _invitation.id,
      reason: reason,
    );

    setState(() => _loading = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: t.interviewCancelled);
      await _refresh();
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? t.errorCancelling,
        backgroundColor: AppColors.danger,
      );
    }
  }

  Future<String?> _showReasonDialog(String title) async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          title,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: t.pleaseProvideReason,
            hintStyle: TextStyle(color: AppColors.gray),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(t.cancel, style: TextStyle(color: AppColors.gray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            child: Text(t.submit),
          ),
        ],
      ),
    );
  }

  Future<void> _completeInterview() async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          t.completeInterview,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.addNotesAboutInterview,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _meetingNotesController,
              maxLines: 4,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: t.meetingNotesHint,
                hintStyle: TextStyle(color: AppColors.gray),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.feedbackOptional,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 2,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: t.additionalFeedbackHint,
                hintStyle: TextStyle(color: AppColors.gray),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel, style: TextStyle(color: AppColors.gray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            child: Text(t.complete),
          ),
        ],
      ),
    );

    if (result != true) return;

    setState(() => _loading = true);

    final apiResult = await ApiService.addInterviewNotes(
      invitationId: _invitation.id,
      meetingNotes: _meetingNotesController.text,
      feedback: _feedbackController.text.isNotEmpty
          ? _feedbackController.text
          : null,
    );

    setState(() => _loading = false);

    if (apiResult['success'] == true) {
      Fluttertoast.showToast(msg: t.interviewCompleted);
      await _refresh();
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: apiResult['message'] ?? t.errorCompletingInterview,
        backgroundColor: AppColors.danger,
      );
    }
  }

  Future<void> _addToCalendar(String type) async {
    final t = AppLocalizations.of(context)!;
    final result = await ApiService.addToCalendar(
      invitationId: _invitation.id,
      calendarType: type,
    );

    if (type == 'ics') {
      Fluttertoast.showToast(msg: t.calendarFileDownloaded);
    } else if (result['success'] == true) {
      Fluttertoast.showToast(msg: t.addedToCalendar);
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? t.errorAddingToCalendar,
        backgroundColor: AppColors.danger,
      );
    }
  }

  Future<void> _sendManualReminder() async {
    final t = AppLocalizations.of(context)!;
    final result = await ApiService.sendManualReminder(_invitation.id);
    if (result['success'] == true) {
      Fluttertoast.showToast(msg: t.reminderSent);
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? t.errorSendingReminder,
        backgroundColor: AppColors.danger,
      );
    }
  }

  Future<void> _addFeedback() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostInterviewFeedbackScreen(
          invitationId: _invitation.id,
          freelancerName: _invitation.freelancer?.name ?? 'Freelancer',
        ),
      ),
    );
    if (result == true) {
      await _refresh();
    }
  }

  Future<void> _selectDateTime() async {
    final t = AppLocalizations.of(context)!;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: t.selectDate,
      cancelText: t.cancel,
      confirmText: t.ok,
    );

    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
      helpText: t.selectTime,
      cancelText: t.cancel,
      confirmText: t.ok,
    );

    if (time == null) return;

    setState(() {
      _selectedTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isClient = _userRole == 'client';
    final isFreelancer = _userRole == 'freelancer';
    final isPending = _invitation.isPending && !_invitation.isExpiredByDate;
    final isAccepted = _invitation.isAccepted;
    final isCompleted = _invitation.isCompleted;
    final otherParty = isClient ? _invitation.freelancer : _invitation.client;
    final project = _invitation.project;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.interviewDetails),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          if (isAccepted && !isCompleted && _invitation.selectedTime != null)
            PopupMenuButton<String>(
              onSelected: _addToCalendar,
              icon: Icon(Icons.calendar_today, color: theme.iconTheme.color),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'google',
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month),
                      const SizedBox(width: 8),
                      Text(t.googleCalendar),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'ics',
                  child: Row(
                    children: [
                      const Icon(Icons.download),
                      const SizedBox(width: 8),
                      Text(t.downloadIcsFile),
                    ],
                  ),
                ),
              ],
            ),

          if (isAccepted && !isCompleted && _invitation.selectedTime != null)
            IconButton(
              icon: const Icon(
                Icons.notifications_active,
                color: Colors.orange,
              ),
              onPressed: _sendManualReminder,
              tooltip: t.sendReminder,
            ),

          if (isAccepted && !isCompleted && !_invitation.isExpiredByDate)
            IconButton(
              icon: Icon(Icons.edit_calendar, color: Colors.orange),
              onPressed: _rescheduleInterview,
              tooltip: t.reschedule,
            ),

          if (isAccepted && !isCompleted)
            IconButton(
              icon: Icon(Icons.cancel, color: AppColors.danger),
              onPressed: _cancelInterview,
              tooltip: t.cancel,
            ),

          if (isCompleted && _invitation.feedbackRating == null && isClient)
            IconButton(
              icon: const Icon(Icons.rate_review, color: Colors.amber),
              onPressed: _addFeedback,
              tooltip: t.addFeedback,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildProjectCard(project, otherParty),
            const SizedBox(height: 16),
            if (_invitation.message != null && _invitation.message!.isNotEmpty)
              _buildMessageCard(),
            const SizedBox(height: 16),
            _buildTimelineCard(),
            const SizedBox(height: 16),
            if (isAccepted && _invitation.meetingLink != null)
              _buildMeetingCard(),
            if (isPending && isFreelancer) _buildResponseCard(),
            if (isAccepted && !isCompleted && isFreelancer)
              _buildCompletionCard(),
            if (isCompleted && _invitation.meetingNotes != null)
              _buildNotesCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isExpired = _invitation.isExpiredByDate;
    final statusColor = isExpired ? AppColors.gray : _invitation.statusColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.3 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_invitation.statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? t.expired : _invitation.statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isExpired
                      ? t.invitationExpired
                      : _invitation.isAccepted &&
                            _invitation.selectedTime != null
                      ? '${t.scheduledFor} ${_invitation.formattedSelectedTime}'
                      : _invitation.isPending
                      ? t.waitingForResponse
                      : _invitation.isCompleted
                      ? t.interviewCompleted
                      : _invitation.isDeclined
                      ? t.interviewDeclined
                      : '',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project? project, User? otherParty) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.projectDetails,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage: otherParty?.avatar != null
                    ? NetworkImage(otherParty!.avatar!)
                    : null,
                child: otherParty?.avatar == null
                    ? Text(
                        otherParty?.name?[0].toUpperCase() ?? '?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherParty?.name ?? t.user,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      otherParty?.email ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 24, color: theme.dividerColor),
          Text(
            project?.title ?? t.project,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            project?.description ?? '',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${t.budget}: ${t.dollar}${project?.budget?.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${t.duration}: ${project?.duration} ${t.days}',
                  style: TextStyle(fontSize: 11, color: AppColors.info),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sender = _userRole == 'client' ? t.freelancer : t.client;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.message, size: 18, color: AppColors.info),
              const SizedBox(width: 8),
              Text(
                '${t.messageFrom} $sender',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _invitation.message!,
            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.timeline,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(
            icon: Icons.send,
            label: t.invitationSent,
            date: _invitation.createdAt,
            isFirst: true,
          ),
          if (_invitation.respondedAt != null)
            _buildTimelineItem(
              icon: _invitation.isAccepted ? Icons.check_circle : Icons.cancel,
              label: _invitation.isAccepted ? t.accepted : t.declined,
              date: _invitation.respondedAt!,
              color: _invitation.isAccepted
                  ? theme.colorScheme.secondary
                  : AppColors.danger,
            ),
          if (_invitation.selectedTime != null)
            _buildTimelineItem(
              icon: Icons.calendar_today,
              label: t.interviewScheduled,
              date: _invitation.selectedTime!,
            ),
          if (_invitation.respondedAt != null &&
              _invitation.responseMessage != null)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 8, bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${_invitation.responseMessage}"',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          if (_invitation.rescheduleReason != null)
            _buildTimelineItem(
              icon: Icons.update,
              label: t.rescheduled,
              date: _invitation.updatedAt,
              color: AppColors.warning,
              subtitle: '${t.reason}: ${_invitation.rescheduleReason}',
            ),
          if (_invitation.completedAt != null)
            _buildTimelineItem(
              icon: Icons.verified,
              label: t.completed,
              date: _invitation.completedAt!,
              color: AppColors.info,
            ),
          _buildTimelineItem(
            icon: Icons.timer_off,
            label: t.expires,
            date: _invitation.expiresAt,
            isLast: true,
            color: _invitation.isExpiredByDate
                ? AppColors.danger
                : AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String label,
    required DateTime date,
    String? subtitle,
    Color? color,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: effectiveColor),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(date),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingCard() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.video_call,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.joinInterview,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            t.joinInterviewDescription,
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final url = Uri.parse(_invitation.meetingLink!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.video_call),
              label: Text(t.joinMeeting),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final suggestedTimes = _invitation.suggestedTimes;
    final isSingleTime = suggestedTimes.length == 1;
    final effectiveSelectedTime = isSingleTime
        ? suggestedTimes.first
        : _selectedTime;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.interviewInvitation,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          if (isSingleTime) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.proposedTime,
                          style: TextStyle(fontSize: 12, color: AppColors.gray),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(suggestedTimes.first),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!isSingleTime) ...[
            Text(
              t.availableTimes,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...suggestedTimes.map((time) {
              final isSelected = _selectedTime == time;
              return GestureDetector(
                onTap: () => setState(() => _selectedTime = time),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : (isDark
                              ? AppColors.darkSurface
                              : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<DateTime>(
                        value: time,
                        groupValue: _selectedTime,
                        onChanged: (value) =>
                            setState(() => _selectedTime = value),
                        activeColor: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatDateTime(time),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 16),

          TextField(
            controller: _responseMessageController,
            maxLines: 2,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: t.addMessageOptional,
              hintStyle: TextStyle(color: AppColors.gray),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade50,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : _declineInterview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(t.decline),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          if (isSingleTime) {
                            _acceptInterview(suggestedTimes.first);
                          } else if (_selectedTime != null) {
                            _acceptInterview(_selectedTime!);
                          } else {
                            Fluttertoast.showToast(
                              msg: t.pleaseSelectTime,
                              backgroundColor: AppColors.warning,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isSingleTime
                              ? t.acceptAndConfirm
                              : t.acceptSelectedTime,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.completeInterview,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.completeInterviewDescription,
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _completeInterview,
              icon: const Icon(Icons.check_circle),
              label: Text(t.markAsCompleted),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: AppColors.info),
              const SizedBox(width: 8),
              Text(
                t.meetingNotes,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _invitation.meetingNotes ?? '',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (_invitation.feedback != null) ...[
            const SizedBox(height: 12),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.feedback, size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                Text(
                  t.feedback,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _invitation.feedback!,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
