import 'package:shared_preferences/shared_preferences.dart';

/// Persisted first-run and profile prefs (name, currency, onboarding flag).
class UserPrefsService {
  UserPrefsService._();

  static const onboardingCompletedKey = 'onboardingCompletedV1';
  static const userNameKey = 'userName';
  static const currencyKey = 'userCurrency';
  static const notificationsKey = 'pref_notifications';
  static const importPastSmsKey = 'pref_import_past_sms';
  static const skipImportKey = 'smsInboxImportSkipV1';

  static Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  static Future<bool> isOnboardingCompleted() async =>
      (await _p).getBool(onboardingCompletedKey) ?? false;

  static Future<void> setOnboardingCompleted(bool v) async =>
      (await _p).setBool(onboardingCompletedKey, v);

  static Future<String> getUserName() async =>
      (await _p).getString(userNameKey) ?? 'User';

  static Future<void> setUserName(String name) async => (await _p).setString(
    userNameKey,
    name.trim().isEmpty ? 'User' : name.trim(),
  );

  static Future<String> getCurrency() async =>
      (await _p).getString(currencyKey) ?? 'INR';

  static Future<void> setCurrency(String code) async =>
      (await _p).setString(currencyKey, code);

  static Future<bool> getNotificationsEnabled() async =>
      (await _p).getBool(notificationsKey) ?? true;

  static Future<void> setNotificationsEnabled(bool v) async =>
      (await _p).setBool(notificationsKey, v);

  static Future<bool> getImportPastSms() async =>
      (await _p).getBool(importPastSmsKey) ?? true;

  static Future<void> setImportPastSms(bool v) async =>
      (await _p).setBool(importPastSmsKey, v);

  /// If the user opted out during onboarding, record it. The inbox is only
  /// ever read from the Inbox scan screen, which the user opens on purpose.
  static Future<void> applyImportPreference() async {
    final prefs = await _p;
    final want = prefs.getBool(importPastSmsKey) ?? true;
    if (!want) {
      await prefs.setBool('smsInboxImportV1', true);
      await prefs.setBool(skipImportKey, true);
    }
  }
}

/// Shared rule for the display name (Profile and onboarding): null when OK,
/// else the inline error. Empty names are rejected rather than saved as
/// "User".
String? validateDisplayName(String name) =>
    name.trim().isEmpty ? 'Enter a name' : null;
