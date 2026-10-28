import 'package:flutter/material.dart';

import 'package:expensetracker_reloaded/routes/app_routes.dart';
import 'package:expensetracker_reloaded/services/user_prefs_service.dart';
import 'package:expensetracker_reloaded/utils/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expensetracker_reloaded/providers/providers.dart';

/// User profile (name, currency, stats); settings live in [ComprehensiveSettingsPage].
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameCtrl = TextEditingController();
  String _currency = 'INR';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await UserPrefsService.getUserName();
    final currency = await UserPrefsService.getCurrency();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = name == 'User' ? '' : name;
      _currency = currency;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await UserPrefsService.setUserName(_nameCtrl.text);
    // Through the provider so every screen re-renders in the new currency.
    await ref.read(currencyProvider.notifier).set(_currency);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final displayName = _nameCtrl.text.trim().isEmpty
        ? 'User'
        : _nameCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: primary,
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppConstants.appName} user',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Text('Currency', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final c in ['INR', 'USD', 'EUR', 'GBP', 'AED'])
                      ChoiceChip(
                        label: Text(c),
                        selected: _currency == c,
                        onSelected: (_) => setState(() => _currency = c),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: _save, child: const Text('Save')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.comprehensiveSettings),
                  icon: const Icon(Icons.palette_outlined),
                  label: const Text('Appearance is in Settings'),
                ),
              ],
            ),
    );
  }
}
