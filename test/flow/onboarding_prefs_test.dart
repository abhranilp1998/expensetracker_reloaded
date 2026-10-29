import 'package:expensetracker_reloaded/services/user_prefs_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('onboarding flag defaults false then persists true', () async {
    expect(await UserPrefsService.isOnboardingCompleted(), isFalse);
    await UserPrefsService.setOnboardingCompleted(true);
    expect(await UserPrefsService.isOnboardingCompleted(), isTrue);
  });

  test('name and currency round-trip', () async {
    await UserPrefsService.setUserName('Abhranil');
    await UserPrefsService.setCurrency('USD');
    expect(await UserPrefsService.getUserName(), 'Abhranil');
    expect(await UserPrefsService.getCurrency(), 'USD');
  });

  test('import opt-out marks inbox import done', () async {
    await UserPrefsService.setImportPastSms(false);
    await UserPrefsService.applyImportPreference();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('smsInboxImportV1'), isTrue);
  });
}
