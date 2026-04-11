import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/interview_model.dart';
import '../../services/api_service.dart';
import '../../utils/token_storage.dart';
import 'interview_detail_screen.dart';

class InterviewCalendarScreen extends StatefulWidget {
  const InterviewCalendarScreen({super.key});

  @override
  State<InterviewCalendarScreen> createState() =>
      _InterviewCalendarScreenState();
}

class _InterviewCalendarScreenState extends State<InterviewCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<InterviewInvitation>> _events = {};
  List<InterviewInvitation> _allInterviews = [];
  bool _loading = true;
  String? _userRole;
  String _viewMode = 'month';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadUserRole();
    _loadInterviews();
  }

  Future<void> _loadUserRole() async {
    final role = await TokenStorage.getUserRole();
    setState(() => _userRole = role);
  }

  Future<void> _loadInterviews() async {
    setState(() => _loading = true);

    try {
      final response = await ApiService.getUserInterviews();
      print('📥 Raw interviews response: ${response['invitations']?.length}');

      final allInterviews =
          (response['invitations'] as List?)
              ?.map((j) => InterviewInvitation.fromJson(j))
              .where((i) => i.isAccepted && i.selectedTime != null)
              .toList() ??
          [];

      print('📊 Found ${allInterviews.length} accepted interviews with times');

      final events = <DateTime, List<InterviewInvitation>>{};

      for (final interview in allInterviews) {
        final selectedTime = interview.selectedTime!.toUtc();

        final date = DateTime(
          selectedTime.year,
          selectedTime.month,
          selectedTime.day,
        );

        print('📅 Adding interview on: $date');

        if (!events.containsKey(date)) {
          events[date] = [];
        }
        events[date]!.add(interview);
      }

      setState(() {
        _allInterviews = allInterviews;
        _events = events;
        _loading = false;
      });

      print('✅ Events map has ${events.keys.length} unique dates');
    } catch (e) {
      print('❌ Error loading interviews: $e');
      setState(() => _loading = false);
    }
  }

  List<InterviewInvitation> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);

    print('🔍 Looking for events on: $normalizedDay');
    print(
      '📅 Available dates: ${_events.keys.map((d) => d.toString()).toList()}',
    );

    final events = _events[normalizedDay] ?? [];
    print('📊 Found ${events.length} events on this day');

    return events;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Interview Calendar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          ToggleButtons(
            isSelected: [
              _viewMode == 'month',
              _viewMode == 'week',
              _viewMode == 'list',
            ],
            onPressed: (index) {
              setState(() {
                switch (index) {
                  case 0:
                    _viewMode = 'month';
                    break;
                  case 1:
                    _viewMode = 'week';
                    break;
                  case 2:
                    _viewMode = 'list';
                    break;
                }
              });
            },
            children: const [
              Icon(Icons.calendar_month),
              Icon(Icons.view_week),
              Icon(Icons.list),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInterviews,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: _viewMode != 'list'
          ? FloatingActionButton.extended(
              onPressed: () {
                // إضافة مقابلة يدوياً (اختياري)
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Interview'),
              backgroundColor: Colors.purple,
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_viewMode) {
      case 'week':
        return _buildWeekView();
      case 'list':
        return _buildListView();
      default:
        return _buildMonthView();
    }
  }

  Widget _buildMonthView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 30)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: _onDaySelected,
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            markersAlignment: Alignment.bottomCenter,
            markerSize: 6,
            weekendTextStyle: const TextStyle(color: Colors.red),
            todayDecoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
            defaultDecoration: BoxDecoration(shape: BoxShape.circle),
          ),
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: true,
            formatButtonShowsNext: false,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildSelectedDayEvents()),
      ],
    );
  }

  Widget _buildSelectedDayEvents() {
    if (_selectedDay == null) {
      return const Center(child: Text('Select a day to view interviews'));
    }

    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No interviews scheduled for this day',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final interview = events[index];
        return _buildInterviewCard(interview);
      },
    );
  }

  Widget _buildWeekView() {
    final weekDays = _getWeekDays(_focusedDay);
    final now = DateTime.now();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) {
              final isToday = isSameDay(day, now);
              final hasEvents = _getEventsForDay(day).isNotEmpty;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onDaySelected(day, _focusedDay),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEE').format(day),
                        style: TextStyle(
                          fontSize: 12,
                          color: isToday ? Colors.purple : Colors.grey,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isToday
                              ? Colors.purple
                              : isSameDay(day, _selectedDay)
                              ? Colors.purple.withOpacity(0.2)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(
                              color: isToday
                                  ? Colors.white
                                  : isSameDay(day, _selectedDay)
                                  ? Colors.purple
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (hasEvents)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildSelectedDayEvents()),
      ],
    );
  }

  Widget _buildListView() {
    final groupedInterviews = <String, List<InterviewInvitation>>{};

    for (final interview in _allInterviews) {
      final monthYear = DateFormat('MMMM yyyy').format(interview.selectedTime!);
      if (!groupedInterviews.containsKey(monthYear)) {
        groupedInterviews[monthYear] = [];
      }
      groupedInterviews[monthYear]!.add(interview);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedInterviews.keys.length,
      itemBuilder: (context, index) {
        final month = groupedInterviews.keys.elementAt(index);
        final interviews = groupedInterviews[month]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                month,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...interviews.map(
              (interview) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildInterviewCard(interview),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildInterviewCard(InterviewInvitation interview) {
    final project = interview.project;
    final otherParty = _userRole == 'client'
        ? interview.freelancer
        : interview.client;
    final isToday = isSameDay(interview.selectedTime!, DateTime.now());
    final isPast = interview.selectedTime!.isBefore(DateTime.now());

    return Container(
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
        border: isToday ? Border.all(color: Colors.purple, width: 2) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InterviewDetailScreen(invitation: interview),
              ),
            ).then((_) => _loadInterviews());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.grey.shade100
                        : Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('HH:mm').format(interview.selectedTime!),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isPast ? Colors.grey : Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd/MM').format(interview.selectedTime!),
                        style: TextStyle(
                          fontSize: 10,
                          color: isPast ? Colors.grey : Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project?.title ?? 'Project',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            otherParty?.name ?? 'User',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.video_call,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              interview.meetingLink ?? 'No link',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                    color: isPast
                        ? Colors.grey.shade100
                        : isToday
                        ? Colors.purple.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPast
                        ? 'Past'
                        : isToday
                        ? 'Today'
                        : 'Upcoming',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPast
                          ? Colors.grey
                          : isToday
                          ? Colors.purple
                          : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<DateTime> _getWeekDays(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
