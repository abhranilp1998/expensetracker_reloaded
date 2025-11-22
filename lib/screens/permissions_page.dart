import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:expensetracker_reloaded/services/event_logger_service.dart';

/// Permissions management page
class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  late Map<String, PermissionStatus> _permissionStatuses;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);
    
    final smsStatus = await Permission.sms.status;
    final contactsStatus = await Permission.contacts.status;
    final phoneStatus = await Permission.phone.status;

    setState(() {
      _permissionStatuses = {
        'SMS': smsStatus,
        'Contacts': contactsStatus,
        'Phone': phoneStatus,
      };
      _isLoading = false;
    });
  }

  Future<void> _requestSmsPermission() async {
    final status = await Permission.sms.request();
    
    await EventLoggerService.logEvent(
      type: status.isGranted ? EventType.permissionGranted : EventType.permissionDenied,
      message: 'SMS permission request: ${status.isDenied ? 'denied' : status.isGranted ? 'granted' : status.isPermanentlyDenied ? 'permanently denied' : 'unknown'}',
    );

    await _loadPermissions();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status.isGranted 
            ? 'SMS Permission Granted! 🎉' 
            : status.isPermanentlyDenied
            ? 'Permission permanently denied. Open app settings to enable.'
            : 'SMS Permission Denied'),
          backgroundColor: status.isGranted ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );

      if (status.isPermanentlyDenied) {
        _showOpenSettingsDialog();
      }
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('SMS permission is permanently denied. Would you like to open app settings to enable it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    final subtleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text(
          'Permissions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Permissions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ) ?? TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage permissions required for SMS expense tracking',
                    style: TextStyle(color: subtleColor, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _buildPermissionCard(
                    icon: Icons.sms,
                    title: 'SMS Messages',
                    description: 'Required to read incoming SMS for automatic expense detection',
                    status: _permissionStatuses['SMS']!,
                    onTap: _requestSmsPermission,
                    context: context,
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionCard(
                    icon: Icons.contacts,
                    title: 'Contacts',
                    description: 'Optional - for sender identification',
                    status: _permissionStatuses['Contacts']!,
                    onTap: () async {
                      await Permission.contacts.request();
                      await _loadPermissions();
                    },
                    context: context,
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionCard(
                    icon: Icons.phone,
                    title: 'Phone State',
                    description: 'Optional - for advanced SMS handling',
                    status: _permissionStatuses['Phone']!,
                    onTap: () async {
                      await Permission.phone.request();
                      await _loadPermissions();
                    },
                    context: context,
                  ),
                  const SizedBox(height: 32),
                  _buildStatusLegend(context),
                  const SizedBox(height: 32),
                  _buildInfoCard(context),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required PermissionStatus status,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    final subtleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardBgColor = Theme.of(context).cardColor;
    
    final isGranted = status.isGranted;
    final isPermanentlyDenied = status.isPermanentlyDenied;

    final statusColor = isGranted 
      ? Colors.green 
      : isPermanentlyDenied
      ? Colors.red
      : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(isDark ? 0.3 : 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isGranted 
                      ? 'Granted' 
                      : isPermanentlyDenied
                      ? 'Blocked'
                      : 'Denied',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (!isGranted)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isPermanentlyDenied ? 'Open Settings' : 'Grant Permission',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLegend(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(isDark ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(isDark ? 0.25 : 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permission Status Guide',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusRow('Granted', 'Permission is active', Colors.green, context),
          const SizedBox(height: 8),
          _buildStatusRow('Denied', 'Permission was denied', Colors.orange, context),
          const SizedBox(height: 8),
          _buildStatusRow('Blocked', 'Permission permanently denied', Colors.red, context),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String description, Color color, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600, 
                  fontSize: 13,
                  color: textColor,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: subtleColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Colors.amber;
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(isDark ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(isDark ? 0.25 : 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Why We Need SMS Permission',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Automatically detects expense amounts from bank SMS messages\n'
            '• Parses amounts in Indian Rupees (₹) format\n'
            '• Creates expense records without manual entry\n'
            '• Works in background for incoming messages\n'
            '• All data stays on your device (no internet required)',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
