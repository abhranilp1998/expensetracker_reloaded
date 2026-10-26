import 'package:flutter/material.dart';
import 'package:expensetracker_reloaded/widgets/settings_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            color: Colors.orange,
            onTap: () {},
          ),
          SettingsTile(
            icon: Icons.security,
            title: 'Privacy',
            subtitle: 'Privacy and security settings',
            color: Colors.blue,
            onTap: () {},
          ),
          SettingsTile(
            icon: Icons.palette,
            title: 'Appearance',
            subtitle: 'Theme and display options',
            color: Colors.purple,
            onTap: () {},
          ),
          SettingsTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            color: Colors.green,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
