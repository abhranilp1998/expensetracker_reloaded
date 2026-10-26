import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/services/theme_service.dart';
import 'package:expensetracker_reloaded/widgets/preference_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ThemeMode _currentTheme;
  late MaterialColor _currentAccentColor;

  @override
  void initState() {
    super.initState();
    _currentTheme = ThemeService.getCurrentTheme();
    _currentAccentColor = ThemeService.getCurrentAccentColor();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Profile & Preferences',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Column(
                children: [
                  Hero(
                    tag: 'app-logo',
                    flightShuttleBuilder: (flightContext, animation,
                        flightDirection, fromContext, toContext) {
                      return ScaleTransition(
                        scale: animation.drive(
                          Tween(begin: 0.5, end: 1.5).chain(
                            CurveTween(curve: Curves.easeInOutCubic),
                          ),
                        ),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.6),
                                primaryColor,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.6),
                            primaryColor,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Abhranil Paul',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expense Tracker User',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme Settings
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    child: Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Theme Mode Selection
                  PreferenceCard(
                    icon: Icons.brightness_4,
                    title: 'Theme Mode',
                    subtitle: 'Choose your preferred theme',
                    color: Colors.blue,
                    child: Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          title: const Text('Light'),
                          value: ThemeMode.light,
                          groupValue: _currentTheme,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _currentTheme = value);
                              ProviderScope.containerOf(context).read(themeControllerProvider.notifier).setTheme(value);
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
                              ProviderScope.containerOf(context).read(themeControllerProvider.notifier).setTheme(value);
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
                              ProviderScope.containerOf(context).read(themeControllerProvider.notifier).setTheme(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Accent Color Selection
                  PreferenceCard(
                    icon: Icons.palette,
                    title: 'Accent Color',
                    subtitle: 'Customize app colors',
                    color: Colors.purple,
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
                              ProviderScope.containerOf(context).read(themeControllerProvider.notifier).setAccentColor(color);
                            },
                            child: AnimatedScale(
                              scale: isSelected ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color.shade600,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        )
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withOpacity(0.4),
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
                  // User Preferences
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    child: Text(
                      'Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchPreferenceCard(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Receive expense alerts',
                    color: Colors.orange,
                    initialValue: true,
                    onChanged: (value) {
                      // Handle notifications setting
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchPreferenceCard(
                    icon: Icons.security,
                    title: 'Dark Mode Auto-Switch',
                    subtitle: 'Follow system theme',
                    color: Colors.blue,
                    initialValue: _currentTheme == ThemeMode.system,
                    onChanged: (value) {
                      if (value) {
                        ProviderScope.containerOf(context).read(themeControllerProvider.notifier).setTheme(ThemeMode.system);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchPreferenceCard(
                    icon: Icons.vibration,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibrations on interactions',
                    color: Colors.green,
                    initialValue: true,
                    onChanged: (value) {
                      // Handle haptic feedback setting
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
