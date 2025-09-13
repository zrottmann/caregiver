import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar_event.dart';

class EventList extends ConsumerWidget {
  final List<CalendarEvent> events;
  final void Function(CalendarEvent)? onEventTap;
  final bool showDate;

  const EventList({
    super.key,
    required this.events,
    this.onEventTap,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No events scheduled',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final event = events[index];
        return EventListItem(
          event: event,
          onTap: onEventTap,
          showDate: showDate,
        );
      },
    );
  }
}

class EventListItem extends StatelessWidget {
  final CalendarEvent event;
  final void Function(CalendarEvent)? onTap;
  final bool showDate;

  const EventListItem({
    super.key,
    required this.event,
    this.onTap,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildEventIcon(context),
        title: Text(
          event.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description != null) ...[
              Text(event.description!),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: theme.colorScheme.onSurface.withAlpha((255 * 0.6).round())),
                const SizedBox(width: 4),
                Text(
                  event.timeRange,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha((255 * 0.8).round()),
                  ),
                ),
                if (showDate) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurface.withAlpha((255 * 0.6).round())),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(event.startTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha((255 * 0.8).round()),
                    ),
                  ),
                ],
              ],
            ),
            if (event.metadata != null && event.metadata!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildEventMetadata(context),
            ],
          ],
        ),
        trailing: _buildEventTrailing(context),
        onTap: onTap != null ? () => onTap!(event) : null,
      ),
    );
  }

  Widget _buildEventIcon(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getEventColor(context);
    
    IconData icon;
    switch (event.type) {
      case EventType.appointment:
        icon = Icons.medical_services;
        break;
      case EventType.availability:
        icon = Icons.schedule;
        break;
      case EventType.blocked:
        icon = Icons.block;
        break;
      case EventType.reminder:
        icon = Icons.notification_important;
        break;
      case EventType.holiday:
        icon = Icons.celebration;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildEventTrailing(BuildContext context) {
    final theme = Theme.of(context);
    
    if (event.priority == EventPriority.urgent) {
      return Icon(
        Icons.priority_high,
        color: theme.colorScheme.error,
      );
    }
    
    if (event.isAppointment && event.metadata != null) {
      final status = event.metadata!['status'] as String?;
      if (status != null) {
        return _buildStatusChip(context, status);
      }
    }
    
    return const Icon(Icons.chevron_right);
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    switch (status) {
      case 'scheduled':
        color = Colors.orange;
        break;
      case 'confirmed':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((255 * 0.3).round())),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEventMetadata(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = event.metadata!;
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (metadata['patientName'] != null)
          Chip(
            avatar: const Icon(Icons.person, size: 16),
            label: Text(metadata['patientName']),
            labelStyle: theme.textTheme.bodySmall,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        if (metadata['caregiverName'] != null)
          Chip(
            avatar: const Icon(Icons.medical_services, size: 16),
            label: Text(metadata['caregiverName']),
            labelStyle: theme.textTheme.bodySmall,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        if (metadata['totalAmount'] != null)
          Chip(
            avatar: const Icon(Icons.attach_money, size: 16),
            label: Text('\$${metadata['totalAmount']}'),
            labelStyle: theme.textTheme.bodySmall,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  Color _getEventColor(BuildContext context) {
    final theme = Theme.of(context);
    
    if (event.color != null) {
      try {
        return Color(int.parse(event.color!.replaceFirst('#', '0xFF')));
      } catch (_) {
        // If color parsing fails, use default color
      }
    }
    
    switch (event.type) {
      case EventType.appointment:
        return theme.colorScheme.primary;
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}';
  }
}