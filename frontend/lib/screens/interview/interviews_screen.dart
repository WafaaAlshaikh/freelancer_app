import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/interview_model.dart';
import '../../services/api_service.dart';
import '../../utils/token_storage.dart';
import '../../theme/app_theme.dart';
import 'interview_calendar_screen.dart';
import 'interview_detail_screen.dart';
import 'interview_stats_screen.dart';

class InterviewsScreen extends StatefulWidget {
  const InterviewsScreen({super.key});

  @override
  State<InterviewsScreen> createState() => _InterviewsScreenState();
}

class _InterviewsScreenState extends State<InterviewsScreen>
    with SingleTickerProviderStateMixin {
  List<InterviewInvitation> _invitations = [];
  InterviewStats? _stats;
  bool _loading = true;
  String _selectedStatus = 'all';
  String? _userRole;

  List<Map<String, dynamic>> get _statusFilters {
    final t = AppLocalizations.of(context);
    return [
      {
        'value': 'all',
        'label': t?.all ?? 'All',
        'icon': Icons.list,
        'color': AppColors.gray,
      },
      {
        'value': 'pending',
        'label': t?.pending ?? 'Pending',
        'icon': Icons.access_time,
        'color': AppColors.warning,
      },
      {
        'value': 'accepted',
        'label': t?.accepted ?? 'Accepted',
        'icon': Icons.check_circle,
        'color': AppColors.success,
      },
      {
        'value': 'completed',
        'label': t?.completed ?? 'Completed',
        'icon': Icons.verified,
        'color': AppColors.info,
      },
      {
        'value': 'declined',
        'label': t?.declined ?? 'Declined',
        'icon': Icons.cancel,
        'color': AppColors.danger,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserRole();
        _loadData(context);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final role = await TokenStorage.getUserRole();
    if (mounted) setState(() => _userRole = role);
  }

  Future<void> _loadData(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final interviewsRes = await ApiService.getUserInterviews(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );

      final stats = await ApiService.getInterviewStats();

      if (!mounted) return;

      setState(() {
        if (interviewsRes['success'] == true &&
            interviewsRes['invitations'] != null) {
          _invitations = (interviewsRes['invitations'] as List)
              .map(
                (j) => InterviewInvitation.fromJson(j as Map<String, dynamic>),
              )
              .toList();
        } else {
          _invitations = [];
        }

        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      print('Error loading interviews: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _invitations = [];
        _stats = InterviewStats();
      });
      Fluttertoast.showToast(msg: '${t.errorLoadingInterviews}: $e');
    }
  }

  Future<void> _refresh() async {
    await _loadData(context);
  }

  void _navigateToDetail(InterviewInvitation invitation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterviewDetailScreen(invitation: invitation),
      ),
    );
    if (result == true) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isClient = _userRole == 'client';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: t.back,
        ),
        title: Text(
          t.interviews,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.analytics, color: theme.iconTheme.color),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InterviewStatsScreen()),
              );
            },
            tooltip: t.statistics,
          ),
          IconButton(
            icon: Icon(Icons.calendar_month, color: theme.iconTheme.color),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InterviewCalendarScreen(),
                ),
              );
            },
            tooltip: t.calendar,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_stats != null)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _statusFilters.length,
                itemBuilder: (context, index) {
                  final filter = _statusFilters[index];
                  final isSelected = _selectedStatus == filter['value'];
                  final color = filter['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter['label'] as String),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedStatus = filter['value'] as String;
                          _loadData(context);
                        });
                      },
                      avatar: Icon(
                        filter['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : color,
                      ),
                      backgroundColor: isSelected
                          ? color
                          : (isDark
                                ? AppColors.darkSurface
                                : Colors.grey.shade100),
                      selectedColor: color,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: isSelected
                          ? BorderSide.none
                          : BorderSide(color: color.withOpacity(0.3), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: isSelected ? 2 : 0,
                      shadowColor: color.withOpacity(0.3),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 4),

          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _invitations.isEmpty
                ? _buildEmptyState(isClient)
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: theme.colorScheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _invitations.length,
                      itemBuilder: (context, index) {
                        final invitation = _invitations[index];
                        return _buildInterviewCard(invitation);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              shadows: [Shadow(color: color.withOpacity(0.3), blurRadius: 2)],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isClient) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.interpreter_mode,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isClient
                ? t.noInterviewInvitationsSent
                : t.noInterviewInvitationsReceived,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isClient
                ? t.inviteFreelancersToInterview
                : t.interviewsWillAppearHere,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          if (isClient)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/client/projects'),
                icon: const Icon(Icons.work),
                label: Text(t.browseYourProjects),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInterviewCard(InterviewInvitation invitation) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final project = invitation.project;
    final otherParty = _userRole == 'client'
        ? invitation.freelancer
        : invitation.client;
    final isExpired = invitation.isExpiredByDate;
    final statusColor = isExpired ? AppColors.gray : invitation.statusColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isDark ? 1 : 2,
      child: InkWell(
        onTap: () => _navigateToDetail(invitation),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      invitation.statusIcon,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project?.title ?? t.project,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${t.with_} ${otherParty?.name ?? t.user}',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isExpired ? t.expired : invitation.statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (invitation.message != null && invitation.message!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            invitation.message!,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    invitation.isAccepted && invitation.selectedTime != null
                        ? '${t.scheduled}: ${invitation.formattedSelectedTime}'
                        : '${t.expires}: ${invitation.formattedExpiryDate}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              if (invitation.isAccepted && invitation.meetingLink != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.video_call, size: 14, color: AppColors.info),
                      const SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final url = Uri.parse(invitation.meetingLink!);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: Text(
                            t.joinMeeting,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.info,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
