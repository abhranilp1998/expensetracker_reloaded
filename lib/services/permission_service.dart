import 'package:permission_handler/permission_handler.dart';

import 'sms_service.dart';

/// The only runtime permissions the app uses.
enum AppPermission {
  sms(Permission.sms),
  notifications(Permission.notification);

  const AppPermission(this.permission);
  final Permission permission;
}

class PermissionService {
  static Future<Map<AppPermission, PermissionStatus>> statuses() async => {
    for (final p in AppPermission.values) p: await p.permission.status,
  };

  /// Requests [p]. If permanently denied, opens app settings instead.
  /// Starts SMS capture as soon as SMS is granted.
  static Future<PermissionStatus> request(AppPermission p) async {
    var status = await p.permission.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return status;
    }
    status = await p.permission.request();
    if (p == AppPermission.sms && status.isGranted) {
      await SmsService.start();
      await SmsService.importInboxOnce();
    }
    return status;
  }

  /// First-run flow: SMS, then notifications (Android 13+).
  static Future<void> requestAll() async {
    for (final p in AppPermission.values) {
      final s = await p.permission.status;
      if (!s.isGranted && !s.isPermanentlyDenied) await request(p);
    }
  }
}
