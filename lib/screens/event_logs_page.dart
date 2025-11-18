import 'package:flutter/material.dart';
import 'package:expensetracker_reloaded/services/event_logger_service.dart';

/// Event logs page - shows all application events and activity
class EventLogsPage extends StatefulWidget {
  const EventLogsPage({super.key});

  @override
  State<EventLogsPage> createState() => _EventLogsPageState();
}

class _EventLogsPageState extends State<EventLogsPage> {
  late Future<List<AppEvent>> _eventsFuture;
  late Future<Map<String, dynamic>> _statsFuture;
  EventType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _eventsFuture = _selectedFilter == null
        ? EventLoggerService.getAllEvents()
        : EventLoggerService.getEventsByType(_selectedFilter!);
    _statsFuture = EventLoggerService.getStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Event Logs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear') {
                _showClearConfirmation();
              } else if (value == 'export') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon')),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'export',
                child: Text('Export Logs'),
              ),
              const PopupMenuItem<String>(
                value: 'clear',
                child: Text('Clear All Logs'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats card
          FutureBuilder<Map<String, dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final stats = snapshot.data!;
              return _buildStatsCard(stats);
            },
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(null, 'All'),
                  ...EventType.values.map((type) => _buildFilterChip(type, type.toString().split('.').last)),
                ],
              ),
            ),
          ),
          // Event list
          Expanded(
            child: FutureBuilder<List<AppEvent>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final events = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return _buildEventTile(events[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Total Events', stats['totalEvents'].toString(), Colors.blue),
                _buildStatItem('Oldest', stats['oldestEvent'].toString().substring(0, 10), Colors.green),
                _buildStatItem('Latest', stats['newestEvent'].toString().substring(0, 10), Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(EventType? type, String label) {
    final isSelected = _selectedFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (value) {
          setState(() {
            _selectedFilter = value ? type : null;
            _loadData();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.green.shade100,
        side: BorderSide(
          color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.green.shade600 : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEventTile(AppEvent event) {
    final color = _getEventColor(event.type);
    final icon = _getEventIcon(event.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.typeLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.formattedTimeShort,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.metadata != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Details: ${event.metadata.toString()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.smsReceived:
        return Colors.blue;
      case EventType.transactionAdded:
        return Colors.green;
      case EventType.permissionGranted:
        return Colors.green;
      case EventType.permissionDenied:
        return Colors.red;
      case EventType.permissionRevoked:
        return Colors.orange;
      case EventType.appOpened:
        return Colors.purple;
      case EventType.dataReset:
        return Colors.red;
      case EventType.settingsChanged:
        return Colors.amber;
      case EventType.animationChanged:
        return Colors.cyan;
    }
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.smsReceived:
        return Icons.sms;
      case EventType.transactionAdded:
        return Icons.add_circle;
      case EventType.permissionGranted:
        return Icons.check_circle;
      case EventType.permissionDenied:
        return Icons.block;
      case EventType.permissionRevoked:
        return Icons.cancel;
      case EventType.appOpened:
        return Icons.open_in_new;
      case EventType.dataReset:
        return Icons.refresh;
      case EventType.settingsChanged:
        return Icons.settings;
      case EventType.animationChanged:
        return Icons.animation;
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs?'),
        content: const Text('This will permanently delete all event logs. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await EventLoggerService.clearAllLogs();
              setState(() => _loadData());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All logs cleared')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
