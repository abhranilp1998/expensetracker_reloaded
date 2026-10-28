import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker_reloaded/routes/app_routes.dart';
import 'package:expensetracker_reloaded/services/debug_unlock_service.dart';
import 'package:expensetracker_reloaded/widgets/drawer_tile.dart';
import 'package:expensetracker_reloaded/providers/providers.dart';

/// Side menu: Till Now, Profile, Showcase, Event logs, Debug (PIN gated).
class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  /// Same provider as the Home greeting, so both always agree (bug #5).
  String get _name => ref.watch(userNameProvider).value ?? 'User';

  Future<void> _openDebug() async {
    if (DebugUnlockService.sessionUnlocked) {
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed(AppRoutes.debugHub);
      return;
    }
    final unlocked = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _DebugUnlockDialog(),
    );
    if (unlocked == true && mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed(AppRoutes.debugHub);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primary.withValues(alpha: isDark ? 0.1 : 0.05),
              primary.withValues(alpha: isDark ? 0.05 : 0.02),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: primary,
                      child: Icon(
                        Icons.person,
                        color: theme.colorScheme.onPrimary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    DrawerTile(
                      icon: Icons.trending_up,
                      title: 'Till Now',
                      color: theme.colorScheme.tertiary,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(AppRoutes.tillNow);
                      },
                    ),
                    DrawerTile(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      color: theme.colorScheme.secondary,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(AppRoutes.profile);
                      },
                    ),
                    DrawerTile(
                      icon: Icons.auto_awesome,
                      title: 'Animation Showcase',
                      color: theme.colorScheme.primary,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.animationShowcase);
                      },
                    ),
                    DrawerTile(
                      icon: Icons.lock_outline,
                      title: 'Debug',
                      color: theme.colorScheme.error,
                      onTap: _openDebug,
                    ),
                  ],
                ),
              ),
              const Divider(),
              DrawerTile(
                icon: Icons.settings,
                title: 'Settings',
                color: theme.colorScheme.outline,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.comprehensiveSettings);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugUnlockDialog extends StatefulWidget {
  const _DebugUnlockDialog();

  @override
  State<_DebugUnlockDialog> createState() => _DebugUnlockDialogState();
}

class _DebugUnlockDialogState extends State<_DebugUnlockDialog> {
  final _pin = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _needsSetup = false;

  @override
  void initState() {
    super.initState();
    DebugUnlockService.hasPin().then((has) {
      if (mounted) setState(() => _needsSetup = !has);
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _bio() async {
    setState(() => _busy = true);
    final ok = await DebugUnlockService.unlockWithBiometric();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Biometric failed — try PIN');
    }
  }

  Future<void> _submit() async {
    final pin = _pin.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits');
      return;
    }
    setState(() => _busy = true);
    if (_needsSetup) {
      await DebugUnlockService.setPin(pin);
      DebugUnlockService.sessionUnlocked = true;
      if (mounted) Navigator.of(context).pop(true);
      return;
    }
    final ok = await DebugUnlockService.unlockWithPin(pin);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Wrong PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_needsSetup ? 'Set Debug PIN' : 'Unlock Debug'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _needsSetup
                ? 'Choose a PIN (4+ digits). You can also use fingerprint next time.'
                : 'Enter your Debug PIN or use biometrics.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'PIN',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        if (!_needsSetup)
          TextButton(
            onPressed: _busy ? null : _bio,
            child: const Text('Biometric'),
          ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_needsSetup ? 'Set PIN' : 'Unlock'),
        ),
      ],
    );
  }
}
