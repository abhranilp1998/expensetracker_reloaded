import 'package:flutter/material.dart';

import 'package:expensetracker_reloaded/routes/app_routes.dart';
import 'package:expensetracker_reloaded/services/debug_unlock_service.dart';

/// Debug destinations unlocked via PIN / biometric (not kDebugMode).
class DebugHubPage extends StatelessWidget {
  const DebugHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!DebugUnlockService.sessionUnlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug'),
        actions: [
          TextButton(
            onPressed: () {
              DebugUnlockService.lock();
              Navigator.of(context).pop();
            },
            child: const Text('Lock'),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Demo'),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.demo),
          ),
          ListTile(
            leading: const Icon(Icons.event_note),
            title: const Text('Event Logs'),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.eventLogs),
          ),
        ],
      ),
    );
  }
}
