import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unlock Debug drawer items with biometric or a PIN (hashed, salted).
class DebugUnlockService {
  DebugUnlockService._();

  static const _pinHashKey = 'debugPinHashV1';
  static const _pinSaltKey = 'debugPinSaltV1';
  static bool sessionUnlocked = false;

  static final _auth = LocalAuthentication();

  static Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  static Future<bool> hasPin() async =>
      (await _p).getString(_pinHashKey) != null;

  static Future<void> setPin(String pin) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final hash = _hash(pin, salt);
    final prefs = await _p;
    await prefs.setString(_pinSaltKey, salt);
    await prefs.setString(_pinHashKey, hash);
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await _p;
    final salt = prefs.getString(_pinSaltKey);
    final expected = prefs.getString(_pinHashKey);
    if (salt == null || expected == null) return false;
    return _hash(pin, salt) == expected;
  }

  static String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt::$pin')).toString();

  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> unlockWithBiometric() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Ledgerly Debug',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (ok) sessionUnlocked = true;
      return ok;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> unlockWithPin(String pin) async {
    final ok = await verifyPin(pin);
    if (ok) sessionUnlocked = true;
    return ok;
  }

  static void lock() => sessionUnlocked = false;
}
