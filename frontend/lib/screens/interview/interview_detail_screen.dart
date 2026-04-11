// lib/screens/interview/interview_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelancer_platform/models/project_model.dart';
import 'package:freelancer_platform/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/interview_model.dart';
import '../../services/api_service.dart';
import '../../utils/token_storage.dart';
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
    setState(() => _loading = true);

    print('📤 Sending acceptance with time: ${selectedTime.toIso8601String()}');

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
      Fluttertoast.showToast(msg: 'Interview accepted!');
      await _refresh();
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Error accepting interview',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _declineInterview() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Interview'),
        content: const Text(
          'Are you sure you want to decline this interview invitation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
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
      Fluttertoast.showToast(msg: 'Interview declined');
      await _refresh();
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Error declining interview',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _rescheduleInterview() async {
    final DateTime? newTime = await showDatePicker(
      context: context,
      initialDate:
          _invitation.selectedTime ??
          DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (newTime == null) return;

    final TimeOfDay? newTimeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (newTimeOfDay == null) return;

    final fullDateTime = DateTime(
      newTime.year,
      newTime.month,
      newTime.day,
      newTimeOfDay.hour,
      newTimeOfDay.minute,
    );

    final reason = await _showReasonDialog('Reason for rescheduling?');

    if (reason == null) return;

    setState(() => _loading = true);

    final result = await ApiService.rescheduleInterview(
      invitationId: _invitation.id,
      newTime: fullDateTime,
      reason: reason,
    );

    setState(() => _loading = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: 'Interview rescheduled');
      await _refresh();
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Error rescheduling',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _cancelInterview() async {
    final reason = await _showReasonDialog('Reason for cancellation?');

    if (reason == null) return;

    setState(() => _loading = true);

    final result = await ApiService.cancelInterview(
      invitationId: _invitation.id,
      reason: reason,
    );

    setState(() => _loading = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: 'Interview cancelled');
      await _refresh();
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Error cancelling',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<String?> _showReasonDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Please provide a reason...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeInterview() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Interview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add notes about the interview:'),
            const SizedBox(height: 12),
            TextField(
              controller: _meetingNotesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Meeting notes...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Feedback (optional):'),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Any additional feedback...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
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
      Fluttertoast.showToast(msg: 'Interview completed!');
      await _refresh();
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(
        msg: apiResult['message'] ?? 'Error completing interview',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _addToCalendar(String type) async {
    final result = await ApiService.addToCalendar(
      invitationId: _invitation.id,
      calendarType: type,
    );

    if (type == 'ics') {
      Fluttertoast.showToast(msg: 'Calendar file downloaded');
    } else if (result['success'] == true) {
      Fluttertoast.showToast(msg: 'Added to calendar successfully!');
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Error adding to calendar',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _sendManualReminder() async {
    final result = await ApiService.sendManualReminder(_invitation.id);
    if (result['success'] == true) {
      Fluttertoast.showToast(msg: 'Reminder sent successfully!');
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Error sending reminder',
        backgroundColor: Colors.red,
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
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
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
    final isClient = _userRole == 'client';
    final isFreelancer = _userRole == 'freelancer';
    final isPending = _invitation.isPending && !_invitation.isExpiredByDate;
    final isAccepted = _invitation.isAccepted;
    final isCompleted = _invitation.isCompleted;
    final otherParty = isClient ? _invitation.freelancer : _invitation.client;
    final project = _invitation.project;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Interview Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (isAccepted && !isCompleted && _invitation.selectedTime != null)
            PopupMenuButton<String>(
              onSelected: _addToCalendar,
              icon: const Icon(Icons.calendar_today),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'google',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month),
                      SizedBox(width: 8),
                      Text('Google Calendar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'ics',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Download .ics file'),
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
              tooltip: 'Send Reminder',
            ),

          if (isAccepted && !isCompleted && !_invitation.isExpiredByDate)
            IconButton(
              icon: const Icon(Icons.edit_calendar, color: Colors.orange),
              onPressed: _rescheduleInterview,
              tooltip: 'Reschedule',
            ),

          if (isAccepted && !isCompleted)
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: _cancelInterview,
              tooltip: 'Cancel',
            ),

          if (isCompleted && _invitation.feedbackRating == null && isClient)
            IconButton(
              icon: const Icon(Icons.rate_review, color: Colors.amber),
              onPressed: _addFeedback,
              tooltip: 'Add Feedback',
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
    final isExpired = _invitation.isExpiredByDate;
    final statusColor = isExpired ? Colors.grey : _invitation.statusColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  isExpired ? 'Expired' : _invitation.statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isExpired
                      ? 'This invitation has expired'
                      : _invitation.isAccepted &&
                            _invitation.selectedTime != null
                      ? 'Scheduled for ${_invitation.formattedSelectedTime}'
                      : _invitation.isPending
                      ? 'Waiting for response'
                      : _invitation.isCompleted
                      ? 'Interview completed'
                      : _invitation.isDeclined
                      ? 'Interview declined'
                      : '',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project? project, User? otherParty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: otherParty?.avatar != null
                    ? NetworkImage(otherParty!.avatar!)
                    : null,
                child: otherParty?.avatar == null
                    ? Text(
                        otherParty?.name?[0].toUpperCase() ?? '?',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                      otherParty?.name ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      otherParty?.email ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            project?.title ?? 'Project',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            project?.description ?? '',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Budget: \$${project?.budget?.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Duration: ${project?.duration} days',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.message, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Message from ${_userRole == 'client' ? 'Freelancer' : 'Client'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _invitation.message!,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(
            icon: Icons.send,
            label: 'Invitation Sent',
            date: _invitation.createdAt,
            isFirst: true,
          ),
          if (_invitation.respondedAt != null)
            _buildTimelineItem(
              icon: _invitation.isAccepted ? Icons.check_circle : Icons.cancel,
              label: _invitation.isAccepted ? 'Accepted' : 'Declined',
              date: _invitation.respondedAt!,
              color: _invitation.isAccepted ? Colors.green : Colors.red,
            ),
          if (_invitation.selectedTime != null)
            _buildTimelineItem(
              icon: Icons.calendar_today,
              label: 'Interview Scheduled',
              date: _invitation.selectedTime!,
            ),
          if (_invitation.respondedAt != null &&
              _invitation.responseMessage != null)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 8, bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${_invitation.responseMessage}"',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          if (_invitation.rescheduleReason != null)
            _buildTimelineItem(
              icon: Icons.update,
              label: 'Rescheduled',
              date: _invitation.updatedAt,
              color: Colors.orange,
              subtitle: 'Reason: ${_invitation.rescheduleReason}',
            ),
          if (_invitation.completedAt != null)
            _buildTimelineItem(
              icon: Icons.verified,
              label: 'Completed',
              date: _invitation.completedAt!,
              color: Colors.blue,
            ),
          _buildTimelineItem(
            icon: Icons.timer_off,
            label: 'Expires',
            date: _invitation.expiresAt,
            isLast: true,
            color: _invitation.isExpiredByDate ? Colors.red : Colors.orange,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(width: 2, height: 20, color: Colors.grey.shade300),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: (color ?? Colors.blue).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color ?? Colors.blue),
            ),
            if (!isLast)
              Container(width: 2, height: 20, color: Colors.grey.shade300),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(date),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.video_call,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Join Interview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Click the button below to join the video interview.',
            style: TextStyle(fontSize: 13),
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
              label: const Text('Join Meeting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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
    final suggestedTimes = _invitation.suggestedTimes;
    final isSingleTime = suggestedTimes.length == 1;
    final effectiveSelectedTime = isSingleTime
        ? suggestedTimes.first
        : _selectedTime;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interview Invitation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (isSingleTime) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.purple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Proposed Time:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(suggestedTimes.first),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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
            const Text(
              'Available Times:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                        ? Colors.purple.shade50
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.purple : Colors.transparent,
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
                        activeColor: Colors.purple,
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
            decoration: const InputDecoration(
              hintText: 'Add a message (optional)',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF5F6F8),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : _declineInterview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Decline'),
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
                              msg: 'Please select a time',
                              backgroundColor: Colors.orange,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff14A800),
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
                              ? 'Accept & Confirm'
                              : 'Accept Selected Time',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complete Interview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'After the interview, add your notes and feedback.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _completeInterview,
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Meeting Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _invitation.meetingNotes ?? '',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          if (_invitation.feedback != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.feedback, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Feedback',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _invitation.feedback!,
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
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
