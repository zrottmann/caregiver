import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart'; // Removed GoRouter dependency
import '../../models/calendar_event.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/calendar/custom_calendar.dart';
import '../../widgets/calendar/event_list.dart';
import 'appointment_details_screen.dart';
import 'appointment_history_screen.dart';
import 'availability_management_screen.dart';
import 'book_appointment_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProfileProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            onPressed: () => _showDatePicker(context),
            icon: const Icon(Icons.today),
            tooltip: 'Go to today',
          ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_appointment',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('New Appointment'),
                  ],
                ),
              ),
              if (currentUser?.isCaregiver == true)
                const PopupMenuItem(
                  value: 'manage_availability',
                  child: Row(
                    children: [
                      Icon(Icons.schedule),
                      SizedBox(width: 8),
                      Text('Manage Availability'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'view_history',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Appointment History'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Month', icon: Icon(Icons.calendar_view_month)),
            Tab(text: 'Week', icon: Icon(Icons.calendar_view_week)),
            Tab(text: 'Day', icon: Icon(Icons.calendar_today)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonthView(),
          _buildWeekView(),
          _buildDayView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewAppointment(),
        child: const Icon(Icons.add),
        tooltip: 'New Appointment',
      ),
    );
  }

  Widget _buildMonthView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar
          CustomCalendar(
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
            onEventTap: _onEventTap,
          ),
          
          const SizedBox(height: 24),
          
          // Selected Date Events
          if (_selectedDate != null) ...[
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Events on ${_formatSelectedDate(_selectedDate!)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSelectedDateEvents(),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    final startOfWeek = _getStartOfWeek(_selectedDate ?? DateTime.now());
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    final weekEventsAsync = ref.watch(calendarEventsProvider(CalendarFilters(
      startDate: startOfWeek,
      endDate: endOfWeek,
    )));

    return weekEventsAsync.when(
      data: (events) => _buildWeekViewContent(startOfWeek, events),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 8),
            Text('Failed to load week events: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekViewContent(DateTime startOfWeek, List<CalendarEvent> events) {
    return Column(
      children: [
        // Week Navigation
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _previousWeek(),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _getWeekRangeString(startOfWeek),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _nextWeek(),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        
        // Week Grid
        Expanded(
          child: _buildWeekGrid(startOfWeek, events),
        ),
      ],
    );
  }

  Widget _buildWeekGrid(DateTime startOfWeek, List<CalendarEvent> events) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 7,
      itemBuilder: (context, index) {
        final date = startOfWeek.add(Duration(days: index));
        final dayEvents = events.where((event) => event.isOnDate(date)).toList();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isSameDay(date, DateTime.now())
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isSameDay(date, DateTime.now())
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDayName(date),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${dayEvents.length} events',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            children: [
              if (dayEvents.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: EventList(
                    events: dayEvents,
                    onEventTap: _onEventTap,
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No events scheduled'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayView() {
    final selectedDate = _selectedDate ?? DateTime.now();
    
    return Column(
      children: [
        // Day Navigation
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _previousDay(),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatSelectedDate(selectedDate),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getDayName(selectedDate),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _nextDay(),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        
        // Day Events
        Expanded(
          child: _buildSelectedDateEvents(),
        ),
      ],
    );
  }

  Widget _buildSelectedDateEvents() {
    if (_selectedDate == null) {
      return const Center(child: Text('Select a date to view events'));
    }

    final dayEventsAsync = ref.watch(dayCalendarEventsProvider(_selectedDate!));

    return dayEventsAsync.when(
      data: (events) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: EventList(
          events: events,
          onEventTap: _onEventTap,
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 8),
            Text('Failed to load events: $error'),
          ],
        ),
      ),
    );
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'create_appointment':
        _createNewAppointment();
        break;
      case 'manage_availability':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AvailabilityManagementScreen(),
          ),
        );
        break;
      case 'view_history':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AppointmentHistoryScreen(),
          ),
        );
        break;
    }
  }

  void _onEventTap(CalendarEvent event) {
    if (event.appointmentId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppointmentDetailsScreen(appointmentId: event.appointmentId!),
        ),
      );
    }
  }

  void _createNewAppointment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BookAppointmentScreen(),
      ),
    );
  }

  void _showDatePicker(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  void _previousWeek() {
    setState(() {
      _selectedDate = (_selectedDate ?? DateTime.now()).subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _selectedDate = (_selectedDate ?? DateTime.now()).add(const Duration(days: 7));
    });
  }

  void _previousDay() {
    setState(() {
      _selectedDate = (_selectedDate ?? DateTime.now()).subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = (_selectedDate ?? DateTime.now()).add(const Duration(days: 1));
    });
  }

  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  String _getWeekRangeString(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    if (startOfWeek.month == endOfWeek.month) {
      return '${_getMonthName(startOfWeek.month)} ${startOfWeek.day}-${endOfWeek.day}, ${startOfWeek.year}';
    } else {
      return '${_getMonthName(startOfWeek.month)} ${startOfWeek.day} - ${_getMonthName(endOfWeek.month)} ${endOfWeek.day}, ${startOfWeek.year}';
    }
  }

  String _formatSelectedDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}