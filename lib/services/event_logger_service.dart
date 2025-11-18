import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

/// Event types for logging
enum EventType {
  smsReceived,
  transactionAdded,
  permissionGranted,
  permissionDenied,
  permissionRevoked,
  appOpened,
  dataReset,
  settingsChanged,
  animationChanged,
}

/// Represents a single logged event
class AppEvent {
  final DateTime timestamp;
  final EventType type;
  final String message;
  final Map<String, dynamic>? metadata;

  AppEvent({
    required this.timestamp,
    required this.type,
    required this.message,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type.toString(),
    'message': message,
    'metadata': metadata,
  };

  factory AppEvent.fromMap(Map<String, dynamic> map) {
    return AppEvent(
      timestamp: DateTime.parse(map['timestamp'].toString()),
      type: EventType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => EventType.appOpened,
      ),
      message: map['message'],
      metadata: map['metadata'],
    );
  }

  String get formattedTime => DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
  String get formattedTimeShort => DateFormat('HH:mm:ss').format(timestamp);
  String get typeLabel => type.toString().split('.').last;
}

/// Service to log application events
class EventLoggerService {
  static const String _eventLogKey = 'app_event_logs';
  static const int _maxLogs = 500; // Keep last 500 events

  /// Log an event
  static Future<void> logEvent({
    required EventType type,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    final event = AppEvent(
      timestamp: DateTime.now(),
      type: type,
      message: message,
      metadata: metadata,
    );

    final prefs = await SharedPreferences.getInstance();
    final List<String> logs = prefs.getStringList(_eventLogKey) ?? [];

    // Add new event
    logs.add(jsonEncode(event.toMap()));

    // Keep only last _maxLogs events
    if (logs.length > _maxLogs) {
      logs.removeRange(0, logs.length - _maxLogs);
    }

    await prefs.setStringList(_eventLogKey, logs);
  }

  /// Get all logged events
  static Future<List<AppEvent>> getAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? logs = prefs.getStringList(_eventLogKey);

    if (logs == null || logs.isEmpty) return [];

    return logs
        .map((json) {
          try {
            return AppEvent.fromMap(jsonDecode(json));
          } catch (e) {
            return null;
          }
        })
        .whereType<AppEvent>()
        .toList()
        .reversed
        .toList(); // Newest first
  }

  /// Get events by type
  static Future<List<AppEvent>> getEventsByType(EventType type) async {
    final allEvents = await getAllEvents();
    return allEvents.where((e) => e.type == type).toList();
  }

  /// Get events from last N days
  static Future<List<AppEvent>> getRecentEvents(int days) async {
    final allEvents = await getAllEvents();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return allEvents.where((e) => e.timestamp.isAfter(cutoffDate)).toList();
  }

  /// Clear all logs
  static Future<void> clearAllLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_eventLogKey);
  }

  /// Get stats
  static Future<Map<String, dynamic>> getStats() async {
    final allEvents = await getAllEvents();
    final typeCounts = <String, int>{};

    for (final event in allEvents) {
      final typeLabel = event.typeLabel;
      typeCounts[typeLabel] = (typeCounts[typeLabel] ?? 0) + 1;
    }

    return {
      'totalEvents': allEvents.length,
      'oldestEvent': allEvents.isNotEmpty ? allEvents.last.formattedTime : 'No events',
      'newestEvent': allEvents.isNotEmpty ? allEvents.first.formattedTime : 'No events',
      'typeBreakdown': typeCounts,
    };
  }
}
