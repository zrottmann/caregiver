import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  BookingStatus? _selectedStatus;
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      await ref.read(bookingProvider.notifier).loadUserBookings(currentUser.$id);
      await ref.read(bookingProvider.notifier).loadBookingStats(currentUser.$id);
    }
  }

  Future<void> _searchBookings() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      await ref.read(bookingProvider.notifier).searchBookings(
        currentUser.$id,
        query: _searchQuery.isEmpty ? null : _searchQuery,
        status: _selectedStatus,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Filter Bookings'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedStatus == null,
                      onSelected: (selected) {
                        setStateDialog(() {
                          _selectedStatus = null;
                        });
                      },
                    ),
                    ...BookingStatus.values.map((status) => FilterChip(
                          label: Text(status.name.toUpperCase()),
                          selected: _selectedStatus == status,
                          onSelected: (selected) {
                            setStateDialog(() {
                              _selectedStatus = selected ? status : null;
                            });
                          },
                        )).toList(),
                  ],
                ),
                
                const SizedBox(height: 16),

                // Date Range Filter
                Text(
                  'Date Range',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                
                OutlinedButton.icon(
                  onPressed: () async {
                    final DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: _selectedDateRange,
                    );
                    if (picked != null) {
                      setStateDialog(() {
                        _selectedDateRange = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Select Date Range'
                        : '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}',
                  ),
                ),
                
                if (_selectedDateRange != null)
                  TextButton(
                    onPressed: () {
                      setStateDialog(() {
                        _selectedDateRange = null;
                      });
                    },
                    child: const Text('Clear Date Range'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {}); // Trigger rebuild with new filters
                _searchBookings();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedDateRange = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadBookings();
  }

  List<Booking> _getFilteredBookings(List<Booking> bookings, BookingStatus? statusFilter) {
    var filtered = bookings;
    
    // Apply status filter
    if (statusFilter != null) {
      filtered = filtered.where((booking) => booking.status == statusFilter).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((booking) {
        return booking.caregiverName.toLowerCase().contains(query) ||
               booking.description.toLowerCase().contains(query) ||
               booking.services.any((service) => service.toLowerCase().contains(query));
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final bookingStats = bookingState.bookingStats;
    final allBookings = bookingState.bookings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.list),
              text: 'All (${bookingStats['total'] ?? 0})',
            ),
            Tab(
              icon: const Icon(Icons.schedule),
              text: 'Pending (${bookingStats['pending'] ?? 0})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle),
              text: 'Confirmed (${bookingStats['confirmed'] ?? 0})',
            ),
            Tab(
              icon: const Icon(Icons.done_all),
              text: 'Completed (${bookingStats['completed'] ?? 0})',
            ),
          ],
          isScrollable: true,
        ),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: Badge(
              isLabelVisible: _selectedStatus != null || _selectedDateRange != null,
              child: const Icon(Icons.filter_list),
            ),
          ),
          IconButton(
            onPressed: _loadBookings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search bookings...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      if (value.isEmpty) {
                        _loadBookings();
                      }
                    },
                    onSubmitted: (value) {
                      _searchBookings();
                    },
                  ),
                ),
                if (_selectedStatus != null || _selectedDateRange != null || _searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear Filters',
                  ),
                ],
              ],
            ),
          ),

          // Active Filters Display
          if (_selectedStatus != null || _selectedDateRange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Filters: ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  if (_selectedStatus != null) ...[
                    Chip(
                      label: Text(_selectedStatus!.name.toUpperCase()),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedStatus = null;
                        });
                        _searchBookings();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (_selectedDateRange != null) ...[
                    Chip(
                      label: Text(
                        '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}',
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                        _searchBookings();
                      },
                    ),
                  ],
                ],
              ),
            ),

          // Booking List
          Expanded(
            child: bookingState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : bookingState.error != null
                    ? _buildErrorState(bookingState.error!)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildBookingList(_getFilteredBookings(allBookings, null)),
                          _buildBookingList(_getFilteredBookings(allBookings, BookingStatus.pending)),
                          _buildBookingList(_getFilteredBookings(allBookings, BookingStatus.confirmed)),
                          _buildBookingList(_getFilteredBookings(allBookings, BookingStatus.completed)),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load bookings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBookings,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking);
        },
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No bookings found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your booking history will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.add),
            label: const Text('Book a Caregiver'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          context.push('/booking-details/${booking.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.caregiverName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'ID: ${booking.id.substring(0, 8).toUpperCase()}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(booking.status),
                ],
              ),

              const SizedBox(height: 12),

              // Date and Time
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(booking.scheduledDate),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.timeSlot,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Services
              if (booking.services.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: booking.services.take(3).map((service) {
                    return Chip(
                      label: Text(
                        service,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer.withAlpha((255 * 0.3).round()),
                    );
                  }).toList()
                    ..addAll(booking.services.length > 3 
                        ? [
                            Chip(
                              label: Text(
                                '+${booking.services.length - 3} more',
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Colors.grey[200],
                            ),
                          ] 
                        : []),
                ),
                const SizedBox(height: 8),
              ],

              // Bottom Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${booking.totalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  Row(
                    children: [
                      if (booking.status == BookingStatus.confirmed)
                        IconButton(
                          onPressed: () {
                            context.push('/chat/booking-${booking.id}');
                          },
                          icon: const Icon(Icons.message, size: 20),
                          tooltip: 'Message Caregiver',
                        ),
                      IconButton(
                        onPressed: () {
                          context.push('/booking-details/${booking.id}');
                        },
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case BookingStatus.confirmed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case BookingStatus.completed:
        color = Colors.blue;
        icon = Icons.done_all;
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((255 * 0.3).round())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}