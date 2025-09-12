import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar_event.dart';
import '../../providers/appointment_provider.dart';

class CustomCalendar extends ConsumerStatefulWidget {
  final void Function(DateTime)? onDateSelected;
  final void Function(CalendarEvent)? onEventTap;
  final bool showEvents;
  final Color? primaryColor;

  const CustomCalendar({
    super.key,
    this.onDateSelected,
    this.onEventTap,
    this.showEvents = true,
    this.primaryColor,
  });

  @override
  ConsumerState<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends ConsumerState<CustomCalendar> {
  late PageController _pageController;
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = DateTime.now();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.colorScheme.primary;
    
    final calendarEventsAsync = widget.showEvents
        ? ref.watch(monthCalendarEventsProvider(_currentMonth))
        : const AsyncValue.data(<CalendarEvent>[]);

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Calendar Header
          _buildCalendarHeader(context, primaryColor),
          
          // Weekday Headers
          _buildWeekdayHeaders(context),
          
          // Calendar Grid
          calendarEventsAsync.when(
            data: (events) => _buildCalendarGrid(context, events, primaryColor),
            loading: () => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: theme.colorScheme.error),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load calendar',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader(BuildContext context, Color primaryColor) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withAlpha((255 * 0.1).round()),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left),
            color: primaryColor,
          ),
          Expanded(
            child: Text(
              _getMonthYearString(_currentMonth),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right),
            color: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders(BuildContext context) {
    final theme = Theme.of(context);
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: weekdays.map((weekday) => Expanded(
          child: Text(
            weekday,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withAlpha((255 * 0.7).round()),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, List<CalendarEvent> events, Color primaryColor) {
    final daysInMonth = _getDaysInMonth(_currentMonth);
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;
    
    // Calculate total cells needed
    final totalCells = (daysInMonth + startingWeekday - 1);
    final rows = (totalCells / 7).ceil();
    
    return SizedBox(
      height: rows * 60.0, // 60 pixels per row
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.2,
        ),
        itemCount: rows * 7,
        itemBuilder: (context, index) {
          final dayNumber = index - startingWeekday + 2;
          
          if (dayNumber < 1 || dayNumber > daysInMonth) {
            return const SizedBox(); // Empty cell
          }
          
          final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
          final dayEvents = events.where((event) => event.isOnDate(date)).toList();
          
          return _buildDayCell(context, date, dayEvents, primaryColor);
        },
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date, List<CalendarEvent> events, Color primaryColor) {
    final theme = Theme.of(context);
    final isSelected = _selectedDate != null && _isSameDay(date, _selectedDate!);
    final isToday = _isSameDay(date, DateTime.now());
    final hasEvents = events.isNotEmpty;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        widget.onDateSelected?.call(date);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : isToday
                  ? primaryColor.withAlpha((255 * 0.2).round())
                  : null,
          borderRadius: BorderRadius.circular(8),
          border: hasEvents
              ? Border.all(color: primaryColor.withAlpha((255 * 0.5).round()), width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? primaryColor
                        : theme.colorScheme.onSurface,
              ),
            ),
            if (hasEvents && !isSelected) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < (events.length > 3 ? 3 : events.length); i++)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: _getEventColor(events[i], primaryColor),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (events.length > 3)
                    Text(
                      '+${events.length - 3}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 8,
                        color: primaryColor,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getEventColor(CalendarEvent event, Color defaultColor) {
    if (event.color != null) {
      try {
        return Color(int.parse(event.color!.replaceFirst('#', '0xFF')));
      } catch (_) {
        // If color parsing fails, use default color
      }
    }
    
    switch (event.type) {
      case EventType.appointment:
        return defaultColor;
      case EventType.availability:
        return Colors.green;
      case EventType.blocked:
        return Colors.red;
      case EventType.reminder:
        return Colors.orange;
      case EventType.holiday:
        return Colors.purple;
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}