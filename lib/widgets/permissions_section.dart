import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:expensetracker_reloaded/services/event_logger_service.dart';
import 'package:expensetracker_reloaded/services/permission_service.dart';

/// SMS + notifications controls for Settings (and reusable elsewhere).
class PermissionsSection extends StatefulWidget {
  const PermissionsSection({super.key});

  @override
  State<PermissionsSection> createState() => _PermissionsSectionState();
}

class _PermissionsSectionState extends State<PermissionsSection>
    with WidgetsBindingObserver {
  PermissionStatus? _sms;
  PermissionStatus? _notif;
  bool _loading = true;
  bool _restricted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final sms = await Permission.sms.status;
    final notif = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _sms = sms;
      _notif = notif;
      _loading = false;
    });
  }

  Future<void> _requestSms() async {
    final outcome = await PermissionService.request(AppPermission.sms);
    await EventLoggerService.logEvent(
      type: outcome == PermissionOutcome.granted
          ? EventType.permissionGranted
          : EventType.permissionDenied,
      message: 'SMS permission request: $outcome',
    );
    setState(() =>
        _restricted = outcome == PermissionOutcome.needsRestrictedSettings);
    await _load();
    if (!mounted) return;
    final msg = switch (outcome) {
      PermissionOutcome.granted => 'SMS granted',
      PermissionOutcome.needsRestrictedSettings =>
        'Blocked by Restricted settings — see steps below',
      _ => 'SMS not granted',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _requestNotif() async {
    await PermissionService.request(AppPermission.notifications);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(
            Icons.sms,
            color: (_sms?.isGranted ?? false)
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
          title: const Text('SMS'),
          subtitle: Text(_sms?.isGranted ?? false
              ? 'Granted — bank messages can be read'
              : 'Required to auto-track expenses'),
          trailing: (_sms?.isGranted ?? false)
              ? const Icon(Icons.check_circle)
              : TextButton(onPressed: _requestSms, child: const Text('Grant')),
        ),
        ListTile(
          leading: Icon(
            Icons.notifications_outlined,
            color: (_notif?.isGranted ?? false)
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          title: const Text('Notifications'),
          subtitle: Text(_notif?.isGranted ?? false ? 'Granted' : 'Optional'),
          trailing: (_notif?.isGranted ?? false)
              ? const Icon(Icons.check_circle)
              : TextButton(onPressed: _requestNotif, child: const Text('Grant')),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            setState(() => _restricted = true);
            await PermissionService.openSettingsForRestricted();
          },
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Open app settings'),
        ),
        if (_restricted) ...[
          const SizedBox(height: 12),
          Card(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'If SMS is greyed out: App info → ⋮ → Allow restricted settings '
                '→ Permissions → SMS → Allow. Or install via adb.',
              ),
            ),
          ),
        ],
      ],
    );
  }
}
