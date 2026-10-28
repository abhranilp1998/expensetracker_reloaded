import 'package:permission_handler/permission_handler.dart';

import 'sms_service.dart';

/// The only runtime permissions the app uses.
enum AppPermission {
  sms(Permission.sms),
  notifications(Permission.notification);

  const AppPermission(this.permission);
  final Permission permission;
}

/// Outcome of a permission attempt, including Android 13+/15 restricted-settings.
enum PermissionOutcome {
  granted,
  denied,

  /// Auto-denied / greyed toggle — typical for sideloaded SMS apps on Android 15+.
  needsRestrictedSettings,
  openedSettings,
}

/// Checks/requests SMS and notification permissions and opens app settings.
class PermissionService {
  static Future<Map<AppPermission, PermissionStatus>> statuses() async => {
    for (final p in AppPermission.values) p: await p.permission.status,
  };

  /// True when SMS cannot be granted via the normal dialog (sideload restricted).
  ///
  /// On Android 15+, apps installed from a browser/file manager get SMS blocked
  /// under Restricted settings — [request] returns permanentlyDenied with no dialog,
  /// and the Settings toggle is greyed until the user enables
  /// App info → ⋮ → Allow restricted settings.
  static Future<bool> smsNeedsRestrictedSettings() async {
    final before = await Permission.sms.status;
    if (before.isGranted) return false;
    // Always attempt once: a prior "blocked" cache must not skip this (after the
    // user unlocks restricted settings, status can still look permanentlyDenied
    // until a fresh grant succeeds).
    final after = await Permission.sms.request();
    if (after.isGranted) return false;
    if (after.isPermanentlyDenied || after.isRestricted) return true;
    // Denied with no rationale often means the OS blocked the prompt.
    final showRationale = await Permission.sms.shouldShowRequestRationale;
    return !showRationale && after.isDenied;
  }

  /// Requests [p]. Always calls the platform request (never skips permanentlyDenied).
  /// Starts SMS capture when SMS is granted.
  static Future<PermissionOutcome> request(AppPermission p) async {
    final status = await p.permission.request();
    if (status.isGranted) {
      if (p == AppPermission.sms) {
        await SmsService.start();
        await SmsService.importInboxOnce();
      }
      return PermissionOutcome.granted;
    }
    if (p == AppPermission.sms) {
      if (status.isPermanentlyDenied ||
          status.isRestricted ||
          !(await Permission.sms.shouldShowRequestRationale)) {
        return PermissionOutcome.needsRestrictedSettings;
      }
    }
    return PermissionOutcome.denied;
  }

  /// Opens the system app-info page so the user can enable
  /// "Allow restricted settings", then grant SMS / notifications.
  static Future<PermissionOutcome> openSettingsForRestricted() async {
    await openAppSettings();
    return PermissionOutcome.openedSettings;
  }

  /// First-run: ask SMS, then notifications. Returns the SMS outcome.
  static Future<PermissionOutcome> requestAll() async {
    final sms = await request(AppPermission.sms);
    final notif = await Permission.notification.status;
    if (!notif.isGranted) {
      await request(AppPermission.notifications);
    }
    return sms;
  }
}
