import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelancer_platform/screens/interview/interview_calendar_screen.dart';
import 'package:freelancer_platform/screens/interview/interview_stats_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/interview_model.dart';
import '../../services/api_service.dart';
import '../../utils/token_storage.dart';
import 'interview_detail_screen.dart';

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
  late TabController _tabController;

  final List<Map<String, dynamic>> _statusFilters = [
    {'value': 'all', 'label': 'All', 'icon': Icons.list},
    {
      'value': 'pending',
      'label': 'Pending',
      'icon': Icons.access_time,
      'color': Colors.orange,
    },
    {
      'value': 'accepted',
      'label': 'Accepted',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'value': 'completed',
      'label': 'Completed',
      'icon': Icons.verified,
      'color': Colors.blue,
    },
    {
      'value': 'declined',
      'label': 'Declined',
      'icon': Icons.cancel,
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserRole();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final role = await TokenStorage.getUserRole();
    setState(() => _userRole = role);
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final interviewsRes = await ApiService.getUserInterviews(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );

      final stats = await ApiService.getInterviewStats();

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
      setState(() {
        _loading = false;
        _invitations = [];
        _stats = InterviewStats();
      });
      Fluttertoast.showToast(msg: 'Error loading interviews: $e');
    }
  }

  Future<void> _refresh() async {
    await _loadData();
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
    final isClient = _userRole == 'client';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Interviews',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InterviewStatsScreen()),
              );
            },
            tooltip: 'Statistics',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InterviewCalendarScreen(),
                ),
              );
            },
            tooltip: 'Calendar',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              if (_stats != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatChip('Total', _stats!.total, Colors.grey),
                      _buildStatChip('Pending', _stats!.pending, Colors.orange),
                      _buildStatChip(
                        'Accepted',
                        _stats!.accepted,
                        Colors.green,
                      ),
                      _buildStatChip(
                        'Completed',
                        _stats!.completed,
                        Colors.blue,
                      ),
                    ],
                  ),
                ),
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _statusFilters.length,
                  itemBuilder: (context, index) {
                    final filter = _statusFilters[index];
                    final isSelected = _selectedStatus == filter['value'];
                    final color = filter['color'] as Color?;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter['label'] as String),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedStatus = filter['value'] as String;
                            _loadData();
                          });
                        },
                        avatar: Icon(
                          filter['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.black : color,
                        ),
                        backgroundColor: Colors.grey.shade100,
                        selectedColor: color ?? Colors.blue,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomOpacity: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _invitations.isEmpty
          ? _buildEmptyState(isClient)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _invitations.length,
                itemBuilder: (context, index) {
                  final invitation = _invitations[index];
                  return _buildInterviewCard(invitation);
                },
              ),
            ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isClient) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.interpreter_mode, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            isClient
                ? 'No interview invitations sent'
                : 'No interview invitations received',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isClient
                ? 'Invite freelancers to interview before hiring'
                : 'When clients invite you for interviews, they will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          if (isClient)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/client/projects');
                },
                icon: const Icon(Icons.work),
                label: const Text('Browse Your Projects'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff14A800),
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
    final project = invitation.project;
    final otherParty = _userRole == 'client'
        ? invitation.freelancer
        : invitation.client;
    final isExpired = invitation.isExpiredByDate;
    final statusColor = isExpired ? Colors.grey : invitation.statusColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          project?.title ?? 'Project',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'with ${otherParty?.name ?? 'User'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
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
                      isExpired ? 'Expired' : invitation.statusText,
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
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            invitation.message!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
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
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    invitation.isAccepted && invitation.selectedTime != null
                        ? 'Scheduled: ${invitation.formattedSelectedTime}'
                        : 'Expires: ${invitation.formattedExpiryDate}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (invitation.isAccepted && invitation.meetingLink != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.video_call, size: 14, color: Colors.blue),
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
                            'Join Meeting',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
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
