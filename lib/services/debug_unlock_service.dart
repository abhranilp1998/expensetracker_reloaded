import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of a PIN attempt.
enum PinResult { ok, wrong, lockedOut }

/// Unlocks the Debug area with biometrics or a PIN.
///
/// * PIN: 4-6 digits, stored only as sha256(salt::pin) with a random salt.
/// * After [maxAttempts] wrong tries the PIN is locked for a cooldown that
///   grows with each lockout ([cooldowns]). State lives in SharedPreferences,
///   so killing the app does not reset it. A correct PIN or biometric clears it.
class DebugUnlockService {
  DebugUnlockService._();

  static const _pinHashKey = 'debugPinHashV1';
  static const _pinSaltKey = 'debugPinSaltV1';
  static const _failsKey = 'debugPinFails';
  static const _levelKey = 'debugPinLockLevel';
  static const _untilKey = 'debugPinLockedUntilMs';

  static const maxAttempts = 5;
  static const cooldowns = [
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];

  static bool sessionUnlocked = false;

  /// Clock hook for tests.
  static DateTime Function() now = DateTime.now;

  static final _auth = LocalAuthentication();
  static Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  /// Null when [pin] is acceptable, else a message for the user.
  static String? validatePin(String pin) {
    if (pin.isEmpty) return 'Enter a PIN';
    if (!RegExp(r'^\d+$').hasMatch(pin)) return 'Digits only';
    if (pin.length < 4 || pin.length > 6) return 'PIN must be 4-6 digits';
    return null;
  }

  static String hashPin(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt::$pin')).toString();

  static String _newSalt() {
    final r = Random.secure();
    return base64Url.encode(List.generate(16, (_) => r.nextInt(256)));
  }

  static Future<bool> hasPin() async =>
      (await _p).getString(_pinHashKey) != null;

  static Future<void> setPin(String pin) async {
    final err = validatePin(pin);
    if (err != null) throw ArgumentError(err);
    final salt = _newSalt();
    final prefs = await _p;
    await prefs.setString(_pinSaltKey, salt);
    await prefs.setString(_pinHashKey, hashPin(pin, salt));
    await _clearLockout(prefs);
  }

  static Future<void> removePin() async {
    final prefs = await _p;
    await prefs.remove(_pinSaltKey);
    await prefs.remove(_pinHashKey);
    await _clearLockout(prefs);
    sessionUnlocked = false;
  }

  /// Pure hash check; does not count attempts.
  static Future<bool> verifyPin(String pin) async {
    final prefs = await _p;
    final salt = prefs.getString(_pinSaltKey);
    final expected = prefs.getString(_pinHashKey);
    if (salt == null || expected == null) return false;
    return hashPin(pin, salt) == expected;
  }

  /// Time left before another PIN try is allowed (zero if not locked).
  static Future<Duration> lockRemaining() async {
    final until = (await _p).getInt(_untilKey) ?? 0;
    final left = until - now().millisecondsSinceEpoch;
    return left > 0 ? Duration(milliseconds: left) : Duration.zero;
  }

  /// Checks [pin], counting wrong tries and applying lockouts.
  static Future<PinResult> attemptPin(String pin) async {
    if (await lockRemaining() > Duration.zero) return PinResult.lockedOut;
    final prefs = await _p;
    if (await verifyPin(pin)) {
      await _clearLockout(prefs);
      return PinResult.ok;
    }
    final fails = (prefs.getInt(_failsKey) ?? 0) + 1;
    if (fails < maxAttempts) {
      await prefs.setInt(_failsKey, fails);
      return PinResult.wrong;
    }
    final level = prefs.getInt(_levelKey) ?? 0;
    final wait = cooldowns[min(level, cooldowns.length - 1)];
    await prefs.setInt(_failsKey, 0);
    await prefs.setInt(_levelKey, level + 1);
    await prefs.setInt(_untilKey, now().add(wait).millisecondsSinceEpoch);
    return PinResult.lockedOut;
  }

  /// Wrong tries left before the next lockout.
  static Future<int> attemptsLeft() async =>
      maxAttempts - ((await _p).getInt(_failsKey) ?? 0);

  static Future<void> _clearLockout(SharedPreferences prefs) async {
    await prefs.remove(_failsKey);
    await prefs.remove(_levelKey);
    await prefs.remove(_untilKey);
  }

  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Biometric/device-credential check, allowed even during a PIN lockout.
  static Future<bool> verifyBiometric() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Ledgerly Debug',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (ok) await _clearLockout(await _p);
      return ok;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> unlockWithBiometric() async {
    final ok = await verifyBiometric();
    if (ok) sessionUnlocked = true;
    return ok;
  }

  static Future<bool> unlockWithPin(String pin) async {
    final ok = await attemptPin(pin) == PinResult.ok;
    if (ok) sessionUnlocked = true;
    return ok;
  }

  static void lock() => sessionUnlocked = false;
}
