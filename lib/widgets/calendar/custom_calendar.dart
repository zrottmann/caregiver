import 'package:flutter/material.dart';

class CustomCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime)? onDateSelected;
  final List<DateTime>? availableDates;
  final List<DateTime>? blockedDates;

  const CustomCalendar({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.availableDates,
    this.blockedDates,
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month/Year header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _navigateMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                _getMonthYearText(_currentMonth),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: () => _navigateMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        // Calendar grid
        Expanded(
          child: _buildCalendarGrid(),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Day headers
        ..._buildDayHeaders(),
        // Calendar days
        ..._buildCalendarDays(),
      ],
    );
  }

  List<Widget> _buildDayHeaders() {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return dayNames.map((day) => Center(
      child: Text(
        day,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    )).toList();
  }

  List<Widget> _buildCalendarDays() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startOfCalendar = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));

    final calendarDays = <Widget>[];

    for (int i = 0; i < 42; i++) { // 6 weeks × 7 days
      final date = startOfCalendar.add(Duration(days: i));
      final isCurrentMonth = date.month == _currentMonth.month;
      final isSelected = _selectedDate != null &&
          date.year == _selectedDate!.year &&
          date.month == _selectedDate!.month &&
          date.day == _selectedDate!.day;
      final isToday = _isToday(date);
      final isAvailable = _isDateAvailable(date);
      final isBlocked = _isDateBlocked(date);

      calendarDays.add(
        GestureDetector(
          onTap: isCurrentMonth && isAvailable && !isBlocked ? () => _selectDate(date) : null,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : isToday
                      ? Theme.of(context).primaryColor.withOpacity(0.3)
                      : null,
              border: isToday && !isSelected
                  ? Border.all(color: Theme.of(context).primaryColor)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: !isCurrentMonth
                      ? Colors.grey.withOpacity(0.5)
                      : isSelected
                          ? Colors.white
                          : isBlocked
                              ? Colors.red
                              : isAvailable
                                  ? Colors.green
                                  : null,
                  fontWeight: isToday || isSelected ? FontWeight.bold : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return calendarDays;
  }

  void _navigateMonth(int direction) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + direction,
      );
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDateSelected?.call(date);
  }

  String _getMonthYearText(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
           date.month == today.month &&
           date.day == today.day;
  }

  bool _isDateAvailable(DateTime date) {
    if (widget.availableDates == null) return true;
    return widget.availableDates!.any((availableDate) =>
        date.year == availableDate.year &&
        date.month == availableDate.month &&
        date.day == availableDate.day);
  }

  bool _isDateBlocked(DateTime date) {
    if (widget.blockedDates == null) return false;
    return widget.blockedDates!.any((blockedDate) =>
        date.year == blockedDate.year &&
        date.month == blockedDate.month &&
        date.day == blockedDate.day);
  }
}