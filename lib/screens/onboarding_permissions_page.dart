import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:expensetracker_reloaded/routes/app_routes.dart';
import 'package:expensetracker_reloaded/services/permission_service.dart';

/// First-run permission gate after Welcome.
///
/// Explains why SMS is needed and, when Android blocks the toggle (sideloaded
/// apps on Android 15+ Restricted settings / India Play Protect paths), shows
/// exact steps: App info → ⋮ → Allow restricted settings → Permissions → SMS.
class OnboardingPermissionsPage extends StatefulWidget {
  const OnboardingPermissionsPage({super.key});

  @override
  State<OnboardingPermissionsPage> createState() =>
      _OnboardingPermissionsPageState();
}

class _OnboardingPermissionsPageState extends State<OnboardingPermissionsPage>
    with WidgetsBindingObserver {
  bool _busy = false;
  bool _showRestrictedHelp = false;
  String? _statusLine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final sms = await Permission.sms.status;
    final notif = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      if (sms.isGranted) {
        _statusLine = notif.isGranted
            ? 'All set — SMS and notifications are on.'
            : 'SMS is on. Notifications still need a grant.';
        _showRestrictedHelp = false;
      } else {
        _statusLine = 'SMS is not granted yet.';
      }
    });
    if (sms.isGranted && mounted) {
      // Soft-continue once SMS works; user can still grant notifications later.
      // Don't auto-navigate — let them tap Continue.
    }
  }

  Future<void> _request() async {
    setState(() {
      _busy = true;
      _statusLine = 'Asking Android…';
    });
    final outcome = await PermissionService.requestAll();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _showRestrictedHelp =
          outcome == PermissionOutcome.needsRestrictedSettings;
      _statusLine = switch (outcome) {
        PermissionOutcome.granted => 'SMS granted.',
        PermissionOutcome.needsRestrictedSettings =>
          'Android blocked SMS (common for sideloaded apps). Follow the steps below.',
        PermissionOutcome.denied => 'Permission denied. Try again or open Settings.',
        PermissionOutcome.openedSettings => 'Returned from Settings.',
      };
    });
    await _refresh();
  }

  Future<void> _openSettings() async {
    setState(() => _showRestrictedHelp = true);
    await PermissionService.openSettingsForRestricted();
  }

  void _continue() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Ledgerly needs SMS access',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'We read bank/UPI debit and credit messages on this device only. '
              'Nothing is uploaded. Notifications are optional (Android 13+).',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _request,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sms_outlined),
              label: Text(_busy ? 'Requesting…' : 'Grant SMS & notifications'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Open app settings'),
            ),
            if (_statusLine != null) ...[
              const SizedBox(height: 16),
              Text(_statusLine!, style: theme.textTheme.bodySmall),
            ],
            if (_showRestrictedHelp) ...[
              const SizedBox(height: 24),
              Card(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SMS toggle greyed out?',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text(
                        'On Android 15+, apps installed from a browser or file '
                        'manager cannot get SMS until you unlock Restricted settings:\n\n'
                        '1. Tap Open app settings above.\n'
                        '2. Tap the ⋮ menu (top right) → Allow restricted settings.\n'
                        '3. Confirm with PIN / fingerprint.\n'
                        '4. Permissions → SMS → Allow.\n'
                        '5. Return here and tap Grant again.\n\n'
                        'Easier alternative: uninstall, then install with a computer:\n'
                        '  adb install -r -g ledgerly-arm64.apk\n'
                        'ADB installs are not treated as local-file sideloads, so '
                        'SMS can be granted normally. Play Store / internal testing '
                        'also avoids this block.\n\n'
                        'In India, Play Protect may also block installing any APK '
                        'that declares READ_SMS/RECEIVE_SMS when downloaded from a '
                        'browser — that is separate from Restricted settings; install '
                        'via adb or Play instead of a browser download when possible.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            TextButton(
              onPressed: _continue,
              child: const Text('Continue without SMS'),
            ),
            FilledButton(
              onPressed: _continue,
              child: const Text('Continue to Ledgerly'),
            ),
          ],
        ),
      ),
    );
  }
}
