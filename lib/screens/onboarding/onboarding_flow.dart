import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/routes/app_routes.dart';
import 'package:expensetracker_reloaded/services/permission_service.dart';
import 'package:expensetracker_reloaded/services/theme_service.dart';
import 'package:expensetracker_reloaded/services/user_prefs_service.dart';
import 'package:expensetracker_reloaded/utils/animations.dart';

/// Multi-page first-run onboarding. Persists [UserPrefsService.onboardingCompletedKey].
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _page = PageController();
  int _index = 0;
  static const _pageCount = 6;

  final _nameCtrl = TextEditingController();
  String _currency = 'INR';
  ThemeMode _theme = ThemeMode.system;
  MaterialColor _accent = Colors.indigo;
  bool _importPast = true;
  bool _notifications = true;

  bool _permBusy = false;
  bool _showRestrictedHelp = false;
  String? _permStatus;

  @override
  void initState() {
    super.initState();
    _theme = ThemeService.getCurrentTheme();
    _accent = ThemeService.getCurrentAccentColor();
    UserPrefsService.getUserName().then((n) {
      if (n != 'User') _nameCtrl.text = n;
    });
  }

  @override
  void dispose() {
    _page.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _next() async {
    if (_index < _pageCount - 1) {
      await _page.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool _finishing = false;

  Future<void> _finish() async {
    if (_finishing) return; // ignore double taps while prefs save
    _finishing = true;
    await UserPrefsService.setUserName(_nameCtrl.text);
    await UserPrefsService.setCurrency(_currency);
    await UserPrefsService.setImportPastSms(_importPast);
    await UserPrefsService.setNotificationsEnabled(_notifications);
    await UserPrefsService.applyImportPreference();
    await ref.read(themeControllerProvider.notifier).setTheme(_theme);
    await ref.read(themeControllerProvider.notifier).setAccentColor(_accent);
    await UserPrefsService.setOnboardingCompleted(true);
    if (!mounted) return;
    // Clear the onboarding stack and land on the Home tab.
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  Future<void> _requestPerms() async {
    setState(() {
      _permBusy = true;
      _permStatus = 'Asking Android…';
    });
    final outcome = await PermissionService.requestAll();
    if (!mounted) return;
    setState(() {
      _permBusy = false;
      _showRestrictedHelp =
          outcome == PermissionOutcome.needsRestrictedSettings;
      _permStatus = switch (outcome) {
        PermissionOutcome.granted => 'SMS granted.',
        PermissionOutcome.needsRestrictedSettings =>
          'Android blocked SMS (common for sideloaded apps). Follow the steps below.',
        PermissionOutcome.denied =>
          'Permission denied. Try again or open Settings.',
        PermissionOutcome.openedSettings => 'Returned from Settings.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  if (_index > 0)
                    IconButton(
                      onPressed: () => _page.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                      icon: const Icon(Icons.arrow_back),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: (_index + 1) / _pageCount,
                        minHeight: 6,
                        backgroundColor: primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_index + 1}/$_pageCount',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _welcomePage(theme, primary),
                  _whatPage(theme),
                  _aboutYouPage(theme),
                  _setupPage(theme),
                  _permissionsPage(theme),
                  _allSetPage(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomePage(ThemeData theme, Color primary) {
    return _PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Hero(
            tag: 'app-logo',
            flightShuttleBuilder: HeroAnimations.logoFlightShuttle,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/branding/icon_full.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 56,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            _greeting,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome to Ledgerly',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your personal money tracker — private, on-device, and driven by your bank SMS.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const Spacer(flex: 3),
          FilledButton(onPressed: _next, child: const Text('Continue')),
          TextButton(onPressed: _finish, child: const Text('Skip setup')),
        ],
      ),
    );
  }

  Widget _whatPage(ThemeData theme) {
    final items = [
      (
        Icons.sms_outlined,
        'Reads bank & UPI SMS',
        'Detects debits and credits automatically.',
      ),
      (
        Icons.insights_outlined,
        'Tracks spend & income',
        'See today, week, and month at a glance.',
      ),
      (
        Icons.school_outlined,
        'Learns from your reviews',
        'Uncertain messages wait for your call.',
      ),
      (
        Icons.phone_android,
        'Stays on your phone',
        'Nothing is uploaded. Your data is yours.',
      ),
    ];
    return _PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What Ledgerly does',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Short version — no fluff.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 28),
          for (final (icon, title, sub) in items) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(sub),
            ),
            const SizedBox(height: 8),
          ],
          const Spacer(),
          FilledButton(onPressed: _next, child: const Text('Continue')),
        ],
      ),
    );
  }

  Widget _aboutYouPage(ThemeData theme) {
    const currencies = ['INR', 'USD', 'EUR', 'GBP', 'AED'];
    return _PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'About you',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Used in greetings and on your Profile. Change anytime in Settings.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 20),
          Text('Currency', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final c in currencies)
                ChoiceChip(
                  label: Text(c),
                  selected: _currency == c,
                  onSelected: (_) => setState(() => _currency = c),
                ),
            ],
          ),
          const Spacer(),
          FilledButton(onPressed: _next, child: const Text('Continue')),
        ],
      ),
    );
  }

  Widget _setupPage(ThemeData theme) {
    return _PageFrame(
      child: ListView(
        children: [
          Text(
            'Your setup',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick from the existing themes and accents. You can change these later in Settings.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('Theme', style: theme.textTheme.titleSmall),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: _theme,
            onChanged: (v) => setState(() => _theme = v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: _theme,
            onChanged: (v) => setState(() => _theme = v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            value: ThemeMode.system,
            groupValue: _theme,
            onChanged: (v) => setState(() => _theme = v!),
          ),
          const SizedBox(height: 8),
          Text('Accent', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final e in ThemeService.availableColors.entries)
                GestureDetector(
                  onTap: () => setState(() => _accent = e.value),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: e.value.shade600,
                      shape: BoxShape.circle,
                      border: _accent == e.value
                          ? Border.all(
                              color: theme.colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Import past SMS'),
            subtitle: const Text('Last 180 days of bank messages'),
            value: _importPast,
            onChanged: (v) => setState(() => _importPast = v),
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Alert when a transaction is detected'),
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          const SizedBox(height: 12),
          Text(
            'All of these can be changed later in Settings.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _next, child: const Text('Continue')),
        ],
      ),
    );
  }

  Widget _permissionsPage(ThemeData theme) {
    return _PageFrame(
      child: ListView(
        children: [
          Text(
            'Permissions',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ledgerly needs SMS to read bank messages on this device only. Notifications are optional.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _permBusy ? null : _requestPerms,
            icon: _permBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sms_outlined),
            label: Text(
              _permBusy ? 'Requesting…' : 'Grant SMS & notifications',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              setState(() => _showRestrictedHelp = true);
              await PermissionService.openSettingsForRestricted();
            },
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Open app settings'),
          ),
          if (_permStatus != null) ...[
            const SizedBox(height: 16),
            Text(_permStatus!, style: theme.textTheme.bodySmall),
          ],
          if (_showRestrictedHelp) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'SMS toggle greyed out?\n\n'
                  '1. Open app settings → ⋮ → Allow restricted settings.\n'
                  '2. Confirm with PIN / fingerprint.\n'
                  '3. Permissions → SMS → Allow.\n'
                  '4. Return and tap Grant again.\n\n'
                  'Or install via adb: adb install -r -g ledgerly-arm64.apk',
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(onPressed: _next, child: const Text('Continue')),
          TextButton(
            onPressed: _next,
            child: const Text('Continue without SMS'),
          ),
        ],
      ),
    );
  }

  Widget _allSetPage(ThemeData theme) {
    final name = _nameCtrl.text.trim().isEmpty
        ? 'there'
        : _nameCtrl.text.trim();
    return _PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Icon(
            Icons.check_circle_outline,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'You\'re all set, $name',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Currency $_currency · ${_theme.name} theme\n'
            '${_importPast ? 'Past SMS import on' : 'Past SMS import off'} · '
            '${_notifications ? 'Notifications on' : 'Notifications off'}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const Spacer(flex: 3),
          FilledButton(onPressed: _finish, child: const Text('Go to Home')),
        ],
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: child,
    );
  }
}

extension on ThemeMode {
  String get name => switch (this) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System',
  };
}
