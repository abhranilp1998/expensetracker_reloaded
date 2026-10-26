import 'package:flutter/material.dart';
import 'package:expensetracker_reloaded/routes/app_routes.dart' show AppRoutes;
import 'package:expensetracker_reloaded/widgets/drawer_tile.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    primaryColor.withOpacity(0.1),
                    primaryColor.withOpacity(0.05),
                  ]
                : [
                    primaryColor.withOpacity(0.05),
                    primaryColor.withOpacity(0.02),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Hero(
                      tag: 'app-logo',
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Abhranil Paul',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '😁',
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    DrawerTile(
                      icon: Icons.home,
                      title: 'Home',
                      color: Colors.green,
                      onTap: () => Navigator.of(context).pushReplacementNamed('/home'),
                    ),
                    DrawerTile(
                      icon: Icons.rule,
                      title: 'Needs review',
                      color: Colors.deepOrange,
                      onTap: () => Navigator.of(context).pushNamed('/review'),
                    ),
                    DrawerTile(
                      icon: Icons.history,
                      title: 'History',
                      color: Colors.purple,
                      onTap: () => Navigator.of(context).pushNamed('/history'),
                    ),
                    DrawerTile(
                      icon: Icons.emoji_events,
                      title: 'Medals',
                      color: Colors.amber,
                      onTap: () {},
                    ),
                    DrawerTile(
                      icon: Icons.person,
                      title: 'Profile',
                      color: Colors.blue,
                      onTap: () => Navigator.of(context).pushNamed('/profile'),
                    ),
                    DrawerTile(
                      icon: Icons.bug_report,
                      title: 'Demo',
                      color: Colors.orange,
                      onTap: () => Navigator.of(context).pushNamed('/demo'),
                    ),
                    DrawerTile(
                      icon: Icons.fireplace_outlined,
                      title: 'Fun',
                      color: Colors.red,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.animationShowcase),
                    ),
                    DrawerTile(
                      icon: Icons.trending_up,
                      title: 'Till Now',
                      color: Colors.teal,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.tillNow),
                    ),
                    DrawerTile(
                      icon: Icons.lock_open,
                      title: 'Permissions',
                      color: Colors.indigo,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.permissions),
                    ),
                    DrawerTile(
                      icon: Icons.event_note,
                      title: 'Event Logs',
                      color: Colors.cyan,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.eventLogs),
                    ),
                  ],
                ),
              ),
              const Divider(),
              DrawerTile(
                icon: Icons.settings,
                title: 'Settings',
                color: Colors.grey,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.comprehensiveSettings),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
