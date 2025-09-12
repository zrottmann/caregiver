import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';

class AppointmentHistoryScreen extends ConsumerStatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  ConsumerState<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends ConsumerState<AppointmentHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;
  List<AppointmentStatus> _selectedStatuses = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment History'),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
          ),
          IconButton(
            onPressed: _exportHistory,
            icon: const Icon(Icons.download),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search appointments...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filter Chips
          if (_hasActiveFilters) ...[
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_selectedDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          '${_formatShortDate(_selectedDateRange!.start)} - ${_formatShortDate(_selectedDateRange!.end)}',
                        ),
                        selected: false,
                        onSelected: (bool value) {},
                        onDeleted: () {
                          setState(() {
                            _selectedDateRange = null;
                          });
                        },
                      ),
                    ),
                  ..._selectedStatuses.map((status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status.name.toUpperCase()),
                          selected: false,
                          onSelected: (bool value) {},
                          onDeleted: () {
                            setState(() {
                              _selectedStatuses.remove(status);
                            });
                          },
                        ),
                      )),
                ],
              ),
            ),
          ],

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentList(null),
                _buildAppointmentList([AppointmentStatus.scheduled, AppointmentStatus.confirmed]),
                _buildAppointmentList([AppointmentStatus.completed]),
                _buildAppointmentList([AppointmentStatus.cancelled]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(List<AppointmentStatus>? defaultStatuses) {
    final currentUser = ref.watch(currentUserProfileProvider);
    if (currentUser == null) {
      return const Center(child: Text('Please log in to view appointments'));
    }

    final statuses = _selectedStatuses.isEmpty ? defaultStatuses : _selectedStatuses;

    final appointmentsAsync = ref.watch(appointmentsProvider(AppointmentFilters(
      userId: currentUser.id,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
      statuses: statuses,
    )));

    return appointmentsAsync.when(
      data: (appointments) {
        var filteredAppointments = appointments;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          filteredAppointments = appointments.where((appointment) {
            final query = _searchQuery.toLowerCase();
            return appointment.caregiverName.toLowerCase().contains(query) ||
                   appointment.patientName.toLowerCase().contains(query) ||
                   appointment.services.any((service) => 
                     service.toLowerCase().contains(query)) ||
                   (appointment.description?.toLowerCase().contains(query) ?? false);
          }).toList();
        }

        if (filteredAppointments.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(appointmentsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredAppointments.length,
            itemBuilder: (context, index) {
              final appointment = filteredAppointments[index];
              return _buildAppointmentCard(appointment);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(error),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(appointment.status);
    final isUpcoming = appointment.startTime.isAfter(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/appointment-details/${appointment.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha((255 * 0.1).round()),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withAlpha((255 * 0.3).round())),
                    ),
                    child: Text(
                      appointment.statusText.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(appointment.startTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Participants
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.caregiverName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Time and Services
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appointment.timeSlot,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.medical_services,
                    size: 16,
                    color: theme.colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.services.join(', '),
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Cost and Actions
              Row(
                children: [
                  if (appointment.totalAmount != null) ...[
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\$${appointment.totalAmount!.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (isUpcoming && appointment.canReschedule) ...[
                    TextButton.icon(
                      onPressed: () => _rescheduleAppointment(appointment),
                      icon: const Icon(Icons.schedule, size: 16),
                      label: const Text('Reschedule'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                  PopupMenuButton<String>(
                    onSelected: (value) => _onMenuSelected(value, appointment),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info, size: 16),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      if (appointment.canCancel)
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Cancel', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 16),
                            SizedBox(width: 8),
                            Text('Share'),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.5).round()),
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.7).round()),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/book-appointment'),
            icon: const Icon(Icons.add),
            label: const Text('Book New Appointment'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load appointments',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(appointmentsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Appointments'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range Filter
                Text(
                  'Date Range',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final dateRange = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDateRange: _selectedDateRange,
                          );
                          if (dateRange != null) {
                            setDialogState(() {
                              _selectedDateRange = dateRange;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _selectedDateRange != null
                              ? '${_formatShortDate(_selectedDateRange!.start)} - ${_formatShortDate(_selectedDateRange!.end)}'
                              : 'Select Range',
                        ),
                      ),
                    ),
                    if (_selectedDateRange != null)
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            _selectedDateRange = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Status Filter
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: AppointmentStatus.values.map((status) {
                    final isSelected = _selectedStatuses.contains(status);
                    return FilterChip(
                      label: Text(status.name.toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            _selectedStatuses.add(status);
                          } else {
                            _selectedStatuses.remove(status);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _selectedDateRange = null;
                  _selectedStatuses.clear();
                });
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Apply filters
                });
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _exportHistory() {
    // In a real app, you would implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality not implemented yet'),
      ),
    );
  }

  void _rescheduleAppointment(Appointment appointment) {
    context.push('/appointment-details/${appointment.id}');
  }

  void _onMenuSelected(String value, Appointment appointment) {
    switch (value) {
      case 'details':
        context.push('/appointment-details/${appointment.id}');
        break;
      case 'cancel':
        _showCancelDialog(appointment);
        break;
      case 'share':
        _shareAppointment(appointment);
        break;
    }
  }

  void _showCancelDialog(Appointment appointment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cancel appointment with ${appointment.caregiverName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelAppointment(appointment, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _cancelAppointment(Appointment appointment, String reason) async {
    try {
      await ref.read(appointmentNotifierProvider.notifier).cancelAppointment(
        appointment.id,
        reason.isEmpty ? 'No reason provided' : reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel appointment: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareAppointment(Appointment appointment) {
    // In a real app, you would implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality not implemented yet'),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.inProgress:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  bool get _hasActiveFilters => _selectedDateRange != null || _selectedStatuses.isNotEmpty;
}