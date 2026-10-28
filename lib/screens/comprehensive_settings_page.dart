import 'package:flutter/material.dart';
import 'package:expensetracker_reloaded/utils/money.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/services/theme_service.dart';
import 'package:expensetracker_reloaded/services/event_logger_service.dart';
import 'package:expensetracker_reloaded/routes/animation_preferences.dart';
import 'package:expensetracker_reloaded/routes/animation_variants.dart';
import 'package:expensetracker_reloaded/routes/app_routes.dart';
import 'package:expensetracker_reloaded/widgets/app_drawer.dart';
import 'package:expensetracker_reloaded/widgets/permissions_section.dart';
import 'package:expensetracker_reloaded/widgets/debug_pin_section.dart';
import 'package:expensetracker_reloaded/services/app_settings.dart';

/// Single sectioned Settings page: Appearance, SMS & permissions, Learned rules, About.
class ComprehensiveSettingsPage extends StatefulWidget {
  const ComprehensiveSettingsPage({super.key, this.asTab = false});

  final bool asTab;

  @override
  State<ComprehensiveSettingsPage> createState() =>
      _ComprehensiveSettingsPageState();
}

class _ComprehensiveSettingsPageState extends State<ComprehensiveSettingsPage> {
  final Map<String, GlobalKey> _sectionKeys = {
    'Appearance': GlobalKey(),
    'SMS & Permissions': GlobalKey(),
    'Learned rules': GlobalKey(),
    'About': GlobalKey(),
  };

  late ThemeMode _currentTheme;
  late MaterialColor _currentAccentColor;
  late AnimationType _currentAnimation;
  Map<String, bool> _preferences = {};

  @override
  void initState() {
    super.initState();
    _currentTheme = ThemeService.getCurrentTheme();
    _currentAccentColor = ThemeService.getCurrentAccentColor();
    _currentAnimation = AnimationVariants.currentType;
    _loadPreferences();
  }

  /// Copies theme/accent from [themeControllerProvider] and the animation
  /// from [AnimationVariants] into the page's selection state.
  void _syncSelections(BuildContext context) {
    final theme = ProviderScope.containerOf(
      context,
    ).read(themeControllerProvider);
    setState(() {
      _currentTheme = theme.mode;
      _currentAccentColor = theme.accent;
      _currentAnimation = AnimationVariants.currentType;
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _preferences = {
        'notifications': prefs.getBool('pref_notifications') ?? true,
        'haptic_feedback': prefs.getBool('pref_haptic_feedback') ?? true,
        'animations_enabled': prefs.getBool('pref_animations_enabled') ?? true,
        'event_logging': prefs.getBool('pref_event_logging') ?? true,
      };
    });
  }

  Future<void> _updatePreference(String key, bool value) async {
    // AppSettings persists the flag and applies it right away (bug #11).
    await AppSettings.set('pref_$key', value);
    setState(() => _preferences[key] = value);

    // Log preference change
    await EventLoggerService.logEvent(
      type: EventType.settingsChanged,
      message: 'Updated $key: $value',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      drawer: widget.asTab ? const AppDrawer() : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final name in _sectionKeys.keys)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(name),
                          onPressed: () {
                            final ctx = _sectionKeys[name]!.currentContext;
                            if (ctx != null) {
                              Scrollable.ensureVisible(
                                ctx,
                                duration: const Duration(milliseconds: 300),
                              );
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Theme Settings Section
              _SectionHeader(
                key: _sectionKeys['Appearance'],
                icon: Icons.palette,
                title: 'Appearance Settings',
                color: cs.primary,
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                title: 'Theme Mode',
                subtitle: 'Choose your preferred theme',
                icon: Icons.brightness_4,
                color: cs.primary,
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      value: ThemeMode.light,
                      groupValue: _currentTheme,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _currentTheme = value);
                          ProviderScope.containerOf(context)
                              .read(themeControllerProvider.notifier)
                              .setTheme(value);
                          EventLoggerService.logEvent(
                            type: EventType.settingsChanged,
                            message: 'Theme changed to Light',
                          );
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      value: ThemeMode.dark,
                      groupValue: _currentTheme,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _currentTheme = value);
                          ProviderScope.containerOf(context)
                              .read(themeControllerProvider.notifier)
                              .setTheme(value);
                          EventLoggerService.logEvent(
                            type: EventType.settingsChanged,
                            message: 'Theme changed to Dark',
                          );
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('System'),
                      value: ThemeMode.system,
                      groupValue: _currentTheme,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _currentTheme = value);
                          ProviderScope.containerOf(context)
                              .read(themeControllerProvider.notifier)
                              .setTheme(value);
                          EventLoggerService.logEvent(
                            type: EventType.settingsChanged,
                            message: 'Theme changed to System',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'Accent Color',
                subtitle: 'Customize app colors',
                icon: Icons.palette_outlined,
                color: cs.primary,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: ThemeService.availableColors.length,
                    itemBuilder: (context, index) {
                      final colorName = ThemeService.availableColors.keys
                          .toList()[index];
                      final color = ThemeService.availableColors[colorName]!;
                      final isSelected = _currentAccentColor == color;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _currentAccentColor = color);
                          ProviderScope.containerOf(context)
                              .read(themeControllerProvider.notifier)
                              .setAccentColor(color);
                          EventLoggerService.logEvent(
                            type: EventType.settingsChanged,
                            message: 'Accent color changed to $colorName',
                          );
                        },
                        child: AnimatedScale(
                          scale: isSelected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.shade600,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Animation Settings Section
              _SectionHeader(
                icon: Icons.animation,
                title: 'Animation Settings',
                color: cs.primary,
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                title: 'Route Animations',
                subtitle: 'Choose page transition style',
                icon: Icons.flash_on,
                color: cs.primary,
                child: Column(
                  children: [
                    for (final animType in AnimationType.values)
                      RadioListTile<AnimationType>(
                        title: Text(
                          AnimationVariants.getAnimationName(animType),
                        ),
                        subtitle: Text(
                          AnimationPreferencesService.getDescription(animType),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: animType,
                        groupValue: _currentAnimation,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _currentAnimation = value);
                            AnimationPreferencesService.saveAnimationType(
                              value,
                            );
                            EventLoggerService.logEvent(
                              type: EventType.animationChanged,
                              message:
                                  'Animation type changed to ${AnimationVariants.getAnimationName(value)}',
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _PreferenceToggle(
                icon: Icons.animation_outlined,
                title: 'Enable Animations',
                subtitle: 'Off: pages switch instantly',
                value: _preferences['animations_enabled'] ?? true,
                color: cs.primary,
                onChanged: (value) =>
                    _updatePreference('animations_enabled', value),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.rule),
                      title: const Text('Needs review'),
                      subtitle: const Text(
                        'Uncertain SMS waiting for your decision',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.review),
                    ),
                    ListTile(
                      leading: const Icon(Icons.psychology_outlined),
                      title: const Text('Learned rules'),
                      subtitle: const Text(
                        'View or delete on-device SMS rules',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.learnedRules),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Animation Preview Button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.animationShowcase);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.slideshow,
                          color: cs.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Animation Showcase',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Preview all animation types',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onPrimary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: cs.primary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // SMS & Permissions
              _SectionHeader(
                key: _sectionKeys['SMS & Permissions'],
                icon: Icons.lock_open,
                title: 'SMS & Permissions',
                color: cs.primary,
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                title: 'Device access',
                subtitle: 'SMS and notifications for auto-tracking',
                icon: Icons.security,
                color: cs.primary,
                child: const PermissionsSection(),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  key: const Key('scanInboxTile'),
                  leading: Icon(Icons.manage_search, color: cs.primary),
                  title: const Text('Scan SMS inbox'),
                  subtitle: const Text(
                    'Find past transactions. Already-added messages are skipped.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.inboxScan),
                ),
              ),
              const SizedBox(height: 24),

              // Name and currency live on Profile; link them here (bug #20).
              Card(
                child: ListTile(
                  key: const Key('profileCurrencyTile'),
                  leading: Icon(Icons.badge_outlined, color: cs.primary),
                  title: const Text('Name & currency'),
                  subtitle: const Text(
                    'Edit on your Profile. $currencySymbolNote',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.profile),
                ),
              ),
              const SizedBox(height: 24),

              // Debug PIN (bug #14/#20)
              const DebugPinSection(),
              const SizedBox(height: 24),

              // Learned rules
              _SectionHeader(
                key: _sectionKeys['Learned rules'],
                icon: Icons.auto_fix_high,
                title: 'Learned rules',
                color: cs.primary,
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Icon(Icons.rule, color: cs.primary),
                  title: const Text('Manage learned rules'),
                  subtitle: const Text(
                    'Senders and patterns learned from your reviews',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.learnedRules),
                ),
              ),
              const SizedBox(height: 24),

              // Feature Settings Section
              _SectionHeader(
                icon: Icons.settings,
                title: 'Feature Settings',
                color: cs.primary,
              ),
              const SizedBox(height: 12),
              _PreferenceToggle(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Alert when an SMS transaction is detected',
                value: _preferences['notifications'] ?? true,
                color: cs.primary,
                onChanged: (value) => _updatePreference('notifications', value),
              ),
              const SizedBox(height: 12),
              _PreferenceToggle(
                icon: Icons.vibration,
                title: 'Haptic Feedback',
                subtitle: 'Vibrate on tabs, Add, Save and Delete',
                value: _preferences['haptic_feedback'] ?? true,
                color: cs.primary,
                onChanged: (value) =>
                    _updatePreference('haptic_feedback', value),
              ),
              const SizedBox(height: 12),
              _PreferenceToggle(
                icon: Icons.event_note,
                title: 'Activity log',
                subtitle:
                    'Keep a local log on this phone for debugging. Never uploaded.',
                value: _preferences['event_logging'] ?? true,
                color: cs.primary,
                onChanged: (value) => _updatePreference('event_logging', value),
              ),
              const SizedBox(height: 24),

              // "Auto Dark Mode" was removed (bug #11): Theme Mode > System
              // already follows the phone's dark mode.
              // About & Info Section
              _SectionHeader(
                key: _sectionKeys['About'],
                icon: Icons.info,
                title: 'About',
                color: cs.primary,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.info_outline,
                title: 'App Version',
                value: '1.0.0',
                color: cs.primary,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.devices,
                title: 'Platform',
                value: 'Android',
                color: cs.primary,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.memory,
                title: 'Storage Info',
                value: 'Preferences synced',
                color: cs.primary,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Clear All Preferences'),
                onPressed: () => _showClearPreferencesDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.secondary,
                  foregroundColor: cs.onSecondary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear_all),
                label: const Text('Reset to Defaults'),
                onPressed: () => _showResetDefaultsDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showClearPreferencesDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Preferences?'),
        content: const Text(
          'This will clear all user preferences but keep your data. Settings will reset to defaults.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pref_notifications');
      await prefs.remove('pref_haptic_feedback');
      await prefs.remove('pref_animations_enabled');
      await prefs.remove('pref_event_logging');
      await prefs.remove('pref_auto_dark_mode'); // legacy key
      await AppSettings.load();

      if (mounted) {
        await EventLoggerService.logEvent(
          type: EventType.settingsChanged,
          message: 'All preferences cleared',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Preferences cleared'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadPreferences();
      }
    }
  }

  Future<void> _showResetDefaultsDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will reset all settings to their default values including theme, animations, and preferences.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('app_theme_mode');
      await prefs.remove('app_accent_color');
      await prefs.remove('animationType');
      await prefs.remove('pref_notifications');
      await prefs.remove('pref_haptic_feedback');
      await prefs.remove('pref_animations_enabled');
      await prefs.remove('pref_event_logging');
      await prefs.remove('pref_auto_dark_mode'); // legacy key
      await AppSettings.load();

      if (mounted) {
        await EventLoggerService.logEvent(
          type: EventType.settingsChanged,
          message: 'All settings reset to defaults',
        );

        // Reset to defaults
        ProviderScope.containerOf(
          context,
        ).read(themeControllerProvider.notifier).setTheme(ThemeMode.system);
        ProviderScope.containerOf(
          context,
        ).read(themeControllerProvider.notifier).setAccentColor(Colors.green);
        await AnimationPreferencesService.saveAnimationType(
          AnimationType.fadeSlide,
        );
        // Re-read the selections from the source of truth so the radios and
        // accent swatch don't keep showing the pre-reset values (Codex A8).
        if (!context.mounted) return;
        _syncSelections(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Settings reset to defaults'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadPreferences();
      }
    }
  }
}

class _SectionHeader extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              widget.title,
              style:
                  Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ) ??
                  TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.outlineVariant
        : Theme.of(context).colorScheme.outlineVariant;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style:
                                  Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold) ??
                                  const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle,
                              style:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ) ??
                                  TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreferenceToggle extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final Function(bool) onChanged;

  const _PreferenceToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  State<_PreferenceToggle> createState() => _PreferenceToggleState();
}

class _PreferenceToggleState extends State<_PreferenceToggle>
    with SingleTickerProviderStateMixin {
  late bool _value;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      setState(() => _value = !_value);
      widget.onChanged(_value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.outlineVariant
        : Theme.of(context).colorScheme.outlineVariant;

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _rotateAnimation,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_rotateAnimation.value),
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _value
                  ? widget.color.withValues(alpha: 0.08)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _value
                    ? widget.color.withValues(alpha: 0.3)
                    : borderColor,
                width: _value ? 1.5 : 0.5,
              ),
              boxShadow: _value
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: _value ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 400),
                    turns: _value ? 0.1 : 0,
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style:
                            (Theme.of(context).textTheme.titleMedium ??
                                    const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ))
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _value
                                      ? widget.color
                                      : Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.color,
                                ),
                        child: Text(widget.title),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style:
                            (Theme.of(context).textTheme.bodySmall ??
                                    TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ))
                                .copyWith(
                                  color: _value
                                      ? widget.color.withValues(alpha: 0.7)
                                      : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant),
                                ),
                        child: Text(widget.subtitle),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: RotationTransition(
                        turns: Tween<double>(
                          begin: 0.5,
                          end: 1.0,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Switch(
                    key: ValueKey<bool>(_value),
                    value: _value,
                    onChanged: (value) {
                      _handleTap();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.outlineVariant
        : Theme.of(context).colorScheme.outlineVariant;
    final subtleTextColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final iconColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ) ??
                              const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.value,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: subtleTextColor,
                              ) ??
                              TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 500),
                    turns: 0.25,
                    child: Icon(Icons.info_outline, color: iconColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
