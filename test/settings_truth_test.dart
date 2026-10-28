import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/routes/animation_variants.dart';
import 'package:expensetracker_reloaded/services/app_settings.dart';
import 'package:expensetracker_reloaded/services/event_logger_service.dart';
import 'package:expensetracker_reloaded/utils/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Money.code = 'INR';
  });

  test(
    'currency provider changes every Money label and persists (#4)',
    () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(Money.minor(12050), '₹120.50');
      await c.read(currencyProvider.notifier).set('USD');
      expect(c.read(currencyProvider), 'USD');
      expect(Money.minor(12050), r'$120.50');
      final p = await SharedPreferences.getInstance();
      expect(p.getString('userCurrency'), 'USD');
    },
  );

  test('toggles persist and apply immediately (#11)', () async {
    await AppSettings.set(AppSettings.animationsKey, false);
    await AppSettings.set(AppSettings.eventLoggingKey, false);
    await AppSettings.set(AppSettings.hapticKey, false);
    await AppSettings.set(AppSettings.notificationsKey, false);
    // Simulate restart.
    AppSettings.animations = true;
    AppSettings.eventLogging = true;
    AppSettings.haptics = true;
    await AppSettings.load();
    expect(AppSettings.animations, isFalse);
    expect(AppSettings.eventLogging, isFalse);
    expect(AppSettings.haptics, isFalse);
    expect(await AppSettings.notificationsEnabled(), isFalse);

    final route = AnimationVariants.createRoute(const SizedBox());
    expect((route as PageRoute).transitionDuration, Duration.zero);

    await EventLoggerService.logEvent(
      type: EventType.values.first,
      message: 'x',
    );
    expect(await EventLoggerService.getAllEvents(), isEmpty);

    await AppSettings.set(AppSettings.animationsKey, true);
    await AppSettings.set(AppSettings.eventLoggingKey, true);
    await EventLoggerService.logEvent(
      type: EventType.values.first,
      message: 'y',
    );
    expect(await EventLoggerService.getAllEvents(), hasLength(1));
  });
}
