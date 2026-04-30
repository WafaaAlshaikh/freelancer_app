// screens/workspace/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../models/calendar_event.dart';
import '../../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  List<CalendarEvent> _events = [];
  List<CalendarEvent> _upcomingEvents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);

    final events = await ApiService.getCalendarEvents(
      _currentMonth.year,
      _currentMonth.month,
    );

    final upcoming = await ApiService.getUpcomingEvents(30);

    setState(() {
      _events = events.map((e) => CalendarEvent.fromJson(e)).toList();
      _upcomingEvents = upcoming.map((e) => CalendarEvent.fromJson(e)).toList();
      _loading = false;
    });
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events
        .where(
          (e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    _loadEvents();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.calendarAndDeadlines),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm),
            onPressed: () {
              if (_events.isNotEmpty) {
                Navigator.pushNamed(
                  context,
                  '/add-reminder',
                  arguments: _events.first.contractId,
                );
              } else {
                Fluttertoast.showToast(msg: t.noActiveContractsToAddReminder);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: t.refresh,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            color: theme.colorScheme.onSurface,
                          ),
                          onPressed: _previousMonth,
                        ),
                        Text(
                          DateFormat.yMMMM().format(_currentMonth),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onSurface,
                          ),
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                  ),

                  _buildCalendarGrid(),

                  Divider(height: 32, color: theme.dividerColor),

                  _buildSelectedDayEvents(),

                  Divider(height: 32, color: theme.dividerColor),

                  _buildUpcomingEvents(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildCalendarGrid() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final startOffset = firstDayOfMonth.weekday - 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: t.weekDays.split(',').map((day) {
              return Expanded(
                child: Text(
                  day.trim(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.85,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayNumber = index - startOffset + 1;
              final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
              final date = isCurrentMonth
                  ? DateTime(_currentMonth.year, _currentMonth.month, dayNumber)
                  : null;

              final isSelected =
                  date != null &&
                  date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;

              final isToday =
                  date != null &&
                  date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              final dayEvents = date != null
                  ? _getEventsForDay(date)
                  : <CalendarEvent>[];

              return GestureDetector(
                onTap: date != null
                    ? () => setState(() => _selectedDate = date)
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary.withOpacity(0.25)
                            : isToday
                            ? AppColors.info.withOpacity(0.2)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(
                                color: AppColors.info.withOpacity(0.8),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          isCurrentMonth ? dayNumber.toString() : '',
                          style: TextStyle(
                            fontSize: 14,
                            color: isCurrentMonth
                                ? isSelected
                                      ? AppColors.secondary
                                      : theme.colorScheme.onSurface
                                : Colors.transparent,
                            fontWeight: isToday || isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 3),

                    SizedBox(
                      height: 8,
                      child: dayEvents.isNotEmpty
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: dayEvents
                                  .take(3)
                                  .map(
                                    (e) => Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: e.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayEvents() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dayEvents = _getEventsForDay(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat.yMMMd().format(_selectedDate),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (dayEvents.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${dayEvents.length} ${t.events}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (dayEvents.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.noEventsForThisDay,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: dayEvents.length,
            itemBuilder: (context, index) {
              final event = dayEvents[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: theme.cardColor,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: event.color.withOpacity(0.1),
                    child: Icon(
                      event.type == 'milestone'
                          ? Icons.flag
                          : event.type == 'reminder'
                          ? Icons.alarm
                          : Icons.event,
                      color: event.color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    event.title,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    event.projectTitle ?? '',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  trailing: Text(
                    DateFormat('HH:mm').format(event.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/contract',
                      arguments: {
                        'contractId': event.contractId,
                        'userRole': 'freelancer',
                      },
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildUpcomingEvents() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_upcomingEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            t.upcomingNext7Days,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _upcomingEvents.length > 5 ? 5 : _upcomingEvents.length,
          itemBuilder: (context, index) {
            final event = _upcomingEvents[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: event.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      event.type == 'milestone' ? Icons.flag : Icons.alarm,
                      color: event.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          event.projectTitle ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('MMM d').format(event.date),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _getDaysRemaining(event.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getDaysColor(event.date),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _getDaysRemaining(DateTime date) {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) return t?.overdue ?? 'Overdue';
    if (difference == 0) return t?.today ?? 'Today';
    if (difference == 1) return t?.tomorrow ?? 'Tomorrow';
    return t?.daysLeft(difference) ?? '$difference days left';
  }

  Color _getDaysColor(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) return AppColors.danger;
    if (difference <= 2) return AppColors.warning;
    return AppColors.success;
  }
}
