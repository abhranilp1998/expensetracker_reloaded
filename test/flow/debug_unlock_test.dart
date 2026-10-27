import 'package:expensetracker_reloaded/services/debug_unlock_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DebugUnlockService.lock();
  });

  test('PIN set and verify', () async {
    expect(await DebugUnlockService.hasPin(), isFalse);
    await DebugUnlockService.setPin('1234');
    expect(await DebugUnlockService.hasPin(), isTrue);
    expect(await DebugUnlockService.verifyPin('1234'), isTrue);
    expect(await DebugUnlockService.verifyPin('9999'), isFalse);
  });

  test('unlockWithPin sets session flag', () async {
    await DebugUnlockService.setPin('4321');
    expect(DebugUnlockService.sessionUnlocked, isFalse);
    expect(await DebugUnlockService.unlockWithPin('4321'), isTrue);
    expect(DebugUnlockService.sessionUnlocked, isTrue);
    DebugUnlockService.lock();
    expect(DebugUnlockService.sessionUnlocked, isFalse);
  });
}
