import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/interview_model.dart';
import '../../services/api_service.dart';
import '../../utils/token_storage.dart';
import '../../theme/app_theme.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserRole();
        _loadInterviews(context);
      }
    });
  }

  Future<void> _loadUserRole() async {
    final role = await TokenStorage.getUserRole();
    if (mounted) setState(() => _userRole = role);
  }

  Future<void> _loadInterviews(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final response = await ApiService.getUserInterviews();

      final allInterviews =
          (response['invitations'] as List?)
              ?.map((j) => InterviewInvitation.fromJson(j))
              .where((i) => i.isAccepted && i.selectedTime != null)
              .toList() ??
          [];

      final events = <DateTime, List<InterviewInvitation>>{};

      for (final interview in allInterviews) {
        final selectedTime = interview.selectedTime!.toUtc();

        final date = DateTime(
          selectedTime.year,
          selectedTime.month,
          selectedTime.day,
        );

        if (!events.containsKey(date)) {
          events[date] = [];
        }
        events[date]!.add(interview);
      }

      if (!mounted) return;

      setState(() {
        _allInterviews = allInterviews;
        _events = events;
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading interviews: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<InterviewInvitation> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<DateTime> _getWeekDays(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.interviewCalendar,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          ToggleButtons(
            isSelected: [
              _viewMode == 'month',
              _viewMode == 'week',
              _viewMode == 'list',
            ],
            color: theme.iconTheme.color,
            selectedColor: theme.colorScheme.primary,
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
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
            onPressed: () => _loadInterviews(context),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _buildBody(),
      floatingActionButton: _viewMode != 'list'
          ? FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: Text(t.addInterview),
              backgroundColor: Colors.purple,
            )
          : null,
    );
  }

  Widget _buildInterviewCard(InterviewInvitation interview) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final project = interview.project;
    final otherParty = _userRole == 'client'
        ? interview.freelancer
        : interview.client;
    final isToday = isSameDay(interview.selectedTime!, DateTime.now());
    final isPast = interview.selectedTime!.isBefore(DateTime.now());

    return Container(
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
        border: isToday
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
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
            ).then((_) => _loadInterviews(context));
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
                        ? (isDark
                              ? AppColors.darkSurface
                              : Colors.grey.shade100)
                        : theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('HH:mm').format(interview.selectedTime!),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isPast
                              ? (isDark ? Colors.grey.shade500 : Colors.grey)
                              : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd/MM').format(interview.selectedTime!),
                        style: TextStyle(
                          fontSize: 10,
                          color: isPast
                              ? (isDark ? Colors.grey.shade500 : Colors.grey)
                              : theme.colorScheme.primary,
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
                        project?.title ?? t.project,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
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
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            otherParty?.name ?? t.user,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
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
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              interview.meetingLink ?? t.noLink,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
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
                        ? (isDark
                              ? AppColors.darkSurface
                              : Colors.grey.shade100)
                        : isToday
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPast
                        ? t.past
                        : isToday
                        ? t.today
                        : t.upcoming,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPast
                          ? (isDark ? Colors.grey.shade500 : Colors.grey)
                          : isToday
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            markerDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            weekendTextStyle: const TextStyle(color: Colors.red),
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            defaultDecoration: BoxDecoration(shape: BoxShape.circle),
            defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
            weekendDecoration: BoxDecoration(shape: BoxShape.circle),
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: true,
            formatButtonShowsNext: false,
            titleTextStyle: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            formatButtonTextStyle: TextStyle(color: theme.colorScheme.primary),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: theme.colorScheme.onSurface),
            weekendStyle: const TextStyle(color: Colors.red),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildSelectedDayEvents()),
      ],
    );
  }

  Widget _buildSelectedDayEvents() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_selectedDay == null) {
      return Center(
        child: Text(
          t.selectDayToViewInterviews,
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
      );
    }

    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              t.noInterviewsScheduledForThisDay,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weekDays = _getWeekDays(_focusedDay);
    final now = DateTime.now();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
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
                          color: isToday
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.6),
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
                              ? theme.colorScheme.primary
                              : isSameDay(day, _selectedDay)
                              ? theme.colorScheme.primary.withOpacity(0.2)
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
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
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
                            color: theme.colorScheme.primary,
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
                color: theme.colorScheme.primary,
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
}
